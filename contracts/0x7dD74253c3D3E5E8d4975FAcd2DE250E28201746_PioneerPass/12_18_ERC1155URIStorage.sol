// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts

pragma solidity ^0.8.17;

import "./ERC1155.sol";

contract ERC1155URIStorage {
    string internal _baseURI = "ipfs:/";
    mapping(uint256 => string) internal _tokenURIs;
}