//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract UniswapV2Router02 {
    using SafeERC20 for IERC20;
    address public currency;

    constructor(address _currency) public {
        currency = _currency;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        public
        returns (
            uint256[] memory amounts // uint256 deadline
        )
    {
        amounts = new uint256[](path.length);
        uint256 amountOut = amountIn;
        IERC20(currency).safeTransfer(to, amountOut);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
        return amounts;
    }
}