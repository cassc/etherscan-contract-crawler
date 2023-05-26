// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../libs/RoyaltyLibrary.sol";

interface IRoyalty {
    using RoyaltyLibrary for RoyaltyLibrary.Strategy;
    using RoyaltyLibrary for RoyaltyLibrary.RoyaltyInfo;
    using RoyaltyLibrary for RoyaltyLibrary.RoyaltyShareDetails;

    /*
     * bytes4(keccak256('getRoyalty(uint256)')) == 0x1af9cf49
     * bytes4(keccak256('getRoyaltyShares(uint256)')) == 0xac04f243
     * bytes4(keccak256('getTokenContract()') == 0x28b7bede
     *
     * => 0x1af9cf49 ^ 0xac04f243 ^ 0x28b7bede  == 0x9e4a83d4
     */

    //    bytes4 private constant _INTERFACE_ID_ROYALTY = 0x9e4a83d4;
    //
    //    constructor() public {
    //        _registerInterface(_INTERFACE_ID_ROYALTY);
    //    }

    function getRoyalty(uint256 _tokenId) external view returns (RoyaltyLibrary.RoyaltyInfo memory);

    function getRoyaltyShares(uint256 _tokenId) external view returns (RoyaltyLibrary.RoyaltyShareDetails[] memory);

    function getTokenContract() external view returns (address);
}