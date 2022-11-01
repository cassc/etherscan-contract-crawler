// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error NonExistentToken(uint256 tokenId);
error MintZeroQuantity();
error MintOverMaxSupply(uint16 numberToMint, uint16 remainingSupply);
error AllTokensMinted();
error SearchNotPossible();
error SearchOutOfRange(uint16 startIndex, uint16 endIndex, uint16 minTokenIndex, uint256 maxTokenIndex);