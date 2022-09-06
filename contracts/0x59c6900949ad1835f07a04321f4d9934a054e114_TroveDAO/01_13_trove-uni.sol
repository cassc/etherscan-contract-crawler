// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;
 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Router01.sol";
import "../interfaces/IUniswapV2Router02.sol";

import "../interfaces/IMevRepel.sol";
import "../dependencies/Controller.sol";

contract TroveDAO is ERC20, Ownable, Controller {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    MEVRepel mevrepel;  
 
    bool private swapping;
 
    address private marketingWallet;
    address private communityWallet;
 
    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;
 
    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public mevRepelActive = true;
    bool public swapEnabled = false;
    bool public enableEarlySellTax = true;
 
     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
 
    // Seller Map
    mapping (address => bool) private _holderMigrationLimit;
 
    // Blacklist Map
    mapping (address => bool) private _blacklist;
    bool public transferDelayEnabled = true;

    bool public feesEnabled = true;
    bool _useWhaleIncentive = true;
    uint256 public buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buyLiquidityFee;
    uint256 public buyCommunityFee;
 
    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellLiquidityFee;
    uint256 public sellCommunityFee;
 
    uint256 public earlySellLiquidityFee;
    uint256 public earlySellMarketingFee;
    uint256 public earlySellCommunityFee;
 
    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    uint256 public tokensForCommunity;
 
    // block number of opened trading
    uint256 launchedAt;
    uint256 launchedTime;
 
    // exclude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;
 
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
 
    event ExcludeFromFees(address indexed account, bool isExcluded);
 
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
 
    event marketingWalletUpdated(address indexed newWallet, address indexed oldWallet);
 
    event communityWalletUpdated(address indexed newWallet, address indexed oldWallet);
 
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
  
    constructor() ERC20("Trove DAO", "TROVE") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
 
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
 
        // set buy fees
        buyMarketingFee = 5;
        buyLiquidityFee = 4;
        buyCommunityFee = 1;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyCommunityFee;

        // set sell fees
        sellMarketingFee = 4;
        sellLiquidityFee = 5;
        sellCommunityFee = 1;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellCommunityFee;
 
        // set early sell fees
        earlySellLiquidityFee = 20;
        earlySellMarketingFee = 8;
	    earlySellCommunityFee = 2;

        uint256 totalSupply = 1 * 1e9 * 1e18; // 1 Billion
 
        maxTransactionAmount = totalSupply * 30 / 1000; 
        maxWallet = totalSupply * 30 / 1000;
        swapTokensAtAmount = totalSupply * 10 / 10000;
 
        marketingWallet = address(owner()); // set as marketing wallet
        communityWallet = address(owner()); // set as community wallet
 
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
        require(!_blacklist[to] && !_blacklist[from], "You have been blacklisted from transfering tokens");

        // prevent dodging early sell tax
        if (_holderMigrationLimit[from] == true && (block.timestamp <= launchedTime + (7 days))) {
            require(_isExcludedFromFees[to] || from == uniswapV2Pair || to == uniswapV2Pair, "Not allowed");
        }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        //mev repellant
        if (tradingActive && mevRepelActive) {
           bool notmev;
           address orig = tx.origin;
           try mevrepel.isMEV(from,to,orig) returns (bool mev) {
              notmev = mev;
           } catch { revert(); }
          require(notmev, "MEV Bot Detected");
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
 
        // anti bot logic
        if (block.number <= (launchedAt + 2) && 
                to != uniswapV2Pair && 
                to != address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
            ) { 
            _blacklist[to] = true;
        }
 
        // early sell logic
        bool isBuy = from == uniswapV2Pair;
        if (!isBuy && enableEarlySellTax) {
            if (_holderMigrationLimit[from] == true &&
                (block.timestamp <= launchedTime + (7 days)))  {
                sellLiquidityFee = earlySellLiquidityFee;
                sellMarketingFee = earlySellMarketingFee;
		        sellCommunityFee = earlySellCommunityFee;
                sellTotalFees = sellMarketingFee + sellLiquidityFee + sellCommunityFee;
            }
            else {
                sellLiquidityFee = 4;
                sellMarketingFee = 5;
                sellCommunityFee = 1;
                sellTotalFees = sellMarketingFee + sellLiquidityFee + sellCommunityFee;
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

            //avoid swapping more than amount set
            contractTokenBalance = swapTokensAtAmount;
 
            swapBack();
 
            swapping = false;
        }

        if(feesEnabled) {
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
                    fees = amount * sellTotalFees / 100;
                    tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                    tokensForCommunity += fees * sellCommunityFee / sellTotalFees;
                    tokensForMarketing += fees * sellMarketingFee / sellTotalFees;
                }
                // on buy
                else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {  

                    //dynamic whale incentive
                    if(_useWhaleIncentive) {
                        uint256 slippagePercent = fees / (balanceOf(uniswapV2Pair) + amount);
                        uint256 _whaleFee = buyTotalFees;

                        if(slippagePercent < buyTotalFees) {
                            _whaleFee = buyTotalFees;
                        } else if(slippagePercent > 40) {
                            _whaleFee = buyTotalFees - 4;
                        } else {
                            _whaleFee = buyTotalFees - 3;
                        }
                        if(_whaleFee % 2 != 0) {
                            buyTotalFees - 2;
                        }
        
                        fees = amount * _whaleFee / 100;

                    } else {
                        fees = amount * buyTotalFees / 100;
                    }

                    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                    tokensForCommunity += fees * buyCommunityFee / buyTotalFees;
                    tokensForMarketing += fees * buyMarketingFee / buyTotalFees;
                }
                
    
                if(fees > 0){    
                    super._transfer(from, address(this), fees);
                }
    
                amount -= fees;
            }
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
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing + tokensForCommunity;
        bool success;
 
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}
 
        if(contractBalance > swapTokensAtAmount * 20){
          contractBalance = swapTokensAtAmount * 20;
        }
 
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance - liquidityTokens;
 
        uint256 initialETHBalance = address(this).balance;
 
        swapTokensForEth(amountToSwapForETH); 
 
        uint256 ethBalance = address(this).balance - initialETHBalance;
 
        uint256 ethForMarketing = ethBalance * tokensForMarketing / totalTokensToSwap;
        uint256 ethForCommunity = ethBalance* tokensForCommunity / totalTokensToSwap;
        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForCommunity;
 
 
        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForCommunity = 0;
 
        (success,) = address(communityWallet).call{value: ethForCommunity}("");
 
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }
 
        (success,) = address(marketingWallet).call{value: address(this).balance}("");
    }

    function burnTrove(uint256 amount) external { 
        _burn(msg.sender, amount);
    }

    // ADMIN FUNCTIONS
    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
        launchedAt = block.number;
        launchedTime = block.timestamp;
    }

    function setMev(address _mevrepel) external onlyOwner {
        mevrepel = MEVRepel(_mevrepel);
        mevrepel.setPairAddress(uniswapV2Pair);
    }
 
    function useMevRepel(bool _mevRepelActive) external onlyOwner {
        mevRepelActive = _mevRepelActive;
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
 
    function setEarlySellTax(bool onoff) external onlyOwner  {
        enableEarlySellTax = onoff;
    }
 
    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
        require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
        require(newAmount <= totalSupply() * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
        swapTokensAtAmount = newAmount;
        return true;
    }
 
    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 1000)/1e18, "Cannot set maxTransactionAmount lower than 0.1%");
        maxTransactionAmount = newNum * (10**18);
    }
 
    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 5 / 1000)/1e18, "Cannot set maxWallet lower than 0.5%");
        maxWallet = newNum * (10**18);
    }
 
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }
 
    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner(){
        swapEnabled = enabled;
    }

    function updateFeesEnabled(bool enabled) external onlyOwner(){
        feesEnabled = enabled;
    }
 
    function updateBuyFees(uint256 _marketingFee, uint256 _liquidityFee, uint256 _communityFee) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyLiquidityFee = _liquidityFee;
        buyCommunityFee = _communityFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyCommunityFee;
        require(buyTotalFees <= 20, "Must keep fees at 20% or less");
    }
 
    function updateSellFees(uint256 _marketingFee, uint256 _liquidityFee, uint256 _communityFee, uint256 _earlySellLiquidityFee, uint256 _earlySellMarketingFee, uint256 _earlySellCommunityFee) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellLiquidityFee = _liquidityFee;
        sellCommunityFee = _communityFee;
        earlySellLiquidityFee = _earlySellLiquidityFee;
        earlySellMarketingFee = _earlySellMarketingFee;
	    earlySellCommunityFee = _earlySellCommunityFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellCommunityFee;
        require(sellTotalFees <= 25, "Must keep fees at 25% or less");
    }
 
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }
 
    function useWhaleIncentive(bool enabled) public onlyOwner {
        _useWhaleIncentive = enabled;
    }
 
    function blacklistAccount (address account, bool isBlacklisted) public onlyOwner {
        _blacklist[account] = isBlacklisted;
    }
 
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
 
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
 
    function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
        emit marketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }
 
    function updateCommunityWallet(address newWallet) external onlyOwner {
        emit communityWalletUpdated(newWallet, communityWallet);
        communityWallet = newWallet;
    }

    // BRIDGE OPERATOR ONLY REQUIRES 2BA - TWO BLOCKCHAIN AUTHENTICATION //
    function unlock(address account, uint256 amount) external onlyOperator {
        _mint(account, amount);
    }

    function lock(address account, uint256 amount) external onlyOperator {
        _burn(account, amount);
    }

    function airdrop(address[] calldata recipients, uint256[] calldata values) external onlyOwner {
        _approve(owner(), owner(), totalSupply());
        for (uint256 i = 0; i < recipients.length; i++) {
            transferFrom(msg.sender, recipients[i], values[i] * 10 ** decimals());
            _holderMigrationLimit[recipients[i]] = true;
        }
    }
}