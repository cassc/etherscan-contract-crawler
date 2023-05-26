// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { InsuranceFundDefs } from "../libs/defs/InsuranceFundDefs.sol";
import { IDIFundTokenFactory } from "../tokens/interfaces/IDIFundTokenFactory.sol";

library LibDiamondStorageInsuranceFund {
    struct DiamondStorageInsuranceFund {
        // List of supported collateral names
        bytes32[] collateralNames;
        // Collateral name to stake collateral struct
        mapping(bytes32 => InsuranceFundDefs.StakeCollateral) stakeCollaterals;
        mapping(address => InsuranceFundDefs.DDXClaimantState) ddxClaimantState;
        // aToken name to yield checkpoints
        mapping(bytes32 => InsuranceFundDefs.ExternalYieldCheckpoint) aTokenYields;
        mapping(address => uint256) stakerToOtherRewardsClaims;
        // Interval to COMP yield checkpoint
        InsuranceFundDefs.ExternalYieldCheckpoint compYields;
        // Set the interval for other rewards claiming checkpoints
        // (i.e. COMP and aTokens that accrue to the contract)
        // (e.g. 40320 ~ 1 week = 7 * 24 * 60 * 60 / 15 blocks)
        uint32 interval;
        // Current insurance mining withdrawal factor
        uint32 withdrawalFactor;
        // DDX to be issued per block as insurance mining reward
        uint96 mineRatePerBlock;
        // Incentive to advance the insurance mining interval
        // (e.g. 100e18 = 100 DDX)
        uint96 advanceIntervalReward;
        // Total DDX insurance mined
        uint96 minedAmount;
        // Insurance fund capitalization due to liquidations and fees
        uint96 liqAndFeeCapitalization;
        // Checkpoint block for other rewards
        uint256 otherRewardsCheckpointBlock;
        // Insurance mining final block number
        uint256 miningFinalBlockNumber;
        InsuranceFundDefs.DDXMarketState ddxMarketState;
        IDIFundTokenFactory diFundTokenFactory;
    }

    bytes32 constant DIAMOND_STORAGE_POSITION_INSURANCE_FUND =
        keccak256("diamond.standard.diamond.storage.DerivaDEX.InsuranceFund");

    function diamondStorageInsuranceFund() internal pure returns (DiamondStorageInsuranceFund storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION_INSURANCE_FUND;
        assembly {
            ds_slot := position
        }
    }
}