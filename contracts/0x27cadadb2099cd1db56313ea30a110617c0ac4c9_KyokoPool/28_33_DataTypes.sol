// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

library DataTypes {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        // variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        // the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address kTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint256 id;
    }

    struct ReserveConfigurationMap {
        // bit 0-15: factor
        // bit 16-31: borrow ratio
        // bit 32-71: period
        // bit 72-111: min borrow time
        // bit 112: reserve is active
        // bit 113-128: Liq. threshold
        // bit 129: borrowing is enabled
        // bit 130: stable rate borrowing enabled
        // bit 131-154: liquidation duration
        // bit 155-178: auction duration
        // bit 179: reserve is frozen
        // bit 180-211: initial liquidity lock period
        // bit 212-219: reserve type
        uint256 data;
    }

    struct Request {
        address user;
        address nft;
        uint256 id;
        InterestRateMode rateMode;
        uint256 reserveId;
    }

    enum Status {
        BORROW,
        REPAY,
        AUCTION,
        WITHDRAW
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }

    struct BorrowInfo {
        uint256 reserveId;
        address nft;
        uint256 nftId;
        address user;
        uint64 startTime;
        uint256 principal;
        uint256 borrowId;
        uint64 liquidateTime;
        Status status;
        InterestRateMode rateMode;
    }

    struct Auction {
        // ID for the Noun (ERC721 token ID)
        uint256 borrowId;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
    }

    struct InitReserveInput {
        uint256 reserveId;
        address kTokenImpl;
        address stableDebtTokenImpl;
        address variableDebtTokenImpl;
        address interestRateStrategyAddress;
        address underlyingAsset;
        address treasury;
        uint16 factor;
        uint16 borrowRatio;
        uint40 period;
        uint40 minBorrowTime;
        uint16 liqThreshold;
        uint24 liqDuration;
        uint24 bidDuration;
        uint32 lockTime;
        bool stableBorrowed;
    }

    struct RateStrategyInput {
        uint256 reserveId;
        uint256 optimalUtilizationRate;
        uint256 baseVariableBorrowRate;
        uint256 variableSlope1;
        uint256 variableSlope2;
        uint256 baseStableBorrowRate;
        uint256 stableSlope1;
        uint256 stableSlope2;
    }
    
    struct Rate {
        /**
         * @dev this constant represents the utilization rate at which the pool aims to obtain most competitive borrow rates.
         * Expressed in ray
         **/
        uint256 optimalUtilizationRate;
        /**
         * @dev This constant represents the excess utilization rate above the optimal. It's always equal to
         * 1-optimal utilization rate. Added as a constant here for gas optimizations.
         * Expressed in ray
         **/
        uint256 excessUtilizationRate;
        // Base variable borrow rate when Utilization rate = 0. Expressed in ray
        uint256 baseVariableBorrowRate;
        // Slope of the variable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
        uint256 variableRateSlope1;
        // Slope of the variable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
        uint256 variableRateSlope2;
        // Base stable borrow rate when Utilization rate = 0. Expressed in ray
        uint256 baseStableBorrowRate;
        // Slope of the stable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
        uint256 stableRateSlope1;
        // Slope of the stable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
        uint256 stableRateSlope2;
    }
}