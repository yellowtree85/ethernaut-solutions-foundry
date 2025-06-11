#!/bin/bash
# On Sepolia!
source .env

MAX_CALLS=2  # 👉 Set call count here

echo "#####################Sepolia############################"
echo "Running the script to call CoinFlip contracts on Sepolia..."

for ((i = 1; i <= MAX_CALLS; i++)); do
    echo "[$i/$MAX_CALLS] call flip..."
    forge script script/CoinFlipExp.s.sol:onChainExp \
        --rpc-url ${SEPOLIA_RPC_URL} \
        --account updraft \
        --sender ${ACCOUNT_SEPOLIA} \
        --broadcast -vvvvv

    if [ "$i" -lt "$MAX_CALLS" ]; then
        echo "waiting 40 seconds before next tx..."
        sleep 40
    fi
done

echo "All done!"
echo "#####################Sepolia############################"
