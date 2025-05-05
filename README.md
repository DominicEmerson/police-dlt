# Police DLT System (Hyperledger Fabric)

A prototype distributed ledger system for incident logging and controlled access between police stations, built using Hyperledger Fabric.

---

## 📁 Project Structure

police-dlt/
├── bin/ # Fabric CLI tools (peer, configtxgen, etc.)
├── chaincode/
│ └── incidentcc/ # Custom Go chaincode for incident reporting
├── config/ # Fabric core configs
├── network/ # Fabric network setup and scripts

## ⚙️ Current State

- ✅ Fabric network with **Org1** and **Org2** deployed
- ✅ Custom chaincode `incidentcc` written in Go
- ✅ Chaincode deployed and successfully invoked on `mychannel`
- ✅ Chaincode operations:
  - `InitLedger`: preload sample incident
  - `CreateIncident`: add new reports
  - `GetAllIncidents`: query all incidents
  - `ReadIncident`, `UpdateIncidentStatus`, etc.

---

## 🔒 Endorsement Policy

The default policy is:

```text
AND('Org1MSP.peer', 'Org2MSP.peer')

🧪 How to Test
1. Start the network
bash
Copy
Edit
cd network
./network.sh up createChannel

2. Deploy chaincode
bash
Copy
Edit
./network.sh deployCC -ccn incidentcc -ccp ../chaincode/incidentcc -ccl go

export PATH=../bin:$PATH
export FABRIC_CFG_PATH=../config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

# Create an incident
peer chaincode invoke -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile "$PWD/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
  -C mychannel -n incidentcc \
  --peerAddresses localhost:7051 \
  --tlsRootCertFiles "$PWD/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" \
  --peerAddresses localhost:9051 \
  --tlsRootCertFiles "$PWD/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" \
  -c '{"function":"CreateIncident","Args":["INC003","Trespassing reported","StationA","Open","2025-05-05T09:00:00Z"]}'


🗂 Future Plans
 Add Org3: Central Command

 Access control by MSP identity

 Audit log of updates to incidents

 Django REST API + frontend interface

 CI/CD and persistent volumes for production
