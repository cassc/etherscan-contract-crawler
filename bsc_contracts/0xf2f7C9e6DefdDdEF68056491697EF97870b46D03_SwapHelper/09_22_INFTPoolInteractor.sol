// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

/// @notice
/// @param pool Address of liquidity pool
/// @param manager NFT manager contract, such as uniswap V3 positions manager
/// @param tokenId ID representing NFT
/// @param liquidity Amount of liquidity, used when converting part of the NFT to some other asset
/// @param data Data used when creating the NFT position, contains int24 tickLower, int24 tickUpper, uint minAmount0 and uint minAmount1
struct Asset {
    address pool;
    address manager;
    uint tokenId;
    uint liquidity;
    bytes data;
}

interface INFTPoolInteractor {
    function burn(
        Asset memory asset
    ) external payable returns (address[] memory receivedTokens, uint256[] memory receivedTokenAmounts);

    function mint(
        Asset memory toMint,
        address[] memory underlyingTokens,
        uint256[] memory underlyingAmounts,
        address receiver
    ) external payable returns (uint256);

    function simulateMint(
        Asset memory toMint,
        address[] memory underlyingTokens,
        uint[] memory underlyingAmounts
    ) external view returns (uint);

    function getRatio(address poolAddress, int24 tick0, int24 tick1) external view returns (uint, uint);

    function testSupported(address token) external view returns (bool);

    function testSupportedPool(address token) external view returns (bool);

    function getUnderlyingAmount(
        Asset memory nft
    ) external view returns (address[] memory underlying, uint[] memory amounts);

    function getUnderlyingTokens(address lpTokenAddress) external view returns (address[] memory);
}