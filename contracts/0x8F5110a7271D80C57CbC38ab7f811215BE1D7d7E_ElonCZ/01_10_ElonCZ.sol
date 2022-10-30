// SPDX-License-Identifier: AGPL-3.0-or-later

/*

🔥 Telegram: https://twitter.com/ElonCZ_eth

🐦 Twitter: https://t.me/ElonCZ_ETH

🌐 Website: https://www.eloncz.xyz/

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IDividendSplitter.sol";

contract ElonCZ is ERC20, Ownable {

    uint256 public supply;
    uint256 public canSwapTokens;

    // % of the supply
    uint256 public maxWalletPercent = 5;
    uint256 public maxTxSupply = 5;
    uint256 public maxWallet;
    uint256 public maxTx;

    // allow to exclude address from fees or/and max txs
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    mapping(address => bool) public automatedMarketMakerPairs;
    
    IDividendSplitter private dividendSplitter;

    bool public tradingActive = false; // toggle trading
    uint256 public blockDelay = 5;
    mapping(address => uint256) private _accountTransferTimestamp;
    bool private swapping;

    address public marketingWallet;


    constructor(address _uniswapV2RouterAddress, address _dividendSplitterAddress) ERC20("ElonCZ", "ECZ") {
        uint256 totalSupply = 1 * 1e13 * 1e6; // 10,000,000,000,000
        supply = totalSupply;

        // Exclude owner, contract, dead and router from max txs and fees
        excludeFromFees(owner(), true);
        excludeFromMaxTx(owner(), true);

        excludeFromFees(address(this), true);
        excludeFromMaxTx(address(this), true);
       
        excludeFromFees(address(0xdead), true);
        excludeFromMaxTx(address(0xdead), true);

        dividendSplitter = IDividendSplitter(_dividendSplitterAddress);

        // UniV2 Router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);
        excludeFromMaxTx(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        // UniV2 LP
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTx(address(uniswapV2Pair), true);
        automatedMarketMakerPairs[address(uniswapV2Pair)] = true;

        // limits
        maxTx = (supply * maxTxSupply) / 100;
        canSwapTokens = (supply * 5) / 10000;
        maxWallet = (supply * maxWalletPercent) / 100;

        marketingWallet = owner();

        _approve(owner(), address(uniswapV2Router), totalSupply);
        _mint(msg.sender, totalSupply);
    }

    /* ---- Setters ---- */

    function enableTrading() external onlyOwner {
        tradingActive = true;
    }

    function updateLimitsPercent(uint256 _maxTx, uint256 _maxWallet) external onlyOwner {
        maxTxSupply = _maxTx;
        maxWalletPercent = _maxWallet;
        updateLimits();
    }

    function updateMarketingWallet(address _new) external onlyOwner {
        marketingWallet = _new;
    }

    function excludeFromMaxTx(address _account, bool _status) public onlyOwner {
        _isExcludedMaxTransactionAmount[_account] = _status;
    }

    function excludeFromFees(address _account, bool _status) public onlyOwner {
        _isExcludedFromFees[_account] = _status;
    }

    function updateBlockDelay(uint256 _new) external onlyOwner {
        blockDelay = _new;
    }

    /* ---- View ---- */

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    /* ---- Brain ---- */

    function updateLimits() private {
        maxTx = (supply * maxTxSupply) / 100;
        canSwapTokens = (supply * 5) / 10000;
        maxWallet = (supply * maxWalletPercent) / 100;
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
                require(_accountTransferTimestamp[tx.origin] < block.number, "Only one purchase per block allowed.");
                _accountTransferTimestamp[tx.origin] = block.number + blockDelay;
            }
            if (isBuying && !_isExcludedMaxTransactionAmount[to]) { // buy case
                require(amount <= maxTx, "Buy transfer amount exceeds the maxTx");
                require(amount + balanceOf(to) <= maxWallet, "Buy transfer amount exceeds maxWalletAmount");
            } else if (isSelling && !_isExcludedMaxTransactionAmount[from]) {  // sell case
                require(amount <= maxTx, "Sell transfer amount exceeds the maxTx");
            } else if (!_isExcludedMaxTransactionAmount[to]) { // classic transfert case
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
            }
        }

        bool canSwap = balanceOf(address(this)) >= canSwapTokens;

        if (canSwap && !swapping && !isBuying && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            retrieveSwap();
            swapping = false;
        }

        uint256 fees = 0;
        uint256 tokensForBurn = 0;

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            (fees, tokensForBurn) = dividendSplitter.splitDividend(isSelling, isBuying, amount);
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

    function swapTokensToWETH(uint256 tokenAmount) private {
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

    function retrieveSwap() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;
        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > canSwapTokens * 20) {
            contractBalance = canSwapTokens * 20;
        }

        swapTokensToWETH(contractBalance);

        // Send native token to marketing wallet
        (success, ) = address(marketingWallet).call{value: address(this).balance}("");
    }

    receive() external payable {}

}