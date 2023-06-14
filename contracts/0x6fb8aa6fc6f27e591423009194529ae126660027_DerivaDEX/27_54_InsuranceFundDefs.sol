// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { IDIFundToken } from "../../tokens/interfaces/IDIFundToken.sol";

/**
 * @title InsuranceFundDefs
 * @author DerivaDEX
 *
 * This library contains the common structs and enums pertaining to
 * the insurance fund.
 */
library InsuranceFundDefs {
    // DDX market state maintaining claim index and last updated block
    struct DDXMarketState {
        uint224 index;
        uint32 block;
    }

    // DDX claimant state maintaining claim index and claimed DDX
    struct DDXClaimantState {
        uint256 index;
        uint96 claimedDDX;
    }

    // Supported collateral struct consisting of the collateral's token
    // addresses, collateral flavor/type, current cap and withdrawal
    // amounts, the latest checkpointed cap, and exchange rate (for
    // cTokens). An interface for the DerivaDEX Insurance Fund token
    // corresponding to this collateral is also maintained.
    struct StakeCollateral {
        address underlyingToken;
        address collateralToken;
        IDIFundToken diFundToken;
        uint96 cap;
        uint96 withdrawalFeeCap;
        uint96 checkpointCap;
        uint96 exchangeRate;
        Flavor flavor;
    }

    // Contains the yield accrued and the total normalized cap.
    // Total normalized cap is maintained for Compound flavors so COMP
    // distribution can be paid out properly
    struct ExternalYieldCheckpoint {
        uint96 accrued;
        uint96 totalNormalizedCap;
    }

    // Type of collateral
    enum Flavor { Vanilla, Compound, Aave }
}