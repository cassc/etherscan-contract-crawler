// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";
import "../weth/IWETH.sol";
import "../WethProvider.sol";
import "./IKyberDmmRouter.sol";

abstract contract KyberDmm is WethProvider {
    uint256 constant MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    struct KyberDMMData {
        address[] poolPath;
        IERC20[] path;
    }

    function swapOnKyberDmm(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        KyberDMMData memory data = abi.decode(payload, (KyberDMMData));

        address _fromToken = address(fromToken) == Utils.ethAddress() ? WETH : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress() ? WETH : address(toToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
        }

        Utils.approve(address(exchange), _fromToken, fromAmount);

        IDMMExchangeRouter(exchange).swapExactTokensForTokens(
            fromAmount,
            1,
            data.poolPath,
            data.path,
            address(this),
            MAX_INT // deadline
        );

        if (address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }
}