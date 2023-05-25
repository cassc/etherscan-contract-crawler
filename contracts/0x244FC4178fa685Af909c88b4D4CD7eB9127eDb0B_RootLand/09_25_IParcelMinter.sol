// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IParcelMinter {
    function allocatedParcels(uint256 tokenId) external view returns (address);
}