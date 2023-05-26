// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @member The information stored at the index.
  @member The index.
*/
struct JBBitmapWord {
  uint256 currentWord;
  uint256 currentDepth;
}