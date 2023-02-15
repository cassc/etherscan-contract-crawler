// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IAugustusRFQ.sol";
import "../Utils.sol";
import "../WethProvider.sol";
import "../weth/IWETH.sol";

abstract contract AugustusRFQ is WethProvider {
    using SafeMath for uint256;

    struct AugustusRFQData {
        IAugustusRFQ.OrderInfo[] orderInfos;
    }

    function swapOnAugustusRFQ(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        AugustusRFQData memory data = abi.decode(payload, (AugustusRFQData));

        for (uint256 i = 0; i < data.orderInfos.length; ++i) {
            address userAddress = address(uint160(data.orderInfos[i].order.nonceAndMeta));
            require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");
        }

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
            Utils.approve(exchange, WETH, fromAmount);
        } else {
            Utils.approve(exchange, address(fromToken), fromAmount);
        }

        IAugustusRFQ(exchange).tryBatchFillOrderTakerAmount(data.orderInfos, fromAmount, address(this));

        if (address(toToken) == Utils.ethAddress()) {
            uint256 amount = IERC20(WETH).balanceOf(address(this));
            IWETH(WETH).withdraw(amount);
        }
    }

    function buyOnAugustusRFQ(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmountMax,
        uint256 toAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        AugustusRFQData memory data = abi.decode(payload, (AugustusRFQData));

        for (uint256 i = 0; i < data.orderInfos.length; ++i) {
            address userAddress = address(uint160(data.orderInfos[i].order.nonceAndMeta));
            require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");
        }

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmountMax }();
            Utils.approve(exchange, WETH, fromAmountMax);
        } else {
            Utils.approve(exchange, address(fromToken), fromAmountMax);
        }

        IAugustusRFQ(exchange).tryBatchFillOrderMakerAmount(data.orderInfos, toAmount, address(this));

        if (address(fromToken) == Utils.ethAddress() || address(toToken) == Utils.ethAddress()) {
            uint256 amount = IERC20(WETH).balanceOf(address(this));
            IWETH(WETH).withdraw(amount);
        }
    }
}