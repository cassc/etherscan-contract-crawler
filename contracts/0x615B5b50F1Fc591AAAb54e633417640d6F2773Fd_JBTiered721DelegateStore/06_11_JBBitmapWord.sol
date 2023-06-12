// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @custom:member The information stored at the index.
/// @custom:member The index.
struct JBBitmapWord {
    uint256 currentWord;
    uint256 currentDepth;
}