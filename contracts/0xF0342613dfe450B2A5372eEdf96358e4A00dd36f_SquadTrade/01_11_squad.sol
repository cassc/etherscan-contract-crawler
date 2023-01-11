/*

SquadTrade
$SQUAD
      
SquadTrade is a crypto trading Telegram bot for teams. 
Add our bot to your team's Telegram group to start analyzing,
trading, and sniping crypto with your squad.
     
 ⍣ Website:
   https://squadtrade.net
       
 ⍣ Telegram:   
   https://t.me/squadtradeportal

 ⍣ TG Bot:
   https://t.me/SquadTradeBot
          
**/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.15;   

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";    
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";    
import "@openzeppelin/contracts/access/Ownable.sol";    
import "@openzeppelin/contracts/utils/math/SafeMath.sol";    
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";    
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";    
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";    

contract SquadTrade is ERC20, Ownable { 

    using SafeMath for uint256;   

    IUniswapV2Router02 public immutable uniswapV2Router;   
    address public immutable uniswapV2Pair;   
    address public constant deadAddress = address(0xdead);   

    mapping(address => string) public telegramUsername;   

    bool private swapping;   

    address public marketingWallet;   
    address public devWallet;   

    uint256 public maxTransactionAmt;   
    uint256 public swapTokensAtAmt;   
    uint256 public maxWallet;   

    uint256 public percentForLPBurn = 10; // .1%
    bool public lpBurnEnabled = true;   
    uint256 public lpBurnFrequency = 3600 seconds;   
    uint256 public lastLpBurnTime;   

    uint256 public manualBurnFrequency = 30 minutes;   
    uint256 public lastManualLpBurnTime;   

    bool public limitsInEffect = true;   
    bool public tradingActive = false;   
    bool public swapEnabled = false;   

    mapping(address => uint256) private _holderLastTransferTimestamp;  
    bool public transferDelayEnabled = true;   

    uint256 public tokensForMarketing;   
    uint256 public tokensForLiquidity;   
    uint256 public tokensForDev;   

    uint256 public buyTotalFees;   
    uint256 public buyMarketingFee;   
    uint256 public buyLiquidityFee;   
    uint256 public buyDevFee;   

    uint256 public sellTotalFees;   
    uint256 public sellMarketingFee;   
    uint256 public sellLiquidityFee;   
    uint256 public sellDevFee;   

    mapping(address => bool) private _isExcludedFromFees;   
    mapping(address => bool) public _isExcludedMaxTransactionAmt;   

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


    constructor() ERC20("SquadTrade", "SQUAD") { 

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );   


        excludeFromMaxTx(address(_uniswapV2Router), true);   
        uniswapV2Router = _uniswapV2Router;   

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());   
        excludeFromMaxTx(address(uniswapV2Pair), true);   
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);   


        uint256 _buyMarketingFee = 3;   
        uint256 _buyLiquidityFee = 0;   
        uint256 _buyDevFee = 3;   


        uint256 _sellMarketingFee = 4;   
        uint256 _sellLiquidityFee = 0;   
        uint256 _sellDevFee = 4;   

        uint256 totalSupply = 1_000_000_000 * 1e18;   
        maxTransactionAmt = 10_000_000 * 1e18;   // 1% 
        maxWallet = 10_000_000 * 1e18;   // 1% 

        swapTokensAtAmt = (totalSupply * 5) / 10000;   // 0.05%

        devWallet = msg.sender;   
        marketingWallet = address(0x8D7DE6481dd2563552aCC20E5f8ae19332b82B7B);   

        buyMarketingFee = _buyMarketingFee;   
        buyLiquidityFee = _buyLiquidityFee;   
        buyDevFee = _buyDevFee;   
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyDevFee;   

        sellMarketingFee = _sellMarketingFee;   
        sellLiquidityFee = _sellLiquidityFee;   
        sellDevFee = _sellDevFee;   
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellDevFee;   

       // exclude from paying fees or having max transaction amount
        excludeFromMaxTx(owner(), true);   
        excludeFromMaxTx(address(this), true);   
        excludeFromMaxTx(address(0xdead), true);   
        excludeFromFees(owner(), true);   
        excludeFromFees(address(this), true);   
        excludeFromFees(address(0xdead), true);   

        _mint(msg.sender, totalSupply);   
    }             

    receive() external payable { }            

    function updateTelegramUsername(string memory susername) public {
        telegramUsername[msg.sender] = susername;   
    }        

    function excludeFromFees(address account, bool excluded) public onlyOwner { 
        _isExcludedFromFees[account] = excluded;   
        emit ExcludeFromFees(account, excluded);   
    }             

    function removeLimits() external onlyOwner returns (bool) { 
        limitsInEffect = false;   
        return true;   
    }     

    function updateBuySwapFees(
        uint256 _marketingfee,
        uint256 _liquidityfee,
        uint256 _devfee
    ) external onlyOwner { 
        buyMarketingFee = _marketingfee;   
        buyLiquidityFee = _liquidityfee;   
        buyDevFee = _devfee;   
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyDevFee;   
        require(buyTotalFees <= 10, "Must keep fees at 10% or less");   
    }             

    function updateSellSwapFees(
        uint256 _marketingfee,
        uint256 _liquidityfee,
        uint256 _devfee
    ) external onlyOwner { 
        sellMarketingFee = _marketingfee;   
        sellLiquidityFee = _liquidityfee;   
        sellDevFee = _devfee;   
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellDevFee;   
        require(sellTotalFees <= 10, "Must keep fees at 10% or less");   
    }                     

    function disableTransferDelay() external onlyOwner returns (bool) { 
        transferDelayEnabled = false;   
        return true;   
    }             

    function updateSwapTokensAtAmt(uint256 newAmt)
        external
        onlyOwner
        returns (bool)
    { 
        require(
            newAmt >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply." 
        );   
        require(
            newAmt <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply." 
        );   
        swapTokensAtAmt = newAmt;   
        return true;   
    }             

    function updateMaxWalletAmt(uint256 newNum) external onlyOwner { 
        require(
            newNum >= ((totalSupply() * 10) / 1000) / 1e18,
            "Cannot set maxWallet lower than 1 %" 
        );   
        maxWallet = newNum * (10**18);   
    }             
    function updateMaxTxAmt(uint256 newNum) external onlyOwner { 
        require(
            newNum >= ((totalSupply() * 10) / 1000) / 1e18,
            "Cannot set maxTransactionAmt lower than 1 %" 
        );   
        maxTransactionAmt = newNum * (10**18);   
    }             

    function excludeFromMaxTx(address updAds, bool isEx)
        public
        onlyOwner
    { 
        _isExcludedMaxTransactionAmt[updAds] = isEx;   
    }             

    function enableTrading() external onlyOwner { 
        tradingActive = true;   
        swapEnabled = true;   
        lastLpBurnTime = block.timestamp;   
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

    function updateDevWallet(address _newWallet) external onlyOwner { 
        emit devWalletUpdated(_newWallet, devWallet);   
        devWallet = _newWallet;   
    }             

    function isExcludedFromFees(address account) public view returns (bool) { 
        return _isExcludedFromFees[account];   
    }             

    function updateMarketingWallet(address newMarketingWallet)
        external
        onlyOwner
    { 
        emit marketingWalletUpdated(newMarketingWallet, marketingWallet);   
        marketingWallet = newMarketingWallet;   
    }             

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
                        "Trading is not active!" 
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
                            "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed!" 
                        );   
                        _holderLastTransferTimestamp[tx.origin] = block.number;   
                    }             
                }             

               // when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmt[to]
                ) { 
                    require(
                        amount <= maxTransactionAmt,
                        "Buy transfer amount exceeds the maxTransactionAmt!"
                    );   
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded."
                    );   
                }             
               // when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmt[from]
                ) { 
                    require(
                        amount <= maxTransactionAmt,
                        "Sell transfer amount exceeds the maxTransactionAmt!"
                    );   
                }             else if (!_isExcludedMaxTransactionAmt[to]) { 
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded."
                    );   
                }             
            }             
        }             


        uint256 contractTokenBalance = balanceOf(address(this));   

        bool canSwap = contractTokenBalance >= swapTokensAtAmt;   


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

    function addLiquidity(uint256 tokenAmt, uint256 ethAmt) private { 
       // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmt);   

       // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmt}             (
            address(this),
            tokenAmt,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );   
    }             

    function swapTokensForEth(uint256 tokenAmt) private { 
       // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);   
        path[0] = address(this);   
        path[1] = uniswapV2Router.WETH();   

        _approve(address(this), address(uniswapV2Router), tokenAmt);   

       // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmt,
            0, // accept any amount of ETH
            path,
            address(this),
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

        if (contractBalance > swapTokensAtAmt * 20) { 
            contractBalance = swapTokensAtAmt * 20;   
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

        (success, ) = address(devWallet).call{value: ethForDev} ("");   

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
        }             ("");   
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

       // sync price since this is not in a swap transaction!
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
        require(percent <= 1000, "May not nuke more than 10% of tokens in LP");   
        lastManualLpBurnTime = block.timestamp;   

       // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(uniswapV2Pair);   

       // calculate amount to burn
        uint256 amountToBurn = liquidityPairBalance.mul(percent).div(10000);   

       // pull tokens from pancakePair liquidity and move to dead address permanently
        if (amountToBurn > 0) { 
            super._transfer(uniswapV2Pair, address(0xdead), amountToBurn);   
        }             

       // sync price since this is not in a swap transaction!
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);   
        pair.sync();   
        emit ManualNukeLP();   
        return true;   
    }    
  
}