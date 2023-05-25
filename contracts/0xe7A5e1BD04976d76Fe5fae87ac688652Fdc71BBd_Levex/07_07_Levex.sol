/*

Levex - A new age margin trading protocol.

Web - https://levex.one
Telegram - https://t.me/levex_chat
Twitter - https://twitter.com/Levex_one

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Levex is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;

    address public immutable uniswapV2Pair;
    address public devWallet;
    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromMaxWallet;

    uint256 public swapTokensAtAmount;
    uint256 public buyDevFee;
    uint256 public buyLiquidityFee;
    uint256 public buyTotalFees;
    uint256 public sellDevFee;
    uint256 public sellLiquidityFee;
    uint256 public sellTotalFees;
    uint256 public maxWallet;

    bool public swapBackEnabled = true;
    bool public limitsInEffect = true;
    bool public tradingActive;
    bool private swapping;

    constructor() ERC20("Levex", "LVX") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), USDC);

        uint256 totalSupply = 1000000000e18;
        maxWallet = totalSupply * 2 / 100;

        swapTokensAtAmount = (totalSupply * 5) / 100000; // 0.005%

        buyDevFee = 2;
        buyLiquidityFee = 1;
        buyTotalFees = buyDevFee + buyLiquidityFee;
        sellDevFee = 2;
        sellLiquidityFee = 1;
        sellTotalFees = sellDevFee + sellLiquidityFee;

        devWallet = owner();

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(0x0000), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(0xdead), true);
        excludeFromMaxWallet(address(0x0000), true);

        _mint(msg.sender, totalSupply);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool isBuy = from == uniswapV2Pair;
        bool isSell = to == uniswapV2Pair;

        if(!tradingActive && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) require(false, "Trading has not started yet");

        if(limitsInEffect && !_isExcludedFromMaxWallet[to] && !swapping) {
            if(isBuy) {
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded (buy)");
            }
            if(!isBuy && !isSell) {
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded (transfer)");
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if (canSwap && swapBackEnabled && !swapping && to == uniswapV2Pair && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        uint256 tokensForLiquidity = 0;

        if (takeFee) {
            if (to == uniswapV2Pair && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity = (fees * sellLiquidityFee) / sellTotalFees;
            }
            else if (from == uniswapV2Pair && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity = (fees * buyLiquidityFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            if (tokensForLiquidity > 0) {
                super._transfer(address(this), uniswapV2Pair, tokensForLiquidity);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForUSDC(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            devWallet,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0) {
            return;
        }

        swapTokensForUSDC(contractBalance);
    }

    receive() external payable {}

    function updateDevWallet(address newWallet) external onlyOwner {
        devWallet = newWallet;
    }

    function updateSwapBackEnabled(bool enabled) external onlyOwner {
        swapBackEnabled = enabled;
    }

    function updateBuyFee(uint256 _devFee, uint256 _liquidityFee) external onlyOwner {
        buyDevFee = _devFee;
        buyLiquidityFee = _liquidityFee;
        buyTotalFees = buyDevFee + buyLiquidityFee;
        require(buyTotalFees <= 10, "Fees > 10%");
    }

    function updateSellFees(uint256 _devFee, uint256 _liquidityFee) external onlyOwner {
        sellDevFee = _devFee;
        sellLiquidityFee = _liquidityFee;
        sellTotalFees = sellDevFee + sellLiquidityFee;
        require(sellTotalFees <= 10, "Must keep fees at 10% or less");
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool) {
        require(newAmount >= (totalSupply() * 1) / 100000, "< 0.001% total supply.");
        require(newAmount <= (totalSupply() * 5) / 1000, "> 0.5% total supply.");
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxWallet(uint256 newAmount) external onlyOwner {
        require(newAmount >= (totalSupply() * 5 / 1000) / 1e18, "Cannot set maxWallet lower than 0.5%");
        maxWallet = newAmount * 1e18;
    }

    function enableTrading() public onlyOwner {
        tradingActive = true;
    }

    function enableLimits(bool _limitsInEffect) public onlyOwner {
        limitsInEffect = _limitsInEffect;
    }

    function rescue(address token) public onlyOwner {
        ERC20 Token = ERC20(token);
        uint256 balance = Token.balanceOf(address(this));
        if(balance > 0) Token.transfer(_msgSender(), balance);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function excludeFromMaxWallet(address account, bool excluded) public onlyOwner {
        _isExcludedFromMaxWallet[account] = excluded;
    }

    function isExcludedFromMaxWallet(address account) public view returns (bool) {
        return _isExcludedFromMaxWallet[account];
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }
}