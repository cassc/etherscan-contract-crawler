// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../lib/PMMRangeOrder.sol";
import "../lib/Errors.sol";
import {IDODOSwapCallback} from "../intf/IDODOSwapCallback.sol";
import {ID3Maker} from "../intf/ID3Maker.sol";
import {ID3Vault} from "../intf/ID3Vault.sol";
import {D3Funding} from "./D3Funding.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract D3Trading is D3Funding {
    using SafeERC20 for IERC20;

    modifier onlyMaker() {
        require(msg.sender == state._MAKER_, "not maker");
        _;
    }

    // =============== Read ===============

    /// @notice for external users to read tokenMMInfo
    function getTokenMMPriceInfoForRead(
        address token
    )
        external
        view
        returns (uint256 askDownPrice, uint256 askUpPrice, uint256 bidDownPrice, uint256 bidUpPrice, uint256 swapFee)
    {
        (Types.TokenMMInfo memory tokenMMInfo, ) =
            ID3Maker(state._MAKER_).getTokenMMInfoForPool(token);

        askDownPrice = tokenMMInfo.askDownPrice;
        askUpPrice = tokenMMInfo.askUpPrice;
        bidDownPrice = tokenMMInfo.bidDownPrice;
        bidUpPrice = tokenMMInfo.bidUpPrice;
        swapFee = tokenMMInfo.swapFeeRate;
    }

    function getTokenMMOtherInfoForRead(
        address token
    )
        external
        view
        returns (
            uint256 askAmount,
            uint256 bidAmount,
            uint256 kAsk,
            uint256 kBid,
            uint256 cumulativeAsk,
            uint256 cumulativeBid
        )
    {
        (Types.TokenMMInfo memory tokenMMInfo, uint256 tokenIndex) =
            ID3Maker(state._MAKER_).getTokenMMInfoForPool(token);
        cumulativeAsk = allFlag >> (tokenIndex) & 1 == 0 ? 0 : tokenCumMap[token].cumulativeAsk;
        cumulativeBid = allFlag >> (tokenIndex) & 1 == 0 ? 0 : tokenCumMap[token].cumulativeBid;

        bidAmount = tokenMMInfo.bidAmount;
        askAmount = tokenMMInfo.askAmount;
        kAsk = tokenMMInfo.kAsk;
        kBid = tokenMMInfo.kBid;
    }

    // ============ Swap =============
    /// @notice get swap status for internal swap
    function getRangeOrderState(
        address fromToken,
        address toToken
    ) public view returns (Types.RangeOrderState memory roState) {
        roState.oracle = state._ORACLE_;
        uint256 fromTokenIndex;
        uint256 toTokenIndex;
        (roState.fromTokenMMInfo, fromTokenIndex) = ID3Maker(state._MAKER_).getTokenMMInfoForPool(fromToken);
        (roState.toTokenMMInfo, toTokenIndex) = ID3Maker(state._MAKER_).getTokenMMInfoForPool(toToken);

        // deal with update flag

        roState.fromTokenMMInfo.cumulativeAsk =
            allFlag >> (fromTokenIndex) & 1 == 0 ? 0 : tokenCumMap[fromToken].cumulativeAsk;
        roState.fromTokenMMInfo.cumulativeBid =
            allFlag >> (fromTokenIndex) & 1 == 0 ? 0 : tokenCumMap[fromToken].cumulativeBid;
        roState.toTokenMMInfo.cumulativeAsk =
            allFlag >> (toTokenIndex) & 1 == 0 ? 0 : tokenCumMap[toToken].cumulativeAsk;
        roState.toTokenMMInfo.cumulativeBid =
            allFlag >> (toTokenIndex) & 1 == 0 ? 0 : tokenCumMap[toToken].cumulativeBid;
    }

    /// @notice user sell a certain amount of fromToken,  get toToken
    function sellToken(
        address to,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minReceiveAmount,
        bytes calldata data
    ) external poolOngoing nonReentrant returns (uint256) {
        require(ID3Maker(state._MAKER_).checkHeartbeat(), Errors.HEARTBEAT_CHECK_FAIL);

        _updateCumulative(fromToken);
        _updateCumulative(toToken);

        (uint256 payFromAmount, uint256 receiveToAmount, uint256 vusdAmount, uint256 swapFee, uint256 mtFee) =
            querySellTokens(fromToken, toToken, fromAmount);
        require(receiveToAmount >= minReceiveAmount, Errors.MINRES_NOT_ENOUGH);

        _transferOut(to, toToken, receiveToAmount);

        // external call & swap callback
        IDODOSwapCallback(msg.sender).d3MMSwapCallBack(fromToken, fromAmount, data);
        // transfer mtFee to maintainer
        _transferOut(state._MAINTAINER_, toToken, mtFee);

        require(
            IERC20(fromToken).balanceOf(address(this)) - state.balances[fromToken] >= fromAmount,
            Errors.FROMAMOUNT_NOT_ENOUGH
        );

        // record swap
        uint256 toTokenDec = IERC20Metadata(toToken).decimals();
        _recordSwap(fromToken, toToken, vusdAmount, Types.parseRealAmount(receiveToAmount + swapFee, toTokenDec));
        require(checkSafe(), Errors.BELOW_IM_RATIO);

        emit Swap(to, fromToken, toToken, payFromAmount, receiveToAmount, swapFee, mtFee, 0);
        return receiveToAmount;
    }

    /// @notice user ask for a certain amount of toToken, fromToken's amount will be determined by toToken's amount
    function buyToken(
        address to,
        address fromToken,
        address toToken,
        uint256 quoteAmount,
        uint256 maxPayAmount,
        bytes calldata data
    ) external poolOngoing nonReentrant returns (uint256) {
        require(ID3Maker(state._MAKER_).checkHeartbeat(), Errors.HEARTBEAT_CHECK_FAIL);

        _updateCumulative(fromToken);
        _updateCumulative(toToken);

        // query amount and transfer out
        (uint256 payFromAmount, uint256 receiveToAmount, uint256 vusdAmount, uint256 swapFee, uint256 mtFee) =
            queryBuyTokens(fromToken, toToken, quoteAmount);
        require(payFromAmount <= maxPayAmount, Errors.MAXPAY_NOT_ENOUGH);

        _transferOut(to, toToken, receiveToAmount);

        // external call & swap callback
        IDODOSwapCallback(msg.sender).d3MMSwapCallBack(fromToken, payFromAmount, data);
        // transfer mtFee to maintainer
        _transferOut(state._MAINTAINER_, toToken, mtFee);

        require(
            IERC20(fromToken).balanceOf(address(this)) - state.balances[fromToken] >= payFromAmount,
            Errors.FROMAMOUNT_NOT_ENOUGH
        );

        // record swap
        uint256 toTokenDec = IERC20Metadata(toToken).decimals();
        _recordSwap(fromToken, toToken, vusdAmount, Types.parseRealAmount(receiveToAmount + swapFee, toTokenDec));
        require(checkSafe(), Errors.BELOW_IM_RATIO);

        emit Swap(to, fromToken, toToken, payFromAmount, receiveToAmount, swapFee, mtFee, 1);
        return payFromAmount;
    }

    /// @notice user could query sellToken result deducted swapFee, assign fromAmount
    /// @return payFromAmount fromToken's amount = fromAmount
    /// @return receiveToAmount toToken's amount
    /// @return vusdAmount fromToken bid vusd
    /// @return swapFee dodo takes the fee
    function querySellTokens(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) public view returns (uint256 payFromAmount, uint256 receiveToAmount, uint256 vusdAmount, uint256 swapFee, uint256 mtFee) {
        require(fromAmount > 1000, Errors.AMOUNT_TOO_SMALL);
        Types.RangeOrderState memory D3State = getRangeOrderState(fromToken, toToken);

        {
        uint256 fromTokenDec = IERC20Metadata(fromToken).decimals();
        uint256 toTokenDec = IERC20Metadata(toToken).decimals();
        uint256 fromAmountWithDec18 = Types.parseRealAmount(fromAmount, fromTokenDec);
        uint256 receiveToAmountWithDec18;
        ( , receiveToAmountWithDec18, vusdAmount) =
            PMMRangeOrder.querySellTokens(D3State, fromToken, toToken, fromAmountWithDec18);

        receiveToAmount = Types.parseDec18Amount(receiveToAmountWithDec18, toTokenDec);
        payFromAmount = fromAmount;
        }

        receiveToAmount = receiveToAmount > state.balances[toToken] ? state.balances[toToken] : receiveToAmount;

        uint256 swapFeeRate = D3State.fromTokenMMInfo.swapFeeRate +  D3State.toTokenMMInfo.swapFeeRate;
        swapFee = DecimalMath.mulFloor(receiveToAmount, swapFeeRate);
        uint256 mtFeeRate = D3State.fromTokenMMInfo.mtFeeRate +  D3State.toTokenMMInfo.mtFeeRate;
        mtFee = DecimalMath.mulFloor(receiveToAmount, mtFeeRate);

        return (payFromAmount, receiveToAmount - swapFee, vusdAmount, swapFee, mtFee);
    }

    /// @notice user could query sellToken result deducted swapFee, assign toAmount
    /// @return payFromAmount fromToken's amount
    /// @return receiveToAmount toToken's amount = toAmount
    /// @return vusdAmount fromToken bid vusd
    /// @return swapFee dodo takes the fee
    function queryBuyTokens(
        address fromToken,
        address toToken,
        uint256 toAmount
    ) public view returns (uint256 payFromAmount, uint256 receiveToAmount, uint256 vusdAmount, uint256 swapFee, uint256 mtFee) {
        require(toAmount > 1000, Errors.AMOUNT_TOO_SMALL);
        Types.RangeOrderState memory D3State = getRangeOrderState(fromToken, toToken);

        // query amount and transfer out
        uint256 toAmountWithFee;
        {
        uint256 swapFeeRate = D3State.fromTokenMMInfo.swapFeeRate +  D3State.toTokenMMInfo.swapFeeRate;
        swapFee = DecimalMath.mulFloor(toAmount, swapFeeRate);
        uint256 mtFeeRate = D3State.fromTokenMMInfo.mtFeeRate +  D3State.toTokenMMInfo.mtFeeRate;
        mtFee = DecimalMath.mulFloor(toAmount, mtFeeRate);
        toAmountWithFee = toAmount + swapFee;
        }

        require(toAmountWithFee <= state.balances[toToken], Errors.BALANCE_NOT_ENOUGH);

        uint256 fromTokenDec = IERC20Metadata(fromToken).decimals();
        uint256 toTokenDec = IERC20Metadata(toToken).decimals();
        uint256 toFeeAmountWithDec18 = Types.parseRealAmount(toAmountWithFee, toTokenDec);
        uint256 payFromAmountWithDec18;
        (payFromAmountWithDec18, , vusdAmount) =
            PMMRangeOrder.queryBuyTokens(D3State, fromToken, toToken, toFeeAmountWithDec18);
        payFromAmount = Types.parseDec18Amount(payFromAmountWithDec18, fromTokenDec);
        if(payFromAmount == 0) {
            payFromAmount = 1;
        }

        return (payFromAmount, toAmount, vusdAmount, swapFee, mtFee);
    }

    // ================ internal ==========================

    function _recordSwap(address fromToken, address toToken, uint256 fromAmount, uint256 toAmount) internal {
        tokenCumMap[fromToken].cumulativeBid += fromAmount;
        tokenCumMap[toToken].cumulativeAsk += toAmount;

        _updateReserve(fromToken);
        _updateReserve(toToken);
    }

    function _updateCumulative(address token) internal {
        uint256 tokenIndex = uint256(ID3Maker(state._MAKER_).getOneTokenOriginIndex(token));
        uint256 tokenFlag = (allFlag >> tokenIndex) & 1;
        if (tokenFlag == 0) {
            tokenCumMap[token].cumulativeAsk = 0;
            tokenCumMap[token].cumulativeBid = 0;
            allFlag |= (1 << tokenIndex);
        }
    }

    function _transferOut(address to, address token, uint256 amount) internal {
        IERC20(token).safeTransfer(to, amount);
    }

    // ================ call by maker ==========================
    function setNewAllFlag(uint256 newFlag) external onlyMaker {
        allFlag = newFlag;
    }
}