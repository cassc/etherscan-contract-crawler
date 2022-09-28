// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./libraries/exchange/TickPosition.sol";
import "./libraries/exchange/LimitOrder.sol";
import "./libraries/exchange/LiquidityBitmap.sol";
import "./libraries/types/PairManagerStorage.sol";
import "./libraries/helper/Timers.sol";
import "../interfaces/IPairManager.sol";
import "../interfaces/IPosiCallback.sol";
import {Errors} from "./libraries/helper/Errors.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "hardhat/console.sol";
import "./implement/Block.sol";
import "./libraries/helper/Convert.sol";
import "./libraries/helper/PackedOrderId.sol";
import "./libraries/helper/TradeConvert.sol";
import "./libraries/helper/BitMathLiquidity.sol";

/// @title A PairManager stores all the information about the pairs and the liquidity
/// @author Position Exchange Team
/// @notice
/// @dev
contract PairManagerBond is IPairManager, Block, PairManagerStorage {
    using TickPosition for TickPosition.Data;
    using LiquidityBitmap for mapping(uint128 => uint256);
    using Timers for uint64;
    using Convert for uint256;
    using Convert for int256;
    using PackedOrderId for uint128;
    using PackedOrderId for bytes32;
    using TradeConvert for uint256;

    modifier onlyCounterParty() {
        require(
            counterParty == _msgSender() || liquidityPoolAllowed[_msgSender()],
            Errors.VL_ONLY_COUNTERPARTY
        );
        _;
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), Errors.VL_ONLY_OWNER);
        _;
    }
    constructor(
        address _quoteAsset,
        address _baseAsset,
        address _counterParty,
        uint256 _basisPoint,
        uint256 _BASE_BASIC_POINT,
        uint128 _maxFindingWordsIndex,
        uint128 _initialPip,
        uint64 _expireTime,
        address _owner,
        address _liquidityPool
    ) {
        reserveSnapshots.push(
            ReserveSnapshot(_initialPip, _blockTimestamp(), _blockNumber())
        );

        counterParty = _counterParty;
        quoteAsset = IERC20(_quoteAsset);
        baseAsset = IERC20(_baseAsset);
        singleSlot.pip = _initialPip;
        basisPoint = _basisPoint;
        BASE_BASIC_POINT = _BASE_BASIC_POINT;
        maxFindingWordsIndex = _maxFindingWordsIndex;
        maxWordRangeForLimitOrder = _maxFindingWordsIndex;
        maxWordRangeForMarketOrder = _maxFindingWordsIndex;
        expireTime = _expireTime;

        owner = _owner;
        liquidityPool = _liquidityPool;

        _isInitialized = true;

        _approve();
        emit PairManagerInitialized(
            _quoteAsset,
            _baseAsset,
            _counterParty,
            _basisPoint,
            _BASE_BASIC_POINT,
            _maxFindingWordsIndex,
            _initialPip,
            _expireTime,
            _owner
        );
    }

    function initializeFactory(
        address _quoteAsset,
        address _baseAsset,
        address _counterParty,
        uint256 _basisPoint,
        uint256 _BASE_BASIC_POINT,
        uint128 _maxFindingWordsIndex,
        uint128 _initialPip,
        uint64 _expireTime,
        address _owner,
        address _liquidityPool
    ) public override {}

    function collectFund(
        IERC20 token,
        address to,
        uint256 amount
    ) external override {}

    function cancelGridOrders(bytes32[] memory _orderIds)
        public
        override
        returns (uint256 base, uint256 quote)
    {}

    function accumulatePoolLiquidityClaimableAmount(
        uint128 _pip,
        uint64 _orderId,
        IPairManager.ExchangedData memory exData,
        uint256 basisPoint,
        uint16 fee,
        uint128 feeBasis
    )
        external
        virtual
        override
        returns (IPairManager.ExchangedData memory, bool isFilled)
    {}

    function supplyGridOrder(
        Grid.GridOrderData[] memory orders,
        address user,
        bytes memory data,
        bytes32 poolId
    )
        external
        override
        returns (
            uint256 baseAmountUsed,
            uint256 quoteAmountUsed,
            bytes32[] memory orderIds
        )
    {}

    //------------------------------------------------------------------------------------------------------------------
    // FUNCTIONS CALLED FROM SPOT HOUSE
    //------------------------------------------------------------------------------------------------------------------

    function updatePartialFilledOrder(uint128 pip, uint64 orderId)
        external
        override
        onlyCounterParty
    {
        uint256 newSize = tickPosition[pip].updateOrderWhenClose(orderId);
        emit LimitOrderUpdated(address(this), orderId, pip, newSize);
    }

    function cancelLimitOrder(uint128 pip, uint64 orderId)
        external
        override
        onlyCounterParty
        returns (uint256 remainingSize, uint256 partialFilled)
    {
        return _internalCancelLimitOrder(pip, orderId);
    }

    function openLimit(
        uint128 pip,
        uint128 size,
        bool isBuy,
        address trader,
        uint256 quoteDeposited
    )
        external
        override
        onlyCounterParty
        returns (
            uint64 orderId,
            uint256 sizeOut,
            uint256 quoteAmount
        )
    {
        require(!isExpired(), Errors.VL_EXPIRED);
        (orderId, sizeOut, quoteAmount) = _internalOpenLimit(
            ParamsInternalOpenLimit({
                pip: pip,
                size: size,
                isBuy: isBuy,
                trader: trader,
                quoteDeposited: quoteDeposited
            })
        );
    }

    function openMarket(
        uint256 size,
        bool isBuy,
        address trader
    )
        external
        override
        onlyCounterParty
        returns (uint256 sizeOut, uint256 quoteAmount)
    {
        require(!isExpired(), Errors.VL_EXPIRED);
        return _internalOpenMarketOrder(size, isBuy, 0, trader, true);
    }

    function openMarketWithQuoteAsset(
        uint256 quoteAmount,
        bool _isBuy,
        address _trader
    )
        external
        override
        onlyCounterParty
        returns (uint256 sizeOutQuote, uint256 baseAmount)
    {
        require(!isExpired(), Errors.VL_EXPIRED);

        (sizeOutQuote, baseAmount) = _internalOpenMarketOrder(
            quoteAmount,
            _isBuy,
            0,
            _trader,
            false
        );
    }

    function decreaseBaseFeeFunding(uint256 baseFee)
        external
        override
        onlyCounterParty
    {
        if (baseFee > 0) {
            baseFeeFunding -= baseFee;
        }
    }

    function decreaseQuoteFeeFunding(uint256 quoteFee)
        external
        override
        onlyCounterParty
    {
        if (quoteFee > 0) {
            quoteFeeFunding -= quoteFee;
        }
    }

    function increaseBaseFeeFunding(uint256 baseFee)
        external
        override
        onlyCounterParty
    {
        if (baseFee > 0) {
            baseFeeFunding += baseFee;
        }
    }

    function increaseQuoteFeeFunding(uint256 quoteFee)
        external
        override
        onlyCounterParty
    {
        if (quoteFee > 0) {
            quoteFeeFunding += quoteFee;
        }
    }

    function resetFee(uint256 baseFee, uint256 quoteFee)
        external
        override
        onlyCounterParty
    {
        baseFeeFunding -= baseFee;
        quoteFeeFunding -= quoteFee;
    }

    //------------------------------------------------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //------------------------------------------------------------------------------------------------------------------

    function getAmountEstimate(
        uint256 size,
        bool isBuy,
        bool isBase
    ) external view override returns (uint256 sizeOut, uint256 openOtherSide) {}

    function accumulateClaimableAmount(
        uint128 _pip,
        uint64 _orderId,
        IPairManager.ExchangedData memory exData,
        uint256 basisPoint,
        uint16 fee,
        uint128 feeBasis
    ) external view override returns (IPairManager.ExchangedData memory) {
        (
            bool isFilled,
            bool isBuy,
            uint256 baseSize,
            uint256 partialFilled
        ) = getPendingOrderDetail(_pip, _orderId);
        uint256 filledSize = isFilled ? baseSize : partialFilled;
        {
            if (isBuy) {
                //BUY => can claim base asset
                exData.baseAmount += filledSize;
                //                exData.feeQuoteAmount += _feeRefundCalculator(
                //                    filledSize.baseToQuote(_pip, basisPoint),
                //                    fee,
                //                    feeBasis
                //                );
            } else {
                // SELL => can claim quote asset
                exData.quoteAmount += filledSize.baseToQuote(_pip, basisPoint);
                //                exData.feeBaseAmount += _feeRefundCalculator(
                //                    filledSize,
                //                    fee,
                //                    feeBasis
                //                );
            }
        }
        return exData;
    }

    function accumulatePoolExchangedData(
        bytes32[256] memory _orderIds,
        uint16 _feeShareRatio,
        uint128 _feeBasis,
        int128 soRemovablePosBuy,
        int128 soRemovablePosSell
    ) external view override returns (int128 quoteAdjust, int128 baseAdjust) {}

    function getFee() external view override returns (uint256, uint256) {
        return (baseFeeFunding, quoteFeeFunding);
    }

    function isExpired() public view returns (bool) {
        // If not set expireTime for this pair
        // expireTime is 0 and unlimited time to expire
        if (expireTime == 0) {
            return false;
        }
        return expireTime.passed(_blockTimestamp());
    }

    function getBaseBasisPoint() public view override returns (uint256) {
        return BASE_BASIC_POINT;
    }

    function getBasisPoint() public view override returns (uint256) {
        return basisPoint;
    }

    function getCurrentPipAndBasisPoint()
        public
        view
        override
        returns (uint128, uint128)
    {
        return (singleSlot.pip, uint128(basisPoint));
    }

    function getCurrentPip() public view override returns (uint128) {
        return singleSlot.pip;
    }

    function getCurrentSingleSlot()
        public
        view
        override
        returns (uint128, uint8)
    {
        return (singleSlot.pip, singleSlot.isFullBuy);
    }

    function getPrice() public view override returns (uint256) {
        return (uint256(singleSlot.pip) * BASE_BASIC_POINT) / basisPoint;
    }

    function getQuoteAsset() public view override returns (IERC20) {
        return quoteAsset;
    }

    function getBaseAsset() public view override returns (IERC20) {
        return baseAsset;
    }

    function pipToPrice(uint128 pip) public view override returns (uint256) {
        return (uint256(pip) * BASE_BASIC_POINT) / basisPoint;
    }

    function pipToPriceV2(
        uint128 pip,
        uint256 baseBasisPoint,
        uint256 basisPoint
    ) public view returns (uint256) {
        return (uint256(pip) * baseBasisPoint) / basisPoint;
    }

    function calculatingQuoteAmount(uint256 quantity, uint128 pip)
        public
        view
        override
        returns (uint256)
    {
        return TradeConvert.baseToQuote(quantity, pip, basisPoint);
    }

    function calculatingQuoteAmountV2(
        uint256 quantity,
        uint128 pip,
        uint256 baseBasisPoint,
        uint256 basisPoint
    ) public view returns (uint256) {
        return
            (quantity * pipToPriceV2(pip, baseBasisPoint, basisPoint)) /
            baseBasisPoint;
    }

    function getLiquidityInCurrentPip() public view override returns (uint128) {
        return
            liquidityBitmap.hasLiquidity(singleSlot.pip)
                ? tickPosition[singleSlot.pip].liquidity
                : 0;
    }

    function hasLiquidity(uint128 pip) public view override returns (bool) {
        return liquidityBitmap.hasLiquidity(pip);
    }

    function getPendingOrderDetail(uint128 pip, uint64 orderId)
        public
        view
        virtual
        override
        returns (
            bool isFilled,
            bool isBuy,
            uint256 size,
            uint256 partialFilled
        )
    {
        (isFilled, isBuy, size, partialFilled) = tickPosition[pip]
            .getQueueOrder(orderId);

        if (!liquidityBitmap.hasLiquidity(pip)) {
            isFilled = true;
        }
        if (size != 0 && size == partialFilled) {
            isFilled = true;
        }
    }

    function getLiquidityInPipRange(
        uint128 fromPip,
        uint256 dataLength,
        bool toHigher
    ) external view override returns (LiquidityOfEachPip[] memory, uint128) {
        uint128[] memory allInitializedPip = new uint128[](uint128(dataLength));
        allInitializedPip = liquidityBitmap.findAllLiquidityInMultipleWords(
            fromPip,
            dataLength,
            toHigher
        );
        LiquidityOfEachPip[] memory allLiquidity = new LiquidityOfEachPip[](
            dataLength
        );

        for (uint256 i = 0; i < dataLength; i++) {
            allLiquidity[i] = LiquidityOfEachPip({
                pip: allInitializedPip[i],
                liquidity: tickPosition[allInitializedPip[i]].liquidity
            });
        }
        return (allLiquidity, allInitializedPip[dataLength - 1]);
    }

    //------------------------------------------------------------------------------------------------------------------
    // ONLY OWNER FUNCTIONS
    //------------------------------------------------------------------------------------------------------------------

    function updateSpotHouse(address _newSpotHouse)
        external
        override
        onlyOwner
    {
        counterParty = _newSpotHouse;
        _approve();
    }

    function updateMaxWordRangeForLimitOrder(
        uint128 _newMaxWordRangeForLimitOrder
    ) external onlyOwner {
        maxWordRangeForLimitOrder = _newMaxWordRangeForLimitOrder;
    }

    function updateMaxWordRangeForMarketOrder(
        uint128 _newMaxWordRangeForMarketOrder
    ) external onlyOwner {
        maxWordRangeForMarketOrder = _newMaxWordRangeForMarketOrder;
    }

    function updateMaxFindingWordsIndex(uint128 _newMaxFindingWordsIndex)
        external
        override
        onlyOwner
    {
        maxFindingWordsIndex = _newMaxFindingWordsIndex;
        emit UpdateMaxFindingWordsIndex(
            address(this),
            _newMaxFindingWordsIndex
        );
    }

    function updateExpireTime(uint64 _expireTime) external onlyOwner {
        expireTime = _expireTime;
        emit UpdateExpireTime(address(this), _expireTime);
    }

    //------------------------------------------------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //------------------------------------------------------------------------------------------------------------------

    function _transfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) token.transfer(to, amount);
    }

    function _internalCancelLimitOrder(uint128 pip, uint64 orderId)
        internal
        returns (uint256 remainingSize, uint256 partialFilled)
    {
        bool isBuy;
        (remainingSize, partialFilled, isBuy) = tickPosition[pip]
            .cancelLimitOrder(orderId);
        if (tickPosition[pip].liquidity == 0) {
            liquidityBitmap.toggleSingleBit(pip, false);

            if (pip == getCurrentPip()) {
                singleSlot.isFullBuy = 0;
            }
        }
        emit LimitOrderCancelled(isBuy, orderId, pip, remainingSize);
    }

    function _accumulatePoolExchangedData(
        AccPoolExchangedDataParams memory params,
        uint16 _feeShareRatio,
        uint128 _feeBasis
    ) internal view {
        (uint128 _pip, uint64 _orderId, bool isBuy) = params.orderId.unpack();
        (
            bool isFilled,
            ,
            uint256 baseSize,
            uint256 partialFilled
        ) = getPendingOrderDetail(_pip, _orderId);
        uint256 filledSize = isFilled ? baseSize : partialFilled;
        if (isBuy) {
            //BUY => can claim base asset
            params.baseAdjust += filledSize.toI128();
            // sub quote and plus quote fee
            params.quoteAdjust -= (filledSize
                .baseToQuote(_pip, params.basisPoint)
                .toI128() -
                _feeRefundCalculator(
                    filledSize.baseToQuote(_pip, params.basisPoint),
                    _feeShareRatio,
                    _feeBasis
                ).toI128());
        } else {
            // SELL => can claim quote asset
            params.quoteAdjust += filledSize
                .baseToQuote(_pip, params.basisPoint)
                .toI128();
            //            if(_pip == params.currentPip){
            //                params.baseFilledCurrentPip -= filledSize.toI128();
            //            }

            params.baseAdjust -= (filledSize.toI128() -
                _feeRefundCalculator(baseSize, _feeShareRatio, _feeBasis)
                    .toI128());
        }
    }

    function _feeRefundCalculator(
        uint256 _amount,
        uint16 _fee,
        uint128 _feeBasis
    ) internal view returns (uint256 feeRefund) {
        if (_amount == 0 || _feeBasis == 0) return 0;
        feeRefund = (_amount * _fee) / (_feeBasis - _fee);
    }

    function emitEventSwap(
        bool isBuy,
        uint256 _baseAmount,
        uint256 _quoteAmount,
        address _trader
    ) internal {
        uint256 amount0In;
        uint256 amount1In;
        uint256 amount0Out;
        uint256 amount1Out;

        if (isBuy) {
            amount1In = _quoteAmount;
            amount0Out = _baseAmount;
        } else {
            amount0In = _baseAmount;
            amount1Out = _quoteAmount;
        }
        emit Swap(
            msg.sender,
            amount0In,
            amount1In,
            amount0Out,
            amount1Out,
            _trader
        );
    }

    function quoteToBase(uint256 quoteAmount, uint128 pip)
        public
        view
        override
        returns (uint256)
    {
        return (quoteAmount * basisPoint) / pip;
    }

    function quoteToBaseV2(
        uint256 quoteAmount,
        uint128 pip,
        uint256 basisPoint
    ) public view returns (uint256) {
        return (quoteAmount * basisPoint) / pip;
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _approve() internal {
        quoteAsset.approve(counterParty, type(uint256).max);
        baseAsset.approve(counterParty, type(uint256).max);
    }

    struct SwapState {
        uint256 remainingSize;
        // the tick associated with the current price
        uint128 pip;
        uint32 basisPoint;
        uint32 baseBasisPoint;
        uint128 startPip;
        uint128 remainingLiquidity;
        uint8 isFullBuy;
        bool isSkipFirstPip;
        uint128 lastMatchedPip;
    }

    function _openMarketWithMaxPip(
        uint256 size,
        bool isBuy,
        uint128 maxPip,
        address _trader
    ) internal returns (uint256 sizeOut, uint256 quoteAmount) {
        // plus 1 avoid  (singleSlot.pip - maxPip)/250 = 0
        uint128 _maxFindingWordsIndex = ((
            isBuy ? maxPip - singleSlot.pip : singleSlot.pip - maxPip
        ) / 250) + 1;
        return
            _internalOpenMarketOrderWithMaxFindingWord(
                size,
                isBuy,
                maxPip,
                address(0),
                true,
                _maxFindingWordsIndex
            );
    }

    function _internalOpenMarketOrder(
        uint256 _size,
        bool _isBuy,
        uint128 _maxPip,
        address _trader,
        bool _isBase
    ) internal returns (uint256 sizeOut, uint256 openOtherSide) {
        return
            _internalOpenMarketOrderWithMaxFindingWord(
                _size,
                _isBuy,
                _maxPip,
                _trader,
                _isBase,
                maxFindingWordsIndex
            );
    }

    function _internalOpenMarketOrderWithMaxFindingWord(
        uint256 _size,
        bool _isBuy,
        uint128 _maxPip,
        address _trader,
        bool _isBase,
        uint128 _maxFindingWordsIndex
    ) internal returns (uint256 sizeOut, uint256 openOtherSide) {
        // get current tick liquidity
        SingleSlot memory _initialSingleSlot = singleSlot;
        //save gas
        SwapState memory state = SwapState({
            remainingSize: _size,
            pip: _initialSingleSlot.pip,
            basisPoint: basisPoint.Uint256ToUint32(),
            baseBasisPoint: BASE_BASIC_POINT.Uint256ToUint32(),
            startPip: 0,
            remainingLiquidity: 0,
            isFullBuy: 0,
            isSkipFirstPip: false,
            lastMatchedPip: _initialSingleSlot.pip
        });
        {
            CurrentLiquiditySide currentLiquiditySide = CurrentLiquiditySide(
                _initialSingleSlot.isFullBuy
            );
            if (currentLiquiditySide != CurrentLiquiditySide.NotSet) {
                if (_isBuy)
                    // if buy and latest liquidity is buy. skip current pip
                    state.isSkipFirstPip =
                        currentLiquiditySide == CurrentLiquiditySide.Buy;
                    // if sell and latest liquidity is sell. skip current pip
                else
                    state.isSkipFirstPip =
                        currentLiquiditySide == CurrentLiquiditySide.Sell;
            }
        }
        while (state.remainingSize != 0) {
            StepComputations memory step;
            (step.pipNext) = liquidityBitmap.findHasLiquidityInMultipleWords(
                state.pip,
                _maxFindingWordsIndex,
                !_isBuy
            );
            // updated findHasLiquidityInMultipleWords, save more gas
            if (_maxPip != 0) {
                // if order is buy and step.pipNext (pip has liquidity) > maxPip then break cause this is limited to maxPip and vice versa
                if (
                    (_isBuy && step.pipNext > _maxPip) ||
                    (!_isBuy && step.pipNext < _maxPip)
                ) {
                    break;
                }
            }
            if (step.pipNext == 0) {
                // no more next pip
                // state pip back 1 pip
                if (_isBuy) {
                    state.pip--;
                } else {
                    state.pip++;
                }
                break;
            } else {
                if (!state.isSkipFirstPip) {
                    if (state.startPip == 0) state.startPip = step.pipNext;

                    // get liquidity at a tick index
                    uint128 liquidity = tickPosition[step.pipNext].liquidity;
                    if (_maxPip != 0) {
                        state.lastMatchedPip = step.pipNext;
                    }
                    uint256 baseAmount = _isBase
                        ? state.remainingSize
                        : quoteToBaseV2(state.remainingSize, step.pipNext, state.basisPoint);
                    if (liquidity > baseAmount) {
                        // pip position will partially filled and stop here
                        tickPosition[step.pipNext].partiallyFill(
                            baseAmount.Uint256ToUint128()
                        );
                        if (_isBase)
                            openOtherSide += calculatingQuoteAmountV2(
                                state.remainingSize,
                                step.pipNext,
                                state.baseBasisPoint,
                                state.basisPoint
                            );
                        else openOtherSide += baseAmount;

                        // remaining liquidity at current pip
                        state.remainingLiquidity =
                            liquidity -
                            baseAmount.Uint256ToUint128();
                        state.remainingSize = 0;
                        state.pip = step.pipNext;
                        state.isFullBuy = uint8(
                            !_isBuy
                                ? CurrentLiquiditySide.Buy
                                : CurrentLiquiditySide.Sell
                        );
                    } else if (baseAmount > liquidity) {
                        // order in that pip will be fulfilled
                        if (_isBase) {
                            state.remainingSize -= liquidity;
                            openOtherSide += calculatingQuoteAmountV2(
                                liquidity,
                                step.pipNext,
                                state.baseBasisPoint,
                                state.basisPoint
                            );
                        } else {
                            state.remainingSize -= calculatingQuoteAmountV2(
                                liquidity,
                                step.pipNext,
                                state.baseBasisPoint,
                                state.basisPoint
                            );
                            openOtherSide += liquidity;
                        }
                        state.pip = _isBuy
                            ? step.pipNext + 1
                            : step.pipNext - 1;
                    } else {
                        // remaining size = liquidity
                        // only 1 pip should be toggled, so we call it directly here
                        liquidityBitmap.toggleSingleBit(step.pipNext, false);
                        if (_isBase) {
                            openOtherSide += calculatingQuoteAmountV2(
                                state.remainingSize,
                                step.pipNext,
                                state.baseBasisPoint,
                                state.basisPoint
                            );
                        } else {
                            openOtherSide += liquidity;
                        }
                        state.remainingSize = 0;
                        state.pip = step.pipNext;
                        state.isFullBuy = 0;
                    }
                } else {
                    state.isSkipFirstPip = false;
                    state.pip = _isBuy ? step.pipNext + 1 : step.pipNext - 1;
                }
            }
        }
        {
            if (
                _initialSingleSlot.pip != state.pip &&
                state.remainingSize != _size
            ) {
                // all ticks in shifted range must be marked as filled
                if (
                    !(state.remainingLiquidity > 0 &&
                        state.startPip == state.pip)
                ) {
                    if (_maxPip != 0) {
                        state.pip = state.lastMatchedPip;
                    }
                    liquidityBitmap.unsetBitsRange(
                        state.startPip,
                        state.remainingLiquidity > 0
                            ? (_isBuy ? state.pip - 1 : state.pip + 1)
                            : state.pip
                    );
                }
                // TODO write a checkpoint that we shift a range of ticks
            } else if (
                _maxPip != 0 &&
                _initialSingleSlot.pip == state.pip &&
                state.remainingSize < _size &&
                state.remainingSize != 0
            ) {
                // if limit order with max pip filled current pip, toggle current pip to initialized
                // after that when create new limit order will initialize pip again in `OpenLimitPosition`
                liquidityBitmap.toggleSingleBit(state.pip, false);
            }

            if (state.remainingSize != _size) {
                // if limit order with max pip filled other order, update isFullBuy
                singleSlot.isFullBuy = state.isFullBuy;
            }
            if (_maxPip != 0) {
                // if limit order still have remainingSize, change current price to limit price
                // else change current price to last matched pip
                singleSlot.pip = state.remainingSize != 0
                    ? _maxPip
                    : state.lastMatchedPip;
            } else {
                singleSlot.pip = state.pip;
            }
        }

        sizeOut = _size - state.remainingSize;
        //        _addReserveSnapshot();

        if (sizeOut != 0) {
            if (_isBase) {
                emit MarketFilled(
                    _isBuy,
                    sizeOut,
                    singleSlot.pip,
                    state.startPip,
                    state.remainingLiquidity,
                    tickPosition[singleSlot.pip].calculatingFilledIndex()
                );
            } else {
                emit MarketFilled(
                    _isBuy,
                    openOtherSide,
                    singleSlot.pip,
                    state.startPip,
                    state.remainingLiquidity,
                    tickPosition[singleSlot.pip].calculatingFilledIndex()
                );
            }

            emitEventSwap(_isBuy, sizeOut, openOtherSide, _trader);
        }
    }

    struct ParamsInternalOpenLimit {
        uint128 pip;
        uint128 size;
        bool isBuy;
        address trader;
        uint256 quoteDeposited;
    }

    function _internalOpenLimit(ParamsInternalOpenLimit memory _params)
        internal
        returns (
            uint64 orderId,
            uint256 sizeOut,
            uint256 quoteAmount
        )
    {
        require(_params.size != 0, Errors.VL_INVALID_SIZE);
        SingleSlot memory _singleSlot = singleSlot;

        {
            if (_params.isBuy) {
                int128 maxPip = int128(_singleSlot.pip) -
                    int128(maxWordRangeForLimitOrder * 250);
                if (maxPip > 0) {
                    require(
                        int128(_params.pip) >= maxPip,
                        Errors.VL_MUST_CLOSE_TO_INDEX_PRICE_LONG
                    );
                } else {
                    require(
                        _params.pip >= 1,
                        Errors.VL_MUST_CLOSE_TO_INDEX_PRICE_LONG
                    );
                }
            } else {
                require(
                    _params.pip >= 1,
                    Errors.VL_MUST_CLOSE_TO_INDEX_PRICE_LONG
                );
                require(
                    _params.pip <=
                        (_singleSlot.pip + maxWordRangeForLimitOrder * 250),
                    Errors.VL_MUST_CLOSE_TO_INDEX_PRICE_SHORT
                );
            }
            bool hasLiquidity = liquidityBitmap.hasLiquidity(_params.pip);
            //save gas
            {
                bool canOpenMarketWithMaxPip = (_params.isBuy &&
                    _params.pip >= _singleSlot.pip) ||
                    (!_params.isBuy && _params.pip <= _singleSlot.pip);
                if (canOpenMarketWithMaxPip) {
                    // TODO use the following code to calculate slippage
                    //                if(isBuy){
                    //                    // higher pip when long must lower than max word range for market order short
                    //                    require(_pip <= _singleSlot.pip + maxWordRangeForMarketOrder * 250, Errors.VL_MARKET_ORDER_MUST_CLOSE_TO_INDEX_PRICE);
                    //                }else{
                    //                    // lower pip when short must higher than max word range for market order long
                    //                    require(int128(_pip) >= (int256(_singleSlot.pip) - int128(maxWordRangeForMarketOrder * 250)), Errors.VL_MARKET_ORDER_MUST_CLOSE_TO_INDEX_PRICE);
                    //                }
                    // open market
                    (sizeOut, quoteAmount) = _openMarketWithMaxPip(
                        _params.size,
                        _params.isBuy,
                        _params.pip,
                        _params.trader
                    );
                    hasLiquidity = liquidityBitmap.hasLiquidity(_params.pip);
                    _singleSlot = singleSlot;
                }
            }

            {
                if (
                    (_params.size > sizeOut) ||
                    (_params.size == sizeOut &&
                        _params.quoteDeposited > quoteAmount &&
                        _params.quoteDeposited > 0)
                ) {
                    uint128 remainingSize;

                    if (
                        _params.quoteDeposited > 0 &&
                        _params.isBuy &&
                        _params.quoteDeposited > quoteAmount
                    ) {
                        remainingSize = uint128(
                            quoteToBase(
                                _params.quoteDeposited - quoteAmount,
                                _params.pip
                            )
                        );
                    } else {
                        remainingSize = _params.size - uint128(sizeOut);
                    }

                    if (
                        _params.pip == _singleSlot.pip &&
                        _singleSlot.isFullBuy != (_params.isBuy ? 1 : 2)
                    ) {
                        singleSlot.isFullBuy = _params.isBuy ? 1 : 2;
                    }

                    orderId = tickPosition[_params.pip].insertLimitOrder(
                        remainingSize,
                        hasLiquidity,
                        _params.isBuy
                    );
                    if (!hasLiquidity) {
                        //set the bit to mark it has liquidity
                        liquidityBitmap.toggleSingleBit(_params.pip, true);
                    }
                    emit LimitOrderCreated(
                        orderId,
                        _params.pip,
                        remainingSize,
                        _params.isBuy
                    );
                }
            }
        }
    }

    // TODO for test only needs remove on production
    // BECARE FULL DEPLOY MEEEEEE
    ///////////////////////////////////////////
    // should move me to a mock contract for test only
    //    function clearCurrentPip() external onlyOwner {
    //        liquidityBitmap.toggleSingleBit(singleSlot.pip, false);
    //        singleSlot.isFullBuy = 0;
    //        tickPosition[singleSlot.pip].liquidity = 0;
    //    }

    //    function _addReserveSnapshot() internal {
    //        uint64 currentBlock = _blockNumber();
    //        ReserveSnapshot memory latestSnapshot = reserveSnapshots[
    //            reserveSnapshots.length - 1
    //        ];
    //        if (currentBlock == latestSnapshot.blockNumber) {
    //            reserveSnapshots[reserveSnapshots.length - 1].pip = singleSlot.pip;
    //        } else {
    //            reserveSnapshots.push(
    //                ReserveSnapshot(singleSlot.pip, _blockTimestamp(), currentBlock)
    //            );
    //        }
    //        emit ReserveSnapshotted(singleSlot.pip, _blockTimestamp());
    //    }
}