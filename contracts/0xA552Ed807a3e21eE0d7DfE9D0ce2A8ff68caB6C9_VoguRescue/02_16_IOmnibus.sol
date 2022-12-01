// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IOmnibus is IERC721 {
    function burn(uint256 tokenId) external;

    function burnBatch(uint256[] calldata tokenIds) external;
}