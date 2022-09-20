pragma solidity ^0.8.17;

interface IENSReverseRegistrar {
    function claim(address owner) external returns (bytes32);
    function defaultResolver() view external returns (address);
    function ens() view external returns (address);
    function node(address addr) pure external returns (bytes32);
    function setName(string memory name) external returns (bytes32);
}