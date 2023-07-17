// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

interface IDeedAuthorizer {

    /// @dev If this hook contains side effects, you MUST check msg.sender
    function isAuthedForDeeds(
        address claimant,
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external returns (bool);
    
    /// @dev If this hook contains side effects, you MUST check msg.sender
    function deedsMerged(
        address returnee,
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external returns (bool);

}