pragma solidity ^0.8.0;

interface EnsResolver {
    function setAddr(bytes32 node, address addr) external;

    function addr(bytes32 node) external view returns (address);
}
