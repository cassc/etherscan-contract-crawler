// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

interface INFTSupplyV0 {
    /**
     * @dev Total amount of tokens minted.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);
}

interface INFTSupplyV1 is INFTSupplyV0 {
    /// @dev Offset for token IDs.
    function getSmallestTokenId() external view returns (uint8);
}

interface IPublicNFTSupplyV0 {
    /**
     * @dev Total amount of tokens minted.
     */
    function totalSupply() external view returns (uint256);
}

interface IDelegatedNFTSupplyV0 {
    /// @dev Offset for token IDs.
    function getSmallestTokenId() external view returns (uint8);
}

interface IDelegatedNFTSupplyV1 is IDelegatedNFTSupplyV0 {
    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);
}