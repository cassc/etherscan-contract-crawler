// SPDX-License-Identifier: MIT

// copied from @rarible/royalties/contracts/LibRoyaltiesV2.sol
// to support the newest solidity version

pragma solidity ^0.8.9;

library LibRoyaltiesV2 {
  /*
   * bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
   */
  bytes4 constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
}