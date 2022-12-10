// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Extended is IERC721 {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}