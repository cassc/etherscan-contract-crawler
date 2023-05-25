pragma solidity >=0.8.4;

interface IETHRegistrarController {
    function rentPrice(string memory, uint) external view returns (uint);

    function available(string memory) external returns (bool);

    function commit(bytes32) external;

    function register(string calldata, address, uint256, bytes32) external payable;

    function registerWithConfig(string memory, address, uint256, bytes32, address, address) external payable;

    function makeCommitmentWithConfig(string memory, address, bytes32, address, address) external pure returns (bytes32);

    function renew(string calldata, uint256) external payable;

    function commitments(bytes32) external view returns (uint256);
}