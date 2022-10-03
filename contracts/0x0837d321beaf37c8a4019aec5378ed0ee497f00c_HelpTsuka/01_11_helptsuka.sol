// SPDX-License-Identifier: MIT
// Website https://helptsuka.com

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract HelpTsuka is ERC20, Ownable {
    using SafeMath for uint256;


    address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address TSUKA = 0xc5fB36dd2fb59d3B98dEfF88425a3F425Ee469eD;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    bool private _swapping;

    address private devWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;

    uint256 private _devFee;
    uint256 private _liquidityFee;

    uint256 private _tokensForDev;
    uint256 private _tokensForLiquidity;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;

    mapping(address => bool) private automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);



    constructor() ERC20("Help Tsuka", "HELP") {
        uniswapV2Router = IUniswapV2Router02(ROUTER);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        excludeFromMaxTransaction(address(uniswapV2Router), true);
        excludeFromMaxTransaction(address(uniswapV2Pair), true);

        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 totalSupply = 5_000_000_000 * 1e18;

        maxTransactionAmount = (totalSupply * 2) / 100;
        maxWallet = (totalSupply * 2) / 100;
        swapTokensAtAmount = (totalSupply * 15) / 10000;

        _devFee = 2;
        _liquidityFee = 3;
        devWallet = owner();
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _approve(devWallet, address(uniswapV2Router), type(uint256).max);
        _approve(owner(), address(uniswapV2Router), type(uint256).max);
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        ERC20(USDC).approve(address(uniswapV2Router), type(uint256).max);
        ERC20(USDC).approve(address(this), type(uint256).max);

        ERC20(TSUKA).approve(address(uniswapV2Router), type(uint256).max);
        ERC20(TSUKA).approve(address(this), type(uint256).max);

        _mint(owner(), totalSupply);
    }

    function hatsubai() external onlyOwner {
        tradingActive = true;
    }

    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    function updateSwapTokensAtAmount(uint256 newAmount)
    external
    onlyOwner
    returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxTxnAmount(uint256 newNum)
    external
    onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set lower than 0.1%"
        );
        maxTransactionAmount = newNum * 1e18;
    }

    function updateMaxWalletAmount(uint256 newNum)
    external
    onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum * 1e18;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
    public
    onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateFees(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
        require(_liquidityFee <= 20, "liquidityFee 20% fee");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
    public
    onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateDevWallet(address newWallet) external onlyOwner {
        devWallet = newWallet;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function getFee() public view returns (uint256) {
        return _liquidityFee + _devFee;
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
        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !_swapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {} else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if (
            canSwap &&
            !_swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            _swapping = true;
            swapBack();
            _swapping = false;
        }

        bool takeFee = !_swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        if (takeFee) {
            uint256 totalFees = _liquidityFee + _devFee;
            if (totalFees > 0) {
                fees = amount.mul(totalFees).div(100);
                _tokensForLiquidity += (fees * _liquidityFee) / totalFees;
                _tokensForDev += (fees * _devFee) / totalFees;
                if (fees > 0) {
                    super._transfer(from, address(this), fees);
                }
                amount -= fees;
            }
        }

        super._transfer(from, to, amount);
    }


    function _swapTokensForUsdc(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = USDC;
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function _addLiquidityTsuka(uint256 tokenAmount, uint256 usdcAmount) private {
        uniswapV2Router.addLiquidity(
            USDC,
            TSUKA,
            usdcAmount,
            tokenAmount,
            0,
            0,
            devWallet,
            block.timestamp
        );
    }
    function _swapUsdcForTsuka(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = TSUKA;
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }



    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _tokensForLiquidity + _tokensForDev;
        if (contractBalance == 0 || totalTokensToSwap == 0) return;
        if (contractBalance > swapTokensAtAmount) {
            contractBalance = swapTokensAtAmount;
        }
        uint256 amountToSwapForUSDC = contractBalance;

        uint256 initialUSDCBalance = ERC20(USDC).balanceOf(address(this));
        _swapTokensForUsdc(amountToSwapForUSDC);
        uint256 usdcBalance = ERC20(USDC).balanceOf(address(this)).sub(initialUSDCBalance);
        uint256 usdcForMarketing = usdcBalance.mul(_tokensForDev).div(
            totalTokensToSwap
        );
        uint256 usdcForLiquidity = usdcBalance - usdcForMarketing;

        uint256 tsukaBefore = ERC20(TSUKA).balanceOf(address(this));
        uint256 usdcForTsuka = usdcForLiquidity / 2;
        _swapUsdcForTsuka(usdcForTsuka);
        uint256 tsukaLiquidityTokens = ERC20(TSUKA).balanceOf(address(this)) - tsukaBefore;


        _tokensForLiquidity = 0;
        _tokensForDev = 0;
        ERC20(USDC).transfer(devWallet, usdcForMarketing);

        if (usdcForTsuka > 0 && tsukaLiquidityTokens > 0) {
            _addLiquidityTsuka(tsukaLiquidityTokens, usdcForTsuka);
        }
    }


    receive() external payable {}
}