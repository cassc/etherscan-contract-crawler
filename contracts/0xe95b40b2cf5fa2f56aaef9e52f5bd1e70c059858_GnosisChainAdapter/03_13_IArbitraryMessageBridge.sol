// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArbitraryMessageBridge {
    function messageSender() external view returns (address);
    function messageSourceChainId() external view returns (uint256);
    function requireToPassMessage(address _contract, bytes memory _data, uint256 _gas) external returns (bytes32);
    function destinationChainId() external view returns (uint256);
}