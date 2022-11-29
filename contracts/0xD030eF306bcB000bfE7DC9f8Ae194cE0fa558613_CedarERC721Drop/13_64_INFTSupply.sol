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