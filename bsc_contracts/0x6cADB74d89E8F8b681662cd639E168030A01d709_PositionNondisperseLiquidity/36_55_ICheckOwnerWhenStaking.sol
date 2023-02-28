/**
 * @author Musket
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICheckOwnerWhenStaking {
    /// @notice check Nft is owner when staking
    /// @param user the owner of nft
    /// @param tokenId id of the nft
    /// @return isOwner true if is owner, false otherwise
    /// @return caller address of the delegate call
    function isOwnerWhenStaking(address user, uint256 tokenId)
        external
        view
        returns (bool isOwner, address caller);
}