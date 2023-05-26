// SPDX-License-Identifier: MIT                                                                               
                                                    
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SafeMathUint.sol";
import "./SafeMathInt.sol";
import "./IUniswapV2Router.sol";



contract FlashInu is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    mapping (address => bool) internal authorizations;

    bool private swapping;

    address public marketingWallet;
    address public devWallet;
    
    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;
    
    uint256 public percentForLPBurn = 25; // 25 = .25%
    bool public lpBurnEnabled = true;
    uint256 public lpBurnFrequency = 3600 seconds;
    uint256 public lastLpBurnTime;
    
    uint256 public manualBurnFrequency = 30 minutes;
    uint256 public lastManualLpBurnTime;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    bool public tokenBurnEnabled = true;
    
     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public buyTotalFees;
    uint256 public marketingFee = 2; // this is in %
    uint256 public liquidityFee = 2;
    uint256 public devFee = 5;
    uint256 public tokenBurnFee = 1;
    
    uint256 public sellTotalFees;
    uint256 public extraSellTax = 0; // this is number

    mapping(address => bool) public _isBot;
    

    
    /******************/

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;


    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(address indexed newWallet, address indexed oldWallet);
    
    event devWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    
    event AutoNukeLP();
    
    event ManualNukeLP();

    constructor() ERC20("FlashInu", "FLASH") {
        authorizations[_msgSender()] = true;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        
        uint256 totalSupply = 1 * 1e9 * 1e18;
        
        maxTransactionAmount = totalSupply * 5 / 1000; // 0.5% maxTransactionAmountTxn
        maxWallet = totalSupply * 6 / 1000; // .6% maxWallet
        swapTokensAtAmount = totalSupply * 5 / 1000; // 0.5% swap wallet

       
        buyTotalFees = marketingFee + liquidityFee + devFee + tokenBurnFee;
        sellTotalFees = buyTotalFees;
        
        marketingWallet = 0x87b3D84923B7AE809eE91D6064e9BAD69143bD45; // set as marketing wallet
        devWallet = 0x8C354aB778A26797FfA7c975A3E5575D13126E90; // set as dev wallet

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(devWallet, true);
        
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(deadAddress, true);
        excludeFromMaxTransaction(marketingWallet, true);
        excludeFromMaxTransaction(devWallet, true);
        
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {

  	}

      /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }
 
    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) external onlyOwner {
        authorizations[adr] = true;
    }
 
    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) external onlyOwner {
        authorizations[adr] = false;
    }
 
    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }


    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
        lastLpBurnTime = block.timestamp;
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
    
     // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external authorized returns (bool){
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
  	    swapTokensAtAmount = newAmount;
  	    return true;
  	}
    
    function updateMaxTxnAmount(uint256 newNum) external authorized {
        require(newNum >= (totalSupply() * 1 / 1000)/1e18, "Cannot set maxTransactionAmount lower than 0.1%");
        maxTransactionAmount = newNum * (10**18);
    }

    function updateMaxWalletAmount(uint256 newNum) external authorized {
        require(newNum >= (totalSupply() * 5 / 1000)/1e18, "Cannot set maxWallet lower than 0.5%");
        maxWallet = newNum * (10**18);
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx) public authorized {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateBotStatus(address account, bool value) external authorized{
        _isBot[account] = value;
    }
    
    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external authorized(){
        swapEnabled = enabled;
    }

    function updateTokenBurnEnabled(bool enabled) external authorized(){
        require(tokenBurnEnabled !=enabled, "Values are same.");
        tokenBurnEnabled = enabled;
        if(enabled){
            buyTotalFees = marketingFee + liquidityFee + devFee + tokenBurnFee;
        }else{
            buyTotalFees = marketingFee + liquidityFee + devFee;
        }
         if(extraSellTax>0){
            sellTotalFees = buyTotalFees+ extraSellTax;
        }else{
            sellTotalFees = buyTotalFees;
        }
        require(buyTotalFees <= 20, "Must keep fees at 20% or less");
        require(sellTotalFees <= 25, "Must keep fees at 25% or less");
    }

    function updateFees(uint256 _marketingFee, uint256 _liquidityFee, uint256 _devFee, uint256 _tokenBurnFee, uint256 _extraSellTax) external authorized {
        marketingFee = _marketingFee;
        liquidityFee = _liquidityFee;
        devFee = _devFee;
        tokenBurnFee = _tokenBurnFee;
        extraSellTax = _extraSellTax;
        if(tokenBurnEnabled){
            buyTotalFees = marketingFee + liquidityFee + devFee + tokenBurnFee;
        }else{
            buyTotalFees = marketingFee + liquidityFee + devFee;
        }

        if(extraSellTax>0){
            sellTotalFees = buyTotalFees + extraSellTax;
        }else{
            sellTotalFees = buyTotalFees;
        }
        
        require(buyTotalFees <= 20, "Must keep fees at 20% or less");
        require(sellTotalFees <= 25, "Must keep fees at 25% or less");
    }

    function excludeFromFees(address account, bool excluded) public authorized {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public authorized {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
        require(newMarketingWallet != address(0), "ERC20: Marketing address can not be zero address");
        emit marketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
        excludeFromFees(marketingWallet, true);
        excludeFromMaxTransaction(marketingWallet, true);
    }
    
    function updateDevWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "ERC20: Dev address can not be zero address");
        emit devWalletUpdated(newWallet, devWallet);
        devWallet = newWallet;
        excludeFromFees(devWallet, true);
        excludeFromMaxTransaction(devWallet, true);
    }
    

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function checkTxLimit(address sender) internal view {
        if(automatedMarketMakerPairs[sender]){
            return;
        }
        require(!_isBot[sender], 'Robot detected'); 
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount >  0,'Transfer amount must be greater than zero');
        
        
        if(limitsInEffect){
            if (
                from != owner() &&
                to != owner() &&
                to != deadAddress &&
                !swapping
            ){
                if(!tradingActive){
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.  
                if (transferDelayEnabled){
                    if (automatedMarketMakerPairs[from]){
                        _holderLastTransferTimestamp[tx.origin] = block.number+20;
                    }else{
                        require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one transaction per 20 block allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number+20;
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
        
        checkTxLimit(from);
        
		uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if (contractTokenBalance >= maxTransactionAmount) {
            contractTokenBalance = maxTransactionAmount;
        }
        if( 
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            if(tokenBurnEnabled){
                uint256 burnTokens = contractTokenBalance.mul(tokenBurnFee).div(tokenBurnFee+marketingFee+devFee+liquidityFee);
                super._transfer(address(this), deadAddress, burnTokens);
                contractTokenBalance = contractTokenBalance - burnTokens;
            }
            uint256 marketingAndDevTokens = contractTokenBalance.mul(marketingFee + devFee).div(marketingFee+devFee+liquidityFee);
            uint256 liquidityTokens = contractTokenBalance - marketingAndDevTokens;
            

            swapAndSendToFee(marketingAndDevTokens);
            swapAndLiquify(liquidityTokens);


            swapping = false;
        }
        
        if(!swapping && automatedMarketMakerPairs[to] && lpBurnEnabled && block.timestamp >= lastLpBurnTime + lpBurnFrequency && !_isExcludedFromFees[from]){
            autoBurnLiquidityPairTokens();
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
            }
            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
        	    fees = amount.mul(buyTotalFees).div(100);
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
    
    function swapAndLiquify(uint256 tokens) private {
       // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
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
            owner(),
            block.timestamp
        );
    }

     function swapAndSendToFee(uint256 tokens) private  {
        bool success;
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 ethForMarketing = newBalance.mul(marketingFee).div(marketingFee + devFee);
        uint256 ethForDev = newBalance.mul(devFee).div(marketingFee + devFee);
        
        (success,) = address(devWallet).call{value: ethForDev}("");
        (success,) = address(marketingWallet).call{value: ethForMarketing}("");
    }
    
    function setAutoLPBurnSettings(uint256 _frequencyInSeconds, uint256 _percent, bool _Enabled) external onlyOwner {
        require(_frequencyInSeconds >= 600, "cannot setAutoLPBurn more often than every 10 minutes.");
        require(_percent <= 1000 && _percent >= 0, "Must set auto LP burn percent between 0% and 10%");
        lpBurnFrequency = _frequencyInSeconds;
        percentForLPBurn = _percent;
        lpBurnEnabled = _Enabled;
    }
    
    function autoBurnLiquidityPairTokens() internal returns (bool){
        
        lastLpBurnTime = block.timestamp;
        
        // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(uniswapV2Pair);
        
        // calculate amount to burn
        uint256 amountToBurn = liquidityPairBalance.mul(percentForLPBurn).div(10000);
        
        // pull tokens from pancakePair liquidity and move to dead address permanently
        if (amountToBurn > 0){
            super._transfer(uniswapV2Pair, deadAddress, amountToBurn);
        }
        
        //sync price since this is not in a swap transaction!
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        pair.sync();
        emit AutoNukeLP();
        return true;
    }

    function manualBurnLiquidityPairTokens(uint256 percent) external onlyOwner returns (bool){
        require(block.timestamp > lastManualLpBurnTime + manualBurnFrequency , "Must wait for cooldown to finish");
        require(percent <= 1000, "May not nuke more than 10% of tokens in LP");
        lastManualLpBurnTime = block.timestamp;
        
        // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(uniswapV2Pair);
        
        // calculate amount to burn
        uint256 amountToBurn = liquidityPairBalance.mul(percent).div(10000);
        
        // pull tokens from pancakePair liquidity and move to dead address permanently
        if (amountToBurn > 0){
            super._transfer(uniswapV2Pair, deadAddress, amountToBurn);
        }
        
        //sync price since this is not in a swap transaction!
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        pair.sync();
        emit ManualNukeLP();
        return true;
    }

    function sweep(address to) external onlyOwner {
        bool success;
        (success,) = address(to).call{value: address(this).balance}("");
    }
    
}