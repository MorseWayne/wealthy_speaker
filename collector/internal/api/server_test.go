package api

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHealthResponse(t *testing.T) {
	resp := HealthResponse{
		Status:    "healthy",
		Timestamp: "2024-01-16T12:00:00Z",
		Database:  "healthy",
		Version:   "1.0.0",
	}

	if resp.Status != "healthy" {
		t.Errorf("Expected status 'healthy', got '%s'", resp.Status)
	}
	if resp.Version != "1.0.0" {
		t.Errorf("Expected version '1.0.0', got '%s'", resp.Version)
	}
}

func TestMustParseInt(t *testing.T) {
	tests := []struct {
		input    string
		defVal   int
		expected int
	}{
		{"10", 5, 10},
		{"", 5, 5},
		{"abc", 5, 5},
		{"0", 5, 5},
		{"100", 20, 100},
	}

	for _, test := range tests {
		result := mustParseInt(test.input, test.defVal)
		if result != test.expected {
			t.Errorf("mustParseInt(%q, %d) = %d, expected %d", test.input, test.defVal, result, test.expected)
		}
	}
}

func TestServerCreation(t *testing.T) {
	server := NewServer(":8080")

	if server == nil {
		t.Fatal("Expected server to be created")
	}
	if server.router == nil {
		t.Error("Expected router to be initialized")
	}
	if server.srv == nil {
		t.Error("Expected http.Server to be initialized")
	}
}

func TestHandleRoot(t *testing.T) {
	server := NewServer(":8080")

	req, err := http.NewRequest("GET", "/", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	server.router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("Expected status %d, got %d", http.StatusOK, rr.Code)
	}

	var response map[string]interface{}
	if err := json.NewDecoder(rr.Body).Decode(&response); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}

	if response["message"] != "Financial Summary Data Collector API" {
		t.Errorf("Unexpected message: %v", response["message"])
	}
}

func TestJSONResponse(t *testing.T) {
	server := NewServer(":8080")
	rr := httptest.NewRecorder()

	testData := map[string]string{"test": "value"}
	server.jsonResponse(rr, http.StatusOK, testData)

	if rr.Code != http.StatusOK {
		t.Errorf("Expected status %d, got %d", http.StatusOK, rr.Code)
	}

	contentType := rr.Header().Get("Content-Type")
	if contentType != "application/json" {
		t.Errorf("Expected Content-Type 'application/json', got '%s'", contentType)
	}
}

func TestErrorResponse(t *testing.T) {
	server := NewServer(":8080")
	rr := httptest.NewRecorder()

	server.errorResponse(rr, http.StatusBadRequest, "test error")

	if rr.Code != http.StatusBadRequest {
		t.Errorf("Expected status %d, got %d", http.StatusBadRequest, rr.Code)
	}

	var response map[string]string
	if err := json.NewDecoder(rr.Body).Decode(&response); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}

	if response["error"] != "test error" {
		t.Errorf("Expected 'test error', got '%s'", response["error"])
	}
}
