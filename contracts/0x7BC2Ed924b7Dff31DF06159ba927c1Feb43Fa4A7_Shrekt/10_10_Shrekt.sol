// SPDX-License-Identifier: MIT
/**
Shrekt
Website: https://www.shrekt.lol/ 
Twitter: https://twitter.com/shrekterc 
Telegram: https://t.me/shrektentry

 */
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Shrekt is ERC20, Ownable {
    using SafeMath for uint256;
 
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
 
    bool private swapping;
 
    address private marketingWallet;
    address private devWallet;
 
    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;
 
    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
 
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = true;
 
    uint256 public buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buyLiquidityFee;
    uint256 public buyDevFee;
 
    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellLiquidityFee;
    uint256 public sellDevFee;
 
    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    uint256 public tokensForDev;
    uint256 launchedAt;
 
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;
    mapping (address => bool) public automatedMarketMakerPairs;
 
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
 
    event ExcludeFromFees(address indexed account, bool isExcluded);
 
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
 
    event marketingWalletUpdated(address indexed newWallet, address indexed oldWallet);
 
    event devWalletUpdated(address indexed newWallet, address indexed oldWallet);
 
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
 
    constructor() ERC20("Shrekt", "Shrekt") {
 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
 
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
 
        uint256 _buyMarketingFee = 0;
        uint256 _buyLiquidityFee = 0;
        uint256 _buyDevFee = 0;
 
        uint256 _sellMarketingFee = 0;
        uint256 _sellLiquidityFee = 0;
        uint256 _sellDevFee = 0;
 
        // Shrekislovelife
        uint256 totalSupply = 747354756835433 * 1e18;
 
        maxTransactionAmount = totalSupply * 20 / 1000; // 2%
        maxWallet = totalSupply * 20 / 1000; // 2% 
        swapTokensAtAmount = totalSupply * 5 / 10000; // 0.05%
 
        buyMarketingFee = _buyMarketingFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyDevFee = _buyDevFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyDevFee;
 
        sellMarketingFee = _sellMarketingFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellDevFee = _sellDevFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellDevFee;
 
        marketingWallet = address(0xB71E7965504e243645435B4aA4d60E3e3c5A5f99);
        devWallet = address(0xB71E7965504e243645435B4aA4d60E3e3c5A5f99);
 
        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
 
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
 
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }
 
    receive() external payable {
 
    }
 
    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
        launchedAt = block.number;
    }
 
    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool){
        limitsInEffect = false;
        return true;
    }
 
    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner returns (bool){
        transferDelayEnabled = false;
        return true;
    }
 
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateFees(
        uint256 _buyDevFee,
        uint256 _buyLiquidityFee,
        uint256 _buyMarketingFee,
        uint256 _sellDevFee,
        uint256 _sellLiquidityFee,
        uint256 _sellMarketingFee
    ) external onlyOwner {
        buyDevFee = _buyDevFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyMarketingFee = _buyMarketingFee;
        buyTotalFees = buyDevFee + buyLiquidityFee + buyMarketingFee;
        sellDevFee = _sellDevFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellMarketingFee = _sellMarketingFee;
        sellTotalFees = sellDevFee + sellLiquidityFee + sellMarketingFee;
    }
 
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
 
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
 
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
         if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
 
        if(limitsInEffect){
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ){
                if(!tradingActive){
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }
 
                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.  
                if (transferDelayEnabled){
                    if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)){
                        require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }
 
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                        require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                        require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
 
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                        require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                }
                else if(!_isExcludedMaxTransactionAmount[to]){
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
        }
 
        uint256 contractTokenBalance = balanceOf(address(this));
 
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
 
        if( 
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
 
            swapBack();
 
            swapping = false;
        }
 
        bool takeFee = !swapping;
 
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
 
        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForDev += fees * sellDevFee / sellTotalFees;
                tokensForMarketing += fees * sellMarketingFee / sellTotalFees;
            }
            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForDev += fees * buyDevFee / buyTotalFees;
                tokensForMarketing += fees * buyMarketingFee / buyTotalFees;
            }
 
            if(fees > 0){    
                super._transfer(from, address(this), fees);
            }
 
            amount -= fees;
        }
 
        super._transfer(from, to, amount);
    }
 
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
 
        _approve(address(this), address(uniswapV2Router), tokenAmount);
 
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
 
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
 
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }
 
    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing + tokensForDev;
        bool success;
 
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}
 
        if(contractBalance > swapTokensAtAmount * 20){
          contractBalance = swapTokensAtAmount * 20;
        }
 
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
 
        uint256 initialETHBalance = address(this).balance;
 
        swapTokensForEth(amountToSwapForETH); 
 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(totalTokensToSwap);
        uint256 ethForDev = ethBalance.mul(tokensForDev).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDev;
 
 
        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForDev = 0;
 
        (success,) = address(devWallet).call{value: ethForDev}("");
 
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }
 
        (success,) = address(marketingWallet).call{value: address(this).balance}("");
    }
}