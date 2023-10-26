// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@uniswap/swap-router-contracts/contracts/interfaces/IV2SwapRouter.sol";
import "@uniswap/swap-router-contracts/contracts/interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract TGBot is Ownable{    

    using SafeERC20 for IERC20;

    uint immutable _baseProportion = 10000;
    uint public gas = 2e15;
    uint public feeProportion = 100;
    address weth;
    IV2SwapRouter uniswapV2Router02;
    IERC20 token;
    mapping(address => address) referral;


    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    constructor(address weth_, IV2SwapRouter uniswapV2Router02_, IERC20 token_) {
        weth = weth_;
        uniswapV2Router02 = uniswapV2Router02_;
        token = token_;
    }

    function setFee(uint feeProportion_) external onlyOwner{
        feeProportion = feeProportion_;
    }

    function swapETHToToekn() external payable {
        uint amountIn = msg.value - gas;
        uint balance = token.balanceOf(address(this));
        IWETH(weth).deposit{value: amountIn}();
        IERC20(weth).safeApprove(address(uniswapV2Router02), amountIn);
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = address(token);
        uniswapV2Router02.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this)
        );
        balance = token.balanceOf(address(this)) - balance;
        uint fee = balance * feeProportion / _baseProportion;
        if (referral[msg.sender] != address(0)) token.safeTransfer(referral[msg.sender], fee / 5);
        token.safeTransfer(msg.sender, balance - fee);
    }

    function swapToeknToETH(uint amountIn) external payable {
        require(msg.value >= gas);
        uint balance = payable(address(this)).balance;
        token.safeTransferFrom(msg.sender, address(this), amountIn);
        uint fee = amountIn * feeProportion / _baseProportion;
        if (referral[msg.sender] != address(0)) token.safeTransfer(referral[msg.sender], fee / 5);
        amountIn = amountIn - fee;
        token.approve(address(uniswapV2Router02), amountIn);
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = weth;
        uniswapV2Router02.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this)
        );
        IWETH(weth).withdraw(IERC20(weth).balanceOf(address(this)));
        balance = payable(address(this)).balance - balance;
        payable(msg.sender).transfer(balance);
    }

    function invite(address referral_) external {
        require(referral[msg.sender] == address(0), 'Has already been invited');
        referral[msg.sender] = referral_;
    }

    function withdrawERC20(address erc20) public onlyOwner {
        IERC20(erc20).transfer(msg.sender, IERC20(erc20).balanceOf(address(this)));
    }

    function withdrawETH(address erc20) public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}