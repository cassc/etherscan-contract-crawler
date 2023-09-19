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