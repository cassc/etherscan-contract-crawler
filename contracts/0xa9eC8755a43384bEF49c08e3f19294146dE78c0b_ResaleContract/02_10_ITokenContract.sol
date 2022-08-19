// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITokenContract is IERC721 {
    function mint(uint tokenId, bytes calldata signature) external returns (uint mintedTokenId);
    function adminMint(address recipient, uint tokenId) external returns (uint mintedTokenId);
    function adminBatchMint(address[] calldata recipients, uint[] calldata tokenIds) external;
}