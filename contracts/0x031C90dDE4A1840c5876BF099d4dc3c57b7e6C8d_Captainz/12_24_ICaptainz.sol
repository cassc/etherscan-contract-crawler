// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICaptainz {
    function isPotatozQuesting(uint256 tokenId) external view returns (bool);
    function removeCrew(uint256 potatozTokenId) external;
}