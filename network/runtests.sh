#!/usr/bin/env bash

# run_tests.sh — sequential CLI smoke tests for incidentcc
# Usage:
#   cd network
#   ./run_tests.sh

set -e

# common vars
export PATH=../bin:$PATH
export FABRIC_CFG_PATH=../config
ORDERER_CA=$PWD/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
CHANNEL="mychannel"
CC_NAME="incidentcc"

function pause(){
  echo
  read -p "⏸  Press Enter to run next test... " _
  echo
}

function org1_env(){
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_LOCALMSPID="Org1MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  export CORE_PEER_ADDRESS=localhost:7051
}

function org2_env(){
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_LOCALMSPID="Org2MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
  export CORE_PEER_ADDRESS=localhost:9051
}

function org3_env(){
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_LOCALMSPID="Org3MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
  export CORE_PEER_ADDRESS=localhost:11051
}

echo
echo "▶ Running incidentcc smoke tests on channel '$CHANNEL'"
echo

# 1) Init ledger
echo "=== Test 1: InitLedger (just in case) ==="
org1_env
peer chaincode invoke \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls --cafile "$ORDERER_CA" \
  -C $CHANNEL -n $CC_NAME \
  -c '{"function":"InitLedger","Args":[]}'
pause

# 2) Query all (should show initial INC001…INC006 + any past)
echo "=== Test 2: GetAllIncidents ==="
org1_env
peer chaincode query -C $CHANNEL -n $CC_NAME \
  -c '{"Args":["GetAllIncidents"]}'
pause

# 3) Create a new incident (unique)
echo "=== Test 3: CreateIncident INC100 ==="
org1_env
peer chaincode invoke \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls --cafile "$ORDERER_CA" \
  -C $CHANNEL -n $CC_NAME \
  --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE \
  -c '{"function":"CreateIncident","Args":["INC100","CLI smoke test","StationA","Open","2025-05-08T10:00:00Z"]}'
pause

# 4) Query again (INC100 should appear)
echo "=== Test 4: GetAllIncidents (after INC100) ==="
org1_env
peer chaincode query -C $CHANNEL -n $CC_NAME \
  -c '{"Args":["GetAllIncidents"]}'
pause

# 5) Duplicate-ID check
echo "=== Test 5: CreateIncident duplicate INC100 (should error) ==="
org1_env
set +e
peer chaincode invoke \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls --cafile "$ORDERER_CA" \
  -C $CHANNEL -n $CC_NAME \
  --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE \
  -c '{"function":"CreateIncident","Args":["INC100","Duplicate test","StationA","Open","2025-05-08T11:00:00Z"]}'
set -e
pause

# 6) Read existing
echo "=== Test 6: ReadIncident INC100 ==="
org1_env
peer chaincode query -C $CHANNEL -n $CC_NAME \
  -c '{"Args":["ReadIncident","INC100"]}'
pause

# 7) Read non-existent
echo "=== Test 7: ReadIncident INC999 (should error) ==="
org1_env
set +e
peer chaincode query -C $CHANNEL -n $CC_NAME \
  -c '{"Args":["ReadIncident","INC999"]}'
set -e
pause

# 8) Update status
echo "=== Test 8: UpdateIncidentStatus INC100→Closed ==="
org1_env
peer chaincode invoke \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls --cafile "$ORDERER_CA" \
  -C $CHANNEL -n $CC_NAME \
  --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE \
  -c '{"function":"UpdateIncidentStatus","Args":["INC100","Closed"]}'
pause

# 9) Verify update
echo "=== Test 9: ReadIncident INC100 (status Closed) ==="
org1_env
peer chaincode query -C $CHANNEL -n $CC_NAME \
  -c '{"Args":["ReadIncident","INC100"]}'
pause

# 10) Update non-existent
echo "=== Test 10: UpdateIncidentStatus INC999 (should error) ==="
org1_env
set +e
peer chaincode invoke \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls --cafile "$ORDERER_CA" \
  -C $CHANNEL -n $CC_NAME \
  --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE \
  -c '{"function":"UpdateIncidentStatus","Args":["INC999","Closed"]}'
set -e
pause

# 11) Query from Org2
echo "=== Test 11: GetAllIncidents (Org2 context) ==="
org2_env
peer chaincode query -C $CHANNEL -n $CC_NAME \
  -c '{"Args":["GetAllIncidents"]}'
pause

# 12) Query from Org3
echo "=== Test 12: GetAllIncidents (Org3 context) ==="
org3_env
peer chaincode query -C $CHANNEL -n $CC_NAME \
  -c '{"Args":["GetAllIncidents"]}'
pause

# 13) Endorsement‐policy check (Org1+Org2+Org3)
echo "=== Test 13: CreateIncident INC101 via all three peers ==="
org1_env
peer chaincode invoke \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls --cafile "$ORDERER_CA" \
  -C $CHANNEL -n $CC_NAME \
  --peerAddresses localhost:7051       --tlsRootCertFiles $PWD/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
  --peerAddresses localhost:9051       --tlsRootCertFiles $PWD/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
  --peerAddresses localhost:11051      --tlsRootCertFiles $PWD/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt \
  -c '{"function":"CreateIncident","Args":["INC101","Endorsement test","StationB","Open","2025-05-08T12:00:00Z"]}'
pause

# 14) Final state
echo "=== Test 14: GetAllIncidents (final) ==="
org1_env
peer chaincode query -C $CHANNEL -n $CC_NAME \
  -c '{"Args":["GetAllIncidents"]}'
pause

echo "✅ All done!"