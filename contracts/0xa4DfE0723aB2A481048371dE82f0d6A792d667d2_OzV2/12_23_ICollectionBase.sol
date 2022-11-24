// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * @dev Collection Interface
 */
interface ICollectionBase {

    event CollectionActivated(uint256 startTime, uint256 endTime, uint256 presaleInterval, uint256 claimStartTime, uint256 claimEndTime);
    event CollectionDeactivated();

    /**
     * @dev Check if nonce has been used
     */
    function nonceUsed(string memory nonce) external view returns(bool);
}