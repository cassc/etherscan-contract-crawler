// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title Oddsoleum
 * @notice Allows Oddities to enter a queue for being sacrificed on the altar of the Oddgod.
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
contract DevOddsoleum {
    /**
     * @notice The Oddities contract.
     */
    IERC721 public immutable oddities;

    /**
     * @notice Keeps track of Oddities that are in the queue to be sacrificed.
     * @dev Keyed by owner to automatically unqueue Oddities if they are transferred. Consequently, tokens will still
     * be queued after a round-trip, which can't be avoided as it would require a callback from the Oddities contract
     * upon transfer.
     */
    mapping(address owner => mapping(uint256 tokenId => bool)) private _queued;

    constructor(IERC721 oddities_) {
        oddities = oddities_;
    }

    /**
     * @notice Returns whether the given Oddities are in the queue.
     * @dev This does not imply that they can be sacrificed, as the owner may not have approved this contract to burn
     * them.
     */
    function queued(uint256[] calldata tokenIds) public view returns (bool[] memory) {
        bool[] memory queued_ = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            address owner = oddities.ownerOf(tokenIds[i]);
            queued_[i] = _queued[owner][tokenIds[i]];
        }
        return queued_;
    }

    /**
     * @notice Returns whether the given Oddities can be sacrificed.
     * @dev True iff the Oddity is in the queue and the owner has approved this contract to burn it.
     */
    function burnable(uint256[] calldata tokenIds) external view returns (bool[] memory) {
        bool[] memory burnable_ = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            burnable_[i] = _burnable(tokenIds[i]);
        }
        return burnable_;
    }

    /**
     * @notice Returns whether the given Oddities can be sacrificed.
     */
    function _burnable(uint256 tokenId) internal view returns (bool) {
        address owner = oddities.ownerOf(tokenId);
        return _queued[owner][tokenId]
            && (oddities.isApprovedForAll(owner, address(this)) || oddities.getApproved(tokenId) == address(this));
    }
}