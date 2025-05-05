package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/v2/contractapi"
)

// IncidentContract manages incident records
type IncidentContract struct {
	contractapi.Contract
}

// Incident defines the structure of an incident report
type Incident struct {
	ID           string `json:"ID"`
	Description  string `json:"Description"`
	Reporter     string `json:"Reporter"`
	Status       string `json:"Status"`
	IncidentTime string `json:"IncidentTime"` // when it occurred
	LastUpdated  string `json:"LastUpdated"`  // when it was changed
}

// InitLedger preloads the ledger with sample data (optional)
func (s *IncidentContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	incidents := []Incident{
		{
			ID:           "INC001",
			Description:  "Suspicious vehicle reported",
			Reporter:     "StationA",
			Status:       "Open",
			IncidentTime: "2025-05-05T08:00:00Z",
			LastUpdated:  time.Now().Format(time.RFC3339),
		},
	}

	for _, inc := range incidents {
		incJSON, err := json.Marshal(inc)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(inc.ID, incJSON)
		if err != nil {
			return fmt.Errorf("failed to store incident: %v", err)
		}
	}

	return nil
}

// CreateIncident adds a new incident to the ledger
func (s *IncidentContract) CreateIncident(ctx contractapi.TransactionContextInterface, id, description, reporter, status, incidentTime string) error {
	exists, err := s.IncidentExists(ctx, id)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("incident %s already exists", id)
	}

	incident := Incident{
		ID:           id,
		Description:  description,
		Reporter:     reporter,
		Status:       status,
		IncidentTime: incidentTime,
		LastUpdated:  time.Now().Format(time.RFC3339),
	}

	incidentJSON, err := json.Marshal(incident)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, incidentJSON)
}

// ReadIncident retrieves an incident by ID
func (s *IncidentContract) ReadIncident(ctx contractapi.TransactionContextInterface, id string) (*Incident, error) {
	data, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, err
	}
	if data == nil {
		return nil, fmt.Errorf("incident %s not found", id)
	}

	var incident Incident
	err = json.Unmarshal(data, &incident)
	if err != nil {
		return nil, err
	}

	return &incident, nil
}

// UpdateIncidentStatus updates only the status and last updated time
func (s *IncidentContract) UpdateIncidentStatus(ctx contractapi.TransactionContextInterface, id, newStatus string) error {
	incident, err := s.ReadIncident(ctx, id)
	if err != nil {
		return err
	}

	incident.Status = newStatus
	incident.LastUpdated = time.Now().Format(time.RFC3339)

	incidentJSON, err := json.Marshal(incident)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, incidentJSON)
}

// IncidentExists returns true if the given ID exists in world state
func (s *IncidentContract) IncidentExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	data, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, err
	}
	return data != nil, nil
}

// GetAllIncidents returns all stored incidents
func (s *IncidentContract) GetAllIncidents(ctx contractapi.TransactionContextInterface) ([]*Incident, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var results []*Incident
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var incident Incident
		if err := json.Unmarshal(queryResponse.Value, &incident); err != nil {
			return nil, err
		}
		results = append(results, &incident)
	}

	return results, nil
}
