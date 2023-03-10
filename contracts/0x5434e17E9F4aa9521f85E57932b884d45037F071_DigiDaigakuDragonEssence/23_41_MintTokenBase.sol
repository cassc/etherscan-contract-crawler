// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract MintTokenBase {
    /// @dev Inheriting contracts must implement the token minting logic - inheriting contract should use _mint, or something equivalent
    /// The minting function should throw if `to` is address(0)
    function _mintToken(address to, uint256 tokenId) internal virtual;
}