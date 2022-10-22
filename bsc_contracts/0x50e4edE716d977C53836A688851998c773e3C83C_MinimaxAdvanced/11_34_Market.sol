// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./Hints.sol";
import "./v2/PancakeLpMarket.sol";
import "./v2/PairTokenDetector.sol";
import "./IMarket.sol";

contract Market is IMarket, OwnableUpgradeable {
    PancakeLpMarket public pancakeLpMarket;
    SingleMarket public singleMarket;
    PairTokenDetector public pairTokenDetector;

    constructor() initializer {
        __Ownable_init();
    }

    function setPancakeLpMarket(PancakeLpMarket _pancakeLpMarket) public onlyOwner {
        pancakeLpMarket = _pancakeLpMarket;
    }

    function setSingleMarket(SingleMarket _singleMarket) public onlyOwner {
        singleMarket = _singleMarket;
    }

    function setPairTokenDetector(PairTokenDetector _pairTokenDetector) public onlyOwner {
        pairTokenDetector = _pairTokenDetector;
    }

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address destination,
        bytes memory hints
    ) public returns (uint256) {
        IERC20Upgradeable(tokenIn).transferFrom(address(msg.sender), address(this), amountIn);

        if (Hints.getIsPair(hints, tokenIn) || Hints.getIsPair(hints, tokenOut)) {
            IERC20Upgradeable(tokenIn).approve(address(pancakeLpMarket), amountIn);
            return pancakeLpMarket.swap(tokenIn, tokenOut, amountIn, amountOutMin, destination, hints);
        }

        IERC20Upgradeable(tokenIn).approve(address(singleMarket), amountIn);
        return singleMarket.swap(tokenIn, tokenOut, amountIn, amountOutMin, destination, hints);
    }

    function estimateBurn(address lpToken, uint amountIn) public view returns (uint, uint) {
        return pancakeLpMarket.estimateBurn(lpToken, amountIn);
    }

    function estimateOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256 amountOut, bytes memory hints) {
        return estimateOutCustomRouters(new IRouter[](0), tokenIn, tokenOut, amountIn);
    }

    function estimateOutCustomRouters(
        IRouter[] memory routers,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256 amountOut, bytes memory hints) {
        bool tokenInPair = pairTokenDetector.isPairToken{gas: 50000}(tokenIn);
        bool tokenOutPair = pairTokenDetector.isPairToken{gas: 50000}(tokenOut);

        if (tokenInPair || tokenOutPair) {
            (uint256 amountOut, bytes memory hints) = pancakeLpMarket.estimateOut(
                routers,
                tokenIn,
                tokenOut,
                amountIn,
                tokenInPair,
                tokenOutPair
            );

            if (tokenInPair) {
                hints = Hints.merge2(hints, Hints.setIsPair(tokenIn));
            }

            if (tokenOutPair) {
                hints = Hints.merge2(hints, Hints.setIsPair(tokenOut));
            }

            return (amountOut, hints);
        }

        return singleMarket.estimateOut(routers, tokenIn, tokenOut, amountIn);
    }
}