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
