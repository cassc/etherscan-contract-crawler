// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Soulbound is IERC721 {
    event Reclaim(uint256 tokenId, uint256 baseTokenId, address claimant);

    function reclaim(address claimant, uint256 tokenId) external;

    function canReclaim(address claimant, uint256 tokenId) external view returns (bool);

    function soulbound() external view returns (address);

    function soulOwner(uint256 tokenId) external view returns (address);

    function soulboundTo(uint256 tokenId) external view returns (uint256);
}