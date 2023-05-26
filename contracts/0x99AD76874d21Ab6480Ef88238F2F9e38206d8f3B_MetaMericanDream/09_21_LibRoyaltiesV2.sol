// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;
library LibRoyaltiesV2 {
    /*
    * bytes4(keccak256('getRoyalties(LibAsset.AssetType)')) == 0xcad96cca
    */
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
}