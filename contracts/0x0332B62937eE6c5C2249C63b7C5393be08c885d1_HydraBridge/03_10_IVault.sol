// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IVault {
    function lock(
        bytes32 assetId,
        uint8 chainId,
        uint64 nonce,
        address user,
        bytes calldata data
    ) external payable;

    function execute(bytes32 assetId, bytes calldata data) external;

    function setAsset(bytes32 assetId, address tokenAddress) external;

    function setBurnable(address tokenAddress) external;
}