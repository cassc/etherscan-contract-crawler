// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC721 } from "@solmate/tokens/ERC721.sol";

abstract contract IERC721 is ERC721 {
    function initialize(address _puzzle) external virtual;
    function safeMint(address to, uint256 tokenId) external virtual;
    function totalSupply() external view virtual returns (uint256);
}