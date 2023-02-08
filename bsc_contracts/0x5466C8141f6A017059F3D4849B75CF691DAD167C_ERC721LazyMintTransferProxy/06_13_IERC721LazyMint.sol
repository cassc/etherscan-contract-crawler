// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../interfaces/IERC721Upgradeable.sol";
import "../librairies/LibERC721LazyMint.sol";

interface IERC721LazyMint is IERC721Upgradeable {
    function mintAndTransfer(LibERC721LazyMint.Mint721Data memory data, address to) external;

    function transferFromOrMint(LibERC721LazyMint.Mint721Data memory data, address from, address to) external;
}