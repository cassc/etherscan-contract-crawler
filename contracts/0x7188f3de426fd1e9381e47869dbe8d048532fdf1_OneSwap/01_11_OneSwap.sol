// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./IWETH9.sol";
import "./IPancakeSmartRouter.sol";
import "./Address.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV3Router.sol";

using Address for address payable;


contract OneSwap {
    address public admin;
    address public weth;

    address public pancakeSmartRouter;
    address public uniswapV3SmartRouter;
    address public uniswapV2Router01;

    constructor(
        address _weth,
        address _pancakeSmartRouter,
        address _uniswapV3SmartRouter,
        address _uniswapV2Router01
    ) {
        admin = msg.sender;
        weth = _weth;
        pancakeSmartRouter = _pancakeSmartRouter;
        uniswapV3SmartRouter = _uniswapV3SmartRouter;
        uniswapV2Router01 = _uniswapV2Router01;
    }

    event Swap(address fromToken, address toToken, uint256 fromAmount, uint256 toAmount);

    modifier onlyAdmin {
        require(admin == msg.sender, 'only admin');
        _;
    }

    // bsc: pancake-v2, pancake-v3, uniswap-v3
    // arbitrum: uniswap-v3
    // ethereum: uniswap-v2, uniswap-v3
    // polygon: uniswap-v3, quickswap-v2, quickswap-v3
    // optimism: uniswap-v3


    function pancakeV2TestSwap(
        address token
    ) external payable {
        // 1.swap: eth => token
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;
        uint256 amountOut1 = IPancakeSmartRouter(pancakeSmartRouter).swapExactTokensForTokens{value: msg.value}(msg.value, 0, path, address(this));

        // 2. swap: token => weth
        path[0] = token;
        path[1] = weth;
        IERC20(token).approve(pancakeSmartRouter, amountOut1);
        uint256 amountOut2 = IPancakeSmartRouter(pancakeSmartRouter).swapExactTokensForTokens(amountOut1, 0, path, address(this));

        // 3. weth => eth
        IWETH9(weth).withdraw(amountOut2);
        payable(msg.sender).sendValue(amountOut2);
    }

    function pancakeV3TestSwap(
        address token,
        uint24 fee
    ) external payable {
        // 1. eth => weth
        IWETH9(weth).deposit{value: msg.value}();

        // 2. weth => token
        IERC20(weth).approve(pancakeSmartRouter, msg.value);

        IPancakeSmartRouter.ExactInputSingleParams memory param1 = IPancakeSmartRouter.ExactInputSingleParams(
            weth,
            token,
            fee,
            address(this),
            msg.value,
            0,
            0
        );
        uint256 amountOut1 = IPancakeSmartRouter(pancakeSmartRouter).exactInputSingle(param1);
        
        // 3. token => weth
        IERC20(token).approve(pancakeSmartRouter, amountOut1);
        uint256 amountOut2 = IPancakeSmartRouter(pancakeSmartRouter).exactInputSingle(IPancakeSmartRouter.ExactInputSingleParams({
            tokenIn: token,
            tokenOut: weth,
            fee: fee,
            recipient: address(this),
            amountIn: amountOut1,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0            
        }));

        // 4. weth => eth, send eth to user
        IWETH9(weth).withdraw(amountOut2);
        payable(msg.sender).sendValue(amountOut2);
    }

    function pancakeV3EthToToken(
        address token,
        uint24 fee,
        uint256 amountOutMin
    ) external payable {
        // 1. eth => weth
        uint256 amountIn = msg.value;
        IWETH9(weth).deposit{value: amountIn}();

        // 2. weth => token
        IERC20(weth).approve(pancakeSmartRouter, amountIn);
        uint256 amountOut = IPancakeSmartRouter(pancakeSmartRouter).exactInputSingle(IPancakeSmartRouter.ExactInputSingleParams({
            tokenIn: weth,
            tokenOut: token,
            fee: fee,
            recipient: address(this),
            amountIn: amountIn,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0               
        }));
        emit Swap(weth, token, msg.value, amountOut);
    }

    function pancakeV3TokenToEth(
        address token,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMin
    ) external onlyAdmin {
        // 1. token => weth
        uint256 amountOut = IPancakeSmartRouter(pancakeSmartRouter).exactInputSingle(IPancakeSmartRouter.ExactInputSingleParams({
            tokenIn: token,
            tokenOut: weth,
            fee: fee,
            recipient: address(this),
            amountIn: amountIn,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0               
        }));
        // 2. weth => eth, send eth to user
        IWETH9(weth).withdraw(amountOut);
        payable(msg.sender).sendValue(amountOut);

        emit Swap(token, weth, amountIn, amountOut);
    }

    function pancakeV2EthToToken(
        address token,
        uint256 amountOutMin
    ) external payable {
        // 1. eth => token
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;
        uint256 amountOut = IPancakeSmartRouter(pancakeSmartRouter).swapExactTokensForTokens{value: msg.value}(msg.value, amountOutMin, path, address(this));
        emit Swap(weth, token, msg.value, amountOut);
    }

    function pancakeV2TokenToEth(
        address token,
        uint256 amountIn,
        uint256 amountOutMin
    ) external onlyAdmin {
        // 1. token => weth
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = weth;
        IERC20(token).approve(pancakeSmartRouter, amountIn);
        uint256 amountOut = IPancakeSmartRouter(pancakeSmartRouter).swapExactTokensForTokens(amountIn, amountOutMin, path, address(this));
        // 2. weth => eth, send eth to user
        IWETH9(weth).withdraw(amountOut);
        payable(msg.sender).sendValue(amountOut);
        emit Swap(token, weth, amountIn, amountOut);
    }

    function uniswapV2TestSwap(
        address token,
        uint256 deadline
    ) external payable {
        // 1. eth => weth
        uint256 amountIn = msg.value;
        IWETH9(weth).deposit{value: amountIn}();

        // 2.swap:  weth => token
        IERC20(weth).approve(uniswapV2Router01, amountIn);
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;
        uint256[] memory amounts = IUniswapV2Router01(uniswapV2Router01).swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this),
            deadline
        );
        uint256 amountOut1 = amounts[amounts.length - 1];

        // 3. swap: token => weth
        IERC20(token).approve(uniswapV2Router01, amountIn);
        path[0] = token;
        path[1] = weth;
        amounts = IUniswapV2Router01(uniswapV2Router01).swapExactTokensForTokens(
            amountOut1,
            0,
            path,
            address(this),
            deadline
        );
        uint256 amountOut2 = amounts[amounts.length - 1];

        // 4. weth => eth
        IWETH9(weth).withdraw(amountOut2);
        payable(msg.sender).sendValue(amountOut2);
    }

    function uniswapV3TestSwap(
        address token,
        uint24 fee,
        uint256 deadline
    ) external payable {
        // 1. eth => weth;
        IWETH9(weth).deposit{value: msg.value}();

        // 2. swap: weth => token
        IERC20(weth).approve(uniswapV3SmartRouter, msg.value);
        uint256 amountOut1 = IUniswapV3Router(uniswapV3SmartRouter).exactInputSingle(IUniswapV3Router.ExactInputSingleParams({
            tokenIn: weth,
            tokenOut: token,
            fee: fee,
            recipient: address(this),
            deadline: deadline,
            amountIn: msg.value,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        }));

        // 3. swap: token => weth
        IERC20(token).approve(uniswapV3SmartRouter, amountOut1);
        uint256 amountOut2 = IUniswapV3Router(uniswapV3SmartRouter).exactInputSingle(IUniswapV3Router.ExactInputSingleParams({
            tokenIn: token,
            tokenOut: weth,
            fee: fee,
            recipient: address(this),
            deadline: deadline,
            amountIn: amountOut1,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        }));

        // 4. weth => eth
        IWETH9(weth).withdraw(amountOut2);
        payable(msg.sender).sendValue(amountOut2);
    }

    function uniswapV2EthToToken(
        address token,
        uint256 amountOutMin,
        uint256 deadline
    ) external payable {
        // 1. eth => weth
        IWETH9(weth).deposit{value: msg.value}();

        // 2. swap: weth => token
        IERC20(weth).approve(uniswapV2Router01, msg.value);
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;
        uint256[] memory amounts = IUniswapV2Router01(uniswapV2Router01).swapExactTokensForTokens(
            msg.value,
            amountOutMin,
            path,
            address(this),
            deadline
        );
        uint256 amountOut = amounts[amounts.length - 1];
        emit Swap(weth, token, msg.value, amountOut);
    }

    function uniswapV2TokenToEth(
        address token,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external onlyAdmin {
        // 1. token => weth
        address [] memory path = new address[](2);
        path[0] = token;
        path[1] = weth;
        uint256[] memory amounts = IUniswapV2Router01(uniswapV2Router01).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline
        );
        uint256 amountOut = amounts[amounts.length - 1];

        // 2. weth => eth
        IWETH9(weth).withdraw(amountOut);
        payable(msg.sender).sendValue(amountOut);
        emit Swap(token, weth, amountIn, amountOut);
    }

    function uniswapV3EthToToken(
        address token,
        uint24 fee,
        uint256 amountOutMin,
        uint256 deadline
    ) external payable {
        // 1. eth => weth
        IWETH9(weth).deposit{value: msg.value}();

        // 2. weth => token
        IERC20(weth).approve(uniswapV3SmartRouter, msg.value);
        uint256 amountOut = IUniswapV3Router(uniswapV3SmartRouter).exactInputSingle(IUniswapV3Router.ExactInputSingleParams({
            tokenIn: weth,
            tokenOut: token,
            fee: fee,
            recipient: address(this),
            deadline: deadline,
            amountIn: msg.value,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0
        }));
        emit Swap(weth, token, msg.value, amountOut);
    }
    
    function uniswapV3TokenToEth(
        address token,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external onlyAdmin {
        // 1. token => weth
        uint256 amountOut = IUniswapV3Router(uniswapV3SmartRouter).exactInputSingle(IUniswapV3Router.ExactInputSingleParams({
            tokenIn: token,
            tokenOut: weth,
            fee: fee,
            recipient: address(this),
            deadline: deadline,
            amountIn: amountIn,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0
        }));

        // 2. weth => eth
        IWETH9(weth).withdraw(amountOut);
        payable(msg.sender).sendValue(amountOut);
        emit Swap(token, weth, amountIn, amountOut);
    }

    function withdrawToken(
        address token
    ) external onlyAdmin {

        uint256 amount = IERC20(token).balanceOf(address(this));
        if (token == weth) {
            IWETH9(weth).withdraw(amount);
            payable(msg.sender).sendValue(amount);
        } else {
            IERC20(token).transfer(msg.sender, amount);
        }
    }

    function withdrawETH() external  onlyAdmin {
        uint256 amount = address(this).balance;
        payable(msg.sender).sendValue(amount);
    }

    receive() external payable {}
}