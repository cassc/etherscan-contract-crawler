// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract BxSwap {
    using SafeERC20 for IERC20;

    /// @notice Receive function to allow contract to accept ETH
    receive() external payable {}

    /// @notice Fallback function in case receive function is not matched
    fallback() external payable {}

    /// @notice Address to send tip funds to
    address payable public bxAddress;

    /// @notice Trade details
    struct Trade {
        uint amountIn;
        uint amountOut;
        address[] path;
        address payable to;
        uint256 deadline;
    }

    constructor(address payable _bxAddress) {
        bxAddress = _bxAddress;
    }

    /**
     * @notice Swap ETH for tokens and pay amount of ETH input as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param tipAmount amount of ETH to pay as tip
     */
    function swapExactETHForTokensWithTip(
        IUniswapV2Router02 router,
        Trade calldata trade,
        uint256 tipAmount
    ) external payable {
        require(tipAmount > 0, "tip amount must be > 0");
        require(msg.value >= tipAmount, "must send ETH to cover tip");

        _tip(tipAmount);
        uint amountIn = msg.value - tipAmount;
        _swapExactETHForTokens(router, amountIn, trade.amountOut, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap ETH for tokens and pay amount of ETH input as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     * @param tipAmount amount of ETH to pay as tip
     */
    function swapETHForExactTokensWithTip(
        IUniswapV2Router02 router,
        Trade calldata trade,
        uint256 tipAmount
    ) external payable {
        require(tipAmount > 0, "tip amount must be > 0");
        require(msg.value >= tipAmount, "must send ETH to cover tip");

        _tip(tipAmount);
        uint amountIn = msg.value - tipAmount;
        _swapETHForExactTokens(router, amountIn, trade.amountOut, trade.path, trade.to, trade.deadline);
    }


    /**
     * @notice Swap tokens for tokens and pay ETH amount as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     */
    function swapExactTokensForTokensWithTip(
        IUniswapV2Router02 router,
        Trade calldata trade
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tip(msg.value);
        _swapExactTokensForTokens(router, trade.amountIn, trade.amountOut, trade.path, trade.to, trade.deadline);
    }

    /**
      * @notice Swap tokens for tokens and pay ETH amount as tip
      * @param router Uniswap V2-compliant Router contract
      * @param trade Trade details
      */
    function swapTokensForExactTokensWithTip(
        IUniswapV2Router02 router,
        Trade calldata trade
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tip(msg.value);
        _swapTokensForExactTokens(router, trade.amountOut, trade.amountIn, trade.path, trade.to, trade.deadline);
    }

    /**
     * @notice Swap tokens for ETH and pay amount of ETH as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     */
    function swapExactTokensForETHWithTip(
        IUniswapV2Router02 router,
        Trade calldata trade
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tip(msg.value);
        _swapExactTokensForETH(router, trade.amountIn, trade.amountOut, trade.path, trade.to, trade.deadline);
    }


    /**
     * @notice Swap tokens for ETH and pay amount of ETH as tip
     * @param router Uniswap V2-compliant Router contract
     * @param trade Trade details
     */
    function swapTokensForExactETHWithTip(
        IUniswapV2Router02 router,
        Trade calldata trade
    ) external payable {
        require(msg.value > 0, "tip amount must be > 0");
        _tip(msg.value);
        _swapTokensForExactETH(router, trade.amountOut, trade.amountIn, trade.path, trade.to, trade.deadline);
    }

    /**
        INTERNAL FUNCTIONS
     */

    function _tip(uint amount) internal {
        bxAddress.transfer(amount);
    }

    /**
     * @notice Internal implementation of swap ETH for tokens
     * @param amountIn Amount to swap
     * @param amountOutMin Minimum amount out
     * @param path Path for swap
     * @param deadline Block timestamp deadline for trade
     */
    function _swapExactETHForTokens(
        IUniswapV2Router02 router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) internal {
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountIn}(amountOutMin, path, to, deadline);
    }

    /**
     * @notice Internal implementation of swap ETH for tokens
     * @param amountOut Amount of ETH out
     * @param amountInMax Max amount in
     * @param path Path for swap
     * @param to Address to receive ETH
     * @param deadline Block timestamp deadline for trade
     */
    function _swapETHForExactTokens(
        IUniswapV2Router02 router,
        uint amountInMax,
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) internal {
        router.swapETHForExactTokens{value: amountInMax}(amountOut, path, to, deadline);
    }

    /**
     * @notice Internal implementation of swap tokens for tokens
     * @param amountIn Amount to swap
     * @param amountOutMin Minimum amount out
     * @param path Path for swap
     * @param deadline Block timestamp deadline for trade
     */
    function _swapExactTokensForTokens(
        IUniswapV2Router02 router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) internal {
        IERC20 fromToken = IERC20(path[0]);
        fromToken.safeTransferFrom(msg.sender, address(this), amountIn);
        fromToken.safeIncreaseAllowance(address(router), amountIn);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, to, deadline);
    }

    /**
     * @notice Internal implementation of swap tokens for tokens
     * @param amountOut Amount of tokens out
     * @param amountInMax Max amount in
     * @param path Path for swap
     * @param to Address to receive tokens
     * @param deadline Block timestamp deadline for trade
     */
    function _swapTokensForExactTokens(
        IUniswapV2Router02 router,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) internal {
        IERC20 fromToken = IERC20(path[0]);
        fromToken.safeTransferFrom(msg.sender, address(this), amountInMax);
        fromToken.safeIncreaseAllowance(address(router), amountInMax);
        router.swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline);
    }

    /**
     * @notice Internal implementation of swap tokens for ETH
     * @param amountIn Amount to swap
     * @param amountOutMin Minimum amount out
     * @param path Path for swap
     * @param deadline Block timestamp deadline for trade
     */
    function _swapExactTokensForETH(
        IUniswapV2Router02 router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) internal {
        IERC20 fromToken = IERC20(path[0]);
        fromToken.safeTransferFrom(msg.sender, address(this), amountIn);
        fromToken.safeIncreaseAllowance(address(router), amountIn);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, to, deadline);
    }

    /**
     * @notice Internal implementation of swap tokens for ETH
     * @param amountOut Amount of ETH out
     * @param amountInMax Max amount in
     * @param path Path for swap
     * @param to Address to receive ETH
     * @param deadline Block timestamp deadline for trade
     */
    function _swapTokensForExactETH(
        IUniswapV2Router02 router,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) internal {
        IERC20 fromToken = IERC20(path[0]);
        fromToken.safeTransferFrom(msg.sender, address(this), amountInMax);
        fromToken.safeIncreaseAllowance(address(router), amountInMax);
        router.swapTokensForExactETH(amountOut, amountInMax, path, to, deadline);
    }
}