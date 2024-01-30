yarn start notice list | awk 'NR==4' | jq '.[] | select(.payload | contains("wier") | not).payload' | jq -r . | jq .promptLLMResponse
