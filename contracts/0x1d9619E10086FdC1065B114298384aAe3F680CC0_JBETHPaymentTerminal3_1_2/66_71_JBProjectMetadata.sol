// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @custom:member content The metadata content.
/// @custom:member domain The domain within which the metadata applies.
struct JBProjectMetadata {
  string content;
  uint256 domain;
}