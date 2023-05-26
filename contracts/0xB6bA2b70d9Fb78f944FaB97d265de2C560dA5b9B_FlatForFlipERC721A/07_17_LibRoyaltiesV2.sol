// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//  https://github.com/rarible/protocol-contracts/blob/master/royalties/contracts/LibRoyaltiesV2.sol

library LibRoyaltiesV2 {
    /*
     * bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
     */
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
}