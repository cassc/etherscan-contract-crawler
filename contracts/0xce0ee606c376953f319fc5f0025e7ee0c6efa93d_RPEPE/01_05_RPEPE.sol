// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract RPEPE is ERC20 {

    uint256 public MAX_SUPPLY = 100_000_000_000_000 ether;

    address public taxWallet;

    constructor() ERC20("recursive PEPE", "RPEPE"){
        _mint(address(this), MAX_SUPPLY);
        _transfer(address(this), msg.sender, 70_000_000_000_000 ether);
        taxWallet = msg.sender;
    }

    function manualTakeFee(uint256 feeAmount) external {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), feeAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            feeAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        payable(taxWallet).transfer(address(this).balance);
    }
}