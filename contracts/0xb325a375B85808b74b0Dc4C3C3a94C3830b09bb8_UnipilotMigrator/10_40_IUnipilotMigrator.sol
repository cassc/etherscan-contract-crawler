//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./external/IExchangeManager.sol";

/// @title The interface for the Unipilot Factory
interface IUnipilotMigrator {
    struct MigrateV3Params {
        address vault;
        address token0;
        address token1;
        uint256 tokenId;
        bool refundAsETH;
    }

    struct MigrateV2Params {
        address pair; // the Uniswap v2-compatible pair
        address vault;
        address token0;
        address token1;
        uint8 percentageToMigrate; // represented as a numerator over 100
        uint256 liquidityToMigrate;
        bool refundAsETH;
    }

    struct RefundLiquidityParams {
        address vault;
        address token0;
        address token1;
        uint256 amount0Unipilot;
        uint256 amount1Unipilot;
        uint256 amount0Recieved;
        uint256 amount1Recieved;
        uint256 amount0ToMigrate;
        uint256 amount1ToMigrate;
        bool refundAsETH;
    }

    event LiquidityMigratedFromV2(
        address pool,
        address vault,
        address owner,
        uint256 amount0,
        uint256 amount1
    );

    event LiquidityMigratedFromV3(
        bool migrateFromUnipilot,
        address vault,
        address owner,
        uint256 amount0,
        uint256 amount1
    );
}