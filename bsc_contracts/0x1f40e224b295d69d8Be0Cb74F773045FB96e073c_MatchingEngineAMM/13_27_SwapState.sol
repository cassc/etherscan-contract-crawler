// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "../helper/TradeConvert.sol";

library SwapState {
    enum CurrentLiquiditySide {
        NotSet,
        Buy,
        Sell
    }

    struct AmmReserves {
        uint128 baseReserve;
        uint128 quoteReserve;
        uint128 sqrtK;
        uint128 sqrtMaxPip;
        uint128 sqrtMinPip;
        uint128 amountFilled;
    }

    struct AmmState {
        int256 lastPipRangeLiquidityIndex;
        uint8 index;
        uint256[5] pipRangesIndex;
        AmmReserves[5] ammReserves;
    }

    struct State {
        uint256 remainingSize;
        // the tick associated with the current price
        uint128 pip;
        uint32 basisPoint;
        uint128 startPip;
        uint128 remainingLiquidity;
        uint8 isFullBuy;
        bool isSkipFirstPip;
        uint128 lastMatchedPip;
        bool isBuy;
        bool isBase;
        uint256 flipSideOut;
        uint128 pipRange;
        uint128 rangeFindingWordsAmm;
        // For AMM
        AmmState ammState;
    }

    /// @notice init amm stare when start market fill
    /// @return amm state after init value
    function newAMMState() internal pure returns (AmmState memory) {
        AmmReserves[5] memory _ammReserves;
        uint256[5] memory _pipRangesIndex;
        return
            AmmState({
                lastPipRangeLiquidityIndex: -1,
                index: 0,
                pipRangesIndex: _pipRangesIndex,
                ammReserves: _ammReserves
            });
    }

    /// @notice check condition to skip first pip before market fill
    /// @param state the state of market fill
    function beforeExecute(State memory state) internal pure {
        // Check need to skip first pip
        CurrentLiquiditySide currentLiquiditySide = CurrentLiquiditySide(
            state.isFullBuy
        );
        if (currentLiquiditySide != CurrentLiquiditySide.NotSet) {
            if (state.isBuy)
                // if buy and latest liquidity is buy. skip current pip
                state.isSkipFirstPip =
                    currentLiquiditySide == CurrentLiquiditySide.Buy;
                // if sell and latest liquidity is sell. skip current pip
            else
                state.isSkipFirstPip =
                    currentLiquiditySide == CurrentLiquiditySide.Sell;
        }
    }

    /// @notice check is reach max pip when have limit fill market
    /// @param state the state of market fill
    /// @param _pipNext the next pip
    /// @param _maxPip the max pip can reach
    /// @return true if reach max pip
    function isReachedMaxPip(
        State memory state,
        uint128 _pipNext,
        uint128 _maxPip
    ) internal pure returns (bool) {
        return
            (state.isBuy && _pipNext > _maxPip && _maxPip != 0) ||
            (!state.isBuy && _pipNext < _maxPip && _maxPip != 0) ||
            (_maxPip != 0 && _pipNext == 0);
    }

    /// @notice increase or decrease pip back 1 pip depends on buy or sell
    /// @param state the state of market fill
    function moveBack1Pip(State memory state) internal pure {
        if (state.isBuy) {
            state.pip--;
        } else {
            state.pip++;
        }
    }

    /// @notice increase or decrease pip foward 1 pip depends on buy or sell
    /// @param state the state of market fill
    /// @param pipNext the next pip
    function moveForward1Pip(
        State memory state,
        uint128 pipNext
    ) internal pure {
        if (state.isBuy) {
            state.pip = pipNext + 1;
        } else {
            state.pip = pipNext - 1;
        }
    }

    /// @notice update the main size out and flip side out when market fill
    /// @param state the state of market fill
    /// @param tradedQuantity then quan of trade
    /// @param pipNext the next pip reach to
    function updateTradedSize(
        State memory state,
        uint256 tradedQuantity, // base
        uint128 pipNext,
        bool isFullFill
    ) internal pure {
        if (isFullFill) {
            state.remainingSize = 0;
        } else {
            state.remainingSize -= state.isBase
                ? tradedQuantity
                : TradeConvert.baseToQuote(
                    tradedQuantity,
                    pipNext,
                    state.basisPoint
                );
        }

        state.flipSideOut += state.isBase
            ? TradeConvert.baseToQuote(
                tradedQuantity,
                pipNext,
                state.basisPoint
            )
            : tradedQuantity;
    }

    /// @notice update the state with flag buy or sell
    function reverseIsFullBuy(State memory state) internal pure {
        if (!state.isBuy) {
            state.isFullBuy = uint8(1);
        } else {
            state.isFullBuy = uint8(2);
        }
    }

    /// @notice udpate the amm traded when fill amm
    /// @param state the state of market fill
    /// @param baseAmount fill with amm
    /// @param quoteAmount fill with amm
    function updateAMMTradedSize(
        State memory state,
        uint128 baseAmount,
        uint128 quoteAmount
    ) internal pure {
        if (state.isBase) {
            state.flipSideOut += quoteAmount;
            state.remainingSize -= baseAmount;
        } else {
            state.flipSideOut += baseAmount;
            state.remainingSize -= quoteAmount;
        }
    }

    /// @notice update the amm will full fill active range
    /// @param state the state of market fill
    /// @param baseAmount fill with amm
    /// @param quoteAmount fill with amm
    function ammFillAll(
        State memory state,
        uint128 baseAmount,
        uint128 quoteAmount
    ) internal pure {
        state.remainingSize = 0;
        state.flipSideOut += state.isBase ? quoteAmount : baseAmount;
    }
}