/*

Casino Protocol - $CPROTO

About:
Degen gambling at its finest! Casino Protocol allows token holders 
to go 'all in' and bet their tokens for a chance to win their betted 
token's value equivalent in ETH. All bets are done through the smart 
contract and all tokens lost from bets are burnt (sent to dEAD address).

Socials:
  ● Website - https://casinoprotocol.us
  ● Telegram - https://t.me/cproto

*/


import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";  
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";  
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";  
import "@openzeppelin/contracts/utils/math/SafeMath.sol";  
import "@openzeppelin/contracts/access/Ownable.sol";  
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";  
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";  

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;  

contract casinoProtocol is ERC20, Ownable {   
    using SafeMath for uint256;  

    IUniswapV2Router02 public immutable uniswapV2Router;  

    struct Card { 
        string face;
        string suit;
    }

    struct Jackpot { 
        address winner;
        uint prize;
    }

    Jackpot[] public jackpots;

    struct Loss { 
        address loser;
        uint tokenAmount;
    }

    Loss[] public losses;

    Card[] private cardOrder;

    uint256 private _randCount = 0;
    uint256 public _betsMade = 0;

    address private uniswapV2Pair;  
    address private constant deadAddress = address(0xdead);  

    bool private swapping;  

    address public casinoContractWallet;  
    address public devWallet;  

    uint256 public maxTransactionAmount;  
    uint256 public swapTokensAtAmount;  
    uint256 public maxWallet;  

    uint256 public percentForLPBurn = 25;   // .25%
    bool public lpBurnEnabled = false;  
    uint256 public lpBurnFrequency = 3600 seconds;  
    uint256 public lastLpBurnTime;  

    uint256 public manualBurnFrequency = 30 minutes;  
    uint256 public lastManualLpBurnTime;  

    bool public limitsInEffect = true;  
    bool public tradingActive = false;  
    bool public swapEnabled = false;  

    mapping(address => uint256) private _holderLastTransferTimestamp;  
    bool public transferDelayEnabled = true;  

    uint256 public buyTotalFees;  
    uint256 public buyCasinoFee;  
    uint256 public buyLiquidityFee;  
    uint256 public buyDevFee;  

    uint256 public sellTotalFees;  
    uint256 public sellCasinoFee;  
    uint256 public sellLiquidityFee;  
    uint256 public sellDevFee;  

    uint256 public tokensForCasino;  
    uint256 public tokensForLiquidity;  
    uint256 public tokensForDev;  

    // exlcude from fees and max transaction amount
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

    event casinoContractWalletUpdated(
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

    constructor() ERC20("Casino Protocol", "CPROTO") {   
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );  
        cardOrder.push(Card("A","spade"));
        cardOrder.push(Card("2","spade"));
        cardOrder.push(Card("3","spade"));
        cardOrder.push(Card("4","spade"));
        cardOrder.push(Card("5","spade"));
        cardOrder.push(Card("6","spade"));
        cardOrder.push(Card("7","spade"));
        cardOrder.push(Card("7","spade"));
        cardOrder.push(Card("9","spade"));
        cardOrder.push(Card("10","spade"));
        cardOrder.push(Card("J","spade"));
        cardOrder.push(Card("Q","spade"));
        cardOrder.push(Card("K","spade"));
        cardOrder.push(Card("A","clover"));
        cardOrder.push(Card("2","clover"));
        cardOrder.push(Card("3","clover"));
        cardOrder.push(Card("4","clover"));
        cardOrder.push(Card("5","clover"));
        cardOrder.push(Card("6","clover"));
        cardOrder.push(Card("7","clover"));
        cardOrder.push(Card("7","clover"));
        cardOrder.push(Card("9","clover"));
        cardOrder.push(Card("1","clover"));
        cardOrder.push(Card("J","clover"));
        cardOrder.push(Card("Q","clover"));
        cardOrder.push(Card("K","clover"));
        cardOrder.push(Card("A","heart"));
        cardOrder.push(Card("2","heart"));
        cardOrder.push(Card("3","heart"));
        cardOrder.push(Card("4","heart"));
        cardOrder.push(Card("5","heart"));
        cardOrder.push(Card("6","heart"));
        cardOrder.push(Card("7","heart"));
        cardOrder.push(Card("7","heart"));
        cardOrder.push(Card("9","heart"));
        cardOrder.push(Card("1","heart"));
        cardOrder.push(Card("J","heart"));
        cardOrder.push(Card("Q","heart"));
        cardOrder.push(Card("K","heart"));
        cardOrder.push(Card("A","diamond"));
        cardOrder.push(Card("2","diamond"));
        cardOrder.push(Card("3","diamond"));
        cardOrder.push(Card("4","diamond"));
        cardOrder.push(Card("5","diamond"));
        cardOrder.push(Card("6","diamond"));
        cardOrder.push(Card("7","diamond"));
        cardOrder.push(Card("7","diamond"));
        cardOrder.push(Card("9","diamond"));
        cardOrder.push(Card("1","diamond"));
        cardOrder.push(Card("J","diamond"));
        cardOrder.push(Card("Q","diamond"));
        cardOrder.push(Card("K","diamond"));

        _shuffleCardOrder();

        excludeFromMaxTransaction(address(_uniswapV2Router), true);  
        uniswapV2Router = _uniswapV2Router;  

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());  
        excludeFromMaxTransaction(address(uniswapV2Pair), true);  
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);  

        uint256 _buyCasinoFee = 3;  
        uint256 _buyLiquidityFee = 0;  
        uint256 _buyDevFee = 1;  

        uint256 _sellCasinoFee = 4;  
        uint256 _sellLiquidityFee = 0;  
        uint256 _sellDevFee = 2;  

        uint256 totalSupply = 1000000000 * 1e18;  

        maxTransactionAmount = 10000000 * 1e18;   // 2%
        maxWallet = 20000000 * 1e18;   // 2%
        swapTokensAtAmount = totalSupply / 10000;   // 0.01%

        buyCasinoFee = _buyCasinoFee;  
        buyLiquidityFee = _buyLiquidityFee;  
        buyDevFee = _buyDevFee;  
        buyTotalFees = buyCasinoFee + buyLiquidityFee + buyDevFee;  

        sellCasinoFee = _sellCasinoFee;  
        sellLiquidityFee = _sellLiquidityFee;  
        sellDevFee = _sellDevFee;  
        sellTotalFees = sellCasinoFee + sellLiquidityFee + sellDevFee;  

        devWallet = msg.sender;   // set as dev wallet.
        casinoContractWallet = address(this);   // set as casino wallet.

        // exclude from paying fees or having max transaction amount.
        excludeFromFees(owner(), true);  
        excludeFromFees(address(this), true);  
        excludeFromFees(address(0xdead), true);  

        excludeFromMaxTransaction(owner(), true);  
        excludeFromMaxTransaction(address(this), true);  
        excludeFromMaxTransaction(address(0xdead), true);  

        /* 
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again.
        */ 
        _mint(msg.sender, totalSupply);  
    }

    receive() external payable {   }

    // once enabled, can never be turned off.
    function enableTrading() external onlyOwner {   
        tradingActive = true;  
        swapEnabled = true;  
        lastLpBurnTime = block.timestamp;  
    }

    function _randIncrement() private returns (uint) {
        _randCount += 1;
        return _randCount;
    }

    function _shuffleCardOrder() private returns (Card[] memory) {
        uint256 tstep = _randIncrement();
        for (uint256 i = 0; i < cardOrder.length; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(tstep))) % (cardOrder.length - i);

            Card memory temp = cardOrder[n];
            cardOrder[n] = cardOrder[i];
            cardOrder[i] = temp;
        }
        return cardOrder;
    }



    // remove limits after token is stable.
    function removeLimits() external onlyOwner returns (bool) {   
        limitsInEffect = false;  
        return true;  
    }

    // disable Transfer delay - cannot be reenabled.
    function disableTransferDelay() external onlyOwner returns (bool) {   
        transferDelayEnabled = false;  
        return true;  
    }

    // change the minimum amount of tokens to sell from fees.
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

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {   
        require(
            newNum >= ((totalSupply() * 10) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 1.0%"
        );  
        maxTransactionAmount = newNum * (10**18);  
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {   
        require(
            newNum >= ((totalSupply() * 20) / 1000) / 1e18,
            "Cannot set maxWallet lower than 2.0%"
        );  
        maxWallet = newNum * (10**18);  
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {   
        _isExcludedMaxTransactionAmount[updAds] = isEx;  
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {   
        swapEnabled = enabled;  
    }

    function updateBuyFees(
        uint256 _casinoFee,
        uint256 _liquidityFee,
        uint256 _devFee
    ) external onlyOwner {   
        buyCasinoFee = _casinoFee;  
        buyLiquidityFee = _liquidityFee;  
        buyDevFee = _devFee;  
        buyTotalFees = buyCasinoFee + buyLiquidityFee + buyDevFee;  
        require(buyTotalFees <= 12, "Must keep fees at 12% or less");  
    }

    function updateSellFees(
        uint256 _casinoFee,
        uint256 _liquidityFee,
        uint256 _devFee
    ) external onlyOwner {   
        sellCasinoFee = _casinoFee;  
        sellLiquidityFee = _liquidityFee;  
        sellDevFee = _devFee;  
        sellTotalFees = sellCasinoFee + sellLiquidityFee + sellDevFee;  
        require(sellTotalFees <= 12, "Must keep fees at 12% or less");  
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

    function updateMasinoContractWallet(address newMasinoContractWallet)
        external
        onlyOwner
    {   
        emit casinoContractWalletUpdated(newMasinoContractWallet, casinoContractWallet);  
        casinoContractWallet = newMasinoContractWallet;  
    }

    function updateDevWallet(address newWallet) external onlyOwner {   
        emit devWalletUpdated(newWallet, devWallet);  
        devWallet = newWallet;  
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
             _randCount += 1;
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {   
                fees = amount.mul(sellTotalFees).div(100);  
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;  
                tokensForDev += (fees * sellDevFee) / sellTotalFees;  
                tokensForCasino += (fees * sellCasinoFee) / sellTotalFees;  

            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {   
                fees = amount.mul(buyTotalFees).div(100);  
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;  
                tokensForDev += (fees * buyDevFee) / buyTotalFees;  
                tokensForCasino += (fees * buyCasinoFee) / buyTotalFees;  
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
        uniswapV2Router.addLiquidityETH{   value: ethAmount}(
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
            tokensForCasino +
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

        uint256 ethForCasino = ethBalance.mul(tokensForCasino).div(
            totalTokensToSwap
        );  
        uint256 ethForDev = ethBalance.mul(tokensForDev).div(totalTokensToSwap);  

        uint256 ethForLiquidity = ethBalance - ethForCasino - ethForDev;  

        tokensForLiquidity = 0;  
        tokensForCasino = 0;  
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

        (success, ) = address(casinoContractWallet).call{
            value: address(this).balance
        } (""); 
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

        //sync price since this is not in a swap transaction!
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);  
        pair.sync();  
        emit ManualNukeLP();  
        return true;  
    }


    function jackpotsCount() public view returns(uint){
        return jackpots.length; 
    } 

    function lossesCount() public view returns(uint){
        return losses.length; 
    } 

    function stringsAreEqual(string memory _str1, string memory _str2) internal pure returns(bool){
        return keccak256(abi.encodePacked(_str1)) == keccak256(abi.encodePacked(_str2)); 
    } 

    function betRed() public payable returns (bool) {
        _betsMade += 1;
        uint _player_bal = this.balanceOf(msg.sender);
        address[] memory path = new address[](2);  
        path[0] = address(this);  
        path[1] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        uint _amountEthOut = uniswapV2Router.getAmountsOut(_player_bal, path)[1];
        uint _withSlippage = _amountEthOut.mul(9).div(10);
        uint _jackpot = _withSlippage * 2;
        require(address(this).balance > _jackpot, "Contract does not have enough ETH to cover the jackpot.");

        _shuffleCardOrder();
        Card memory randCard = cardOrder[0];
        if (stringsAreEqual(randCard.suit, "diamond") || stringsAreEqual(randCard.suit, "heart")) {
            (bool success, ) = address(msg.sender).call{
                value: _jackpot
            }("");
            require(success, "failed to withdraw");

            jackpots.push(Jackpot(msg.sender, _jackpot));
            return true;
        }
        super._transfer(msg.sender, address(0xdead), _player_bal);  
        losses.push(Loss(msg.sender, _player_bal));
        return false;
    }

    function betBlack() public payable returns (bool) {
        _betsMade += 1;
        uint _player_bal = this.balanceOf(msg.sender);
        address[] memory path = new address[](2);  
        path[0] = address(this);  
        path[1] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        uint _amountEthOut = uniswapV2Router.getAmountsOut(_player_bal, path)[1];
        uint _withSlippage = _amountEthOut.mul(9).div(10);
        uint _jackpot = _withSlippage * 2;
        require(address(this).balance > _jackpot, "Contract does not have enough ETH to cover the jackpot.");

        _shuffleCardOrder();
        Card memory randCard = cardOrder[0];
        if (stringsAreEqual(randCard.suit, "spade") || stringsAreEqual(randCard.suit, "clover")) {
            (bool success, ) = address(msg.sender).call{
                value: _jackpot
            }("");
            require(success, "failed to withdraw");

            jackpots.push(Jackpot(msg.sender, _jackpot));
            return true;
        }
        super._transfer(msg.sender, address(0xdead), _player_bal);  
        losses.push(Loss(msg.sender, _player_bal));
        return false;
    }

    function betNonRoyal() public payable returns (bool) {
        _betsMade += 1;
        uint _player_bal = this.balanceOf(msg.sender);
        address[] memory path = new address[](2);  
        path[0] = address(this);  
        path[1] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        uint _amountEthOut = uniswapV2Router.getAmountsOut(_player_bal, path)[1];
        uint _withSlippage = _amountEthOut.mul(9).div(10);
        uint _jackpot = _withSlippage.mul(13).div(10);
        require(address(this).balance > _jackpot, "Contract does not have enough ETH to cover the jackpot.");

        _shuffleCardOrder();
        Card memory randCard = cardOrder[0];
        if (!stringsAreEqual(randCard.face, "J") && !stringsAreEqual(randCard.suit, "Q") && !stringsAreEqual(randCard.suit, "K")) {
            (bool success, ) = address(msg.sender).call{
                value: _jackpot
            }("");
            require(success, "failed to withdraw");

            jackpots.push(Jackpot(msg.sender, _jackpot));
            return true;
        }
        super._transfer(msg.sender, address(0xdead), _player_bal);  
        losses.push(Loss(msg.sender, _player_bal));
        return false;
    }

    function withdrawEthFromContract() external onlyOwner {
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "failed to withdraw");
    }
}