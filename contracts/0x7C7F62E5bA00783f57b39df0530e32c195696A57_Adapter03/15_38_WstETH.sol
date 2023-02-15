// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";
import "./IwstETH.sol";

contract WstETH {
    function swapOnWstETH(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange
    ) internal {
        bool wrapping = address(toToken) == exchange;
        bool unwrapping = address(fromToken) == exchange;
        require((wrapping && !unwrapping) || (unwrapping && !wrapping), "One token should be wstETH");

        if (wrapping) {
            Utils.approve(exchange, address(fromToken), fromAmount);
            IwstETH(exchange).wrap(fromAmount);
        } else {
            IwstETH(exchange).unwrap(fromAmount);
        }
    }
}