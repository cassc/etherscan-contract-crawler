// SPDX-License-Identifier: MIT
// Author: Daniel Von Fange (@DanielVF)
pragma solidity ^0.8.16;

import "./DividedPool.sol";

contract DividedFactory {
    mapping(address => address) public pools;
    bytes32 public POOL_BYTECODE_HASH = keccak256(type(DividedPool).creationCode);
    address public deployNftContract;

    event PoolCreated(address collection, address pool);

    function deploy(address collection) external returns (address) {
        deployNftContract = collection;
        address pool = address(new DividedPool{salt:keccak256(abi.encode(collection))}());
        pools[collection] = pool;
        emit PoolCreated(collection, pool);
        return pool;
    }
}