// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../utils/fromOZ/ECDSA.sol";
import "./LibValidator.sol";
import "./LibExchange.sol";
import "./LibUnitConverter.sol";
import "./SafeTransferHelper.sol";
import "../interfaces/IPoolFunctionality.sol";

library LibPool {

    function updateFilledAmount(
        LibValidator.Order memory order,
        uint112 filledBase,
        mapping(bytes32 => uint192) storage filledAmounts
    ) internal {
        bytes32 orderHash = LibValidator.getTypeValueHash(order);
        uint192 total_amount = filledAmounts[orderHash];
        total_amount += filledBase; //it is safe to add ui112 to each other to get i192
        require(total_amount >= filledBase, "E12B_0");
        require(total_amount <= order.amount, "E12B");
        filledAmounts[orderHash] = total_amount;
    }

    function refundChange(uint amountOut) internal {
        uint actualOutBaseUnit = uint(LibUnitConverter.decimalToBaseUnit(address(0), amountOut));
        if (msg.value > actualOutBaseUnit) {
            SafeTransferHelper.safeTransferTokenOrETH(address(0), msg.sender, msg.value - actualOutBaseUnit);
        }
    }

    function retrieveAssetSpend(address pf, address[] memory path) internal view returns (address) {
        return path.length > 2 ? (IPoolFunctionality(pf).isFactory(path[0]) ? path[1] : path[0]) : path[0];
    }

    function doSwapThroughOrionPool(
        IPoolFunctionality.SwapData memory d,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) public returns(bool) {

        require(d.is_exact_spend || !d.supportingFee, "FNS");

        d.asset_spend = retrieveAssetSpend(d.orionpool_router, d.path);
        d.isInContractTrade = assetBalances[msg.sender][d.asset_spend] > 0;

        if (msg.value > 0) {
            uint112 eth_sent = uint112(LibUnitConverter.baseUnitToDecimal(address(0), msg.value));
            if (d.asset_spend == address(0) && eth_sent >= d.amount_spend) {
                d.isSentETHEnough = true;
                d.isInContractTrade = false;
            } else {
                LibExchange._updateBalance(msg.sender, address(0), eth_sent, assetBalances, liabilities);
            }
        }

        d.isFromWallet = assetBalances[msg.sender][d.asset_spend] < d.amount_spend;
        if (d.isInContractTrade) {
            if (d.supportingFee) {
                // Depositing before _updateBalance and changing amount_spend if token has internal fee
                uint beforeBalance = uint(assetBalances[msg.sender][d.asset_spend]);
                int afterBalance = int(beforeBalance) - int(d.amount_spend);
                if (afterBalance < 0) {
                    uint previousBalance = IERC20(d.asset_spend).balanceOf(address(this));
                    LibExchange._tryDeposit(d.asset_spend, uint(-afterBalance), msg.sender);
                    uint depositedAmount = IERC20(d.asset_spend).balanceOf(address(this)) - previousBalance;
                    depositedAmount = LibUnitConverter.baseUnitToDecimal(d.asset_spend, depositedAmount);
                    require(depositedAmount != 0, "E1S");
                    assetBalances[msg.sender][d.asset_spend] += int192(depositedAmount);
                    d.amount_spend = uint112(beforeBalance) + uint112(depositedAmount);
                }
            }
            LibExchange._updateBalance(msg.sender, d.asset_spend, -1*int(d.amount_spend), assetBalances, liabilities);

            require(assetBalances[msg.sender][d.asset_spend] >= 0, "E1S");
        }

        (uint amountOut, uint amountIn) = IPoolFunctionality(d.orionpool_router).doSwapThroughOrionPool(
            d.isInContractTrade || d.isSentETHEnough ? address(this) : msg.sender,
            d.isInContractTrade && !d.supportingFee ? address(this) : msg.sender,
            d
        );

        if (d.isSentETHEnough) {
            refundChange(amountOut);
        } else if (d.isInContractTrade && !d.supportingFee) {
            if (d.amount_spend > amountOut) { //Refund
                LibExchange._updateBalance(msg.sender, d.asset_spend, int(d.amount_spend) - int(amountOut), assetBalances, liabilities);
            }
            LibExchange.creditUserAssets(d.isFromWallet ? 1 : 0, msg.sender, int(amountIn), d.path[d.path.length-1], assetBalances, liabilities);
            return true;
        }

        return d.isInContractTrade;
    }

    //  Just to avoid stack too deep error;
    struct OrderExecutionData {
        LibValidator.Order order;
        uint filledAmount;
        uint blockchainFee;
        address[] path;
        address allowedMatcher;
        address orionpoolRouter;
        uint amount_spend;
        uint amount_receive;
        uint amountQuote;
        uint filledBase;
        uint filledQuote;
        uint filledPrice;
        uint amountOut;
        uint amountIn;
        bool isInContractTrade;
        bool isRetainFee;
        bool isFromWallet;
        address to;
        address asset_spend;
    }

    function calcAmounts(
        OrderExecutionData memory d,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) internal {
        d.amountQuote = uint(d.filledAmount) * d.order.price / (10**8);
        (d.amount_spend, d.amount_receive) = d.order.buySide == 0 ? (d.filledAmount, d.amountQuote)
            : (d.amountQuote, d.filledAmount);

        d.asset_spend = retrieveAssetSpend(d.orionpoolRouter, d.path);
        d.isFromWallet = int(assetBalances[d.order.senderAddress][d.asset_spend]) < int(d.amount_spend);
        d.isInContractTrade = d.asset_spend == address(0) || assetBalances[d.order.senderAddress][d.asset_spend] > 0;

        if (d.blockchainFee > d.order.matcherFee)
            d.blockchainFee = d.order.matcherFee;

        if (d.isInContractTrade) {
            LibExchange._updateBalance(d.order.senderAddress, d.asset_spend, -1*int(d.amount_spend), assetBalances, liabilities);
            require(assetBalances[d.order.senderAddress][d.asset_spend] >= 0, "E1S");
        }

        if (d.order.matcherFeeAsset != d.path[d.path.length-1]) {
            _payMatcherFee(d.order, d.blockchainFee, assetBalances, liabilities);
        } else {
            d.isRetainFee = true;
        }

        d.to = (d.isRetainFee || !d.isFromWallet) ? address(this) : d.order.senderAddress;
    }

    function calcAmountInOutAfterSwap(
        OrderExecutionData memory d,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) internal {

        (d.filledBase, d.filledQuote) = d.order.buySide == 0 ? (d.amountOut, d.amountIn) : (d.amountIn, d.amountOut);
        d.filledPrice = d.filledBase > 0 ? d.filledQuote * (10**8) / d.filledBase : 0;

        if (d.order.buySide == 0 && d.filledBase > 0) {
            require(d.filledPrice >= d.order.price, "EX");
        } else {
            require(d.filledPrice <= d.order.price, "EX");
        }

        if (d.isInContractTrade && d.amount_spend > d.amountOut) { //Refund
            LibExchange._updateBalance(d.order.senderAddress, d.asset_spend, int(d.amount_spend) - int(d.amountOut),
                assetBalances, liabilities);
        }

        if (d.isRetainFee) {
            uint actualFee = d.amountIn >= d.blockchainFee ? d.blockchainFee : d.amountIn;
            d.amountIn -= actualFee;
            // Pay to matcher
            LibExchange._updateBalance(d.order.matcherAddress, d.order.matcherFeeAsset, int(actualFee), assetBalances, liabilities);
            if (actualFee < d.blockchainFee) {
                _payMatcherFee(d.order, d.blockchainFee - actualFee, assetBalances, liabilities);
            }
        }

        if (d.to == address(this) && d.amountIn > 0) {
            LibExchange.creditUserAssets(d.isFromWallet ? 1 : 0, d.order.senderAddress, int(d.amountIn),
                d.path[d.path.length-1], assetBalances, liabilities);
        }
    }

    function doFillThroughOrionPool(
        OrderExecutionData memory d,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities,
        mapping(bytes32 => uint192) storage filledAmounts
    ) public {
        calcAmounts(d, assetBalances, liabilities);

        LibValidator.checkOrderSingleMatch(d.order, msg.sender, d.allowedMatcher, uint112(d.filledAmount), block.timestamp,
            d.asset_spend, d.path[d.path.length - 1]);

        IPoolFunctionality.SwapData memory swapData;
        swapData.amount_spend = uint112(d.amount_spend);
        swapData.amount_receive = uint112(d.amount_receive);
        swapData.path = d.path;
        swapData.is_exact_spend = d.order.buySide == 0;
        swapData.supportingFee = false;

        try IPoolFunctionality(d.orionpoolRouter).doSwapThroughOrionPool(
            d.isInContractTrade ? address(this) : d.order.senderAddress,
            d.to,
            swapData
        ) returns(uint amountOut, uint amountIn) {
            d.amountOut = amountOut;
            d.amountIn = amountIn;
        } catch(bytes memory reason) {
            d.amountOut = 0;
            d.amountIn = 0;
        }

        calcAmountInOutAfterSwap(d, assetBalances, liabilities);

        updateFilledAmount(d.order, uint112(d.filledBase), filledAmounts);

        emit LibExchange.NewTrade(
            d.order.senderAddress,
            address(1),
            d.order.baseAsset,
            d.order.quoteAsset,
            uint64(d.filledPrice),
            uint192(d.filledBase),
            uint192(d.filledQuote)
        );
    }

    function _payMatcherFee(
        LibValidator.Order memory order,
        uint blockchainFee,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) internal {
        LibExchange._updateBalance(order.senderAddress, order.matcherFeeAsset, -1*int(blockchainFee), assetBalances, liabilities);
        require(assetBalances[order.senderAddress][order.matcherFeeAsset] >= 0, "E1F");
        LibExchange._updateBalance(order.matcherAddress, order.matcherFeeAsset, int(blockchainFee), assetBalances, liabilities);
    }

    function doWithdrawToPool(
        address assetA,
        address asseBNotETH,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities,
        address _orionpoolRouter
    ) public returns(uint amountA, uint amountB) {
        require(asseBNotETH != address(0), "TokenBIsETH");

        if (msg.value > 0) {
            uint112 eth_sent = uint112(LibUnitConverter.baseUnitToDecimal(address(0), msg.value));
            LibExchange._updateBalance(msg.sender, address(0), eth_sent, assetBalances, liabilities);
        }

        LibExchange._updateBalance(msg.sender, assetA, -1*int256(amountADesired), assetBalances, liabilities);
        require(assetBalances[msg.sender][assetA] >= 0, "E1w1A");

        LibExchange._updateBalance(msg.sender, asseBNotETH, -1*int256(amountBDesired), assetBalances, liabilities);
        require(assetBalances[msg.sender][asseBNotETH] >= 0, "E1w1B");

        (amountA, amountB, ) = IPoolFunctionality(_orionpoolRouter).addLiquidityFromExchange(
            assetA,
            asseBNotETH,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            msg.sender
        );

        // Refund
        if (amountADesired > amountA) {
            LibExchange._updateBalance(msg.sender, assetA, int(amountADesired - amountA), assetBalances, liabilities);
        }

        if (amountBDesired > amountB) {
            LibExchange._updateBalance(msg.sender, asseBNotETH, int(amountBDesired - amountB), assetBalances, liabilities);
        }
    }

}