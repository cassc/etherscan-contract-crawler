// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Base} from  "../base/Base.sol";
import {ITokenOwnershipFacet} from "../interfaces/ITokenOwnershipFacet.sol";

contract TokenOwnershipFacet is Base, ITokenOwnershipFacet {
    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256) {
        if (_owner == address(0)) revert QueryBalanceOfZeroAddress();
        return s.nftStorage.balances[_owner];
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) public view returns (address) {
        if (s.nftStorage.burnedTokens[_tokenId]) revert QueryBurnedToken();
        address owner = s.nftStorage.tokenOwners[_tokenId];
        if(owner == address(0)) revert QueryNonExistentToken();
        return s.nftStorage.tokenOwners[_tokenId];
    }

    /// @notice Find the owner of an NFT
    /// @dev Does not revert if token is burned, this is used to query via multi-call
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function unsafeOwnerOf(uint256 _tokenId) public view returns (address) {
        address owner = s.nftStorage.tokenOwners[_tokenId];
        if (!s.nftStorage.burnedTokens[_tokenId] && owner == address(0)) revert QueryNonExistentToken();
        return owner;
    }
}