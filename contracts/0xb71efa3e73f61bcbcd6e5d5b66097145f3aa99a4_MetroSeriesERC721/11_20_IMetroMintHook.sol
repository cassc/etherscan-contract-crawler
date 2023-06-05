//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IMetroMintHook
{
    function internalMintHook(uint256 seriesId, uint256 tokenId, uint8 saleType) external;
}