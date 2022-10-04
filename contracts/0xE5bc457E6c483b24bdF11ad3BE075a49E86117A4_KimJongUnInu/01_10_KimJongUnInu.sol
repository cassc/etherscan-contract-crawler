// SPDX-License-Identifier: MIT

/*

$KJUI | Kim Jong Un Inu

https://t.me/KimJongUnInu

Tokenomics
Supply: 1,000,000
Tax: 2/2
Max TX: 2% [20000 $KJUI] 

*/

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/ILiquidityManager.sol";

contract KimJongUnInu is ERC20, Ownable {
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    // it's a % of the supply
    uint256 public walletPercent = 2;
    uint256 public transactionPercent = 2;

    uint256 public delayDigit = 5;

    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch

    uint256 public maxWallet;
    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;

    uint256 public supply;
    address public devWallet;

    bool public tradingActive = false; // toggle trading

    bool private swapping;
    ILiquidityManager private liquidityManager;

    // allow to exclude address from fees or/and max txs
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    mapping(address => bool) public automatedMarketMakerPairs;

    constructor(address _liquidityManagerAddress) ERC20("KIM JONG UN INU", "KJUI") {
        devWallet = owner();

        uint256 totalSupply = 1 * 1e6 * 1e6; // 1,000,000
        supply = totalSupply;

        // Exclude owner, contract, dead and router from max txs and fees
        excludeFromFees(owner(), true);
        excludeAddressFromMaxTx(owner(), true);

        excludeFromFees(address(this), true);
        excludeAddressFromMaxTx(address(this), true);
       
        excludeFromFees(address(0xdead), true);
        excludeAddressFromMaxTx(address(0xdead), true);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeAddressFromMaxTx(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        // creation UniV2 LP
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeAddressFromMaxTx(address(uniswapV2Pair), true);
        automatedMarketMakerPairs[address(uniswapV2Pair)] = true;

        // max tx, max wallet
        maxTransactionAmount = (supply * transactionPercent) / 100;
        swapTokensAtAmount = (supply * 5) / 10000; // 0.05% swap wallet;
        maxWallet = (supply * walletPercent) / 100;

        _approve(owner(), address(uniswapV2Router), totalSupply);
        _mint(msg.sender, totalSupply);

        liquidityManager = ILiquidityManager(_liquidityManagerAddress);
    }

    /* == Setters == */

    function enableTrading() external onlyOwner {
        tradingActive = true;
    }

    function updateDelayDigit(uint256 _new) external onlyOwner {
        delayDigit = _new;
    }

    function updateTransactionPercent(uint256 _new) external onlyOwner {
        transactionPercent = _new;
        updateLimits();
    }

    function updateWalletPercent(uint256 _new) external onlyOwner {
        walletPercent = _new;
        updateLimits();
    }

    function updateDevWallet(address newWallet) external onlyOwner {
        devWallet = newWallet;
    }

    function excludeAddressFromMaxTx(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }


    /* == View == */

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    /* == Core == */

    function updateLimits() private {
        maxTransactionAmount = (supply * transactionPercent) / 100;
        swapTokensAtAmount = (supply * 5) / 10000;
        maxWallet = (supply * walletPercent) / 100;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(tradingActive || _isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active");
        require(from != address(0) && to != address(0), "Cannot transfer from/to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool isSelling = automatedMarketMakerPairs[to];
        bool isBuying = automatedMarketMakerPairs[from];

        // checking transfert conditions
        if (from != owner() && to != owner() && to != address(0xdead) && !swapping) {
            if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one purchase per block allowed.");
                _holderLastTransferTimestamp[tx.origin] = block.number + delayDigit;
            }
            if (isBuying && !_isExcludedMaxTransactionAmount[to]) { // buy case
                require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount");
                require(amount + balanceOf(to) <= maxWallet, "Buy transfer amount exceeds maxWalletAmount");
            } else if (isSelling && !_isExcludedMaxTransactionAmount[from]) {  // sell case
                require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount");
            } else if (!_isExcludedMaxTransactionAmount[to]) { // classic transfert case
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
            }
        }

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;

        if (canSwap && !swapping && !isBuying && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        uint256 fees = 0;
        uint256 tokensForBurn = 0;

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            (fees, tokensForBurn) = liquidityManager.repartitionCalculation(isSelling, isBuying, amount);
            if (fees > 0) {
                super._transfer(from, address(this), fees);
                if (tokensForBurn > 0) {
                    _burn(address(this), tokensForBurn);
                    supply = totalSupply();
                    updateLimits();
                    tokensForBurn = 0;
                }
                amount -= fees;
            }
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // path of token to weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // no limit
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;
        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        swapTokensForEth(contractBalance);

        // Send native token to dev wallet
        (success, ) = address(devWallet).call{value: address(this).balance}("");
    }

    receive() external payable {}

}