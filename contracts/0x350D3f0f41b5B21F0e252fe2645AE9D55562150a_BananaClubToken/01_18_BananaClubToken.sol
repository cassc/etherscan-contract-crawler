// SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./LazyMath.sol";
import "./BananaFactory.sol";
import "./BananaRouter.sol";
import "./BANANA20.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";

pragma solidity 0.8.2;
//File: BananaToken.sol
/*
*         
*/
contract BananaClubToken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private _swapping;

    address public treasury;
    address public buyBack;
    
    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;
        
    bool public limitsInEffect = true;
    bool public tradingActive = false;

    uint256 public buyTotalFees;
    uint256 private _buyTreasuryFee;
    uint256 private _buyLiquidityFee;
    uint256 private _buyBuyBackFee;

    
    uint256 public sellTotalFees;
    uint256 private _sellTreasuryFee;
    uint256 private _sellLiquidityFee;
    uint256 private _sellBuyBackFee;

    
    uint256 private _tokensForTreasury;
    uint256 private _tokensForLiquidity;
    uint256 private _tokensForBuyBack;
    
    /******************/
    // exclude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event TreasuryUpdated(address newAddress);
    event BuyBackUpdated(address newAddress);
    event LPSwap(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event tradingEnabled(bool tradingActive);
    event MaxTxnUpdated(uint256 newNum);
    event MaxWalletAmount(uint256 newNum);
    event MaxTxnExcluded(address updAds);
    event BuyFeeUpdated(uint256 marketingFee, uint256 liquidityFee, uint256 buyBackFee);
    event SellFeeUpdated(uint256 marketingFee, uint256 liquidityFee, uint256 buyBackFee);
    event ExcludedFromFee(address account, bool excluded);
    event limitsRemoved(bool limitsInEffect);
    event swapTokensAt(uint newAmount);
    event feesCollected(bool);



    constructor() ERC20("BananaClubToken", "BCT") ERC20Permit("BananaClubToken") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        
        uint256 buyTreasuryFee = 1;
        uint256 buyLiquidityFee = 0;
        uint256 buyBuyBackFee = 1;

        uint256 sellTreasuryFee = 1;
        uint256 sellLiquidityFee = 1;
        uint256 sellBuyBackFee = 1;
        
        uint256 totalSupply = 1e8 * 1e9; // 100 million 1e8 = 1(00,000,000) * 1e9 ((9).000000000 decimals)
        
        // Initial Deployed settings maybe be changed later with individual functions - Set all fees, Max AMTs
        maxTransactionAmount = totalSupply * 3 / 1000; // 0.3% maxTransactionAmountTxn 300,000 Tokens
        maxWallet = totalSupply * 2 / 100; // 2% maxWallet 2,000,000 Tokens
        swapTokensAtAmount = totalSupply * 3 / 10000; // 0.03% swap wallet 30,000 tokens

        _buyTreasuryFee = buyTreasuryFee;
        _buyLiquidityFee = buyLiquidityFee;
        _buyBuyBackFee = buyBuyBackFee;

        buyTotalFees = _buyTreasuryFee + _buyLiquidityFee + _buyBuyBackFee;
        
        _sellTreasuryFee = sellTreasuryFee;
        _sellLiquidityFee = sellLiquidityFee;
        _sellBuyBackFee = sellBuyBackFee;

        sellTotalFees = _sellTreasuryFee + _sellLiquidityFee + _sellBuyBackFee;
        
        treasury = address(owner()); // set owner as treasury at launch. Change it after Launch with the Update Function
        buyBack = address(owner()); // set owner as buyBack at launch. Change it after Launch with the Update Function

        // exclude from paying fees or having max transaction amount Owner/this/dead
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again, this is used to Issue the initial Supply
        */
        _mint(msg.sender, totalSupply);
    }

        // three required checks in solidity
    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

     /**
     * @dev Enables Trading on Uniswap
     */
    function enableTrading() external onlyOwner {
        tradingActive = true;
        emit tradingEnabled(tradingActive);
    }

        
     /**
     * @dev Removes Max txn, and wallet limits if and when its Needed
     * cannot be turned back on. 
     */
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        emit limitsRemoved(limitsInEffect);
        return true;
    }
    
     /**
     * @dev Update how many tokens to Swap&Liquify at
     */
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool) {
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
  	    swapTokensAtAmount = newAmount;
          emit swapTokensAt(newAmount);
  	    return true;
  	}
    
     /**
     * @dev Update MaxTransaction
     */
    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 1000) / 1e9, "Cannot set maxTransactionAmount lower than 0.1%");
        maxTransactionAmount = newNum * 1e9;
        emit MaxTxnUpdated(newNum);
    }
    
     /**
     * @dev Update MaxWallet
     */
    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 5 / 1000)/1e9, "Cannot set maxWallet lower than 0.5%");
        maxWallet = newNum * 1e9;
        emit MaxWalletAmount(newNum);
    }
    
     /**
     * @dev exclude Address from MaxTxn
     */
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
        emit MaxTxnExcluded(updAds);
    }
    
     /**
     * @dev Update Buy Tax
     */
    function updateBuyFees(uint256 treasuryFee, uint256 liquidityFee, uint256 buyBackFee) external onlyOwner {
        _buyTreasuryFee = treasuryFee;
        _buyLiquidityFee = liquidityFee;
        _buyBuyBackFee = buyBackFee;

        buyTotalFees = _buyTreasuryFee + _buyLiquidityFee + _buyBuyBackFee;
        require(buyTotalFees <= 10, "Must keep fees at 10% or less");
        emit BuyFeeUpdated(treasuryFee, liquidityFee, buyBackFee);
    }
    
     /**
     * @dev Update Sell Tax
     */
    function updateSellFees(uint256 treasuryFee, uint256 liquidityFee, uint256 buyBackFee) external onlyOwner {
        _sellTreasuryFee = treasuryFee;
        _sellLiquidityFee = liquidityFee;
        _sellBuyBackFee = buyBackFee;
   
        sellTotalFees = _sellTreasuryFee + _sellLiquidityFee + _sellBuyBackFee;
        require(sellTotalFees <= 15, "Must keep fees at 15% or less");
        emit SellFeeUpdated(treasuryFee, liquidityFee, buyBackFee);
    }
    
     /**
     * @dev Exclude Address from Tax
     */
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    // function for setting AMM Pairs in the future
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
     /**
     * @dev Update Treasury Address
     */
    function updateTreasury(address newAddress) external onlyOwner {
        treasury = newAddress;
        require(newAddress != address(0),"Address cannot be Zero address");
        emit TreasuryUpdated(newAddress);
    }
    
     /**
     * @dev Update BuyBack Address
     */
    function updateBuyBack(address newAddress) external onlyOwner {
        buyBack = newAddress;
        require(newAddress != address(0),"Address cannot be Zero address");
        emit BuyBackUpdated(newAddress);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    // transfer function with required checks
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
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }

                 
                // when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
                
                // when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                }
                else if (!_isExcludedMaxTransactionAmount[to]){
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

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                _tokensForLiquidity += fees * _sellLiquidityFee / sellTotalFees;
                _tokensForTreasury += fees * _sellTreasuryFee / sellTotalFees;
                _tokensForBuyBack += fees * _sellBuyBackFee / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
        	    fees = amount.mul(buyTotalFees).div(100);
        	    _tokensForLiquidity += fees * _buyLiquidityFee / buyTotalFees;
                _tokensForTreasury += fees * _buyTreasuryFee / buyTotalFees;
                _tokensForBuyBack += fees * _buyBuyBackFee / buyTotalFees;
            }
            
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        	
        	amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
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
        
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
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

function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _tokensForLiquidity + _tokensForTreasury + _tokensForBuyBack;
        bool success;
        
        if (contractBalance == 0 || totalTokensToSwap == 0) return;
        if (contractBalance > swapTokensAtAmount * 20) {
          contractBalance = swapTokensAtAmount * 20;
        }

                // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * _tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        
        uint256 initialETHBalance = address(this).balance;

        _swapTokensForEth(amountToSwapForETH); 

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForTreasury = ethBalance.mul(_tokensForTreasury).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance.mul(_tokensForLiquidity).div(totalTokensToSwap);
        uint256 ethForBuyBack = ethBalance - ethForLiquidity - ethForTreasury;

        _tokensForLiquidity = 0;
        _tokensForTreasury = 0;
        _tokensForBuyBack = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
            emit LPSwap(amountToSwapForETH, ethForLiquidity, _tokensForLiquidity);
        }

        if (ethForTreasury > 0) {
        (success,) = address(treasury).call{value: ethForTreasury}("");
        }

        if (ethForBuyBack > 0) {
            (success,) = address(buyBack).call{value: ethForBuyBack}("");
        }
    }
    
     /**
     * @dev manually collect any eth from contract to treasury
     */
   function manualCollectFees() external onlyOwner {
        bool success;
     (success,) = address(treasury).call{value: address(this).balance}("");
     require(success, "Error on transfer, reverted");
     emit feesCollected(success);
    }
    
     /**
     * @dev Fallback function for contract to recieve.
     */
    receive() external payable {}
}