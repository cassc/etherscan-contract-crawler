// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { NFTBaseAttributes } from '../structs/LilVillainsStructs.sol';

interface ILilCollection {
  function batchMint(address to, uint256[] calldata tokenIds) external;

  function setBaseAttributes(NFTBaseAttributes[] memory nFTsBaseAttributes) external;
}