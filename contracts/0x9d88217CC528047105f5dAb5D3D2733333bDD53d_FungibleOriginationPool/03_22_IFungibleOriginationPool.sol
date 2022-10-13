//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./IOriginationCore.sol";

interface IFungibleOriginationPool {
    struct SaleParams {
        address offerToken; // the token being offered for sale
        address purchaseToken; // the token used to purchase the offered token
        uint256 publicStartingPrice; // in purchase tokens (10^OffrDec offer tokens = 10^PurchDecimals purch tokens)
        uint256 publicEndingPrice; // in purchase tokens
        uint256 whitelistStartingPrice; // in purchase tokens
        uint256 whitelistEndingPrice; // in purchase tokens
        uint256 publicSaleDuration; // the public sale duration
        uint256 whitelistSaleDuration; // the whitelist sale duration
        uint256 totalOfferingAmount; // the total amount of offer tokens for sale
        uint256 reserveAmount; // need to raise this amount of purchase tokens for sale completion
        uint256 vestingPeriod; // the total vesting period (can be 0)
        uint256 cliffPeriod; // the cliff period in case of vesting (must be <= vesting period)
    }

    struct VestingEntry {
        address user; // the user's address with the vesting position
        uint256 offerTokenAmount; // the total vesting position amount
        uint256 offerTokenAmountClaimed; // the amount of tokens claimed so far
    }

    function initialize(
        uint256 originationFee, // 1e18 = 100% fee. 1e16 = 1% fee
        IOriginationCore core,
        address admin,
        address vestingEntryNFT,
        SaleParams calldata saleParams
    ) external;
}