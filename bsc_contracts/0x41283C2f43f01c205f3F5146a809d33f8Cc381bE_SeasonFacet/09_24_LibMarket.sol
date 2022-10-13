/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

import "../interfaces/pancake/IPancakeRouter02.sol";
import "../interfaces/ITopcorn.sol";
import "../interfaces/IWBNB.sol";
import "./LibAppStorage.sol";
import "./LibClaim.sol";

/**
 * @title Market Library handles swapping, addinga and removing LP on Pancake for Farmer.
 **/
library LibMarket {
    event TopcornAllocation(address indexed account, uint256 topcorns);

    struct DiamondStorage {
        address topcorn;
        address wbnb;
        address router;
    }

    struct AddLiquidity {
        uint256 topcornAmount;
        uint256 minTopcornAmount;
        uint256 minBNBAmount;
    }

    bytes32 private constant MARKET_STORAGE_POSITION = keccak256("diamond.standard.market.storage");

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = MARKET_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function initMarket(
        address topcorn,
        address wbnb,
        address router
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.topcorn = topcorn;
        ds.wbnb = wbnb;
        ds.router = router;
    }

    /**
     * Swap
     **/

    function buy(uint256 buyTopcornAmount) internal returns (uint256 amount) {
        (, amount) = _buy(buyTopcornAmount, msg.value, msg.sender);
    }

    function buyAndDeposit(uint256 buyTopcornAmount) internal returns (uint256 amount) {
        (, amount) = _buy(buyTopcornAmount, msg.value, address(this));
    }

    function buyExactTokensToWallet(
        uint256 buyTopcornAmount,
        address to,
        bool toWallet
    ) internal returns (uint256 amount) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (toWallet) amount = buyExactTokens(buyTopcornAmount, to);
        else {
            amount = buyExactTokens(buyTopcornAmount, address(this));
            s.a[to].wrappedTopcorns = s.a[to].wrappedTopcorns + amount;
        }
    }

    function buyExactTokens(uint256 buyTopcornAmount, address to) internal returns (uint256 amount) {
        (uint256 BNBAmount, uint256 topcornAmount) = _buyExactTokens(buyTopcornAmount, msg.value, to);
        allocateBNBRefund(msg.value, BNBAmount, false);
        return topcornAmount;
    }

    function buyAndSow(uint256 buyTopcornAmount, uint256 buyBNBAmount) internal returns (uint256 amount) {
        if (buyTopcornAmount == 0) {
            allocateBNBRefund(msg.value, 0, false);
            return 0;
        }
        (uint256 bnbAmount, uint256 topcornAmount) = _buyExactTokensWBNB(buyTopcornAmount, buyBNBAmount, address(this));
        allocateBNBRefund(msg.value, bnbAmount, false);
        amount = topcornAmount;
    }

    function sellToWBNB(uint256 sellTopcornAmount, uint256 minBuyBNBAmount) internal returns (uint256 amount) {
        (, uint256 outAmount) = _sell(sellTopcornAmount, minBuyBNBAmount, address(this));
        return outAmount;
    }

    /**
     *  Liquidity
     **/

    function removeLiquidity(
        uint256 liqudity,
        uint256 minTopcornAmount,
        uint256 minBNBAmount
    ) internal returns (uint256 topcornAmount, uint256 bnbAmount) {
        DiamondStorage storage ds = diamondStorage();
        return IPancakeRouter02(ds.router).removeLiquidityETH(ds.topcorn, liqudity, minTopcornAmount, minBNBAmount, msg.sender, block.timestamp);
    }

    function removeLiquidityWithTopcornAllocation(
        uint256 liqudity,
        uint256 minTopcornAmount,
        uint256 minBNBAmount
    ) internal returns (uint256 topcornAmount, uint256 bnbAmount) {
        DiamondStorage storage ds = diamondStorage();
        (topcornAmount, bnbAmount) = IPancakeRouter02(ds.router).removeLiquidity(ds.topcorn, ds.wbnb, liqudity, minTopcornAmount, minBNBAmount, address(this), block.timestamp);
        allocateBNBRefund(bnbAmount, 0, true);
    }

    function addAndDepositLiquidity(AddLiquidity calldata al) internal returns (uint256) {
        allocateTopcorns(al.topcornAmount);
        (, uint256 liquidity) = addLiquidity(al);
        return liquidity;
    }

    function addLiquidity(AddLiquidity calldata al) internal returns (uint256, uint256) {
        (uint256 topcornsDeposited, uint256 bnbDeposited, uint256 liquidity) = _addLiquidity(msg.value, al.topcornAmount, al.minBNBAmount, al.minTopcornAmount);
        allocateBNBRefund(msg.value, bnbDeposited, false);
        allocateTopcornRefund(al.topcornAmount, topcornsDeposited);
        return (topcornsDeposited, liquidity);
    }

    function swapAndAddLiquidity(
        uint256 buyTopcornAmount,
        uint256 buyBNBAmount,
        LibMarket.AddLiquidity calldata al
    ) internal returns (uint256) {
        uint256 boughtLP;
        if (buyTopcornAmount > 0) boughtLP = LibMarket.buyTopcornsAndAddLiquidity(buyTopcornAmount, al);
        else if (buyBNBAmount > 0) boughtLP = LibMarket.buyBNBAndAddLiquidity(buyBNBAmount, al);
        else boughtLP = LibMarket.addAndDepositLiquidity(al);
        return boughtLP;
    }

    // al.buyTopcornAmount is the amount of topcorns the user wants to add to LP
    // buyTopcornAmount is the amount of topcorns the person bought to contribute to LP. Note that
    // buyTopcorn amount will AT BEST be equal to al.buyTopcornAmount because of slippage.
    // Otherwise, it will almost always be less than al.buyTopcorn amount
    function buyTopcornsAndAddLiquidity(uint256 buyTopcornAmount, AddLiquidity calldata al) internal returns (uint256 liquidity) {
        DiamondStorage storage ds = diamondStorage();
        IWBNB(ds.wbnb).deposit{value: msg.value}();

        address[] memory path = new address[](2);
        path[0] = ds.wbnb;
        path[1] = ds.topcorn;
        uint256[] memory amounts = IPancakeRouter02(ds.router).getAmountsIn(buyTopcornAmount, path);
        (uint256 bnbSold, uint256 topcorns) = _buyWithWBNB(buyTopcornAmount, amounts[0], address(this));

        // If topcorns bought does not cover the amount of money to move to LP
        if (al.topcornAmount > buyTopcornAmount) {
            uint256 newTopcornAmount = al.topcornAmount - buyTopcornAmount;
            allocateTopcorns(newTopcornAmount);
            topcorns = topcorns + newTopcornAmount;
        }
        uint256 bnbAdded;
        (topcorns, bnbAdded, liquidity) = _addLiquidityWBNB(msg.value - bnbSold, topcorns, al.minBNBAmount, al.minTopcornAmount);

        allocateTopcornRefund(al.topcornAmount, topcorns);
        allocateBNBRefund(msg.value, bnbAdded + bnbSold, true);
        return liquidity;
    }

    // This function is called when user sends more value of TopCorn than BNB to LP.
    // Value of TopCorn is converted to equivalent value of BNB.
    function buyBNBAndAddLiquidity(uint256 buyWbnbAmount, AddLiquidity calldata al) internal returns (uint256) {
        DiamondStorage storage ds = diamondStorage();
        uint256 sellTopcorns = _amountIn(buyWbnbAmount);
        allocateTopcorns(al.topcornAmount + sellTopcorns);
        (uint256 topcornsSold, uint256 wbnbBought) = _sell(sellTopcorns, buyWbnbAmount, address(this));
        if (msg.value > 0) IWBNB(ds.wbnb).deposit{value: msg.value}();
        (uint256 topcorns, uint256 bnbAdded, uint256 liquidity) = _addLiquidityWBNB(msg.value + wbnbBought, al.topcornAmount, al.minBNBAmount, al.minTopcornAmount);

        allocateTopcornRefund(al.topcornAmount + sellTopcorns, topcorns + topcornsSold);
        allocateBNBRefund(msg.value + wbnbBought, bnbAdded, true);
        return liquidity;
    }

    /**
     *  Shed
     **/

    function _sell(
        uint256 sellTopcornAmount,
        uint256 minBuyBNBAmount,
        address to
    ) internal returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.topcorn;
        path[1] = ds.wbnb;
        uint256[] memory amounts = IPancakeRouter02(ds.router).swapExactTokensForTokens(sellTopcornAmount, minBuyBNBAmount, path, to, block.timestamp);
        return (amounts[0], amounts[1]);
    }

    function _buy(
        uint256 topcornAmount,
        uint256 bnbAmount,
        address to
    ) private returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.wbnb;
        path[1] = ds.topcorn;

        uint256[] memory amounts = IPancakeRouter02(ds.router).swapExactETHForTokens{value: bnbAmount}(topcornAmount, path, to, block.timestamp);
        return (amounts[0], amounts[1]);
    }

    function _buyExactTokens(
        uint256 topcornAmount,
        uint256 bnbAmount,
        address to
    ) private returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.wbnb;
        path[1] = ds.topcorn;

        uint256[] memory amounts = IPancakeRouter02(ds.router).swapETHForExactTokens{value: bnbAmount}(topcornAmount, path, to, block.timestamp);
        return (amounts[0], amounts[1]);
    }

    function _buyExactTokensWBNB(
        uint256 topcornAmount,
        uint256 bnbAmount,
        address to
    ) private returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.wbnb;
        path[1] = ds.topcorn;
        IWBNB(ds.wbnb).deposit{value: bnbAmount}();
        uint256[] memory amounts = IPancakeRouter02(ds.router).swapTokensForExactTokens(topcornAmount, bnbAmount, path, to, block.timestamp);
        IWBNB(ds.wbnb).withdraw(bnbAmount - amounts[0]);
        return (amounts[0], amounts[1]);
    }

    function _buyWithWBNB(
        uint256 topcornAmount,
        uint256 bnbAmount,
        address to
    ) internal returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.wbnb;
        path[1] = ds.topcorn;

        uint256[] memory amounts = IPancakeRouter02(ds.router).swapExactTokensForTokens(bnbAmount, topcornAmount, path, to, block.timestamp);
        return (amounts[0], amounts[1]);
    }

    function _addLiquidity(
        uint256 bnbAmount,
        uint256 topcornAmount,
        uint256 minBNBAmount,
        uint256 minTopcornAmount
    )
        private
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        DiamondStorage storage ds = diamondStorage();
        return IPancakeRouter02(ds.router).addLiquidityETH{value: bnbAmount}(ds.topcorn, topcornAmount, minTopcornAmount, minBNBAmount, address(this), block.timestamp);
    }

    function _addLiquidityWBNB(
        uint256 wbnbAmount,
        uint256 topcornAmount,
        uint256 minWBNBAmount,
        uint256 minTopcornAmount
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        DiamondStorage storage ds = diamondStorage();
        return IPancakeRouter02(ds.router).addLiquidity(ds.topcorn, ds.wbnb, topcornAmount, wbnbAmount, minTopcornAmount, minWBNBAmount, address(this), block.timestamp);
    }

    function _amountIn(uint256 buyWBNBAmount) internal view returns (uint256) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.topcorn;
        path[1] = ds.wbnb;
        uint256[] memory amounts = IPancakeRouter02(ds.router).getAmountsIn(buyWBNBAmount, path);
        return amounts[0];
    }

    function allocateTopcornsToWallet(
        uint256 amount,
        address to,
        bool toWallet
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (toWallet) LibMarket.allocateTopcornsTo(amount, to);
        else {
            LibMarket.allocateTopcornsTo(amount, address(this));
            s.a[to].wrappedTopcorns = s.a[to].wrappedTopcorns + amount;
        }
    }

    function transferTopcorns(
        address to,
        uint256 amount,
        bool toWallet
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (toWallet) ITopcorn(s.c.topcorn).transferFrom(msg.sender, to, amount);
        else {
            ITopcorn(s.c.topcorn).transferFrom(msg.sender, address(this), amount);
            s.a[to].wrappedTopcorns = s.a[to].wrappedTopcorns + amount;
        }
    }

    function allocateTopcorns(uint256 amount) internal {
        allocateTopcornsTo(amount, address(this));
    }

    function allocateTopcornsTo(uint256 amount, address to) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 wrappedTopcorns = s.a[msg.sender].wrappedTopcorns;
        uint256 remainingTopcorns = amount;
        if (wrappedTopcorns > 0) {
            if (remainingTopcorns > wrappedTopcorns) {
                s.a[msg.sender].wrappedTopcorns = 0;
                remainingTopcorns = remainingTopcorns - wrappedTopcorns;
            } else {
                s.a[msg.sender].wrappedTopcorns = wrappedTopcorns - remainingTopcorns;
                remainingTopcorns = 0;
            }
            uint256 fromWrappedTopcorns = amount - remainingTopcorns;
            emit TopcornAllocation(msg.sender, fromWrappedTopcorns);
            if (to != address(this)) ITopcorn(s.c.topcorn).transfer(to, fromWrappedTopcorns);
        }
        if (remainingTopcorns > 0) ITopcorn(s.c.topcorn).transferFrom(msg.sender, to, remainingTopcorns);
    }

    // Allocate TopCorn Refund stores the TopCorn refund amount in the state to be refunded at the end of the transaction.
    function allocateTopcornRefund(uint256 inputAmount, uint256 amount) internal {
        if (inputAmount > amount) {
            AppStorage storage s = LibAppStorage.diamondStorage();
            if (s.refundStatus % 2 == 1) {
                s.refundStatus += 1;
                s.topcornRefundAmount = inputAmount - amount;
            } else s.topcornRefundAmount = s.topcornRefundAmount + (inputAmount - amount);
        }
    }

    // Allocate BNB Refund stores the BNB refund amount in the state to be refunded at the end of the transaction.
    function allocateBNBRefund(
        uint256 inputAmount,
        uint256 amount,
        bool wbnb
    ) internal {
        if (inputAmount > amount) {
            AppStorage storage s = LibAppStorage.diamondStorage();
            if (wbnb) IWBNB(s.c.wbnb).withdraw(inputAmount - amount);
            if (s.refundStatus < 3) {
                s.refundStatus += 2;
                s.bnbRefundAmount = inputAmount - amount;
            } else s.bnbRefundAmount = s.bnbRefundAmount + (inputAmount - amount);
        }
    }

    function claimRefund(LibClaim.Claim calldata c) internal {
        // The only case that a Claim triggers an BNB refund is
        // if the farmer claims LP, removes the LP and wraps the underlying Topcorns
        if (c.convertLP && !c.toWallet && c.lpWithdrawals.length > 0) refund();
    }

    function refund() internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // If Refund state = 1 -> No refund
        // If Refund state is even -> Refund Topcorns
        // if Refund state > 2 -> Refund BNB

        uint256 rs = s.refundStatus;
        if (rs > 1) {
            if (rs > 2) {
                (bool success, ) = msg.sender.call{value: s.bnbRefundAmount}("");
                require(success, "Market: Refund failed.");
                rs -= 2;
                s.bnbRefundAmount = 1;
            }
            if (rs == 2) {
                ITopcorn(s.c.topcorn).transfer(msg.sender, s.topcornRefundAmount);
                s.topcornRefundAmount = 1;
            }
            s.refundStatus = 1;
        }
    }
}