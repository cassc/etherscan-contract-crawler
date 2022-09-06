// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC721 interface required by controller functions
 */
interface IERC721TransferableController {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
}