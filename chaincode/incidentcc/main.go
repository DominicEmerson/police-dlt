package main

import (
	"log"

	"github.com/hyperledger/fabric-contract-api-go/v2/contractapi"
)

func main() {
	chaincode, err := contractapi.NewChaincode(new(IncidentContract))
	if err != nil {
		log.Panicf("Error creating incidentcc chaincode: %v", err)
	}

	if err := chaincode.Start(); err != nil {
		log.Panicf("Error starting incidentcc chaincode: %v", err)
	}
}

