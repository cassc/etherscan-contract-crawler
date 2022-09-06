// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ISFTD {
    function burn(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function reserveMint(uint256 reservedAmount, address mintAddress) external;

    function totalSupply() external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function transferOwnership(address newOwner) external;
}