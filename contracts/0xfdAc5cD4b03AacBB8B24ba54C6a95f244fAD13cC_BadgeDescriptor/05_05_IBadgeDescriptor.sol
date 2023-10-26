// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IBadgeDescriptor {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function setBaseURI(string memory newBaseURI) external;
}