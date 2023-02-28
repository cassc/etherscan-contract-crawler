/**
 * @author Musket
 * @author NiKa
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@positionex/matching-engine/contracts/interfaces/IMatchingEngineAMM.sol";
import "@positionex/matching-engine/contracts/libraries/helper/FixedPoint128.sol";
import "@positionex/matching-engine/contracts/libraries/helper/Math.sol";
import "@positionex/matching-engine/contracts/libraries/helper/Require.sol";

import "../libraries/liquidity/Liquidity.sol";
import "../libraries/helper/DexErrors.sol";
import "../interfaces/ILiquidityManager.sol";
import "../interfaces/IUpdateStakingManager.sol";
import "../interfaces/ICheckOwnerWhenStaking.sol";
import "../libraries/helper/LiquidityHelper.sol";
import "../staking/PositionStakingDexManager.sol";
import "../interfaces/ISpotFactory.sol";
import "../libraries/types/Asset.sol";

abstract contract LiquidityManager is ILiquidityManager {
    using UserLiquidity for UserLiquidity.Data;

    mapping(uint256 => UserLiquidity.Data)
        public
        override concentratedLiquidity;

    /**
     * @dev see {ILiquidityManager-addLiquidity}
     */
    function addLiquidity(AddLiquidityParams calldata params)
        public
        payable
        virtual
    {
        _addLiquidityRecipient(params, _msgSender(), _msgSender());
    }

    /**
     * @dev see {ILiquidityManager-addLiquidityWithRecipient}
     */
    function addLiquidityWithRecipient(
        AddLiquidityParams calldata params,
        address recipient
    ) public payable virtual {
        _addLiquidityRecipient(params, _msgSender(), recipient);
    }

    /**
     * @dev see {ILiquidityManager-removeLiquidity}
     */
    function removeLiquidity(uint256 nftTokenId) public virtual {
        UserLiquidity.Data memory liquidityData = concentratedLiquidity[
            nftTokenId
        ];

        burn(nftTokenId);

        delete concentratedLiquidity[nftTokenId];

        (
            uint128 baseAmountRemoved,
            uint128 quoteAmountRemoved
        ) = _removeLiquidity(liquidityData, liquidityData.liquidity);

        UserLiquidity.CollectFeeData memory _collectFeeData;

        _collectFeeData = estimateCollectFee(
            liquidityData.pool,
            liquidityData.feeGrowthBase,
            liquidityData.feeGrowthQuote,
            liquidityData.liquidity,
            liquidityData.indexedPipRange
        );

        address user = _msgSender();

        _withdrawLiquidity(
            liquidityData.pool,
            user,
            Asset.Type.Base,
            baseAmountRemoved + _collectFeeData.feeBaseAmount
        );

        _withdrawLiquidity(
            liquidityData.pool,
            user,
            Asset.Type.Quote,
            quoteAmountRemoved + _collectFeeData.feeQuoteAmount
        );

        emit LiquidityRemoved(
            user,
            address(liquidityData.pool),
            nftTokenId,
            baseAmountRemoved,
            quoteAmountRemoved,
            liquidityData.indexedPipRange,
            liquidityData.liquidity
        );
    }

    /**
     * @dev see {ILiquidityManager-increaseLiquidity}
     */
    function increaseLiquidity(
        uint256 nftTokenId,
        uint128 amountModify,
        bool isBase
    ) public payable virtual {
        Require._require(amountModify != 0, DexErrors.LQ_INVALID_NUMBER);

        UserLiquidity.Data memory liquidityData = concentratedLiquidity[
            nftTokenId
        ];
        address user = _msgSender();
        amountModify = uint128(
            _depositLiquidity(
                liquidityData.pool,
                user,
                isBase ? Asset.Type.Base : Asset.Type.Quote,
                amountModify
            )
        );

        ResultAddLiquidity memory _resultAddLiquidity = _addLiquidity(
            amountModify,
            isBase,
            liquidityData.indexedPipRange,
            _getCurrentIndexPipRange(liquidityData.pool),
            liquidityData.pool
        );

        uint256 amountModifySecondAsset = _depositLiquidity(
            liquidityData.pool,
            user,
            isBase ? Asset.Type.Quote : Asset.Type.Base,
            isBase
                ? _resultAddLiquidity.quoteAmountAdded
                : _resultAddLiquidity.baseAmountAdded
        );

        Require._require(
            isBase
                ? amountModifySecondAsset >=
                    _resultAddLiquidity.quoteAmountAdded
                : amountModifySecondAsset >=
                    _resultAddLiquidity.baseAmountAdded,
            DexErrors.LQ_NOT_SUPPORT
        );

        UserLiquidity.CollectFeeData
            memory _collectFeeData = estimateCollectFee(
                liquidityData.pool,
                liquidityData.feeGrowthBase,
                liquidityData.feeGrowthQuote,
                liquidityData.liquidity,
                liquidityData.indexedPipRange
            );

        _withdrawLiquidity(
            liquidityData.pool,
            user,
            Asset.Type.Base,
            _collectFeeData.feeBaseAmount
        );

        _withdrawLiquidity(
            liquidityData.pool,
            user,
            Asset.Type.Quote,
            _collectFeeData.feeQuoteAmount
        );

        concentratedLiquidity[nftTokenId].updateLiquidity(
            liquidityData.liquidity + uint128(_resultAddLiquidity.liquidity),
            liquidityData.indexedPipRange,
            _collectFeeData.newFeeGrowthBase,
            _collectFeeData.newFeeGrowthQuote
        );

        _updateStakingLiquidity(
            user,
            nftTokenId,
            address(liquidityData.pool),
            uint128(_resultAddLiquidity.liquidity),
            ModifyType.INCREASE
        );

        emit LiquidityModified(
            user,
            address(liquidityData.pool),
            nftTokenId,
            _resultAddLiquidity.baseAmountAdded,
            _resultAddLiquidity.quoteAmountAdded,
            ModifyType.INCREASE,
            liquidityData.indexedPipRange,
            uint128(_resultAddLiquidity.liquidity)
        );
    }

    /**
     * @dev see {ILiquidityManager-decreaseLiquidity}
     */
    function decreaseLiquidity(uint256 nftTokenId, uint128 liquidityAmount)
        public
        virtual
    {
        Require._require(liquidityAmount != 0, DexErrors.LQ_INVALID_NUMBER);

        UserLiquidity.Data memory liquidityData = concentratedLiquidity[
            nftTokenId
        ];

        if (liquidityAmount > liquidityData.liquidity) {
            liquidityAmount = liquidityData.liquidity;
        }

        (
            uint128 baseAmountRemoved,
            uint128 quoteAmountRemoved
        ) = _removeLiquidity(liquidityData, liquidityAmount);

        UserLiquidity.CollectFeeData
            memory _collectFeeData = estimateCollectFee(
                liquidityData.pool,
                liquidityData.feeGrowthBase,
                liquidityData.feeGrowthQuote,
                liquidityData.liquidity,
                liquidityData.indexedPipRange
            );

        concentratedLiquidity[nftTokenId].updateLiquidity(
            liquidityData.liquidity - liquidityAmount,
            liquidityData.indexedPipRange,
            _collectFeeData.newFeeGrowthBase,
            _collectFeeData.newFeeGrowthQuote
        );

        address user = _msgSender();
        _withdrawLiquidity(
            liquidityData.pool,
            user,
            Asset.Type.Base,
            baseAmountRemoved + _collectFeeData.feeBaseAmount
        );

        _withdrawLiquidity(
            liquidityData.pool,
            user,
            Asset.Type.Quote,
            quoteAmountRemoved + _collectFeeData.feeQuoteAmount
        );

        _updateStakingLiquidity(
            user,
            nftTokenId,
            address(liquidityData.pool),
            liquidityAmount,
            ModifyType.DECREASE
        );

        emit LiquidityModified(
            user,
            address(liquidityData.pool),
            nftTokenId,
            baseAmountRemoved,
            quoteAmountRemoved,
            ModifyType.DECREASE,
            liquidityData.indexedPipRange,
            liquidityAmount
        );
    }

    struct ShiftRangeState {
        UserLiquidity.Data liquidityData;
        UserLiquidity.CollectFeeData collectFeeData;
        ResultAddLiquidity resultAddLiquidity;
        address user;
        uint256 currentIndexedPipRange;
        uint128 baseReceiveEstimate;
        uint128 quoteReceiveEstimate;
    }

    /**
     * @dev see {ILiquidityManager-shiftRange}
     */
    function shiftRange(
        uint256 nftTokenId,
        uint32 targetIndex,
        uint128 amountNeeded,
        bool isBase
    ) public payable virtual {
        ShiftRangeState memory state;

        state.liquidityData = concentratedLiquidity[nftTokenId];

        state.currentIndexedPipRange = _getCurrentIndexPipRange(
            state.liquidityData.pool
        );

        Require._require(
            targetIndex != state.liquidityData.indexedPipRange,
            DexErrors.LQ_INDEX_RANGE_NOT_DIFF
        );

        state.collectFeeData = estimateCollectFee(
            state.liquidityData.pool,
            state.liquidityData.feeGrowthBase,
            state.liquidityData.feeGrowthQuote,
            state.liquidityData.liquidity,
            state.liquidityData.indexedPipRange
        );

        (
            uint128 baseAmountRemoved,
            uint128 quoteAmountRemoved
        ) = _removeLiquidity(
                state.liquidityData,
                state.liquidityData.liquidity
            );

        state.baseReceiveEstimate =
            baseAmountRemoved +
            uint128(state.collectFeeData.feeBaseAmount);
        state.quoteReceiveEstimate =
            quoteAmountRemoved +
            uint128(state.collectFeeData.feeQuoteAmount);

        state.user = _msgSender();

        amountNeeded = uint128(
            _depositLiquidity(
                state.liquidityData.pool,
                state.user,
                isBase ? Asset.Type.Base : Asset.Type.Quote,
                amountNeeded
            )
        );

        if (isBase) {
            state.baseReceiveEstimate += amountNeeded;
        } else {
            state.quoteReceiveEstimate += amountNeeded;
        }
        if (
            (targetIndex > state.currentIndexedPipRange &&
                state.baseReceiveEstimate == 0) ||
            (targetIndex < state.currentIndexedPipRange &&
                state.quoteReceiveEstimate == 0)
        ) {
            revert("Invalid amount");
        }

        state.resultAddLiquidity = _addLiquidity(
            // calculate based on BaseAmount. Keep the amount of Base if
            // targetIndex > liquidityData.indexedPipRange
            // else Calculate based on QuoteAmount. Keep the amount of Quote
            isBase ? state.baseReceiveEstimate : state.quoteReceiveEstimate,
            isBase,
            targetIndex,
            state.currentIndexedPipRange,
            state.liquidityData.pool
        );

        {
            uint256 amountNeed;
            uint256 amountTransferred;
            if (
                quoteAmountRemoved + state.collectFeeData.feeQuoteAmount <
                state.resultAddLiquidity.quoteAmountAdded
            ) {
                amountNeed =
                    state.resultAddLiquidity.quoteAmountAdded -
                    quoteAmountRemoved -
                    state.collectFeeData.feeQuoteAmount;
                if (isBase) {
                    amountTransferred = _depositLiquidity(
                        state.liquidityData.pool,
                        state.user,
                        Asset.Type.Quote,
                        amountNeed
                    );
                    Require._require(
                        amountTransferred >= amountNeed,
                        DexErrors.DEX_MUST_NOT_TOKEN_RFI
                    );
                }
            } else {
                _withdrawLiquidity(
                    state.liquidityData.pool,
                    state.user,
                    Asset.Type.Quote,
                    quoteAmountRemoved +
                        state.collectFeeData.feeQuoteAmount -
                        state.resultAddLiquidity.quoteAmountAdded
                );
            }

            if (
                baseAmountRemoved + state.collectFeeData.feeBaseAmount <
                state.resultAddLiquidity.baseAmountAdded
            ) {
                amountNeed =
                    state.resultAddLiquidity.baseAmountAdded -
                    baseAmountRemoved -
                    state.collectFeeData.feeBaseAmount;
                if (!isBase) {
                    amountTransferred = _depositLiquidity(
                        state.liquidityData.pool,
                        state.user,
                        Asset.Type.Base,
                        amountNeed
                    );

                    Require._require(
                        amountTransferred >= amountNeed,
                        DexErrors.DEX_MUST_NOT_TOKEN_RFI
                    );
                }
            } else {
                _withdrawLiquidity(
                    state.liquidityData.pool,
                    state.user,
                    Asset.Type.Base,
                    baseAmountRemoved +
                        state.collectFeeData.feeBaseAmount -
                        state.resultAddLiquidity.baseAmountAdded
                );
            }
        }

        concentratedLiquidity[nftTokenId].updateLiquidity(
            uint128(state.resultAddLiquidity.liquidity),
            targetIndex,
            state.resultAddLiquidity.feeGrowthBase,
            state.resultAddLiquidity.feeGrowthQuote
        );

        _updateStakingLiquidity(
            state.user,
            nftTokenId,
            address(state.liquidityData.pool),
            uint128(state.resultAddLiquidity.liquidity),
            state.resultAddLiquidity.liquidity > state.liquidityData.liquidity
                ? ModifyType.INCREASE
                : ModifyType.DECREASE
        );

        emit LiquidityShiftRange(
            state.user,
            address(state.liquidityData.pool),
            nftTokenId,
            state.liquidityData.indexedPipRange,
            state.liquidityData.liquidity,
            baseAmountRemoved,
            quoteAmountRemoved,
            targetIndex,
            uint128(state.resultAddLiquidity.liquidity),
            state.resultAddLiquidity.baseAmountAdded,
            state.resultAddLiquidity.quoteAmountAdded
        );
    }

    /**
     * @dev see {ILiquidityManager-collectFee}
     */
    function collectFee(uint256 nftTokenId) public virtual {
        UserLiquidity.Data memory liquidityData = concentratedLiquidity[
            nftTokenId
        ];
        UserLiquidity.CollectFeeData memory _collectFeeData;
        _collectFeeData = estimateCollectFee(
            liquidityData.pool,
            liquidityData.feeGrowthBase,
            liquidityData.feeGrowthQuote,
            liquidityData.liquidity,
            liquidityData.indexedPipRange
        );

        address user = _msgSender();
        _withdrawLiquidity(
            liquidityData.pool,
            user,
            Asset.Type.Base,
            _collectFeeData.feeBaseAmount
        );

        _withdrawLiquidity(
            liquidityData.pool,
            user,
            Asset.Type.Quote,
            _collectFeeData.feeQuoteAmount
        );
        concentratedLiquidity[nftTokenId].feeGrowthBase = _collectFeeData
            .newFeeGrowthBase;
        concentratedLiquidity[nftTokenId].feeGrowthQuote = _collectFeeData
            .newFeeGrowthQuote;
    }

    /**
     * @dev see {ILiquidityManager-liquidity}
     */
    function liquidity(uint256 nftTokenId)
        public
        view
        virtual
        returns (
            uint128 baseVirtual,
            uint128 quoteVirtual,
            uint128 liquidity,
            uint128 power,
            uint256 indexedPipRange,
            uint128 feeBasePending,
            uint128 feeQuotePending,
            IMatchingEngineAMM pool
        )
    {
        UserLiquidity.Data memory liquidityData = concentratedLiquidity[
            nftTokenId
        ];
        if (address(liquidityData.pool) == address(0x000)) {
            return (
                baseVirtual,
                quoteVirtual,
                liquidity,
                power,
                indexedPipRange,
                feeBasePending,
                feeQuotePending,
                pool
            );
        }
        UserLiquidity.CollectFeeData memory _collectFeeData;
        _collectFeeData = estimateCollectFee(
            liquidityData.pool,
            liquidityData.feeGrowthBase,
            liquidityData.feeGrowthQuote,
            liquidityData.liquidity,
            liquidityData.indexedPipRange
        );

        uint128 baseAmountRemoved;
        uint128 quoteAmountRemoved;

        if (liquidityData.liquidity > 0) {
            (baseAmountRemoved, quoteAmountRemoved, ) = liquidityData
                .pool
                .estimateRemoveLiquidity(
                    IAutoMarketMakerCore.RemoveLiquidity({
                        liquidity: liquidityData.liquidity,
                        indexedPipRange: liquidityData.indexedPipRange,
                        feeGrowthBase: liquidityData.feeGrowthBase,
                        feeGrowthQuote: liquidityData.feeGrowthQuote
                    })
                );
        }

        power = _calculatePower(
            liquidityData.indexedPipRange,
            uint32(_getCurrentIndexPipRange(liquidityData.pool)),
            liquidityData.liquidity
        );

        return (
            baseAmountRemoved,
            quoteAmountRemoved,
            liquidityData.liquidity,
            power,
            liquidityData.indexedPipRange,
            _collectFeeData.feeBaseAmount,
            _collectFeeData.feeQuoteAmount,
            liquidityData.pool
        );
    }

    function getAllDataDetailTokens(uint256[] memory tokens)
        public
        view
        returns (LiquidityDetail[] memory)
    {
        LiquidityDetail[] memory liquidityData = new LiquidityDetail[](
            tokens.length
        );
        for (uint256 i = 0; i < tokens.length; i++) {
            (
                uint128 baseVirtual,
                uint128 quoteVirtual,
                uint128 liquidityAmount,
                uint128 power,
                uint256 indexedPipRange,
                uint128 feeBasePending,
                uint128 feeQuotePending,
                IMatchingEngineAMM pool
            ) = liquidity(tokens[i]);
            /// This code below will take contract-size increase
            /// but this way avoid stack too deep error
            liquidityData[i].baseVirtual = baseVirtual;
            liquidityData[i].quoteVirtual = quoteVirtual;
            liquidityData[i].liquidity = liquidityAmount;
            liquidityData[i].power = power;
            liquidityData[i].indexedPipRange = indexedPipRange;
            liquidityData[i].feeBasePending = feeBasePending;
            liquidityData[i].feeQuotePending = feeQuotePending;
            liquidityData[i].pool = pool;
        }
        return liquidityData;
    }

    //------------------------------------------------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //------------------------------------------------------------------------------------------------------------------
    function _msgSender() internal view virtual returns (address) {}

    struct ResultAddLiquidity {
        uint128 baseAmountAdded;
        uint128 quoteAmountAdded;
        uint256 liquidity;
        uint256 feeGrowthBase;
        uint256 feeGrowthQuote;
    }

    struct State {
        uint128 baseAmountModify;
        uint128 quoteAmountModify;
        uint256 currentIndexedPipRange;
        ISpotFactory.Pair pair;
        address WBNBAddress;
        uint128 currentPrice;
        uint128 maxPip;
        uint128 minPip;
        uint128 basicPoint;
    }

    function _addLiquidity(
        uint128 amountModify,
        bool isBase,
        uint32 indexedPipRange,
        uint256 currentIndexedPipRange,
        IMatchingEngineAMM pool
    ) internal returns (ResultAddLiquidity memory result) {
        State memory state;
        state.currentIndexedPipRange = currentIndexedPipRange;
        state.currentPrice = pool.getCurrentPip();

        (state.minPip, state.maxPip) = LiquidityMath.calculatePipRange(
            indexedPipRange,
            _getPipRange(pool)
        );

        state.pair = _getQuoteAndBase(pool);

        if (
            (indexedPipRange < state.currentIndexedPipRange) ||
            (indexedPipRange == state.currentIndexedPipRange &&
                state.currentPrice == state.maxPip)
        ) {
            if (isBase) revert(DexErrors.LQ_MUST_QUOTE);

            state.quoteAmountModify = amountModify;
        } else if (
            (indexedPipRange > state.currentIndexedPipRange) ||
            (indexedPipRange == state.currentIndexedPipRange &&
                state.currentPrice == state.minPip)
        ) {
            if (!isBase) revert(DexErrors.LQ_MUST_BASE);
            state.baseAmountModify = amountModify;
        } else if (indexedPipRange == state.currentIndexedPipRange) {
            state.maxPip = uint128(Math.sqrt(uint256(state.maxPip) * 10**18));
            state.minPip = uint128(Math.sqrt(uint256(state.minPip) * 10**18));
            state.currentPrice = uint128(
                Math.sqrt(uint256(state.currentPrice) * 10**18)
            );

            if (isBase) {
                state.baseAmountModify = amountModify;
                state.quoteAmountModify = LiquidityHelper
                    .calculateQuoteVirtualFromBaseReal(
                        LiquidityMath.calculateBaseReal(
                            state.maxPip,
                            amountModify,
                            state.currentPrice
                        ),
                        state.currentPrice,
                        state.minPip,
                        uint128(Math.sqrt(pool.basisPoint()))
                    );
            } else {
                state.quoteAmountModify = amountModify;
                state.baseAmountModify =
                    LiquidityHelper.calculateBaseVirtualFromQuoteReal(
                        LiquidityMath.calculateQuoteReal(
                            state.minPip,
                            amountModify,
                            state.currentPrice
                        ),
                        state.currentPrice,
                        state.maxPip
                    ) *
                    uint128(pool.basisPoint());
            }
        }

        (
            result.baseAmountAdded,
            result.quoteAmountAdded,
            result.liquidity,
            result.feeGrowthBase,
            result.feeGrowthQuote
        ) = pool.addLiquidity(
            IAutoMarketMakerCore.AddLiquidity({
                baseAmount: state.baseAmountModify,
                quoteAmount: state.quoteAmountModify,
                indexedPipRange: indexedPipRange
            })
        );
    }

    function _addLiquidityRecipient(
        AddLiquidityParams calldata params,
        address user,
        address recipient
    ) internal {
        Require._require(
            params.amountVirtual != 0,
            DexErrors.LQ_INVALID_NUMBER
        );
        uint256 _addedAmountVirtual = _depositLiquidity(
            params.pool,
            user,
            params.isBase ? Asset.Type.Base : Asset.Type.Quote,
            params.amountVirtual
        );

        ResultAddLiquidity memory _resultAddLiquidity = _addLiquidity(
            uint128(_addedAmountVirtual),
            params.isBase,
            params.indexedPipRange,
            _getCurrentIndexPipRange(params.pool),
            params.pool
        );

        uint256 amountModifySecondAsset = _depositLiquidity(
            params.pool,
            user,
            params.isBase ? Asset.Type.Quote : Asset.Type.Base,
            params.isBase
                ? _resultAddLiquidity.quoteAmountAdded
                : _resultAddLiquidity.baseAmountAdded
        );
        Require._require(
            params.isBase
                ? amountModifySecondAsset >=
                    _resultAddLiquidity.quoteAmountAdded
                : amountModifySecondAsset >=
                    _resultAddLiquidity.baseAmountAdded,
            DexErrors.LQ_NOT_SUPPORT
        );

        uint256 nftTokenId = mint(recipient);

        concentratedLiquidity[nftTokenId] = UserLiquidity.Data({
            liquidity: uint128(_resultAddLiquidity.liquidity),
            indexedPipRange: params.indexedPipRange,
            feeGrowthBase: _resultAddLiquidity.feeGrowthBase,
            feeGrowthQuote: _resultAddLiquidity.feeGrowthQuote,
            pool: params.pool
        });

        emit LiquidityAdded(
            recipient,
            address(params.pool),
            nftTokenId,
            _resultAddLiquidity.baseAmountAdded,
            _resultAddLiquidity.quoteAmountAdded,
            params.indexedPipRange,
            _resultAddLiquidity.liquidity
        );
    }

    function _removeLiquidity(
        UserLiquidity.Data memory liquidityData,
        uint128 liquidityAmount
    ) internal returns (uint128 baseAmount, uint128 quoteAmount) {
        if (liquidityAmount == 0) return (baseAmount, quoteAmount);
        return
            liquidityData.pool.removeLiquidity(
                IAutoMarketMakerCore.RemoveLiquidity({
                    liquidity: liquidityAmount,
                    indexedPipRange: liquidityData.indexedPipRange,
                    feeGrowthBase: liquidityData.feeGrowthBase,
                    feeGrowthQuote: liquidityData.feeGrowthQuote
                })
            );
    }

    function estimateCollectFee(
        IMatchingEngineAMM pool,
        uint256 feeGrowthBase,
        uint256 feeGrowthQuote,
        uint128 liquidityAmount,
        uint32 indexedPipRange
    ) public view returns (UserLiquidity.CollectFeeData memory _feeData) {
        (
            ,
            ,
            ,
            ,
            ,
            _feeData.newFeeGrowthBase,
            _feeData.newFeeGrowthQuote,

        ) = pool.liquidityInfo(indexedPipRange);

        _feeData.feeBaseAmount = uint128(
            Math.mulDiv(
                _feeData.newFeeGrowthBase - feeGrowthBase,
                liquidityAmount,
                FixedPoint128.Q_POW18
            )
        );
        _feeData.feeQuoteAmount = uint128(
            Math.mulDiv(
                _feeData.newFeeGrowthQuote - feeGrowthQuote,
                liquidityAmount,
                FixedPoint128.Q_POW18
            )
        );
    }

    function _getPipRange(IMatchingEngineAMM pool)
        internal
        view
        returns (uint128 pipRange)
    {
        return pool.pipRange();
    }

    function _getCurrentIndexPipRange(IMatchingEngineAMM pool)
        internal
        view
        returns (uint256)
    {
        return pool.currentIndexedPipRange();
    }

    function _calculatePower(
        uint32 indexedPipRangeNft,
        uint32 currentIndexedPipRange,
        uint256 liquidity
    ) internal pure returns (uint128 power) {
        if (indexedPipRangeNft > currentIndexedPipRange) {
            power = uint128(
                liquidity / ((indexedPipRangeNft - currentIndexedPipRange) + 1)
            );
        } else {
            power = uint128(
                liquidity / ((currentIndexedPipRange - indexedPipRangeNft) + 1)
            );
        }
    }

    function _getCurrentPrice(IMatchingEngineAMM pool)
        internal
        returns (uint128)
    {}

    function _depositLiquidity(
        IMatchingEngineAMM _pairManager,
        address _payer,
        Asset.Type _asset,
        uint256 _amount
    ) internal virtual returns (uint256 amount) {}

    function _withdrawLiquidity(
        IMatchingEngineAMM _pairManager,
        address _recipient,
        Asset.Type _asset,
        uint256 _amount
    ) internal virtual {}

    function _getQuoteAndBase(IMatchingEngineAMM _managerAddress)
        internal
        view
        virtual
        returns (ISpotFactory.Pair memory pair)
    {}

    function _getWBNBAddress() internal view virtual returns (address) {}

    function _updateStakingLiquidity(
        address user,
        uint256 tokenId,
        address poolAddress,
        uint128 deltaLiquidityModify,
        ModifyType modifyType
    ) internal {
        /// NFT in user wallet
        if (_isOwner(tokenId, _msgSender())) return;

        address stakingManager = getStakingManager(poolAddress);
        if (stakingManager != address(0)) {
            if (_isOwner(tokenId, stakingManager)) {
                Require._require(
                    IUpdateStakingManager(stakingManager)
                        .updateStakingLiquidity(
                            user,
                            tokenId,
                            poolAddress,
                            deltaLiquidityModify,
                            modifyType
                        ) == address(this),
                    DexErrors.LQ_NOT_IMPLEMENT_YET
                );
            }
        } else {
            //            revert(DexErrors.LQ_EMPTY_STAKING_MANAGER);
        }
    }

    function isOwnerWhenStaking(address user, uint256 nftId)
        public
        view
        returns (bool)
    {
        UserLiquidity.Data memory liquidityData = concentratedLiquidity[nftId];
        address stakingManager = getStakingManager(address(liquidityData.pool));
        if (stakingManager != address(0)) {
            (bool isOwner, address caller) = ICheckOwnerWhenStaking(
                stakingManager
            ).isOwnerWhenStaking(user, nftId);

            Require._require(
                caller == address(this),
                DexErrors.LQ_NOT_IMPLEMENT_YET
            );
            return isOwner;
        } else {
            //            revert(DexErrors.LQ_EMPTY_STAKING_MANAGER);
        }
        return false;
    }

    function mint(address user) internal virtual returns (uint256 tokenId) {}

    function burn(uint256 tokenId) internal virtual {}

    function _isOwner(uint256 tokenId, address user)
        internal
        view
        virtual
        returns (bool)
    {}

    function getStakingManager(address poolAddress)
        public
        view
        virtual
        returns (address)
    {}

    function _trackingId(address pairManager)
        internal
        virtual
        returns (uint256)
    {}
}