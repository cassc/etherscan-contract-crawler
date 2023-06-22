// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "../IWETH9.sol";
import "../IERC20.sol";
 
contract MockPancakeSmartRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    address public weth;
    constructor(address _weth)  {
        weth = _weth;
    }

    function exactInputSingle(ExactInputSingleParams calldata _params) external payable returns (uint256 amountOut) {
        address fromToken = _params.tokenIn;
        address toToken = _params.tokenOut;

        if (fromToken == weth) {
            IWETH9(weth).deposit{value: _params.amountIn}();
        } else {
            IERC20(fromToken).transferFrom(msg.sender, address(this), _params.amountIn);
        }
        IERC20(toToken).transfer(_params.recipient, _params.amountIn);
        return _params.amountIn;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut) {
        address fromToken = path[0];
        address toToken = path[path.length - 1];

        if (fromToken == weth) {
            IWETH9(weth).deposit{value: amountIn}();
        } else {
            IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn);
        }
        IERC20(toToken).transfer(to, amountIn);
        
        return amountIn;
    }
}