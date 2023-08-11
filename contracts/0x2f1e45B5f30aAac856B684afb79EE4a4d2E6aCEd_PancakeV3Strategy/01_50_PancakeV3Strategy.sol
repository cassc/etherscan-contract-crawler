// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "../HarvestableApyFlowVault.sol";
import "../libraries/PancakeV3Library.sol";
import "../libraries/PricesLibrary.sol";
import "../libraries/Utils.sol";
import "../libraries/SafeAssetConverter.sol";
import "./concentrated-liquidity/BasePancakeV3Strategy.sol";

/// @author YLDR <[email protected]>
contract PancakeV3Strategy is BasePancakeV3Strategy {
    struct ConstructorParams {
        // BaseConcentratedLiquidityStrategy
        int24 ticksDown;
        int24 ticksUp;
        ChainlinkPriceFeedAggregator pricesOracle;
        IAssetConverter assetConverter;
        // BasePancakeV3Strategy
        IMasterChefV3 farm;
        uint256 pid;
        // ApyFlowVault
        IERC20Metadata asset;
        // ERC20
        string name;
        string symbol;
    }

    constructor(ConstructorParams memory params)
        BasePancakeV3Strategy(params.farm, params.pid)
        BaseConcentratedLiquidityStrategy(params.ticksDown, params.ticksUp, params.pricesOracle, params.assetConverter)
        ApyFlowVault(params.asset)
        ERC20(params.name, params.symbol)
    {
        BaseConcentratedLiquidityStrategy._performApprovals();
    }
}