// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IOpenSkyReserveVaultFactory {
    event Create(uint256 indexed reserveId, string name, string symbol, uint8 decimals, address indexed underlyingAsset);

    function create(
        uint256 reserveId,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address underlyingAsset
    ) external returns (address oTokenAddress);
}