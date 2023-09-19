// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICryptoPunksData {
    /**
     * @dev Retrieve base type and attributes of a Punk
     * @param index Punk Index
     * @return Base type and attributes of a Punk, separated by a comma in a single string
     */
    function punkAttributes(uint16 index) external view returns (string memory);
}