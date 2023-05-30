// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITux is IERC721 {
    function owner() external view returns (address);
    function tokenCreator(uint256 tokenId) external view returns (address);
    function creatorTokens(address creator) external view returns (uint256[] memory);
}