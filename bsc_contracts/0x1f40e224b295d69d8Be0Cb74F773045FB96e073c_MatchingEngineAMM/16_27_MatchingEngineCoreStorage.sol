// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "../exchange/TickPosition.sol";
import "../exchange/LiquidityBitmap.sol";
import "../../interfaces/IMatchingEngineCore.sol";

abstract contract MatchingEngineCoreStorage is IMatchingEngineCore {
    using TickPosition for TickPosition.Data;
    using LiquidityBitmap for mapping(uint128 => uint256);

    /// @inheritdoc IMatchingEngineCore
    // the smallest number of the price. Eg. 100 for 0.01
    uint256 public override basisPoint;

    // Max finding word can be 3500
    uint128 public maxFindingWordsIndex;

    //    uint128 public maxWordRangeForLimitOrder;

    //    uint128 public maxWordRangeForMarketOrder;

    // The unit of measurement to express the change in value between two currencies
    struct SingleSlot {
        uint128 pip;
        //0: not set
        //1: buy
        //2: sell
        uint8 isFullBuy;
    }

    struct StepComputations {
        uint128 pipNext;
    }

    SingleSlot public singleSlot;
    mapping(uint128 => TickPosition.Data) public tickPosition;
    // a packed array of bit, where liquidity is filled or not
    mapping(uint128 => uint256) public liquidityBitmap;
}