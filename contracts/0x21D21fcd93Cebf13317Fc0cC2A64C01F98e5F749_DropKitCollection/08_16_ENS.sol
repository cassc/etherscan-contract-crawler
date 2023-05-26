// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract ENS {
    function resolver(bytes32 node) public view virtual returns (Resolver);
}

abstract contract Resolver {
    function addr(bytes32 node) public view virtual returns (address);
}