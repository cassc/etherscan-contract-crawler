// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.6;

/// @title Types
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice Library exposing all Types used in Morpho.
library Types {
    /* ENUMS */

    /// @notice Enumeration of the different position types in the protocol.
    enum Position {
        POOL_SUPPLIER,
        P2P_SUPPLIER,
        POOL_BORROWER,
        P2P_BORROWER
    }

    /* NESTED STRUCTS */

    /// @notice Contains the market side delta data.
    struct MarketSideDelta {
        uint256 scaledDelta; // The delta amount in pool unit.
        uint256 scaledP2PTotal; // The total peer-to-peer amount in peer-to-peer unit.
    }

    /// @notice Contains the delta data for both `supply` and `borrow`.
    struct Deltas {
        MarketSideDelta supply; // The `MarketSideDelta` related to the supply side.
        MarketSideDelta borrow; // The `MarketSideDelta` related to the borrow side.
    }

    /// @notice Contains the market side indexes.
    struct MarketSideIndexes {
        uint128 poolIndex; // The pool index (in ray).
        uint128 p2pIndex; // The peer-to-peer index (in ray).
    }

    /// @notice Contains the indexes for both `supply` and `borrow`.
    struct Indexes {
        MarketSideIndexes supply; // The `MarketSideIndexes` related to the supply side.
        MarketSideIndexes borrow; // The `MarketSideIndexes` related to the borrow side.
    }

    /// @notice Contains the different pauses statuses possible in Morpho.
    struct PauseStatuses {
        bool isP2PDisabled;
        bool isSupplyPaused;
        bool isSupplyCollateralPaused;
        bool isBorrowPaused;
        bool isWithdrawPaused;
        bool isWithdrawCollateralPaused;
        bool isRepayPaused;
        bool isLiquidateCollateralPaused;
        bool isLiquidateBorrowPaused;
        bool isDeprecated;
    }

    /* STORAGE STRUCTS */

    /// @notice Contains the market data that is stored in storage.
    /// @dev This market struct is able to be passed into memory.
    struct Market {
        // SLOT 0-1
        Indexes indexes;
        // SLOT 2-5
        Deltas deltas; // 1024 bits
        // SLOT 6
        address underlying; // 160 bits
        PauseStatuses pauseStatuses; // 80 bits
        bool isCollateral; // 8 bits
        // SLOT 7
        address variableDebtToken; // 160 bits
        uint32 lastUpdateTimestamp; // 32 bits
        uint16 reserveFactor; // 16 bits
        uint16 p2pIndexCursor; // 16 bits
        // SLOT 8
        address aToken; // 160 bits
        // SLOT 9
        address stableDebtToken; // 160 bits
        // SLOT 10
        uint256 idleSupply; // 256 bits
    }

    /// @notice Contains the minimum number of iterations for a `repay` or a `withdraw`.
    struct Iterations {
        uint128 repay;
        uint128 withdraw;
    }

    /* STACK AND RETURN STRUCTS */

    /// @notice Contains the data related to the liquidity of a user.
    struct LiquidityData {
        uint256 borrowable; // The maximum debt value allowed to borrow (in base currency).
        uint256 maxDebt; // The maximum debt value allowed before being liquidatable (in base currency).
        uint256 debt; // The debt value (in base currency).
    }

    /// @notice The paramaters used to compute the new peer-to-peer indexes.
    struct IndexesParams {
        MarketSideIndexes256 lastSupplyIndexes; // The last supply indexes stored (in ray).
        MarketSideIndexes256 lastBorrowIndexes; // The last borrow indexes stored (in ray).
        uint256 poolSupplyIndex; // The current pool supply index (in ray).
        uint256 poolBorrowIndex; // The current pool borrow index (in ray).
        uint256 reserveFactor; // The reserve factor percentage (10 000 = 100%).
        uint256 p2pIndexCursor; // The peer-to-peer index cursor (10 000 = 100%).
        Deltas deltas; // The deltas and peer-to-peer amounts.
        uint256 proportionIdle; // The amount of proportion idle (in underlying).
    }

    /// @notice Contains the data related to growth factors as part of the peer-to-peer indexes computation.
    struct GrowthFactors {
        uint256 poolSupplyGrowthFactor; // The pool's supply index growth factor (in ray).
        uint256 p2pSupplyGrowthFactor; // Peer-to-peer supply index growth factor (in ray).
        uint256 poolBorrowGrowthFactor; // The pool's borrow index growth factor (in ray).
        uint256 p2pBorrowGrowthFactor; // Peer-to-peer borrow index growth factor (in ray).
    }

    /// @notice Contains the market side indexes as uint256 instead of uint128.
    struct MarketSideIndexes256 {
        uint256 poolIndex; // The pool index (in ray).
        uint256 p2pIndex; // The peer-to-peer index (in ray).
    }

    /// @notice Contains the indexes as uint256 instead of uint128.
    struct Indexes256 {
        MarketSideIndexes256 supply; // The `MarketSideIndexes` related to the supply as uint256.
        MarketSideIndexes256 borrow; // The `MarketSideIndexes` related to the borrow as uint256.
    }

    /// @notice Contains the `v`, `r` and `s` parameters of an ECDSA signature.
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice Variables used in the matching engine.
    struct MatchingEngineVars {
        address underlying; // The underlying asset address.
        MarketSideIndexes256 indexes; // The indexes of the market side.
        uint256 amount; // The amount to promote or demote (in underlying).
        uint256 maxIterations; // The maximum number of iterations allowed.
        bool borrow; // Whether the process happens on the borrow side or not.
        function(address, address, uint256, uint256, bool) returns (uint256, uint256) updateDS; // This function will be used to update the data-structure.
        bool demoting; // True for demote, False for promote.
        function(uint256, uint256, MarketSideIndexes256 memory, uint256) pure returns (uint256, uint256, uint256) step; // This function will be used to decide whether to use the algorithm for promoting or for demoting.
    }

    /// @notice Variables used during a borrow or withdraw.
    /// @dev Used to avoid stack too deep.
    struct BorrowWithdrawVars {
        uint256 onPool; // The working scaled balance on pool of the user.
        uint256 inP2P; // The working scaled balance in peer-to-peer of the user.
        uint256 toWithdraw; // The amount to withdraw from the pool (in underlying).
        uint256 toBorrow; // The amount to borrow on the pool (in underlying).
    }

    /// @notice Variables used during a supply or repay.
    /// @dev Used to avoid stack too deep.
    struct SupplyRepayVars {
        uint256 onPool; // The working scaled balance on pool of the user.
        uint256 inP2P; // The working scaled balance in peer-to-peer of the user.
        uint256 toSupply; // The amount to supply on the pool (in underlying).
        uint256 toRepay; // The amount to repay on the pool (in underlying).
    }

    /// @notice Variables used during a liquidate.
    /// @dev Used to avoid stack too deep.
    struct LiquidateVars {
        uint256 closeFactor; // The close factor used during the liquidation process.
        uint256 seized; // The amount of collateral to be seized (in underlying).
    }

    /// @notice Variables used to compute the amount to seize during a liquidation.
    /// @dev Used to avoid stack too deep.
    struct AmountToSeizeVars {
        uint256 liquidationBonus; // The liquidation bonus used during the liquidation process.
        uint256 borrowedTokenUnit; // The borrowed token unit.
        uint256 collateralTokenUnit; // The collateral token unit.
        uint256 borrowedPrice; // The borrowed token price (in base currency).
        uint256 collateralPrice; // The collateral token price (in base currency).
    }
}