// SPDX-License-Identifier: Unlicensed
// https://t.me/hodl_erc20
pragma solidity ^0.8.11;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract HODL is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant zeroAddress = address(0);
    address public constant deadAddress = address(0xdead);

    bool private swapping;
    bool public swapTrigger = true;
    bool public limitsInEffect = true;

    address public marketingWallet;
    address private developmentWallet;

    uint256 public swapTokensAtAmount;
    uint256 public maxTxAmount;
    uint256 public maxWallet;

    struct Taxes {
        uint256 marketing;
        uint256 development;
        uint256 liquidity;
        uint256 total;
    }
    Taxes public buyTax;
    Taxes public sellTax;

    uint256 private tokensForMarketing;
    uint256 private tokensForDevelopment;
    uint256 private tokensForLiquidity;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTxAmount;
    mapping(address => bool) private automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquidity(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    constructor() ERC20("HODL", "HODL") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        excludeFromMaxTxAmount(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTxAmount(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 totalSupply = 1000000000 * 10**decimals();

        maxWallet = maxTxAmount = totalSupply.mul(3).div(100);
        swapTokensAtAmount = totalSupply.mul(2).div(10000);

        marketingWallet = developmentWallet = _msgSender();

        buyTax = Taxes(15, 0, 0, 15);
        sellTax = Taxes(40, 0, 0, 40);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTxAmount(owner(), true);
        excludeFromMaxTxAmount(address(this), true);
        excludeFromMaxTxAmount(address(0xdead), true);

        _mint(_msgSender(), totalSupply);
    }

    receive() external payable {}

    function removeLimits() external onlyOwner {
        require(limitsInEffect == true, "The limits has been removed.");
        limitsInEffect = false;
    }

    function toggerSwapTrigger() external onlyOwner {
        swapTrigger = !swapTrigger;
    }

    function updateBuyTaxes(uint256 _marketing, uint256 _development, uint256 _liquidity) external onlyOwner {
        uint256 _total = _marketing + _development + _liquidity;
        buyTax = Taxes(_marketing, _development, _liquidity, _total);
    }

    function updateSellTaxes(uint256 _marketing, uint256 _development, uint256 _liquidity) external onlyOwner {
        uint256 _total = _marketing + _development + _liquidity;
        sellTax = Taxes(_marketing, _development, _liquidity, _total);
    }

    function updateMarketingWallet(address _marketingWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
    }

    function updateDevelopmentWallet(address _developmentWallet) external onlyOwner {
        developmentWallet = _developmentWallet;
    }

    function excludeFromMaxTxAmount(address _address, bool excluded) public onlyOwner {
        _isExcludedMaxTxAmount[_address] = excluded;
    }

    function excludeFromFees(address _address, bool excluded) public onlyOwner {
        _isExcludedFromFees[_address] = excluded;
        emit ExcludeFromFees(_address, excluded);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != zeroAddress, "ERC20: transfer from the zero address.");
        require(to != zeroAddress, "ERC20: transfer to the zero address.");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero.");

        if (from != owner() && to != owner() && to != zeroAddress && to != deadAddress && !swapping) {
            if (limitsInEffect == true) {
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTxAmount[to]) {
                    require(amount <= maxTxAmount, "ERC20: Buy transfer amount exceeds the max Tx amount.");
                    require(amount + balanceOf(to) <= maxWallet, "ERC20: Max wallet exceeded.");
                } else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTxAmount[from]) {
                    require(amount <= maxTxAmount, "ERC20: Sell transfer amount exceeds the max Tx amount.");
                } else if (!_isExcludedMaxTxAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "ERC20: Max wallet exceeded.");
                }
            }
        }

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if (swapTrigger && canSwap && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        if (takeFee) {
            if (automatedMarketMakerPairs[to] && sellTax.total > 0) {
                fees = amount.mul(sellTax.total).div(100);
                tokensForLiquidity += (fees * sellTax.liquidity) / sellTax.total;
                tokensForMarketing += (fees * sellTax.marketing) / sellTax.total;
                tokensForDevelopment += (fees * sellTax.development) / sellTax.total;
            }
            else if (automatedMarketMakerPairs[from] && buyTax.total > 0) {
                fees = amount.mul(buyTax.total).div(100);
                tokensForLiquidity += (fees * buyTax.liquidity) / buyTax.total;
                tokensForMarketing += (fees * buyTax.marketing) / buyTax.total;
                tokensForDevelopment += (fees * buyTax.development) / buyTax.total;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }
        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            deadAddress,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing + tokensForDevelopment;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(totalTokensToSwap);
        uint256 ethForDevelopment = ethBalance.mul(tokensForDevelopment).div(totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDevelopment;

        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForDevelopment = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquidity(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }

        (success, ) = address(marketingWallet).call{value: ethForMarketing}("");
        (success, ) = address(developmentWallet).call{value: address(this).balance}("");
    }
}