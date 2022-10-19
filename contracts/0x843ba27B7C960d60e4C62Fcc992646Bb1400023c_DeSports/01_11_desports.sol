/**
    dESPORTS - Decentralized Esports
    
    dESPORTS is a decentralized Esports fantasy manager platform.
    Token holders can nominate gamers they know to compete on their
    behalf in competitive gaming to win rewards in ETH.

    https://desports.stream
    https://t.me/desportsportal
**/

//  SPDX-License-Identifier: MIT

pragma solidity 0.8.17; 

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract DeSports is ERC20, Ownable { 

    struct Nomination {
        uint time;
        address user;
        string clash;
        string nominee;
    }
    using SafeMath for uint256; 

    mapping(string => string) public clashes; 
    mapping(string => string) public gamerNominees; 
    Nomination[] public nominations;
    address public gameMaster; 

    IUniswapV2Router02 public immutable uniswapV2Router; 
    address public immutable uniswapV2Pair; 
    address public constant deadAddress = address(0xdead); 

    bool private swapping; 

    address public clashWallet; 
    address public devWallet; 

    uint256 public maxTransactionAmount; 
    uint256 public maxWallet; 
    uint256 public swapTokensAtAmount; 

    uint256 public percentForLPBurn = 20;  // .2%
    bool public lpBurnEnabled = true; 
    uint256 public lpBurnFrequency = 3600 seconds; // per hour
    uint256 public lastLpBurnTime; 

    uint256 public manualBurnFrequency = 30 minutes; 
    uint256 public lastManualLpBurnTime; 

    bool public limitsInEffect = true; 
    bool public tradingActive = false; 
    bool public swapEnabled = false; 

    mapping(address => uint256) private _holderLastTransferTimestamp; 
    bool public transferDelayEnabled = true; 

    uint256 public tokensForClash; 
    uint256 public tokensForLiquidity; 
    uint256 public tokensForDev; 

    uint256 public buyTotalFees; 
    uint256 public buyClashFee; 
    uint256 public buyLiquidityFee; 
    uint256 public buyDevFee; 

    uint256 public sellTotalFees; 
    uint256 public sellClashFee; 
    uint256 public sellLiquidityFee; 
    uint256 public sellDevFee; 

    mapping(address => bool) private _isExcludedFromFees; 
    mapping(address => bool) public _isExcludedMaxTransactionAmount; 

    mapping(address => bool) public automatedMarketMakerPairs; 

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    ); 

    event ExcludeFromFees(address indexed account, bool isExcluded); 

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value); 

    event clashWalletUpdated(
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

    constructor() ERC20("DeSports", "DESPORTS") { 

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        ); 

        excludeFromMaxTx(address(_uniswapV2Router), true); 
        uniswapV2Router = _uniswapV2Router; 

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH()); 
        excludeFromMaxTx(address(uniswapV2Pair), true); 
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true); 

        uint256 _buyClashFee = 4; 
        uint256 _buyLiquidityFee = 0; 
        uint256 _buyDevFee = 2; 

        uint256 _sellClashFee = 4; 
        uint256 _sellLiquidityFee = 0; 
        uint256 _sellDevFee = 2; 

        uint256 totalSupply = 1_000_000_000 * 1e18; 

        maxTransactionAmount = 5_000_000 * 1e18;  // 0.5% maxTransactionAmount. 
        maxWallet = 10_000_000 * 1e18;  // 1% maxWallet. 
        swapTokensAtAmount = (totalSupply * 5) / 10000;  // 0.05% swapTokensAtAmount. 

        gameMaster = msg.sender; 
        devWallet = msg.sender; 
        clashWallet = address(0x50665fe26b53dF8BcBCAC45f0Ef2AD3f2A9cF205); 

        buyClashFee = _buyClashFee; // clash rewards 
        buyLiquidityFee = _buyLiquidityFee; 
        buyDevFee = _buyDevFee; 
        buyTotalFees = buyClashFee + buyLiquidityFee + buyDevFee; 

        sellClashFee = _sellClashFee; 
        sellLiquidityFee = _sellLiquidityFee; 
        sellDevFee = _sellDevFee; 
        sellTotalFees = sellClashFee + sellLiquidityFee + sellDevFee; 

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
        
    function addressToString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40); 
        for (uint i = 0;  i < 20;  i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i))))); 
            bytes1 hi = bytes1(uint8(b) / 16); 
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi)); 
            s[2*i] = _char(hi); 
            s[2*i+1] = _char(lo);             
        }
        return string(s); 
    }

    function _char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30); 
        else return bytes1(uint8(b) + 0x57); 
    }

    function stringsAreEqual(string memory _str1, string memory _str2) internal pure returns(bool){
        return keccak256(abi.encodePacked(_str1)) == keccak256(abi.encodePacked(_str2)); 
    }

    function transferGameMasterRole(address _newGM) public { 
        require(msg.sender == gameMaster, "You are not the Game Master"); 
        gameMaster = _newGM; 
    }

    function newClash(string memory clashName) public { 
        require(msg.sender == gameMaster, "You are not the Game Master"); 
        require(stringsAreEqual(clashes[clashName], ""), "Cannot recreate a clash tournament"); 

        clashes[clashName] = "DRAFTING_NOMINEES"; 
    }

    function lockClash(string memory clashName) public { 
        require(msg.sender == gameMaster, "You are not the Game Master"); 
        require(stringsAreEqual(clashes[clashName], "DRAFTING_NOMINEES"), "Can only lock nominations during DRAFTING_NOMINEES phase"); 

        clashes[clashName] = "NOMINEES_LOCKED"; 
    }

    function setClashResult(string memory clashName, string memory result) public {
        require(msg.sender == gameMaster, "You are not the Game Master"); 
        require(stringsAreEqual(clashes[clashName], "NOMINEES_LOCKED"), "Can only set results during NOMINEES_LOCKED phase"); 
        require(!stringsAreEqual(result, ""), "Cannot delete a clash"); 
        require(!stringsAreEqual(result, "DRAFTING_NOMINEES"), "Cannot revert back to DRAFTING_NOMINEES phase"); 

        clashes[clashName] = result; 
    }

    function nominateGamer(string memory gamerUsername, string memory clashName) public { 
        require(stringsAreEqual(clashes[clashName], "DRAFTING_NOMINEES"), "Clash is not in DRAFTING_NOMINEES phase"); 
        gamerNominees[string.concat(clashName, addressToString(msg.sender))] = gamerUsername; 
        nominations.push(Nomination(block.timestamp, msg.sender, clashName, gamerUsername));
    }     

    function excludeFromFees(address account, bool excluded) public onlyOwner { 
        _isExcludedFromFees[account] = excluded; 
        emit ExcludeFromFees(account, excluded); 
    } 

    function updateBuyFees(
        uint256 _clashFee,
        uint256 _liquidityFee,
        uint256 _devFee
    ) external onlyOwner { 
        buyClashFee = _clashFee; 
        buyLiquidityFee = _liquidityFee; 
        buyDevFee = _devFee; 
        buyTotalFees = buyClashFee + buyLiquidityFee + buyDevFee; 
        require(buyTotalFees <= 10, "Must keep fees at 10% or less"); 
    } 

    function updateSellFees(
        uint256 _clashFee,
        uint256 _liquidityFee,
        uint256 _devFee
    ) external onlyOwner { 
        sellClashFee = _clashFee; 
        sellLiquidityFee = _liquidityFee; 
        sellDevFee = _devFee; 
        sellTotalFees = sellClashFee + sellLiquidityFee + sellDevFee; 
        require(sellTotalFees <= 10, "Must keep fees at 10% or less"); 
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

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    { 
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        ); 
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        ); 
        swapTokensAtAmount = newAmount; 
        return true; 
    } 

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner { 
        require(
            newNum >= ((totalSupply() * 10) / 1000) / 1e18,
            "Cannot set maxWallet lower than 1.0%"
        ); 
        maxWallet = newNum * (10**18); 
    } 
    function updateMaxTxAmount(uint256 newNum) external onlyOwner { 
        require(
            newNum >= ((totalSupply() * 10) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 1.0%"
        ); 
        maxTransactionAmount = newNum * (10**18); 
    } 

    function excludeFromMaxTx(address updAds, bool isEx)
        public
        onlyOwner
    { 
        _isExcludedMaxTransactionAmount[updAds] = isEx; 
    } 

    function enableTrading() external onlyOwner { 
        require(tradingActive == false, "Trading is already open"); 
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

    function updateDevWallet(address newWallet) external onlyOwner { 
        emit devWalletUpdated(newWallet, devWallet); 
        devWallet = newWallet; 
    } 

    function isExcludedFromFees(address account) public view returns (bool) { 
        return _isExcludedFromFees[account]; 
    } 

    function updateClashWallet(address newClashWallet)
        external
        onlyOwner
    { 
        emit clashWalletUpdated(newClashWallet, clashWallet); 
        clashWallet = newClashWallet; 
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
                    !_isExcludedMaxTransactionAmount[to]
                ) { 
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount!"
                    ); 
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded."
                    ); 
                } 
                // when sell 
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) { 
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount!"
                    ); 
                } else if (!_isExcludedMaxTransactionAmount[to]) { 
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded."
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
                tokensForClash += (fees * sellClashFee) / sellTotalFees; 
            } 
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) { 
                fees = amount.mul(buyTotalFees).div(100); 
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees; 
                tokensForDev += (fees * buyDevFee) / buyTotalFees; 
                tokensForClash += (fees * buyClashFee) / buyTotalFees; 
            } 

            if (fees > 0) { 
                super._transfer(from, address(this), fees); 
            } 

            amount -= fees; 
        } 

        super._transfer(from, to, amount); 
    } 

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private { 
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount); 

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount} (
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        ); 
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

    function swapBack() private { 
        uint256 contractBalance = balanceOf(address(this)); 
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForClash +
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

        uint256 ethForClash = ethBalance.mul(tokensForClash).div(
            totalTokensToSwap
        ); 
        uint256 ethForDev = ethBalance.mul(tokensForDev).div(totalTokensToSwap); 

        uint256 ethForLiquidity = ethBalance - ethForClash - ethForDev; 

        tokensForLiquidity = 0; 
        tokensForClash = 0; 
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

        (success, ) = address(clashWallet).call{
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