// SPDX-License-Identifier: MIT       

// This space is ruled by bold and reckless degens. 
// Like in a heist, it's easy to win... if you are smart enough.
                                                    
pragma solidity ^0.8.0;

import "./Context.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Router01.sol";

contract TheHeist is ERC20, ERC20Burnable, Ownable {

    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;

    address public marketingWallet;
    uint256 public swapTokensAtAmount;

    uint256 public maxTransactionAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    
     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public buyFees;
    uint256 public sellFees;
    
    uint256 public tokensForFee;
    
    /******************/

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event marketingWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event jigsawContractUpdated(address indexed newWallet, address indexed oldWallet);
    event BoughtEarly(address indexed sniper);
    event withdrawForeignTokensFromContract(address token, uint256 amount);

    constructor() ERC20("The Heist", "TH") {
        
        // set Uniswap Router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        
        // set AMM Pair
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        // set total supply
        uint256 totalSupply = 1 * 1e6 * 1e18;
        
        // set limits
        maxTransactionAmount = totalSupply * 1 / 100; // 1% maxTransactionAmountTxn
        maxWallet = totalSupply * 2 / 100; // 2% maxWallet
        swapTokensAtAmount = totalSupply * 5 / 10000; // 0.05% swap wallet

        // set buy fees
        buyFees = 2;
        
        // set sell fees
        sellFees = 2;
        
        // set marketing wallet
        marketingWallet = address(owner());

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
    
        // _mint is an internal function in ERC20.sol that is only called here, and CANNOT be called ever again
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {

  	}

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        require(!tradingActive, "Trading is already active, cannot relaunch.");
 
        // add the liquidity
        require(address(this).balance > 0, "Must have ETH on contract to launch");
        require(balanceOf(address(this)) > 0, "Must have Tokens on contract to launch");

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), balanceOf(address(this)));
        // add the liquidity taking in consideration the slippage
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, msg.sender, block.timestamp);

        tradingActive = true;
        swapEnabled = true;
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
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
  	    swapTokensAtAmount = newAmount;
  	    return true;
  	}
    
    // change max transaction amount
    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 1000)/1e18, "Cannot set maxTransactionAmount lower than 0.1%");
        maxTransactionAmount = newNum * (10**18);
    }

    // change max wallet amount
    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 5 / 1000)/1e18, "Cannot set maxWallet lower than 0.5%");
        maxWallet = newNum * (10**18);
    }
    
    // add address to be excluded from max transaction restrictions
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    // update buy fees
    function updateBuyFees(uint256 _Fee) external onlyOwner {
        buyFees = _Fee;
        require(buyFees <= 20, "Must keep fees at 20% or less");
    }
    
    // update sell fees
    function updateSellFees(uint256 _Fee) external onlyOwner {
        sellFees = _Fee;
        require(sellFees <= 25, "Must keep fees at 25% or less");
    }

    // add address to be excluded from fees
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    // add or remove AMM pairs
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    // add or remove AMM pairs (onyl contract)
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    // update marketing wallet
    function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
        emit marketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }

    // check if address is excluded from fees
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    // rules for transfers
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if( amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        if(limitsInEffect){
            if (from != owner() &&
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
                    if (to != owner() && 
                        to != address(uniswapV2Router) && 
                        to != address(uniswapV2Pair)){
                        require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }
                 
                //when buy
                if (automatedMarketMakerPairs[from] && 
                    !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
                
                //when sell
                else if (automatedMarketMakerPairs[to] && 
                        !_isExcludedMaxTransactionAmount[from]) {
                        require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                }
                else if(!_isExcludedMaxTransactionAmount[to]){
                        require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
        }
        
		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap &&
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
        if( _isExcludedFromFees[from] || 
            _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;

        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            // on sell
            if( automatedMarketMakerPairs[to] && 
                sellFees > 0){
                fees = amount.mul(sellFees).div(100);
                tokensForFee += fees;
            }
            // on buy
            else if(automatedMarketMakerPairs[from] && 
                buyFees > 0) {
        	    fees = amount.mul(buyFees).div(100);
                tokensForFee += fees;
            }
            
            if(fees > 0){    
                super._transfer(from, address(this), fees);
            }
        	
        	amount -= fees;
        }

        super._transfer(from, to, amount);

    }

    // withdraw tokens if stuck or someone sends to the address
    function withdrawForeignTokens(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this) || !tradingActive, "Can't withdraw native tokens while trading is active");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit withdrawForeignTokensFromContract(_token, _contractBalance);
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    // swap tokens for eth
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap accepting any amount of ETH
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForFee;

        bool success;
        
        if( contractBalance == 0 || 
            totalTokensToSwap == 0) {
            return;
        }
        if( contractBalance > swapTokensAtAmount * 20){
            contractBalance = swapTokensAtAmount * 20;
        }

        uint256 initialETHBalance = address(this).balance;

        // swap only marketing tokens
        swapTokensForEth(totalTokensToSwap); 
        
        uint256 ethForMarketing = address(this).balance.sub(initialETHBalance);

        tokensForFee = 0;
        
        (success,) = address(marketingWallet).call{value: ethForMarketing}("");
    }
}