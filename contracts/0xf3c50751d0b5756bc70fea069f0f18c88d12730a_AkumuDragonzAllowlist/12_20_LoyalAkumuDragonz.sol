// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { ERC721Base } from "./ERC721Base.sol";

/// @author frolic.eth
/// @title  Akumu Dragonz loyalty
/// @notice Inspired by Corruptions' insight score, this calculates a loyalty
///         score based on how long an NFT has been owned by the current owner.
///         This is a more user-friendly and marketplace-friendly version of
///         staking. We'll use this score later to award long-term holders.
/// @dev    See https://etherscan.io/address/0x5bdf397bb2912859dbd8011f320a222f79a28d2e#code
abstract contract LoyalAkumuDragonz is ERC721Base {

    uint256 public constant LOYALTY_MAX_MULTIPLIER = 24;
    uint256 public loyaltyStartTimestamp;
    // token ID => loyalty
    mapping (uint256 => uint256) public savedLoyalty;

    error LoyaltyAlreadyStarted();

    function startLoyalty()
        external
        onlyOwner
    {
        if (loyaltyStartTimestamp != 0) {
            revert LoyaltyAlreadyStarted();
        }
        loyaltyStartTimestamp = block.timestamp;
    }

    function loyalty(uint256 tokenId) public view returns (uint256) {
        if (loyaltyStartTimestamp == 0) {
            return 0;
        }

        uint256 start = _ownershipOf(tokenId).startTimestamp;
        if (start == 0) {
            return 0;
        }
        if (start < loyaltyStartTimestamp) {
            start = loyaltyStartTimestamp;
        }

        uint256 delta = block.timestamp - start;
        uint256 multiplier = delta / 690_000;
        if (multiplier > LOYALTY_MAX_MULTIPLIER) {
            multiplier = LOYALTY_MAX_MULTIPLIER;
        }
        uint256 total = savedLoyalty[tokenId] + (delta * (multiplier + 1) / 10_000);
        if (total < 1) {
            total = 1;
        }
        return total;
    }

    function saveLoyalty(uint256 tokenId) private {
        savedLoyalty[tokenId] = loyalty(tokenId);
    }

    function _beforeTokenTransfers(address from, address to, uint256 tokenId, uint256 quantity) internal virtual override {
        super._beforeTokenTransfers(from, to, tokenId, quantity);

        for (uint currTokenId = tokenId; currTokenId < tokenId + quantity; currTokenId++) {
            saveLoyalty(currTokenId);
        }
    }
}