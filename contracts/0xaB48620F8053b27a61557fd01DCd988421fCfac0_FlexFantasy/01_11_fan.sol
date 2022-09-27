/*        

Flex Fantasy - Experience a brand new way to play fantasy sports using the team you already have.
https://www.flex.fan/

Follow Us: https://twitter.com/Flex_FantasyApp
           https://www.instagram.com/flex_fantasy/

We're Hiring (Blockchain Engineers): https://angel.co/company/flex-fantasy/jobs

Email: [email protected]

*/

pragma solidity 0.8.10;   

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// SPDX-License-Identifier: MIT

contract FlexFantasy is ERC20, Ownable {  
    using SafeMath for uint256;   

    IUniswapV2Router02 public immutable uniswapV2Router;   
    address public immutable uniswapV2Pair;   
    address public constant deadAddress = address(0xdead);   

    bool private swapping;   

    address public marketingWallet;   
    address public devWallet;   

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

    uint256 public maxTransactionAmount;   
    uint256 public swapTokensAtAmount;   
    uint256 public maxWallet;   

    uint256 public percentForLPBurn = 25;    
    bool public lpBurnEnabled = true;   
    uint256 public lpBurnFrequency = 3600 seconds;   
    uint256 public lastLpBurnTime;   

    uint256 public manualBurnFrequency = 30 minutes;   
    uint256 public lastManualLpBurnTime;   

    bool public limitsInEffect = true;   
    bool public tradingActive = false;   
    bool public swapEnabled = false;   

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp;    // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;   

    // exclude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;   
    mapping(address => bool) public _isExcludedMaxTransactionAmount;   

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;   

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );   

    event ExcludeFromFees(address indexed account, bool isExcluded);   

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);   

    event marketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );   

    event devWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );   

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );   

    event AutoNukeLP();   

    event ManualNukeLP();   

    constructor() ERC20("Flex Fantasy", "FAN") {  
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );   

        excludeFromMaxTransaction(address(_uniswapV2Router), true);   
        uniswapV2Router = _uniswapV2Router;   

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());   
        excludeFromMaxTransaction(address(uniswapV2Pair), true);   
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);   

        uint256 _buyMarketingFee = 2;   
        uint256 _buyLiquidityFee = 2;   
        uint256 _buyDevFee = 1;   

        uint256 _sellMarketingFee = 2;   
        uint256 _sellLiquidityFee = 2;   
        uint256 _sellDevFee = 1;   

        uint256 totalSupply = 1000000000 * 1e18;   

        maxTransactionAmount = 10000000 * 1e18;    // 1% maxTransactionAmount
        maxWallet = 20000000 * 1e18;    // 2% maxWallet
        swapTokensAtAmount = totalSupply / 10000;    // 0.01% swap wallet

        buyMarketingFee = _buyMarketingFee;   
        buyLiquidityFee = _buyLiquidityFee;   
        buyDevFee = _buyDevFee;   
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyDevFee;   

        sellMarketingFee = _sellMarketingFee;   
        sellLiquidityFee = _sellLiquidityFee;   
        sellDevFee = _sellDevFee;   
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellDevFee;   

        marketingWallet = address(0x71E1f5765BB0c0665C329C5f6F5e8D8C351AdABd);    // marketing wallet
        devWallet = address(0x9901Ad163fDb5b4E243dc4393356710f9389DcD8);    //  dev wallet

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

    receive() external payable {  }

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {  
        tradingActive = true;   
        swapEnabled = true;   
        lastLpBurnTime = block.timestamp;   
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {  
        limitsInEffect = false;   
        return true;   
    }

    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner returns (bool) {  
        transferDelayEnabled = false;   
        return true;   
    }
    
    function updateMaxWalletSize(uint256 newNum) external onlyOwner {  
        require(
            newNum >= ((totalSupply() * 30) / 1000) / 1e18,
            "Cannot set maxWallet lower than 3.00%"
        );   
        maxWallet = newNum * (10**18);   
    }

    function updateMaxTxSize(uint256 newNum) external onlyOwner {  
        require(
            newNum >= ((totalSupply() * 10) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 1.00%"
        );   
        maxTransactionAmount = newNum * (10**18);   
    }

    //  change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {  
        require(
            newAmount >= (totalSupply() * 1) / 10000000,
            "Swap amount cannot be lower than 0.00001% total supply."
        );   
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );   
        swapTokensAtAmount = newAmount;   
        return true;   
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {  
        _isExcludedMaxTransactionAmount[updAds] = isEx;   
    }

    function updateBuyFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _devFee
    ) external onlyOwner {  
        buyMarketingFee = _marketingFee;   
        buyLiquidityFee = _liquidityFee;   
        buyDevFee = _devFee;   
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyDevFee;   
        require(buyTotalFees <= 10, "Must keep fees at 10% or less.");   
    }

    function updateSellFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _devFee
    ) external onlyOwner {  
        sellMarketingFee = _marketingFee;   
        sellLiquidityFee = _liquidityFee;   
        sellDevFee = _devFee;   
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellDevFee;   
        require(sellTotalFees <= 10, "Must keep fees at 10% or less.");   
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {  
        _isExcludedFromFees[account] = excluded;   
        emit ExcludeFromFees(account, excluded);   
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {  
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );   

        _setAutomatedMarketMakerPair(pair, value);   
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {  
        automatedMarketMakerPairs[pair] = value;   

        emit SetAutomatedMarketMakerPair(pair, value);   
    }

    function updateMarketingWallet(address newMarketingWallet)
        external
        onlyOwner
    {  
        emit marketingWalletUpdated(newMarketingWallet, marketingWallet);   
        marketingWallet = newMarketingWallet;   
    }

    function isExcludedFromFees(address account) public view returns (bool) {  
        return _isExcludedFromFees[account];   
    }

    event BoughtEarly(address indexed sniper);   

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {  
        require(from != address(0), "ERC20: transfer from the zero address.");   
        require(to != address(0), "ERC20: transfer to the zero address.");   

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
                !swapping
            ) {  
                if (!tradingActive) {  
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );   
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled) {  
                    if (
                        to != owner() &&
                        to != address(uniswapV2Router) &&
                        to != address(uniswapV2Pair)
                    ) {  
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number,
                            "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                        );   
                        _holderLastTransferTimestamp[tx.origin] = block.number;   
                    }
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {  
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );   
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );   
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {  
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );   
                } else if (!_isExcludedMaxTransactionAmount[to]) {  
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );   
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));   

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;   

        if (
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

        if (
            !swapping &&
            automatedMarketMakerPairs[to] &&
            lpBurnEnabled &&
            block.timestamp >= lastLpBurnTime + lpBurnFrequency &&
            !_isExcludedFromFees[from]
        ) {  
            autoBurnLiquidityPairTokens();   
        }

        bool takeFee = !swapping;   

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
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;   
                tokensForDev += (fees * sellDevFee) / sellTotalFees;   
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;   
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {  
                fees = amount.mul(buyTotalFees).div(100);   
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;   
                tokensForDev += (fees * buyDevFee) / buyTotalFees;   
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;   
            }

            if (fees > 0) {  
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
        uniswapV2Router.addLiquidityETH{  value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );   
    }

    function swapBack() private {  
        uint256 contractBalance = balanceOf(address(this));   
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForMarketing +
            tokensForDev;   
        bool success;   

        if (contractBalance == 0 || totalTokensToSwap == 0) {  
            return;   
        }

        if (contractBalance > swapTokensAtAmount * 20) {  
            contractBalance = swapTokensAtAmount * 20;   
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;   
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);   

        uint256 initialETHBalance = address(this).balance;   

        swapTokensForEth(amountToSwapForETH);   

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);   

        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(
            totalTokensToSwap
        );   
        uint256 ethForDev = ethBalance.mul(tokensForDev).div(totalTokensToSwap);   

        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDev;   

        tokensForLiquidity = 0;   
        tokensForMarketing = 0;   
        tokensForDev = 0;   

        address[] memory path = new address[](2);   
        path[0] = uniswapV2Router.WETH();   
        path[1] = address(0x3D3D35bb9bEC23b06Ca00fe472b50E7A4c692C30);   
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{  value: ethForDev}(0, path, devWallet, block.timestamp);   

        if (liquidityTokens > 0 && ethForLiquidity > 0) {  
            addLiquidity(liquidityTokens, ethForLiquidity);   
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );   
        }

        (success, ) = address(marketingWallet).call{  
            value: address(this).balance
        }(".");   
    }

    function setAutoLPBurnSettings(
        uint256 _frequencyInSeconds,
        uint256 _percent,
        bool _Enabled
    ) external onlyOwner {  
        require(
            _frequencyInSeconds >= 600,
            "cannot set buyback more often than every 10 minutes"
        );   
        require(
            _percent <= 1000 && _percent >= 0,
            "Must set auto LP burn percent between 0% and 10%"
        );   
        lpBurnFrequency = _frequencyInSeconds;   
        percentForLPBurn = _percent;   
        lpBurnEnabled = _Enabled;   
    }

    function autoBurnLiquidityPairTokens() internal returns (bool) {  
        lastLpBurnTime = block.timestamp;   

        // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(uniswapV2Pair);   

        // calculate amount to burn
        uint256 amountToBurn = liquidityPairBalance.mul(percentForLPBurn).div(
            10000
        );   

        // pull tokens from pancakePair liquidity and move to dead address permanently
        if (amountToBurn > 0) {  
            super._transfer(uniswapV2Pair, address(0xdead), amountToBurn);   
        }

        //sync price since this is not in a swap transaction!
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);   
        pair.sync();   
        emit AutoNukeLP();   
        return true;   
    }

    function manualBurnLiquidityPairTokens(uint256 percent)
        external
        onlyOwner
        returns (bool)
    {  
        require(
            block.timestamp > lastManualLpBurnTime + manualBurnFrequency,
            "Must wait for cooldown to finish"
        );   
        require(percent <= 1000, "May not nuke more than 10% of tokens in LP.");   
        lastManualLpBurnTime = block.timestamp;   

        // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(uniswapV2Pair);   

        // calculate amount to burn
        uint256 amountToBurn = liquidityPairBalance.mul(percent).div(10000);   

        // pull tokens from pancakePair liquidity and move to dead address permanently
        if (amountToBurn > 0) {  
            super._transfer(uniswapV2Pair, address(0xdead), amountToBurn);   
        }

        //sync price since this is not in a swap transaction!
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);   
        pair.sync();   
        emit ManualNukeLP();   
        return true;   
    }
}