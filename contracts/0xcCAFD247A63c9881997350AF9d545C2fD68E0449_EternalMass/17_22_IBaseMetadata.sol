// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.17;

interface IBaseMetadata {

    /**
     * @notice Generate random values from _input
     * @param _input The NFT token id to get the token metadata
     * @return the seed value converted from keccak256 by uint256
     */
    function seed(uint256 _input) external view returns (uint256);

    /**
     * @notice Generates male or female
     * @param tokenId The NFT token id to get gender
     * @return Generated gender string
     */
    function generateGender(uint256 tokenId) external view returns (string memory);

    /**
     * @notice Get sales phase
     * @param tokenId The NFT token id to get the wave
     * @return either 1st or 2nd
     */
    function getWave(uint256 tokenId) external view returns (string memory);

    /**
     * @notice Get the description
     */
    function description() external view returns (string memory);

    /**
     * @notice Get the external url
     */
    function externalUrl() external view returns (string memory);

}