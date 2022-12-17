// SPDX-License-Identifier: Unverified

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Tsunagari is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private _swapping;

    address private feeWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;

    mapping(address => uint256) private _holderLastTransferTimestamp;

    uint256 private _marketingFee;
    uint256 private _additionalSellFee;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;

    mapping(address => uint256) private _holderFirstBuyTimestamp;

    mapping(address => bool) private automatedMarketMakerPairs;

    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    constructor() ERC20("Tsunagari", "GARI") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), DAI);
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 totalSupply = 1_000_000_000 * 1e18;

        maxTransactionAmount = (totalSupply * 5) / 1000;
        maxWallet = (totalSupply * 10) / 1000;
        swapTokensAtAmount = (totalSupply * 15) / 10000;

        _marketingFee = 10;
        _additionalSellFee = 30;

        feeWallet = address(owner());
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _approve(owner(), address(_uniswapV2Router), type(uint256).max);

        ERC20(DAI).approve(address(_uniswapV2Router), type(uint256).max);
        ERC20(DAI).approve(address(this), type(uint256).max);

        _mint(owner(), totalSupply);
    }

    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
        require(newAmount >= (totalSupply() * 1) / 100000);
        require(newAmount <= (totalSupply() * 5) / 1000);
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(newNum >= ((totalSupply() * 1) / 1000) / 1e18);
        maxTransactionAmount = newNum * 1e18;
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= ((totalSupply() * 5) / 1000) / 1e18);
        maxWallet = newNum * 1e18;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateFees(uint256 marketingFee, uint256 sellFee) external onlyOwner {
        _marketingFee = marketingFee;
        _additionalSellFee = sellFee;
        require(_marketingFee + _additionalSellFee <= 30);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair);
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }

    function updateFeeWallet(address newWallet) external onlyOwner {
        feeWallet = newWallet;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function getFee() public view returns (uint256) {
        return _marketingFee;
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0));
        require(to != address(0));
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
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                } else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
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

        if (!automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        if (takeFee) {
            uint256 totalFees = _marketingFee;
            if (automatedMarketMakerPairs[to]) {
                totalFees = totalFees + _additionalSellFee;
            }
            if (totalFees > 0) {
                fees = amount.mul(totalFees).div(100);
                if (fees > 0) {
                    super._transfer(from, address(this), fees);
                }
                amount -= fees;
            }
        }

        super._transfer(from, to, amount);
    }

    function _swapTokensForDai(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = DAI;

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            feeWallet,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0) return;
        if (contractBalance > swapTokensAtAmount) {
            contractBalance = swapTokensAtAmount;
        }
        uint256 amountToSwapForDAI = contractBalance;
        _swapTokensForDai(contractBalance);
    }

    function forceSwap() external onlyOwner {
        _swapTokensForDai(balanceOf(address(this)));
    }

    function forceSend() external onlyOwner {
        uint256 balance = ERC20(DAI).balanceOf(address(this));
        _approve(address(this), address(uniswapV2Router), balance);
        ERC20(DAI).transfer(msg.sender, balance);
    }

    receive() external payable {}
}