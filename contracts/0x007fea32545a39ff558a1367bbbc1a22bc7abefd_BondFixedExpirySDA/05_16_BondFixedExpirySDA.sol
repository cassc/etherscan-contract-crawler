// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {BondBaseSDA, IBondAggregator, Authority} from "./bases/BondBaseSDA.sol";
import {IBondTeller} from "./interfaces/IBondTeller.sol";
import {IBondFixedExpiryTeller} from "./interfaces/IBondFixedExpiryTeller.sol";

/// @title Bond Fixed-Expiry Sequential Dutch Auctioneer
/// @notice Bond Fixed-Expiry Sequential Dutch Auctioneer Contract
/// @dev Bond Protocol is a permissionless system to create Olympus-style bond markets
///      for any token pair. The markets do not require maintenance and will manage
///      bond prices based on activity. Bond issuers create BondMarkets that pay out
///      a Payout Token in exchange for deposited Quote Tokens. Users can purchase
///      future-dated Payout Tokens with Quote Tokens at the current market price and
///      receive Bond Tokens to represent their position while their bond vests.
///      Once the Bond Tokens vest, they can redeem it for the Quote Tokens.
///
/// @dev The Fixed-Expiry Auctioneer is an implementation of the
///      Bond Base Sequential Dutch Auctioneer contract specific to creating bond markets where
///      all purchases on that market vest at a certain timestamp.
///
/// @author Oighty, Zeus, Potted Meat, indigo
contract BondFixedExpirySDA is BondBaseSDA {
    /* ========== CONSTRUCTOR ========== */
    constructor(
        IBondTeller teller_,
        IBondAggregator aggregator_,
        address guardian_,
        Authority authority_
    ) BondBaseSDA(teller_, aggregator_, guardian_, authority_) {}

    /// @inheritdoc BondBaseSDA
    function createMarket(bytes calldata params_) external override returns (uint256) {
        // Decode params into the struct type expected by this auctioneer
        MarketParams memory params = abi.decode(params_, (MarketParams));

        // Vesting is rounded to the nearest day at 0000 UTC (in seconds) since bond tokens
        // are only unique to a day, not a specific timestamp.
        params.vesting = (params.vesting / 1 days) * 1 days;

        // Check that the vesting parameter is valid for a fixed-expiry market
        if (params.vesting != 0 && params.vesting < params.conclusion)
            revert Auctioneer_InvalidParams();

        // Create market with provided params
        uint256 marketId = _createMarket(params);

        // Create bond token (ERC20 for fixed expiry) if not instant swap
        if (params.vesting != 0) {
            IBondFixedExpiryTeller(address(_teller)).deploy(params.payoutToken, params.vesting);
        }

        // Return market ID
        return marketId;
    }
}