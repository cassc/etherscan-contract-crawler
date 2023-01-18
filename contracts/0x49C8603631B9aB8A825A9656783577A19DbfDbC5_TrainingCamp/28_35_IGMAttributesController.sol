// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import { Attribute } from '../structs/DynamicMetadataStructs.sol';

interface IGMAttributesController is IERC165 {
  function getDynamicAttributes(address from, uint256 tokenId) external view returns (Attribute[] memory attributes);
}