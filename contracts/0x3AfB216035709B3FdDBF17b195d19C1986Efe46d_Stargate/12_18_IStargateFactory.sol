// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IStargateFactory {
    function getPool(uint256) external view returns (address);

    function allPoolsLength() external view returns (uint256);

    function createPool(
        uint256 _poolId,
        address _token,
        uint8 _sharedDecimals,
        uint8 _localDecimals,
        string memory _name,
        string memory _symbol
    ) external view returns (address);
}