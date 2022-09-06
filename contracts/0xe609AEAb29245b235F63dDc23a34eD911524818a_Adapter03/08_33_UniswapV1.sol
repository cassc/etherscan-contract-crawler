// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";
import "./IUniswapExchange.sol";
import "./IUniswapFactory.sol";

contract UniswapV1 {
    using SafeMath for uint256;

    address public immutable factory;

    constructor(address _factory) public {
        factory = _factory;
    }

    function swapOnUniswapV1(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    ) internal {
        _swapOnUniswapV1(fromToken, toToken, fromAmount, 1);
    }

    function buyOnUniswapV1(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount
    ) internal {
        address exchange = getExchange(fromToken, toToken);

        Utils.approve(address(exchange), address(fromToken), fromAmount);

        if (address(fromToken) == Utils.ethAddress()) {
            IUniswapExchange(exchange).ethToTokenSwapOutput{ value: fromAmount }(toAmount, block.timestamp);
        } else if (address(toToken) == Utils.ethAddress()) {
            IUniswapExchange(exchange).tokenToEthSwapOutput(toAmount, fromAmount, block.timestamp);
        } else {
            IUniswapExchange(exchange).tokenToTokenSwapOutput(
                toAmount,
                fromAmount,
                Utils.maxUint(),
                block.timestamp,
                address(toToken)
            );
        }
    }

    function getExchange(IERC20 fromToken, IERC20 toToken) private view returns (address) {
        address exchangeAddress = address(fromToken) == Utils.ethAddress() ? address(toToken) : address(fromToken);

        return IUniswapFactory(factory).getExchange(exchangeAddress);
    }

    function _swapOnUniswapV1(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount
    ) private returns (uint256) {
        address exchange = getExchange(fromToken, toToken);

        Utils.approve(exchange, address(fromToken), fromAmount);

        uint256 receivedAmount = 0;

        if (address(fromToken) == Utils.ethAddress()) {
            receivedAmount = IUniswapExchange(exchange).ethToTokenSwapInput{ value: fromAmount }(
                toAmount,
                block.timestamp
            );
        } else if (address(toToken) == Utils.ethAddress()) {
            receivedAmount = IUniswapExchange(exchange).tokenToEthSwapInput(fromAmount, toAmount, block.timestamp);
        } else {
            receivedAmount = IUniswapExchange(exchange).tokenToTokenSwapInput(
                fromAmount,
                toAmount,
                1,
                block.timestamp,
                address(toToken)
            );
        }

        return receivedAmount;
    }
}