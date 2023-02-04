pragma solidity ^0.5.0;

contract ENS {
    function resolver(bytes32 node) external view returns (Resolver);
}

contract Resolver {
    function addr(bytes32 node) external view returns (address);
}