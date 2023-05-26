// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../libs/RoyaltyLibrary.sol";

interface IPrimaryRoyalty {

    /*
     * bytes4(keccak256('getPrimaryRoyaltyShares(uint256)')) == 0x20b029a5
     */

    //    bytes4 private constant _INTERFACE_ID_PRIMARY_ROYALTY = 0x20b029a5;
    //
    //    constructor() public {
    //        _registerInterface(_INTERFACE_ID_PRIMARY_ROYALTY);
    //    }

    function getPrimaryRoyaltyShares(uint256 _tokenId) external view returns (RoyaltyLibrary.RoyaltyShareDetails[] memory);
}