// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library LibRoyaltiesV2 {
    /*
     * bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
     */
    bytes4 public constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
}