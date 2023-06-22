pragma solidity >=0.8.4;

import "./IPriceOracle.sol";

interface IETHRegistrarController {
    event NewPriceOracle(address indexed oracle);
    function setPriceOracle(IPriceOracle _prices) external;

    function price(string memory) external returns (uint);

    function available(string memory) external returns (bool);
    function reserved(string memory, address sender) external returns (bool);

    function makeCommitment(string memory name, address owner, bytes32 secret) pure external returns(bytes32);
    function makeCommitmentWithConfig(string memory name, address owner, bytes32 secret, address resolver, address addr) pure external returns(bytes32);
    function register(string calldata name, address owner, bytes32 secret) external payable;
    function registerWithConfig(string memory name, address owner, bytes32 secret, address resolver, address addr) external payable;

    function commit(bytes32) external;
}