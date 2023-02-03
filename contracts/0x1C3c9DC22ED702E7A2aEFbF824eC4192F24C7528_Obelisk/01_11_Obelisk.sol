// SPDX-License-Identifier: MIT

/*
                ⠀⠀⠀⠀⠀⠀⢀⠀⠀⠀⠀⠀⠀⢠⡆⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀
                ⠀⠀⠀⠀⠀⠀⠈⣷⣄⠀⠀⠀⠀⣾⣷⠀⠀⠀⠀⣠⣾⠃⠀⠀⠀⠀⠀⠀⠀⠀
                ⠀⠀⠀⠀⠀⠀⠀⢿⠿⠃⠀⠀⠀⠉⠉⠁⠀⠀⠐⠿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀
                ⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣤⣤⣶⣶⣶⣤⣤⣄⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                ⠀⠀⠀⠀⠀⢀⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣦⣄⠀⠀⠀⠀⠀⠀
                ⠀⠀⠀⣠⣶⣿⣿⡿⣿⣿⣿⡿⠋⠉⠀⠀⠉⠙⢿⣿⣿⡿⣿⣿⣷⣦⡀⠀⠀⠀
                ⠀⢀⣼⣿⣿⠟⠁⢠⣿⣿⠏⠀⠀⢠⣤⣤⡀⠀⠀⢻⣿⣿⡀⠙⢿⣿⣿⣦⠀⠀
                ⣰⣿⣿⡟⠁⠀⠀⢸⣿⣿⠀⠀⠀⢿⣿⣿⡟⠀⠀⠈⣿⣿⡇⠀⠀⠙⣿⣿⣷⡄
                ⠈⠻⣿⣿⣦⣄⠀⠸⣿⣿⣆⠀⠀⠀⠉⠉⠀⠀⠀⣸⣿⣿⠃⢀⣤⣾⣿⣿⠟⠁
                ⠀⠀⠈⠻⣿⣿⣿⣶⣿⣿⣿⣦⣄⠀⠀⠀⢀⣠⣾⣿⣿⣿⣾⣿⣿⡿⠋⠁⠀⠀
                ⠀⠀⠀⠀⠀⠙⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠁⠀⠀⠀⠀⠀
                ⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠛⠛⠿⠿⠿⠿⠿⠿⠛⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀
                ⠀⠀⠀⠀⠀⠀⠀⢰⣷⡦⠀⠀⠀⢀⣀⣀⠀⠀⠀⢴⣾⡇⠀⠀⠀⠀⠀⠀⠀⠀
                ⠀⠀⠀⠀⠀⠀⠀⣸⠟⠁⠀⠀⠀⠘⣿⡇⠀⠀⠀⠀⠙⢷⠀⠀⠀⠀⠀⠀⠀⠀
                ⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠻⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀

* The Mysterious Obelisk of the Old World: Eye of Providence?

* For centuries, the towering stone structure known as the Old World Obelisk has stood
* as a symbol of mystery and intrigue. Standing tall in the heart of the ancient city,
* this impressive feat of engineering has confounded scholars and archaeologists alike,
* with no one able to uncover its true purpose or origin.
* 
* But now, a team of experts has been assembled, determined to unlock the secrets of
* the Old World Obelisk and finally shed light on this enduring mystery.
* With cutting-edge technology at their fingertips and a wealth of knowledge and
* experience at their disposal, they embark on a journey that will take them deep
* into the heart of the ancient civilization and beyond.
* 
* What will they find? Will the Obelisk reveal its secrets, or will it continue
* to defy explanation? Only time will tell, as the team embarks on a journey
* filled with danger, discovery, and the pursuit of knowledge. Will you join them on
* this thrilling adventure and help unravel the mysteries of the Old World Obelisk?
*/

pragma solidity 0.8.7;

import "IUniswapV2Factory.sol";
import "IUniswapV2Pair.sol";
import "IUniswapV2Router02.sol";

import "Address.sol";
import "Ownable.sol";
import "ERC20.sol";

contract Obelisk is ERC20, Ownable {
    
    enum TransactionType {
        BUY,
        SELL,
        TRANSFER
    }

    bool private initComleted = false;
    bool private tradeEnabled = false;
    bool private inSwap = false;
    bool private swapAndLiquifyEnabled = false;

    address public marketingWallet;
    IUniswapV2Router02 public immutable uniswapV2Router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 private buyMarketingFee = 20;
    uint256 private buyLiquidityFee = 20;

    uint256 private sellMarketingFee = 20;
    uint256 private sellLiquidityFee = 20;

    uint256 public buyFee;
    uint256 public sellFee;

    uint256 public maxTxLimit;
    uint256 public maxWalletLimit;

    uint256 private tokensForMarketing;
    uint256 private tokensForLiquidity;

    uint256 private swapTokensAtAmount;

    mapping(address => bool) public excludedFromFees;
    mapping(address => bool) private marketMakerPairs;

    event LPAdded(address indexed newLp);
    event FeesUpdated(uint256 marketingFee, uint256 liquidityFee);
    event LimitsUpdated(uint256 txLimit, uint256 walletLimit);
    event ExcludedFromFees(address indexed account, bool value);
    event SwapAndLiquifyEnabled(bool value);
    event InitCompleted();

    constructor() ERC20("Eye of Providence", "Obelisk") {
        address owner = _msgSender();

        marketingWallet = owner;

        buyFee = buyMarketingFee + buyLiquidityFee;
        sellFee = sellMarketingFee + sellLiquidityFee;

        setExcludeFromFees(owner, true);
        setExcludeFromFees(address(this), true);
        setExcludeFromFees(marketingWallet, true);

        uint256 totalSupply = 1_000_000 * 10 ** 18;

        _mint(owner, totalSupply);
    }

    // =============================================================
    //                         MODIFIERS
    // =============================================================
    modifier swapping() {
        if(!inSwap) {
            inSwap = true;
            _;
            inSwap = false;
        }
    }

    // =============================================================
    //                         ADMIN METHODS
    // =============================================================

    /**
     * @dev Initialize a Liquidity Pool (LP)
     * @param newPair Address of the new LP
     * emit {LPAdded} Event that the LP has been added
     * Only callable by the contract owner.
     */
    function initializeLP(address newPair) external onlyOwner {
        marketMakerPairs[newPair] = true;
        emit LPAdded(newPair);
    }

    /**
     * @dev Update the fees for buying tokens
     * @param _marketingFee The fee for marketing the tokens
     * @param _liquidityFee The fee for providing liquidity to the pool
     * emit {FeesUpdated} Event that the fees have been updated
     * Only callable by the contract owner.
     */
    function updateBuyFees(uint256 _marketingFee, uint256 _liquidityFee) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyLiquidityFee = _liquidityFee;
        buyFee = _marketingFee + _liquidityFee;

        require(buyFee <= 100, "Fees cannot be more than 10%");
        emit FeesUpdated(_marketingFee, _liquidityFee);
    }

    /**
    * @dev Update the fees for selling tokens
    * @param _marketingFee The fee for marketing the tokens
    * @param _liquidityFee The fee for providing liquidity to the pool
    * emit FeesUpdated Event that the fees have been updated
    * Only callable by the contract owner.
    */
    function updateSellFees(uint256 _marketingFee, uint256 _liquidityFee) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellLiquidityFee = _liquidityFee;
        sellFee = _marketingFee + _liquidityFee;

        require(sellFee <= 100, "Fees cannot be more than 10%");
        emit FeesUpdated(_marketingFee, _liquidityFee);
    }

    /**
    * @dev Updates the limits for transactions and wallet storage in a smart contract.
    * @param maxTxPerc      Maximum percentage of the total supply that can be used for transactions.
    * @param maxWalletPerc  Maximum percentage of the total supply that can be stored in wallets.
    * emit LimitsUpdated Event that the limits have been updated.
    * Only callable by the contract owner.
    */
    function updateLimits(uint256 maxTxPerc, uint256 maxWalletPerc) external onlyOwner {
        uint256 supply = totalSupply();

        maxTxLimit = (supply * maxTxPerc) / 10_000;
        maxWalletLimit = (supply * maxWalletPerc) / 10_000;

        require(maxTxPerc >= 1, "Tx limit must be at least 0.1%");
        require(maxWalletPerc >= 1, "Wallet limit must be at least 0.1%");
        emit LimitsUpdated(maxTxLimit, maxWalletLimit);
    }

    /**
    * @dev Enable trading
    * emit TradeEnabled Event signaling trading has been enabled.
    * Only callable by the contract owner.
    */
    function openTrading() external onlyOwner {
        require(!tradeEnabled, "Trade already open");
        tradeEnabled = true;
        uint256 supply = totalSupply();

        maxTxLimit = (supply * 33) / 10000;
        maxWalletLimit = (supply * 33) / 10000;
        swapTokensAtAmount = (supply * 50) / 100000;
    }

    /**
    * @dev Mark the contract initialization as completed
    * emit InitCompleted Event signaling that the contract initialization has been completed.
    * Only callable by the contract owner.
    */
    function setCompleted() external onlyOwner {
        require(!initComleted, "Already initialized");
        initComleted = true;
        emit InitCompleted();
    }

    /**
    * @dev Exclude account from fees
    * emit ExcludedFromFees Event signaling the account has been excluded.
    * Only callable by the contract owner.
    */
    function setExcludeFromFees(address account, bool excluded) public onlyOwner {
        excludedFromFees[account] = excluded;
        emit ExcludedFromFees(account, excluded);
    }

    /**
    * @dev Set the amount of tokens for swap
    * Only callable by the contract owner.
    */
    function setSwapTokensAtAmount(uint256 newLimit) external onlyOwner {
        swapTokensAtAmount = newLimit;
    }

    /**
    * @dev Enable/Disable the swap to liquidity
    * emit SwapAndLiquifyEnabled Event signaling the swap back to liquidity feature has been enabled.
    * Only callable by the contract owner.
    */
    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner {
        swapAndLiquifyEnabled = true;
        emit SwapAndLiquifyEnabled(enabled);
    }

    /**
    * @dev Withdraw ETH from the contract
    * Only callable by the contract owner.
    */
    function withdrawStuckEth() external {
        (bool success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }

    /**
    * @dev Perform a manual swap to remove clog
    * Only callable by the contract owner.
    */
    function unclog() public onlyOwner swapping {
        uint256 contractBalance = balanceOf(address(this));
        _swapExactTokensForETHSupportingFeeOnTransferTokens(contractBalance);
        (bool success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }


    // =============================================================
    //                         INTERNAL
    // =============================================================

    
    function _swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amount) private {
        if (amount == 0) return;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router02.WETH();
        _approve(address(this), address(uniswapV2Router02), amount);
        uniswapV2Router02.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp);
    }
    
    function _addLiquidityETH(uint256 tokenAmount, uint256 ethAmount) internal {
        _approve(address(this), address(uniswapV2Router02), tokenAmount);
        uniswapV2Router02.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            marketingWallet,
            block.timestamp
        );
    }

    function _swapBack(uint256 contractBalance) internal swapping {
        uint256 totalTokensToSwap = tokensForMarketing + tokensForLiquidity;
        if (contractBalance == 0 || totalTokensToSwap == 0) return;

        if (contractBalance > swapTokensAtAmount  * 5)
            contractBalance = swapTokensAtAmount * 5;

        uint256 liquidityTokens = contractBalance * tokensForLiquidity / 2;
        uint256 tokensForSwap = contractBalance - liquidityTokens;

        uint256 currentWeiBalance = address(this).balance;

        _swapExactTokensForETHSupportingFeeOnTransferTokens(tokensForSwap);

        uint256 weiEarned = address(this).balance - currentWeiBalance;
        uint256 ethForTreasury = weiEarned  * tokensForMarketing / totalTokensToSwap;
        uint256 ethForLiquidity = weiEarned - ethForTreasury;

        tokensForMarketing = 0;
        tokensForLiquidity = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0)
            _addLiquidityETH(liquidityTokens, ethForLiquidity);

        (bool success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");

        bool takeFee = true;
        uint256 fees = 0;
        TransactionType txType = (marketMakerPairs[from])
            ? TransactionType.BUY
            : (marketMakerPairs[to])
            ? TransactionType.SELL
            : TransactionType.TRANSFER;

        if (!tradeEnabled) {
            require(excludedFromFees[from] || excludedFromFees[to], "Not allowed");
        }
        if (txType == TransactionType.BUY &&
            to != address(uniswapV2Router02) &&
            !excludedFromFees[to]
        ) {
            require(amount <= maxTxLimit, "Transfer amount exceeds the maxTxLimit");
            require(balanceOf(to) + amount <= maxWalletLimit, "Transfer amount exceeds the maxWalletAmount");
        }
        if (txType == TransactionType.SELL &&
            from != address(uniswapV2Router02) &&
            !excludedFromFees[from]  
        ) {
            require(amount <= maxTxLimit, "transfer amount exceeds the maxTxLimit.");
        }
        if (excludedFromFees[from] ||
            excludedFromFees[to] ||
            excludedFromFees[tx.origin] ||
            (txType == TransactionType.TRANSFER)
        ) takeFee = false;

        uint256 contractBalance = balanceOf(address(this));
        bool canSwap = (contractBalance > swapTokensAtAmount) &&
            (txType == TransactionType.SELL);

        if (
            canSwap &&
            swapAndLiquifyEnabled &&
            !inSwap &&
            !excludedFromFees[from] &&
            !excludedFromFees[to] && 
            !excludedFromFees[tx.origin]
        ) {
            _swapBack(contractBalance);
        }

        if (takeFee &&
            txType == TransactionType.BUY &&
            buyFee > 0
        ) {
            fees = (amount * buyFee) / 1000;
            tokensForLiquidity += (fees * buyLiquidityFee) / buyFee;
            tokensForMarketing += (fees * buyMarketingFee) / buyFee;   
        } else if (takeFee &&
                   txType == TransactionType.SELL &&
                   sellFee > 0
        ) {
            fees = (amount * sellFee) / 1000;
            tokensForLiquidity += (fees * sellLiquidityFee) / sellFee;
            tokensForMarketing += (fees * sellMarketingFee) / sellFee;   
        }
        super._transfer(from, to, amount - fees);
        if (fees > 0) {
            super._transfer(from, address(this), fees);
        }
    }
    receive() external payable {}
    fallback() external payable {}
}