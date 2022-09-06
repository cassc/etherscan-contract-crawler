// SPDX-License-Identifier: NOLICENSE

/**
Zen Buddhism

“When you realize nothing is lacking, the whole world belongs to you.” – Lao Tzu.

.

TOKENOMICS
1% AUTO LIQUIDITY
1% AUTO BURN
3% MARKETING wallet

MAX BUY 1% && MAX WALLET 5% AT LAUNCH
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract Zen is Context, ERC20, Ownable {

    using SafeMath for uint256;
    mapping(address => bool) private _isExcludedFromFee;

    uint256 public buyAutoLiquidityFee;
    uint256 public buyAutoBurnFee;
    uint256 public buyMarketingFee;
    uint256 public totalBuyFees;

    uint256 public sellAutoLiquidityFee;
    uint256 public sellAutoBurnFee;
    uint256 public sellMarketingFee;
    uint256 public totalSellFees;

    uint256 public tokensForAutoLiquidity;
    uint256 public tokensForMarketing;
    uint16 public masterTaxDivisor = 10000;

    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;

    bool public tradingOpen = false;
    bool private inSwap = false;
    uint256 private TOTAL_SUPPLY = 1000000 * 1e18;
    uint256 public maxWalletAmount;
    uint256 public maxTxAmount;
    address private marketingWallet;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (address routerAddress) ERC20("Zen Buddhism", "ZEN"){
        if (routerAddress != address(0)) {
            setSwapRouter(routerAddress);
        }

        marketingWallet = owner();

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingWallet] = true;

        buyAutoLiquidityFee = 100;
        buyAutoBurnFee = 100;
        buyMarketingFee = 300;
        totalBuyFees = buyAutoLiquidityFee + buyAutoBurnFee + buyMarketingFee;

        sellAutoLiquidityFee = 100;
        sellAutoBurnFee = 100;
        sellMarketingFee = 300;
        totalSellFees = sellAutoLiquidityFee + sellAutoBurnFee + sellMarketingFee;

        maxTxAmount = TOTAL_SUPPLY / 100 + 1;
        maxWalletAmount = maxTxAmount * 5;

        _mint(_msgSender(), TOTAL_SUPPLY);

    }

    function setSwapRouter(address routerAddress) public onlyOwner {
        require(routerAddress != address(0), "Invalid router address");

        uniswapV2Router = IUniswapV2Router02(routerAddress);
        _approve(address(this), routerAddress, type(uint256).max);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());
        if (uniswapV2Pair == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from), "You are trying to transfer more than your balance");
        require(tradingOpen || _isExcludedFromFee[from] || _isExcludedFromFee[to], "Trading not enabled yet");

        if (inSwap) {
            super._transfer(from, to, amount);
            return;
        }

        if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
            require(amount <= maxTxAmount, "Exceeds the _maxTxAmount.");
            require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds the maxWalletSize.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        if (!inSwap && from != uniswapV2Pair && contractTokenBalance > 0) {
            swapAndLiquify();
            getMarketingFee();
        }

        _tokenTransfer(from, to, amount, !(_isExcludedFromFee[from] || _isExcludedFromFee[to]));
    }

    function getMarketingFee() private lockTheSwap {
        swapTokensForEth(tokensForMarketing);
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            sendETHToFee(address(this).balance);
        }
        tokensForMarketing = 0;
    }

    function swapAndLiquify() private lockTheSwap {
        uint256 half = tokensForAutoLiquidity.div(2);
        uint256 otherHalf = tokensForAutoLiquidity.sub(half);
        swapTokensForEth(half);
        uint256 contractETHBalance = address(this).balance;
        uniswapV2Router.addLiquidityETH{value : contractETHBalance}(
            address(this),
            otherHalf,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            marketingWallet,
            block.timestamp + 360
        );
        tokensForAutoLiquidity = 0;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        uniswapV2Router.swapExactTokensForETH(tokenAmount, 0, path, address(this), block.timestamp + 360);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        uint256 amountReceived = (takeFee) ? takeTaxes(sender, recipient, amount) : amount;
        super._transfer(sender, recipient, amountReceived);
    }

    function takeTaxes(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 liquidityFee;
        uint256 burnFee;
        uint256 marketingFee;
        if (from == uniswapV2Pair && totalBuyFees > 0) {
            liquidityFee = amount * buyAutoLiquidityFee / masterTaxDivisor;
            burnFee = amount * buyAutoBurnFee / masterTaxDivisor;
            marketingFee = amount * buyMarketingFee / masterTaxDivisor;
        } else if (to == uniswapV2Pair && totalSellFees > 0) {
            liquidityFee = amount * sellAutoLiquidityFee / masterTaxDivisor;
            burnFee = amount * sellAutoBurnFee / masterTaxDivisor;
            marketingFee = amount * sellMarketingFee / masterTaxDivisor;
        }

        super._burn(from, burnFee);

        tokensForAutoLiquidity += liquidityFee;
        super._transfer(from, address(this), liquidityFee);

        tokensForMarketing += marketingFee;
        super._transfer(from, address(this), marketingFee);

        uint256 feeAmount = marketingFee + burnFee + liquidityFee;
        return amount - feeAmount;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function openTrading() public onlyOwner {
        tradingOpen = true;
    }

    function setWalletandTxtAmount(uint256 _maxTxAmount, uint256 _maxWalletSize) external onlyOwner {
        require(_maxTxAmount > TOTAL_SUPPLY / 100, "Max Tx Amount need to greater than 1% total supply");
        require(_maxWalletSize > TOTAL_SUPPLY / 100, "Max Wallet Size need to greater than 1% total supply");
        maxTxAmount = _maxTxAmount;
        maxWalletAmount = _maxWalletSize;
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = TOTAL_SUPPLY;
        maxWalletAmount = TOTAL_SUPPLY;
    }

    function sendETHToFee(uint256 amount) private {
        marketingWallet.call{value : amount}("");
    }

    receive() external payable {
    }
}