// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Attribute, Royalty, SCBehavior } from '@gm2/blockchain/src/structs/DynamicMetadataStructs.sol';

struct Metadata {
  string description;
  string image;
  string name;
  Attribute[] attributes;
  Royalty royalty;
}