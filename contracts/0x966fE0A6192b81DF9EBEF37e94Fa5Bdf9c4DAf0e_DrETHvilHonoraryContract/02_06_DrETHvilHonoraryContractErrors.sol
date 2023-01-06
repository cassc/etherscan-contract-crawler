// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error NonExistentToken(uint256 tokenId);
error MintZeroQuantity();
error SearchNotPossible();
error SearchOutOfRange(uint256 startIndex, uint256 endIndex, uint256 minTokenIndex, uint256 maxTokenIndex);