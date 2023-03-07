// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPlantRenderer {
    function growPlant(uint16 tokenId) external;

    function addAddress(uint16 tokenId, address newAddress) external;

    function tokenUri(uint16 id) external view returns (string memory);
}