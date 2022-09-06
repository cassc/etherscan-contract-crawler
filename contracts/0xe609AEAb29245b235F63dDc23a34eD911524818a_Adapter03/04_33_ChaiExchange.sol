// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IChai.sol";
import "../Utils.sol";

contract ChaiExchange {
    address public immutable chai;
    address public immutable dai;

    constructor(address _chai, address _dai) public {
        chai = _chai;
        dai = _dai;
    }

    function swapOnChai(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    ) internal {
        _swapOnChai(fromToken, toToken, fromAmount);
    }

    function buyOnChai(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    ) internal {
        _swapOnChai(fromToken, toToken, fromAmount);
    }

    function _swapOnChai(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    ) private {
        Utils.approve(address(chai), address(fromToken), fromAmount);

        if (address(fromToken) == chai) {
            require(address(toToken) == dai, "Destination token should be dai");
            IChai(chai).exit(address(this), fromAmount);
        } else if (address(fromToken) == dai) {
            require(address(toToken) == chai, "Destination token should be chai");
            IChai(chai).join(address(this), fromAmount);
        } else {
            revert("Invalid fromToken");
        }
    }
}