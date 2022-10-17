// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./LibERC721Mint.sol";
import "@orderinbox/royalties/contracts/LibPart.sol";

interface IERC721Mint is IERC721Upgradeable {
    function transferFromOrMint(
        LibERC721Mint.Mint721Data memory data,
        address from,
        address to
    ) external;
}