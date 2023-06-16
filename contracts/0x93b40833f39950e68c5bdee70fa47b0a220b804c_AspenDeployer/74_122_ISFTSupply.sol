// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

interface ISFTSupplyV0 {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);

    /**
     * @dev Amount of unique tokens minted.
     */
    function getLargestTokenId() external view returns (uint256);
}

interface ISFTSupplyV1 is ISFTSupplyV0 {
    /// @dev Offset for token IDs.
    function getSmallestTokenId() external view returns (uint8);
}

interface IPublicSFTSupplyV0 {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);
}

interface IPublicSFTSupplyV1 {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);
}

interface IDelegatedSFTSupplyV0 {
    /**
     * @dev Amount of unique tokens minted.
     */
    function getLargestTokenId() external view returns (uint256);

    /// @dev Offset for token IDs.
    function getSmallestTokenId() external view returns (uint8);
}

interface IDelegatedSFTSupplyV1 is IDelegatedSFTSupplyV0 {
    function exists(uint256 id) external view returns (bool);
}

interface IDelegatedSFTSupplyV2 is IDelegatedSFTSupplyV1 {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);
}