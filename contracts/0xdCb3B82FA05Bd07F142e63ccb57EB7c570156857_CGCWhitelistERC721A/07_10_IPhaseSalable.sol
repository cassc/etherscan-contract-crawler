// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ICGCMintVersion.sol";

/// @title The interface of several phases of NFT sale.
interface IPhaseSalable is ICGCMintVersion {
    struct SaleInfo {
        uint256 mintStartTime; // Start timestamp of minting
        uint256 mintEndTime; // End timestamp of minting
        bytes32 merkleRoot; // Merkle Tree Root Hash
        uint256 mintPrice; // Token Mint Price
        uint256 mintAmount; // Token Mint Amount
        uint256 maxPerUser; // Max mint amount per user
    }

    event SetupSaleInfo(uint256 saleId, SaleInfo info);

    event Withdrew(uint256 amount);

    function maxSupply() external view returns (uint256);

    function saleId() external view returns (uint256);

    function saleInfo(uint256 _saleId) external view returns (SaleInfo memory);

    function activeSaleInfo() external view returns (SaleInfo memory);

    function mintedAmount(uint256 _saleId) external view returns (uint256);

    function mintedAmountOf(uint256 _saleId, address _account) external view returns (uint256);

    function whitelistSale(
        uint256 _index,
        bytes32[] calldata _proof,
        uint256 _maxAmount,
        uint256 _amount
    ) external payable;

    function publicSale(uint256 _amount) external payable;

    function setupWhitelistSale(
        bytes32 _merkleRoot,
        uint256 _mintStartTime,
        uint256 _mintEndTime,
        uint256 _mintPrice,
        uint256 _mintAmount
    ) external;

    function setupPublicSale(
        uint256 _mintStartTime,
        uint256 _mintEndTime,
        uint256 _mintPrice,
        uint256 _mintAmount,
        uint256 _maxPerUser
    ) external;

    function withdraw(address _to) external;
}