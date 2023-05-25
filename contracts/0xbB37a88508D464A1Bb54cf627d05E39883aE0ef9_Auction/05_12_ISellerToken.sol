// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import './IERC721.sol';

interface ISellerToken is IERC721 {
    function mint(address dest, uint256 tokenId) external returns (uint256);
    function burn(uint256 tokenId) external;
}