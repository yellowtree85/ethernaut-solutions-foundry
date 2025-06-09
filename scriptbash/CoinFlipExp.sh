#!/bin/bash
# On Sepolia!
source .env
# COINFLIP_ADDRESS="0x9A4d4d6A6467D0869AD45E8220958a56421d7B2F"
# SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/Qgj1xB_R16qJTLiMqlM46bmi0xUTEXsJ"
echo "#####################Sepolia############################"
echo "Running the script to call CoinFlip contracts on Sepolia..."
for i in {1..10}
do
    echo "[$i] call flip..."
    forge script script/CoinFlipExp.s.sol:Exp --rpc-url ${SEPOLIA_RPC_URL} --account updraft --broadcast -vvvvv
    # CONSECUTIVE_WINS=$(cast call ${COINFLIP_ADDRESS} "consecutiveWins()" --rpc-url ${SEPOLIA_RPC_URL})
    # echo "current consecutiveWins: $CONSECUTIVE_WINS"
    echo "waiting 60 seconds before next tx..."
    sleep 60
done