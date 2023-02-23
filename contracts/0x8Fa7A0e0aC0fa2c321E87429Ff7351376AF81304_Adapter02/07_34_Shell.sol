// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../Utils.sol";

import "./IShell.sol";
import "../../AugustusStorage.sol";

contract Shell {
    using SafeMath for uint256;

    uint256 public immutable swapLimitOverhead;

    constructor(uint256 _swapLimitOverhead) public {
        swapLimitOverhead = _swapLimitOverhead;
    }

    function swapOnShell(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange
    ) internal {
        Utils.approve(address(exchange), address(fromToken), fromAmount);

        IShell(exchange).originSwap(
            address(fromToken),
            address(toToken),
            fromAmount,
            1,
            block.timestamp + swapLimitOverhead
        );
    }

    function buyOnShell(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address exchange
    ) internal {
        Utils.approve(address(exchange), address(fromToken), fromAmount);

        IShell(exchange).targetSwap(
            address(fromToken),
            address(toToken),
            fromAmount,
            toAmount,
            block.timestamp + swapLimitOverhead
        );
    }
}