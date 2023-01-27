// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IAngleStableMaster {
    struct SLPData {
        // Last timestamp at which the `sanRate` has been updated for SLPs
        uint256 lastBlockUpdated;
        // Fees accumulated from previous blocks and to be distributed to SLPs
        uint256 lockedInterests;
        // Max interests used to update the `sanRate` in a single block
        // Should be in collateral token base
        uint256 maxInterestsDistributed;
        // Amount of fees left aside for SLPs and that will be distributed
        // when the protocol is collateralized back again
        uint256 feesAside;
        // Part of the fees normally going to SLPs that is left aside
        // before the protocol is collateralized back again (depends on collateral ratio)
        // Updated by keepers and scaled by `BASE_PARAMS`
        uint64 slippageFee;
        // Portion of the fees from users minting and burning
        // that goes to SLPs (the rest goes to surplus)
        uint64 feesForSLPs;
        // Slippage factor that's applied to SLPs exiting (depends on collateral ratio)
        // If `slippage = BASE_PARAMS`, SLPs can get nothing, if `slippage = 0` they get their full claim
        // Updated by keepers and scaled by `BASE_PARAMS`
        uint64 slippage;
        // Portion of the interests from lending
        // that goes to SLPs (the rest goes to surplus)
        uint64 interestsForSLPs;
    }

    // Struct to handle all the parameters to manage the fees
    // related to a given collateral pool (associated to the stablecoin)
    struct MintBurnData {
        // Values of the thresholds to compute the minting fees
        // depending on HA hedge (scaled by `BASE_PARAMS`)
        uint64[] xFeeMint;
        // Values of the fees at thresholds (scaled by `BASE_PARAMS`)
        uint64[] yFeeMint;
        // Values of the thresholds to compute the burning fees
        // depending on HA hedge (scaled by `BASE_PARAMS`)
        uint64[] xFeeBurn;
        // Values of the fees at thresholds (scaled by `BASE_PARAMS`)
        uint64[] yFeeBurn;
        // Max proportion of collateral from users that can be covered by HAs
        // It is exactly the same as the parameter of the same name in `PerpetualManager`, whenever one is updated
        // the other changes accordingly
        uint64 targetHAHedge;
        // Minting fees correction set by the `FeeManager` contract: they are going to be multiplied
        // to the value of the fees computed using the hedge curve
        // Scaled by `BASE_PARAMS`
        uint64 bonusMalusMint;
        // Burning fees correction set by the `FeeManager` contract: they are going to be multiplied
        // to the value of the fees computed using the hedge curve
        // Scaled by `BASE_PARAMS`
        uint64 bonusMalusBurn;
        // Parameter used to limit the number of stablecoins that can be issued using the concerned collateral
        uint256 capOnStableMinted;
    }

    function deposit(uint256 amount, address user, address poolManager) external;

    function withdraw(uint256 amount, address burner, address dest, address poolManager) external;

    function collateralMap(address)
        external
        view
        returns (
            address token,
            address sanToken,
            address perpetualManager,
            address oracle,
            uint256 stocksUsers,
            uint256 sanRate,
            uint256 collatBase,
            SLPData memory slpData,
            MintBurnData memory feeData
        );
}