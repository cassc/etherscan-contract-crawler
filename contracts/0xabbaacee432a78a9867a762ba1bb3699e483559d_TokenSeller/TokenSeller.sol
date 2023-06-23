/**
 *Submitted for verification at Etherscan.io on 2023-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract TokenSeller {
    IUniswapV2Router02 public immutable uniswapRouter;
    address public immutable feeRecipient;
    uint256 public immutable feePercentage;
    address public immutable WETHAddress;

    constructor(
        address _uniswapRouter,
        address _feeRecipient,
        uint256 _feePercentage,
        address _WETHAddress
    ) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        feeRecipient = _feeRecipient;
        feePercentage = _feePercentage;
        WETHAddress = _WETHAddress;
    }

    function sellTokens(address tokenAddress, uint256 amountIn, uint256 amountOutMin) external {
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amountIn);

        uint256 feeAmount = (amountIn * feePercentage) / 100;
        uint256 amountInAfterFee = amountIn - feeAmount;

        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = WETHAddress;

        IERC20(tokenAddress).approve(address(uniswapRouter), amountInAfterFee);
        IERC20(tokenAddress).transfer(feeRecipient, feeAmount);

        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountInAfterFee,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp + 600
        );
    }
}