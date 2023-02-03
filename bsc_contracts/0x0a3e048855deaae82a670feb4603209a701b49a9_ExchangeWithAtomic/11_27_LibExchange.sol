// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../utils/fromOZ/SafeERC20.sol";
import "../interfaces/IERC20.sol";
import "./MarginalFunctionality.sol";
import "./LibUnitConverter.sol";
import "./LibValidator.sol";
import "./SafeTransferHelper.sol";

library LibExchange {
    using SafeERC20 for IERC20;

    //  Flags for updateOrders
    //      All flags are explicit
    uint8 public constant kSell = 0;
    uint8 public constant kBuy = 1; //  if 0 - then sell
    uint8 public constant kCorrectMatcherFeeByOrderAmount = 2;

    event NewTrade(
        address indexed buyer,
        address indexed seller,
        address baseAsset,
        address quoteAsset,
        uint64 filledPrice,
        uint192 filledAmount,
        uint192 amountQuote
    );

    function _updateBalance(address user, address asset, int amount,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) internal returns (uint tradeType) { // 0 - in contract, 1 - from wallet
        int beforeBalance = int(assetBalances[user][asset]);
        int afterBalance = beforeBalance + amount;
        require((amount >= 0 && afterBalance >= beforeBalance) || (amount < 0 && afterBalance < beforeBalance), "E11");

        if (amount > 0 && beforeBalance < 0) {
            MarginalFunctionality.updateLiability(user, asset, liabilities, uint112(amount), int192(afterBalance));
        } else if (beforeBalance >= 0 && afterBalance < 0){
            if (asset != address(0)) {
                afterBalance += int(_tryDeposit(asset, uint(-1*afterBalance), user));
            }

            // If we failed to deposit balance is still negative then we move user into liability
            if (afterBalance < 0) {
                setLiability(user, asset, int192(afterBalance), liabilities);
            } else {
                tradeType = beforeBalance > 0 ? 0 : 1;
            }
        }

        if (beforeBalance != afterBalance) {
            require(afterBalance >= type(int192).min && afterBalance <= type(int192).max, "E11");
            assetBalances[user][asset] = int192(afterBalance);
        }
    }

    /**
     * @dev method to add liability
     * @param user - user which created liability
     * @param asset - liability asset
     * @param balance - current negative balance
     */
    function setLiability(address user, address asset, int192 balance,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) internal {
        liabilities[user].push(
            MarginalFunctionality.Liability({
                asset : asset,
                timestamp : uint64(block.timestamp),
                outstandingAmount : uint192(- balance)
            })
        );
    }

    function _tryDeposit(
        address asset,
        uint amount,
        address user
    ) internal returns(uint) {
        uint256 amountInBase = uint256(LibUnitConverter.decimalToBaseUnit(asset, amount));

        // Query allowance before trying to transferFrom
        if (IERC20(asset).balanceOf(user) >= amountInBase && IERC20(asset).allowance(user, address(this)) >= amountInBase) {
            SafeERC20.safeTransferFrom(IERC20(asset), user, address(this), amountInBase);
            return amount;
        } else {
            return 0;
        }
    }

    function creditUserAssets(uint tradeType, address user, int amount, address asset,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) internal {
        int beforeBalance = int(assetBalances[user][asset]);
        int remainingAmount = amount + beforeBalance;
        require((amount >= 0 && remainingAmount >= beforeBalance) || (amount < 0 && remainingAmount < beforeBalance), "E11");
        int sentAmount = 0;

        if (tradeType == 0 && asset == address(0) && user.balance < 1e16) {
            tradeType = 1;
        }

        if (tradeType == 1 && amount > 0 && remainingAmount > 0) {
            uint amountInBase = uint(LibUnitConverter.decimalToBaseUnit(asset, uint(amount)));
            uint contractBalance = asset == address(0) ? address(this).balance : IERC20(asset).balanceOf(address(this));
            if (contractBalance >= amountInBase) {
                SafeTransferHelper.safeTransferTokenOrETH(asset, user, amountInBase);
                sentAmount = amount;
            }
        }
        int toUpdate = amount - sentAmount;
        if (toUpdate != 0) {
            _updateBalance(user, asset, toUpdate, assetBalances, liabilities);
        }
    }

    struct SwapBalanceChanges {
        int amountOut;
        address assetOut;
        int amountIn;
        address assetIn;
    }

    /**
     *  @notice update user balances and send matcher fee
     *  @param flags uint8, see constants for possible flags of order
     */
    function updateOrderBalanceDebit(
        LibValidator.Order memory order,
        uint112 amountBase,
        uint112 amountQuote,
        uint8 flags,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) internal returns (uint tradeType, int actualIn) {
        bool isSeller = (flags & kBuy) == 0;

        {
            //  Stack too deep
            bool isCorrectFee = ((flags & kCorrectMatcherFeeByOrderAmount) != 0);

            if (isCorrectFee) {
                // matcherFee: u64, filledAmount u128 => matcherFee*filledAmount fit u256
                // result matcherFee fit u64
                order.matcherFee = uint64(
                    (uint256(order.matcherFee) * amountBase) / order.amount
                ); //rewrite in memory only
            }
        }

        if (amountBase > 0) {
            SwapBalanceChanges memory swap;

            (swap.amountOut, swap.amountIn) = isSeller
            ? (-1*int(amountBase), int(amountQuote))
            : (-1*int(amountQuote), int(amountBase));

            (swap.assetOut, swap.assetIn) = isSeller
            ? (order.baseAsset, order.quoteAsset)
            : (order.quoteAsset, order.baseAsset);


            uint feeTradeType = 1;
            if (order.matcherFeeAsset == swap.assetOut) {
                swap.amountOut -= order.matcherFee;
            } else if (order.matcherFeeAsset == swap.assetIn) {
                swap.amountIn -= order.matcherFee;
            } else {
                feeTradeType = _updateBalance(order.senderAddress, order.matcherFeeAsset, -1*int256(order.matcherFee),
                    assetBalances, liabilities);
            }

            tradeType = feeTradeType & _updateBalance(order.senderAddress, swap.assetOut, swap.amountOut, assetBalances, liabilities);

            actualIn = swap.amountIn;

            _updateBalance(order.matcherAddress, order.matcherFeeAsset, order.matcherFee, assetBalances, liabilities);
        }

    }

}