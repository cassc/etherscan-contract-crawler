// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721RoyaltiesStorage is IERC721 {

    function getRoyalties(uint256 tokenId) external view returns (address[] memory, uint32[] memory);

    function getRoyaltiesAmount(uint256 tokenId) external view returns (uint32);
}