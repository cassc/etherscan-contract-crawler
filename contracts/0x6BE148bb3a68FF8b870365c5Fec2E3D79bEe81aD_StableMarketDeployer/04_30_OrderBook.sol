// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@clober/library/contracts/OctopusHeap.sol";
import "@clober/library/contracts/SegmentedSegmentTree.sol";

import "./interfaces/CloberMarketFactory.sol";
import "./interfaces/CloberMarketSwapCallbackReceiver.sol";
import "./interfaces/CloberMarketFlashCallbackReceiver.sol";
import "./interfaces/CloberOrderBook.sol";
import "./interfaces/CloberOrderNFT.sol";
import "./Errors.sol";
import "./utils/Math.sol";
import "./utils/OrderKeyUtils.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/RevertOnDelegateCall.sol";

abstract contract OrderBook is CloberOrderBook, ReentrancyGuard, RevertOnDelegateCall {
    using SafeERC20 for IERC20;
    using OctopusHeap for OctopusHeap.Core;
    using SegmentedSegmentTree for SegmentedSegmentTree.Core;
    using PackedUint256 for uint256;
    using DirtyUint64 for uint64;
    using SignificantBit for uint256;
    using OrderKeyUtils for OrderKey;

    uint256 private constant _CLAIM_BOUNTY_UNIT = 1 gwei;
    uint256 private constant _PRICE_PRECISION = 10**18;
    uint256 private constant _FEE_PRECISION = 1000000; // 1 = 0.0001%
    uint256 private constant _MAX_ORDER = 2**15; // 32768
    uint256 private constant _MAX_ORDER_M = 2**15 - 1; // % 32768
    uint24 private constant _PROTOCOL_FEE = 200000; // 20%
    bool private constant _BID = true;
    bool private constant _ASK = false;

    struct Queue {
        SegmentedSegmentTree.Core tree;
        uint256 index; // index of where the next order would go
    }

    IERC20 private immutable _quoteToken;
    IERC20 private immutable _baseToken;
    uint256 private immutable _quotePrecisionComplement; // 10**(18 - d)
    uint256 private immutable _basePrecisionComplement; // 10**(18 - d)
    uint256 public immutable override quoteUnit;
    CloberMarketFactory private immutable _factory;
    int24 public immutable override makerFee;
    uint24 public immutable override takerFee;
    address public immutable override orderToken;

    OctopusHeap.Core private _askHeap;
    OctopusHeap.Core private _bidHeap;

    mapping(uint16 => Queue) internal _askQueues; // priceIndex => Queue
    mapping(uint16 => Queue) internal _bidQueues; // priceIndex => Queue

    mapping(uint16 => uint256) internal _askClaimable;
    mapping(uint16 => uint256) internal _bidClaimable;

    uint128 private _quoteFeeBalance; // dirty slot
    uint128 private _baseFeeBalance;
    mapping(address => uint256) public override uncollectedHostFees;
    mapping(address => uint256) public override uncollectedProtocolFees;
    mapping(uint256 => Order) private _orders;

    constructor(
        address orderToken_,
        address quoteToken_,
        address baseToken_,
        uint96 quoteUnit_,
        int24 makerFee_,
        uint24 takerFee_,
        address factory_
    ) {
        orderToken = orderToken_;
        quoteUnit = quoteUnit_;

        _factory = CloberMarketFactory(factory_);

        _quoteToken = IERC20(quoteToken_);
        _baseToken = IERC20(baseToken_);
        _quotePrecisionComplement = _getDecimalComplement(quoteToken_);
        _basePrecisionComplement = _getDecimalComplement(baseToken_);

        makerFee = makerFee_;
        takerFee = takerFee_;

        _askHeap.init();
        _bidHeap.init();

        // make slot dirty
        _quoteFeeBalance = 1;
    }

    function _getDecimalComplement(address token) internal view returns (uint256) {
        return 10**(18 - IERC20Metadata(token).decimals());
    }

    function limitOrder(
        address user,
        uint16 priceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options,
        bytes calldata data
    ) external payable nonReentrant revertOnDelegateCall returns (uint256 orderIndex) {
        options = options & 0x03; // clear unused bits
        if (msg.value / _CLAIM_BOUNTY_UNIT > type(uint32).max) {
            revert Errors.CloberError(Errors.OVERFLOW_UNDERFLOW);
        }
        bool isBid = (options & 1) == 1;

        uint256 inputAmount;
        uint256 outputAmount;
        uint256 bountyRefundAmount = msg.value % _CLAIM_BOUNTY_UNIT;
        {
            uint256 requestedAmount = isBid ? rawToQuote(rawAmount) : baseAmount;
            // decode option to check if postOnly
            if (options & 2 == 2) {
                OctopusHeap.Core storage heap = _getHeap(!isBid);
                if (!heap.isEmpty() && (isBid ? priceIndex : ~priceIndex) >= heap.root()) {
                    revert Errors.CloberError(Errors.POST_ONLY);
                }
            } else {
                (inputAmount, outputAmount) = _take(user, requestedAmount, priceIndex, !isBid, true, options);
                requestedAmount -= inputAmount;
            }

            uint64 remainingRequestedRawAmount = isBid
                ? quoteToRaw(requestedAmount, false)
                : baseToRaw(requestedAmount, priceIndex, false);
            if (remainingRequestedRawAmount > 0) {
                // requestedAmount was repurposed as requiredAmount to avoid "Stack too deep".
                (requestedAmount, orderIndex) = _makeOrder(
                    user,
                    priceIndex,
                    remainingRequestedRawAmount,
                    uint32(msg.value / _CLAIM_BOUNTY_UNIT),
                    isBid,
                    options
                );
                inputAmount += requestedAmount;
                _mintToken(user, isBid, priceIndex, orderIndex);
            } else {
                orderIndex = type(uint256).max;
                // refund claimBounty if an order was not made.
                bountyRefundAmount = msg.value;
            }
        }

        (IERC20 inputToken, IERC20 outputToken) = isBid ? (_quoteToken, _baseToken) : (_baseToken, _quoteToken);

        _transferToken(outputToken, user, outputAmount);

        _callback(inputToken, outputToken, inputAmount, outputAmount, bountyRefundAmount, data);
    }

    function getExpectedAmount(
        uint16 limitPriceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options
    ) external view returns (uint256 inputAmount, uint256 outputAmount) {
        inputAmount = 0;
        bool isTakingBidSide = (options & 1) == 0;
        bool expendInput = (options & 2) == 2;
        uint256 requestedAmount = isTakingBidSide == expendInput ? baseAmount : rawToQuote(rawAmount);

        OctopusHeap.Core storage core = _getHeap(isTakingBidSide);
        if (isTakingBidSide) {
            // @dev limitPriceIndex is changed to its value in storage, be careful when using this value
            limitPriceIndex = ~limitPriceIndex;
        }

        if (!expendInput) {
            // Increase requestedAmount by fee when expendInput is false
            requestedAmount = _calculateTakeAmountBeforeFees(requestedAmount);
        }

        if (requestedAmount == 0) return (0, 0);

        (uint256 word, uint256[] memory heap) = core.getRootWordAndHeap();
        if (word == 0) return (0, 0);
        uint16 currentIndex = uint16(heap[0] & 0xff00) | word.leastSignificantBit();
        while (word > 0) {
            if (limitPriceIndex < currentIndex) break;
            if (isTakingBidSide) currentIndex = ~currentIndex;

            (uint256 _inputAmount, uint256 _outputAmount, ) = _expectTake(
                isTakingBidSide,
                requestedAmount,
                currentIndex,
                expendInput
            );
            inputAmount += _inputAmount;
            outputAmount += _outputAmount;

            uint256 filledAmount = expendInput ? _inputAmount : _outputAmount;
            if (requestedAmount > filledAmount && filledAmount > 0) {
                unchecked {
                    requestedAmount -= filledAmount;
                }
            } else {
                break;
            }

            do {
                (word, heap) = core.popInMemory(word, heap);
                if (word == 0) break;
                currentIndex = uint16(heap[0] & 0xff00) | word.leastSignificantBit();
            } while (getDepth(isTakingBidSide, isTakingBidSide ? ~currentIndex : currentIndex) == 0);
        }
        outputAmount -= _calculateTakerFeeAmount(outputAmount, true);
    }

    function marketOrder(
        address user,
        uint16 limitPriceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options,
        bytes calldata data
    ) external nonReentrant revertOnDelegateCall {
        options = (options | 0x80) & 0x83; // Set the most significant bit to 1 for market orders and clear unused bits
        bool isBid = (options & 1) == 1;

        uint256 inputAmount;
        uint256 outputAmount;
        uint256 quoteAmount = rawToQuote(rawAmount);
        {
            bool expendInput = (options & 2) == 2;
            (inputAmount, outputAmount) = _take(
                user,
                // Bid & expendInput => quote
                // Bid & !expendInput => base
                // Ask & expendInput => base
                // Ask & !expendInput => quote
                isBid == expendInput ? quoteAmount : baseAmount,
                limitPriceIndex,
                !isBid,
                expendInput,
                options
            );
        }
        IERC20 inputToken;
        IERC20 outputToken;
        {
            uint256 inputThreshold;
            uint256 outputThreshold;
            (inputToken, outputToken, inputThreshold, outputThreshold) = isBid
                ? (_quoteToken, _baseToken, quoteAmount, baseAmount)
                : (_baseToken, _quoteToken, baseAmount, quoteAmount);
            if (inputAmount > inputThreshold || outputAmount < outputThreshold) {
                revert Errors.CloberError(Errors.SLIPPAGE);
            }
        }
        _transferToken(outputToken, user, outputAmount);

        _callback(inputToken, outputToken, inputAmount, outputAmount, 0, data);
    }

    function cancel(address receiver, OrderKey[] calldata orderKeys) external nonReentrant revertOnDelegateCall {
        if (orderKeys.length == 0) {
            revert Errors.CloberError(Errors.EMPTY_INPUT);
        }
        uint256 quoteToTransfer;
        uint256 baseToTransfer;
        uint256 totalCanceledBounty;
        for (uint256 i = 0; i < orderKeys.length; ++i) {
            OrderKey calldata orderKey = orderKeys[i];
            (
                uint64 remainingAmount,
                uint256 minusFee,
                uint256 claimedTokenAmount,
                uint32 refundedClaimBounty
            ) = _cancel(receiver, orderKey);

            // overflow when length == 2**224 > 2 * size(priceIndex) * _MAX_ORDER, absolutely never happening
            unchecked {
                totalCanceledBounty += refundedClaimBounty;
            }

            if (orderKey.isBid) {
                quoteToTransfer += (remainingAmount > 0 ? rawToQuote(remainingAmount) : 0) + minusFee;
                baseToTransfer += claimedTokenAmount;
            } else {
                baseToTransfer +=
                    (remainingAmount > 0 ? rawToBase(remainingAmount, orderKey.priceIndex, false) : 0) +
                    minusFee;
                quoteToTransfer += claimedTokenAmount;
            }
        }
        _transferToken(_quoteToken, receiver, quoteToTransfer);
        _transferToken(_baseToken, receiver, baseToTransfer);
        _sendGWeiValue(receiver, totalCanceledBounty);

        // remove priceIndices that have no open orders
        _cleanHeap(_BID);
        _cleanHeap(_ASK);
    }

    function _cancel(address receiver, OrderKey calldata orderKey)
        internal
        returns (
            uint64 remainingAmount,
            uint256 minusFee,
            uint256 claimedTokenAmount,
            uint32 refundedClaimBounty
        )
    {
        Queue storage queue = _getQueue(orderKey.isBid, orderKey.priceIndex);
        _checkOrderIndexValidity(orderKey.orderIndex, queue.index);
        uint256 orderId = orderKey.encode();
        Order memory mOrder = _orders[orderId];

        if (mOrder.amount == 0) return (0, 0, 0, 0);
        if (msg.sender != mOrder.owner && msg.sender != orderToken) {
            revert Errors.CloberError(Errors.ACCESS);
        }

        // repurpose `remainingAmount` to temporarily store `claimedRawAmount`
        (claimedTokenAmount, minusFee, remainingAmount) = _claim(queue, mOrder, orderKey, receiver);

        _orders[orderId].amount = 0;
        remainingAmount = mOrder.amount - remainingAmount;

        if (remainingAmount > 0) {
            queue.tree.update(
                orderKey.orderIndex & _MAX_ORDER_M,
                queue.tree.get(orderKey.orderIndex & _MAX_ORDER_M) - remainingAmount
            );
            emit CancelOrder(mOrder.owner, remainingAmount, orderKey.orderIndex, orderKey.priceIndex, orderKey.isBid);
            _burnToken(orderId);
        }

        refundedClaimBounty = mOrder.claimBounty;
    }

    function claim(address claimer, OrderKey[] calldata orderKeys) external nonReentrant revertOnDelegateCall {
        uint256 totalBounty;
        for (uint256 i = 0; i < orderKeys.length; ++i) {
            OrderKey calldata orderKey = orderKeys[i];
            Queue storage queue = _getQueue(orderKey.isBid, orderKey.priceIndex);
            if (_isInvalidOrderIndex(orderKey.orderIndex, queue.index)) {
                continue;
            }

            uint256 orderId = orderKey.encode();
            Order memory mOrder = _orders[orderId];
            if (mOrder.amount == 0) {
                continue;
            }

            (uint256 claimedTokenAmount, uint256 minusFee, uint64 claimedRawAmount) = _claim(
                queue,
                mOrder,
                orderKey,
                claimer
            );
            if (claimedRawAmount == 0) {
                continue;
            }

            _orders[orderId].amount = mOrder.amount - claimedRawAmount;

            if (mOrder.amount == claimedRawAmount) {
                // overflow when length == 2**224 > 2 * size(priceIndex) * _MAX_ORDER, absolutely never happening
                unchecked {
                    totalBounty += mOrder.claimBounty;
                }
            }
            (uint256 totalQuoteAmount, uint256 totalBaseAmount) = orderKey.isBid
                ? (minusFee, claimedTokenAmount)
                : (claimedTokenAmount, minusFee);

            _transferToken(_quoteToken, mOrder.owner, totalQuoteAmount);
            _transferToken(_baseToken, mOrder.owner, totalBaseAmount);
        }
        _sendGWeiValue(claimer, totalBounty);
    }

    function flash(
        address borrower,
        uint256 quoteAmount,
        uint256 baseAmount,
        bytes calldata data
    ) external nonReentrant {
        uint256 beforeQuoteAmount = _thisBalance(_quoteToken);
        uint256 beforeBaseAmount = _thisBalance(_baseToken);
        uint256 feePrecision = _FEE_PRECISION;
        uint256 quoteFeeAmount = Math.divide(quoteAmount * takerFee, feePrecision, true);
        uint256 baseFeeAmount = Math.divide(baseAmount * takerFee, feePrecision, true);
        _transferToken(_quoteToken, borrower, quoteAmount);
        _transferToken(_baseToken, borrower, baseAmount);

        CloberMarketFlashCallbackReceiver(msg.sender).cloberMarketFlashCallback(
            address(_quoteToken),
            address(_baseToken),
            quoteAmount,
            baseAmount,
            quoteFeeAmount,
            baseFeeAmount,
            data
        );

        uint256 afterQuoteAmount = _thisBalance(_quoteToken);
        uint256 afterBaseAmount = _thisBalance(_baseToken);
        if (
            afterQuoteAmount < beforeQuoteAmount + quoteFeeAmount || afterBaseAmount < beforeBaseAmount + baseFeeAmount
        ) {
            revert Errors.CloberError(Errors.INSUFFICIENT_BALANCE);
        }

        uint256 earnedQuoteAmount;
        uint256 earnedBaseAmount;
        unchecked {
            earnedQuoteAmount = afterQuoteAmount - beforeQuoteAmount;
            earnedBaseAmount = afterBaseAmount - beforeBaseAmount;
        }
        _addToFeeBalance(false, earnedQuoteAmount);
        _addToFeeBalance(true, earnedBaseAmount);

        emit Flash(msg.sender, borrower, quoteAmount, baseAmount, earnedQuoteAmount, earnedBaseAmount);
    }

    function quoteToken() external view returns (address) {
        return address(_quoteToken);
    }

    function baseToken() external view returns (address) {
        return address(_baseToken);
    }

    function getDepth(bool isBid, uint16 priceIndex) public view returns (uint64) {
        (uint16 groupIndex, uint8 elementIndex) = _splitClaimableIndex(priceIndex);
        return
            _getQueue(isBid, priceIndex).tree.total() -
            _getClaimable(isBid)[groupIndex].get64Unsafe(elementIndex).toClean();
    }

    function getFeeBalance() external view returns (uint128, uint128) {
        unchecked {
            return (_quoteFeeBalance - 1, _baseFeeBalance);
        }
    }

    function isEmpty(bool isBid) external view returns (bool) {
        return _getHeap(isBid).isEmpty();
    }

    function getOrder(OrderKey calldata orderKey) external view returns (Order memory) {
        return _getOrder(orderKey);
    }

    function bestPriceIndex(bool isBid) external view returns (uint16 priceIndex) {
        priceIndex = (isBid ? _bidHeap : _askHeap).root();
        if (isBid) {
            priceIndex = ~priceIndex;
        }
    }

    function indexToPrice(uint16 priceIndex) public view virtual returns (uint128);

    function _cleanHeap(bool isBid) private {
        OctopusHeap.Core storage heap = _getHeap(isBid);
        while (!heap.isEmpty()) {
            if (getDepth(isBid, isBid ? ~heap.root() : heap.root()) == 0) {
                heap.pop();
            } else {
                break;
            }
        }
    }

    function _checkOrderIndexValidity(uint256 orderIndex, uint256 currentIndex) internal pure {
        if (_isInvalidOrderIndex(orderIndex, currentIndex)) {
            revert Errors.CloberError(Errors.INVALID_ID);
        }
    }

    function _isInvalidOrderIndex(uint256 orderIndex, uint256 currentIndex) internal pure returns (bool) {
        // valid active order indices are smaller than the currentIndex
        return currentIndex <= orderIndex;
    }

    function _getOrder(OrderKey memory orderKey) internal view returns (Order storage) {
        _checkOrderIndexValidity(orderKey.orderIndex, _getQueue(orderKey.isBid, orderKey.priceIndex).index);

        return _orders[orderKey.encode()];
    }

    function _getHeap(bool isBid) internal view returns (OctopusHeap.Core storage) {
        return isBid ? _bidHeap : _askHeap;
    }

    function _getQueue(bool isBid, uint16 priceIndex) internal view returns (Queue storage) {
        return (isBid ? _bidQueues : _askQueues)[priceIndex];
    }

    function _getClaimable(bool isBid) internal view returns (mapping(uint16 => uint256) storage) {
        return isBid ? _bidClaimable : _askClaimable;
    }

    function _splitClaimableIndex(uint16 priceIndex) internal pure returns (uint16 groupIndex, uint8 elementIndex) {
        uint256 casted = priceIndex;
        assembly {
            elementIndex := and(priceIndex, 3) // mod 4
            groupIndex := shr(2, casted) // div 4
        }
    }

    function _getClaimRangeRight(Queue storage queue, uint256 orderIndex) internal view returns (uint64 rangeRight) {
        uint256 l = queue.index & _MAX_ORDER_M;
        uint256 r = (orderIndex + 1) & _MAX_ORDER_M;
        rangeRight = (l < r) ? queue.tree.query(l, r) : queue.tree.total() - queue.tree.query(r, l);
    }

    function _calculateClaimableAmountAndFees(
        bool isBidOrder,
        uint64 claimedRawAmount,
        uint16 priceIndex
    )
        internal
        view
        returns (
            uint256 claimableAmount,
            int256 makerFeeAmount,
            uint256 takerFeeAmount
        )
    {
        uint256 baseAmount = rawToBase(claimedRawAmount, priceIndex, false);
        uint256 quoteAmount = rawToQuote(claimedRawAmount);

        uint256 takeAmount;
        (takeAmount, claimableAmount) = isBidOrder ? (quoteAmount, baseAmount) : (baseAmount, quoteAmount);
        // rounding down to prevent insufficient balance
        takerFeeAmount = _calculateTakerFeeAmount(takeAmount, false);

        uint256 feePrecision = _FEE_PRECISION;
        if (makerFee > 0) {
            // rounding up maker fee when makerFee > 0
            uint256 feeAmountAbs = Math.divide(claimableAmount * uint24(makerFee), feePrecision, true);
            // feeAmountAbs < type(uint256).max * _MAX_FEE / feePrecision < type(int256).max
            makerFeeAmount = int256(feeAmountAbs);
            unchecked {
                // makerFee < _MAX_FEE < feePrecision => feeAmountAbs < claimableAmount
                claimableAmount -= feeAmountAbs;
            }
        } else {
            // rounding down maker fee when makerFee < 0
            makerFeeAmount = -int256((takeAmount * uint24(-makerFee)) / feePrecision);
        }
    }

    function _calculateTakeAmountBeforeFees(uint256 amountAfterFees) internal view returns (uint256 amountBeforeFees) {
        uint256 feePrecision = _FEE_PRECISION;
        uint256 divisor;
        unchecked {
            divisor = feePrecision - takerFee;
        }
        amountBeforeFees = Math.divide(amountAfterFees * feePrecision, divisor, true);
    }

    function _calculateTakerFeeAmount(uint256 takeAmount, bool roundingUp) internal view returns (uint256) {
        // takerFee is always positive
        return Math.divide(takeAmount * takerFee, _FEE_PRECISION, roundingUp);
    }

    function rawToBase(
        uint64 rawAmount,
        uint16 priceIndex,
        bool roundingUp
    ) public view returns (uint256) {
        return
            Math.divide(
                (rawToQuote(rawAmount) * _PRICE_PRECISION) * _quotePrecisionComplement,
                _basePrecisionComplement * indexToPrice(priceIndex),
                roundingUp
            );
    }

    function rawToQuote(uint64 rawAmount) public view returns (uint256) {
        return quoteUnit * rawAmount;
    }

    function baseToRaw(
        uint256 baseAmount,
        uint16 priceIndex,
        bool roundingUp
    ) public view returns (uint64) {
        uint256 rawAmount = Math.divide(
            (baseAmount * indexToPrice(priceIndex)) * _basePrecisionComplement,
            _PRICE_PRECISION * _quotePrecisionComplement * quoteUnit,
            roundingUp
        );
        if (rawAmount > type(uint64).max) {
            revert Errors.CloberError(Errors.OVERFLOW_UNDERFLOW);
        }
        return uint64(rawAmount);
    }

    function quoteToRaw(uint256 quoteAmount, bool roundingUp) public view returns (uint64) {
        uint256 rawAmount = Math.divide(quoteAmount, quoteUnit, roundingUp);
        if (rawAmount > type(uint64).max) {
            revert Errors.CloberError(Errors.OVERFLOW_UNDERFLOW);
        }
        return uint64(rawAmount);
    }

    function _expectTake(
        bool isTakingBidSide,
        uint256 remainingAmount,
        uint16 currentIndex,
        bool expendInput
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint64
        )
    {
        uint64 takenRawAmount;
        {
            uint64 depth = getDepth(isTakingBidSide, currentIndex);
            // Rounds down if expendInput, rounds up if !expendInput
            // Bid & expendInput => taking ask & expendInput => rounds down (user specified quote)
            // Bid & !expendInput => taking ask & !expendInput => rounds up (user specified base)
            // Ask & expendInput => taking bid & expendInput => rounds down (user specified base)
            // Ask & !expendInput => taking bid & !expendInput => rounds up (user specified quote)
            uint64 remainingRawAmount;
            remainingRawAmount = isTakingBidSide == expendInput
                ? baseToRaw(remainingAmount, currentIndex, !expendInput)
                : quoteToRaw(remainingAmount, !expendInput);
            takenRawAmount = depth > remainingRawAmount ? remainingRawAmount : depth;
            if (takenRawAmount == 0) {
                return (0, 0, 0);
            }
        }

        (uint256 inputAmount, uint256 outputAmount) = isTakingBidSide
            ? (rawToBase(takenRawAmount, currentIndex, isTakingBidSide), rawToQuote(takenRawAmount))
            : (rawToQuote(takenRawAmount), rawToBase(takenRawAmount, currentIndex, isTakingBidSide));

        return (inputAmount, outputAmount, takenRawAmount);
    }

    function _take(
        address user,
        uint256 requestedAmount,
        uint16 limitPriceIndex,
        bool isTakingBidSide,
        bool expendInput,
        uint8 options
    ) internal returns (uint256 inputAmount, uint256 outputAmount) {
        inputAmount = 0;
        outputAmount = 0;
        if (requestedAmount == 0) {
            revert Errors.CloberError(Errors.EMPTY_INPUT);
        }
        OctopusHeap.Core storage heap = _getHeap(isTakingBidSide);
        if (isTakingBidSide) {
            // @dev limitPriceIndex is changed to its value in storage, be careful when using this value
            limitPriceIndex = ~limitPriceIndex;
        }

        if (!expendInput) {
            // Increase requestedAmount by fee when expendInput is false
            requestedAmount = _calculateTakeAmountBeforeFees(requestedAmount);
        }

        mapping(uint16 => uint256) storage claimable = _getClaimable(isTakingBidSide);
        while (requestedAmount > 0 && !heap.isEmpty()) {
            uint16 currentIndex = heap.root();
            if (limitPriceIndex < currentIndex) break;
            if (isTakingBidSide) currentIndex = ~currentIndex;

            uint64 takenRawAmount;
            {
                uint256 _inputAmount;
                uint256 _outputAmount;
                (_inputAmount, _outputAmount, takenRawAmount) = _expectTake(
                    isTakingBidSide,
                    requestedAmount,
                    currentIndex,
                    expendInput
                );
                if (takenRawAmount == 0) break;
                inputAmount += _inputAmount;
                outputAmount += _outputAmount;

                uint256 filledAmount = expendInput ? _inputAmount : _outputAmount;
                if (requestedAmount > filledAmount) {
                    unchecked {
                        requestedAmount -= filledAmount;
                    }
                } else {
                    requestedAmount = 0;
                }
            }
            {
                (uint16 groupIndex, uint8 elementIndex) = _splitClaimableIndex(currentIndex);
                uint256 claimableGroup = claimable[groupIndex];
                claimable[groupIndex] = claimableGroup.update64Unsafe(
                    elementIndex, // elementIndex < 4
                    claimableGroup.get64Unsafe(elementIndex).addClean(takenRawAmount)
                );
            }
            if (getDepth(isTakingBidSide, currentIndex) == 0) _cleanHeap(isTakingBidSide);

            emit TakeOrder(msg.sender, user, currentIndex, takenRawAmount, options);
        }
        outputAmount -= _calculateTakerFeeAmount(outputAmount, true);
    }

    function _makeOrder(
        address user,
        uint16 priceIndex,
        uint64 rawAmount,
        uint32 claimBounty,
        bool isBid,
        uint8 options
    ) internal returns (uint256 requiredAmount, uint256 orderIndex) {
        if (isBid) {
            _addIndexToHeap(_bidHeap, ~priceIndex);
        } else {
            _addIndexToHeap(_askHeap, priceIndex);
        }

        Queue storage queue = _getQueue(isBid, priceIndex);
        orderIndex = queue.index;
        if (orderIndex >= _MAX_ORDER) {
            OrderKey memory staleOrderKey;
            unchecked {
                staleOrderKey = OrderKey(isBid, priceIndex, orderIndex - _MAX_ORDER);
            }
            uint64 staleOrderAmount = _orders[staleOrderKey.encode()].amount;
            if (staleOrderAmount > 0) {
                uint64 claimedRawAmount = _calculateClaimableRawAmount(queue, staleOrderAmount, staleOrderKey);
                if (claimedRawAmount != staleOrderAmount) {
                    revert Errors.CloberError(Errors.QUEUE_REPLACE_FAILED);
                }
            }
        }

        uint64 staleOrderedAmount = queue.tree.get(orderIndex & _MAX_ORDER_M);
        if (staleOrderedAmount > 0) {
            mapping(uint16 => uint256) storage claimable = _getClaimable(isBid);
            (uint16 groupIndex, uint8 elementIndex) = _splitClaimableIndex(priceIndex);
            claimable[groupIndex] = claimable[groupIndex].sub64Unsafe(elementIndex, staleOrderedAmount);
        }
        queue.index = orderIndex + 1;
        queue.tree.update(orderIndex & _MAX_ORDER_M, rawAmount);
        _orders[OrderKeyUtils.encode(isBid, priceIndex, orderIndex)] = Order({
            claimBounty: claimBounty,
            amount: rawAmount,
            owner: user
        });

        requiredAmount = isBid ? rawToQuote(rawAmount) : rawToBase(rawAmount, priceIndex, true);
        emit MakeOrder(msg.sender, user, rawAmount, claimBounty, orderIndex, priceIndex, options);
    }

    function _calculateClaimableRawAmount(
        Queue storage queue,
        uint64 orderAmount,
        OrderKey memory orderKey
    ) private view returns (uint64 claimableRawAmount) {
        if (orderKey.orderIndex + _MAX_ORDER < queue.index) {
            // replaced order
            return orderAmount;
        }
        (uint16 groupIndex, uint8 elementIndex) = _splitClaimableIndex(orderKey.priceIndex);
        uint64 totalClaimable = _getClaimable(orderKey.isBid)[groupIndex].get64Unsafe(elementIndex).toClean();
        uint64 rangeRight = _getClaimRangeRight(queue, orderKey.orderIndex);

        if (rangeRight >= totalClaimable + orderAmount) return 0;
        if (rangeRight <= totalClaimable) {
            claimableRawAmount = orderAmount;
        } else {
            claimableRawAmount = totalClaimable + orderAmount - rangeRight;
        }
    }

    // @dev Always check if `mOrder.amount == 0` before calling this function
    function _claim(
        Queue storage queue,
        Order memory mOrder,
        OrderKey memory orderKey,
        address claimer
    )
        private
        returns (
            uint256 transferAmount,
            uint256 minusFee,
            uint64 claimedRawAmount
        )
    {
        uint256 claimBounty;

        claimedRawAmount = _calculateClaimableRawAmount(queue, mOrder.amount, orderKey);
        if (claimedRawAmount == 0) return (0, 0, 0);
        if (claimedRawAmount == mOrder.amount) {
            // claiming fully
            claimBounty = _CLAIM_BOUNTY_UNIT * mOrder.claimBounty;
            _burnToken(orderKey.encode());
        }

        uint256 takerFeeAmount;
        int256 makerFeeAmount;
        (transferAmount, makerFeeAmount, takerFeeAmount) = _calculateClaimableAmountAndFees(
            orderKey.isBid,
            claimedRawAmount,
            orderKey.priceIndex
        );

        emit ClaimOrder(
            claimer,
            mOrder.owner,
            claimedRawAmount,
            claimBounty,
            orderKey.orderIndex,
            orderKey.priceIndex,
            orderKey.isBid
        );

        uint256 feeAmountAbs = uint256(makerFeeAmount > 0 ? makerFeeAmount : -makerFeeAmount);
        if (makerFeeAmount > 0) {
            _addToFeeBalance(!orderKey.isBid, takerFeeAmount);
            _addToFeeBalance(orderKey.isBid, feeAmountAbs);
            // minusFee will be zero when makerFee is positive
        } else {
            // If the order is bid, 'minusFee' should be quote
            _addToFeeBalance(!orderKey.isBid, takerFeeAmount - feeAmountAbs);
            minusFee = feeAmountAbs;
        }
    }

    function _addToFeeBalance(bool isBase, uint256 feeAmount) internal {
        // Protocol should collect fees before overflow
        if (isBase) {
            _baseFeeBalance += uint128(feeAmount);
        } else {
            _quoteFeeBalance += uint128(feeAmount);
        }
    }

    function _addIndexToHeap(OctopusHeap.Core storage heap, uint16 index) internal {
        if (!heap.has(index)) {
            heap.push(index);
        }
    }

    function _callback(
        IERC20 inputToken,
        IERC20 outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 bountyRefundAmount,
        bytes calldata data
    ) internal {
        uint256 beforeInputBalance = _thisBalance(inputToken);
        CloberMarketSwapCallbackReceiver(msg.sender).cloberMarketSwapCallback{value: bountyRefundAmount}(
            address(inputToken),
            address(outputToken),
            inputAmount,
            outputAmount,
            data
        );

        if (_thisBalance(inputToken) < beforeInputBalance + inputAmount) {
            revert Errors.CloberError(Errors.INSUFFICIENT_BALANCE);
        }
    }

    function _thisBalance(IERC20 token) internal view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function _transferToken(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            token.safeTransfer(to, amount);
        }
    }

    function _sendGWeiValue(address to, uint256 amountInGWei) internal {
        if (amountInGWei > 0) {
            (bool success, ) = to.call{value: amountInGWei * _CLAIM_BOUNTY_UNIT}("");
            if (!success) {
                revert Errors.CloberError(Errors.FAILED_TO_SEND_VALUE);
            }
        }
    }

    function collectFees(address token, address destination) external nonReentrant {
        address treasury = _factory.daoTreasury();
        address quote = address(_quoteToken);
        if ((token != quote && token != address(_baseToken)) || (destination != treasury && destination != _host())) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        uint256 amount;
        if (token == quote) {
            unchecked {
                amount = _quoteFeeBalance - 1;
            }
            _quoteFeeBalance = 1; // leave it as dirty
        } else {
            amount = _baseFeeBalance;
            _baseFeeBalance = 0;
        }
        // rounding up protocol fee
        uint256 protocolFeeAmount = Math.divide(amount * _PROTOCOL_FEE, _FEE_PRECISION, true);
        uint256 hostFeeAmount;
        unchecked {
            // `protocolFeeAmount` is always less than or equal to `amount`: _PROTOCOL_FEE < _FEE_PRECISION
            hostFeeAmount = amount - protocolFeeAmount;
        }
        (
            mapping(address => uint256) storage remainFees,
            mapping(address => uint256) storage transferFees,
            uint256 transferAmount,
            uint256 remainAmount
        ) = destination == treasury
                ? (uncollectedHostFees, uncollectedProtocolFees, protocolFeeAmount, hostFeeAmount)
                : (uncollectedProtocolFees, uncollectedHostFees, hostFeeAmount, protocolFeeAmount);
        transferAmount += transferFees[token];
        transferFees[token] = 0;
        remainFees[token] += remainAmount;

        _transferToken(IERC20(token), destination, transferAmount);
    }

    function _host() internal view returns (address) {
        return _factory.getMarketHost(address(this));
    }

    function _mintToken(
        address to,
        bool isBid,
        uint16 priceIndex,
        uint256 orderIndex
    ) internal {
        CloberOrderNFT(orderToken).onMint(to, OrderKeyUtils.encode(isBid, priceIndex, orderIndex));
    }

    function _burnToken(uint256 orderId) internal {
        CloberOrderNFT(orderToken).onBurn(orderId);
        _orders[orderId].owner = address(0);
    }

    function changeOrderOwner(OrderKey calldata orderKey, address newOwner) external nonReentrant revertOnDelegateCall {
        if (msg.sender != orderToken) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        // Even though the orderIndex of the orderKey is always valid,
        // it would be prudent to verify its validity to ensure compatibility with any future changes.
        _getOrder(orderKey).owner = newOwner;
    }
}