#!/bin/bash

# Dedicated cache miss test script to generate cache miss metrics

set -e

# Configuration
BASE_URL="http://localhost:9000"
DURATION=30  # 30 seconds of intensive cache miss testing

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting intensive cache miss test for ${DURATION} seconds...${NC}"
echo -e "${BLUE}Base URL: ${BASE_URL}${NC}"
echo ""

# Function to test various cache miss patterns
test_pattern_cache_misses() {
    local pattern=$1
    local count=0
    
    while [ $SECONDS -lt $DURATION ]; do
        # Generate keys with specific patterns
        key="${pattern}_$(date +%s)_$$_$RANDOM"
        curl -s "${BASE_URL}/items/$key" > /dev/null
        count=$((count + 1))
        sleep 0.1
    done
    echo -e "${GREEN}Pattern '$pattern' cache misses completed: $count requests${NC}"
}

# Function to test sequential cache misses
test_sequential_cache_misses() {
    local count=0
    local base_key="sequential_miss"
    
    while [ $SECONDS -lt $DURATION ]; do
        key="${base_key}_$count"
        curl -s "${BASE_URL}/items/$key" > /dev/null
        count=$((count + 1))
        sleep 0.05
    done
    echo -e "${GREEN}Sequential cache misses completed: $count requests${NC}"
}

# Function to test random cache misses
test_random_cache_misses() {
    local count=0
    
    while [ $SECONDS -lt $DURATION ]; do
        # Generate completely random keys
        random_key="random_$(openssl rand -hex 4)_$(date +%s)"
        curl -s "${BASE_URL}/items/$random_key" > /dev/null
        count=$((count + 1))
        sleep 0.08
    done
    echo -e "${GREEN}Random cache misses completed: $count requests${NC}"
}

# Function to test expired key patterns
test_expired_key_patterns() {
    local count=0
    
    while [ $SECONDS -lt $DURATION ]; do
        # Simulate expired keys with timestamp patterns
        timestamp=$(date +%s)
        expired_key="expired_$((timestamp - 3600))_$RANDOM"  # Keys from 1 hour ago
        curl -s "${BASE_URL}/items/$expired_key" > /dev/null
        count=$((count + 1))
        sleep 0.12
    done
    echo -e "${GREEN}Expired key pattern cache misses completed: $count requests${NC}"
}

# Check if the app is running
echo -e "${BLUE}Checking if the Flask app is running...${NC}"
if ! curl -s "${BASE_URL}/" > /dev/null; then
    echo -e "${RED}Error: Flask app is not running at ${BASE_URL}${NC}"
    echo -e "Please start the app first with: docker compose up"
    exit 1
fi

echo -e "${GREEN}Flask app is running!${NC}"

# Start the timer
SECONDS=0

echo -e "\n${YELLOW}Starting intensive cache miss testing...${NC}"
echo -e "${YELLOW}This will generate various patterns of cache misses for better metrics visualization${NC}"

# Start all cache miss test functions in parallel
test_pattern_cache_misses "user_profile" &
test_pattern_cache_misses "product_data" &
test_pattern_cache_misses "session_info" &
test_sequential_cache_misses &
test_random_cache_misses &
test_expired_key_patterns &

# Wait for all background jobs to complete
wait

echo -e "\n${GREEN}Intensive cache miss test completed!${NC}"
echo -e "${BLUE}Check your Grafana dashboard to see the cache miss rate metrics${NC}"

# Show current cache miss metrics
echo -e "\n${YELLOW}Current cache miss metrics:${NC}"
curl -s http://localhost:9000/metrics | grep "redis_app_cache_miss_total" | head -10
