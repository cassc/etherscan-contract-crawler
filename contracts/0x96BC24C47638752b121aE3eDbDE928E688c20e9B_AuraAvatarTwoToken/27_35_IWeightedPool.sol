// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWeightedPool {
    /**
     * @dev Returns the current value of the invariant.
     */
    function getInvariant() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getNormalizedWeights() external view returns (uint256[] memory);
}