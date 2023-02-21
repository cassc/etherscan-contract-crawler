// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IOnChainCheckRenderer_v2_Render {
  function render(uint256 tokenId, uint256 seed, uint24 gasPrice, bool isDarkMode, bool[80] memory isCheckRendered)
    external
    view
    returns (string memory);
}