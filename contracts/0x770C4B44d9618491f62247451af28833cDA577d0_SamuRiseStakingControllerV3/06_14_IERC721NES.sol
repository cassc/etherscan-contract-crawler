// SPDX-License-Identifier: MIT
// Creator: base64.tech
pragma solidity ^0.8.13;

/*
 * Interface for ERC721NES for use in SamuRiseStakingController 
 */
interface IERC721NES {
    function stakeFromController(uint256 tokenId, address originator) external;
    function unstakeFromController(uint256 tokenId, address originator) external;
    function ownerOf(uint256 tokenId) external returns (address);
    function isStaked(uint256 tokenId) external returns (bool);
}