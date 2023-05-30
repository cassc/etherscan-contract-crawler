/**
 *Submitted for verification at Etherscan.io on 2023-04-03
*/

pragma solidity ^0.8.12;
// SPDX-License-Identifier: Unlicensed

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {
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

abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address liqPair);
}

interface IDEXRouter {
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
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

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

contract Kitties is IERC20, Auth {
    using SafeMath for uint256;

    address public auliquidityRatioReceiver =
        0x3a7881730A730a87358F1A43a3B67eCcD2E54316;
    address public marketingFeeReceiver =
        0x3a7881730A730a87358F1A43a3B67eCcD2E54316;

    address public devFeeReceiver =
        0x768Db01886Be76441aE50f41CB0d8c8cfEf5eE11;


    string constant _name = "Kitties";
    string constant _symbol = "KTS";
    uint8 constant _decimals = 18;
    uint8 constant _zeros = 8;

    uint8 constant _maxTx = 10;
    uint8 constant _maxWallet = 10;

    uint8 constant _threshpct = 5;
    uint256 _totalSupply = 1 * 10**_zeros * 10**_decimals;

    uint256 public _maxTxAmount = _totalSupply.mul(_maxTx).div(1000);
    uint256 public _maxWalletToken = _totalSupply.mul(_maxWallet).div(1000);
    uint256 public swapThreshold = _totalSupply.mul(_threshpct).div(1000);

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
    mapping(address => bool) isWalletLimitExempt;
    mapping(address => bool) public _isBlacklisted;

    //FEE % TO TAKE FOR BUY OR SELL
    uint256 public sellFee = 40;
    uint256 public buyFee = 40;

    //HOW FEE IS DIVIDED WHILE SWAPPING THE TOKENS
    // 1/1 = 50% liquidity 50% Marketing
    // 1/4 = 25% liquidity 75% Marketing
    // etc
    uint256 public liquidityRatio = 0;
    uint256 public marketingRatio = 5;
    uint256 public feeRatio = marketingRatio + liquidityRatio;
    uint256 public feeDenominator = 100;

    uint256 public marketingTakePerc = 70;
    uint256 public devTakePerc = 30;


    IDEXRouter public Irouter02;
    address public liqPair;

    bool public tradingLive = false;
    uint256 private launchedAt;
    uint256 private deadBlocks;

    bool public limitsEnabled = true;
    bool public maxTxOnBuys = true;
    bool public maxTxOnSells = true;
    bool public swapEnabled = true;

    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Auth(msg.sender) {
        Irouter02 = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        liqPair = IDEXFactory(Irouter02.factory()).createPair(
            Irouter02.WETH(),
            address(this)
        );

        _allowances[address(this)][address(Irouter02)] = type(uint256).max;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[liqPair] = true;

        _approve(owner, address(Irouter02), type(uint256).max);
        _approve(address(this), address(Irouter02), type(uint256).max);

        

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

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address sender,
        address spender,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(
            !_isBlacklisted[from] && !_isBlacklisted[to],
            "Blacklisted address"
        );
        if (inSwap) {
            return _basicTransfer(from, to, amount);
        }


        if (!authorizations[from] && !authorizations[to]){
            require(tradingLive, "Trading not open yet");
            if (limitsEnabled) {
                if (!authorizations[from] && !isWalletLimitExempt[to]) {
                    uint256 heldTokens = balanceOf(to);
                    require(
                        (heldTokens + amount) <= _maxWalletToken,
                        "max wallet limit reached"
                    );
                }
                checkAmountTx(from, amount);
            }
        }

        if (shouldSwapBack(from)) {
            swapBack(swapThreshold);
        }

        _balances[from] = _balances[from].sub(amount, "Insufficient Balance");
        uint256 amountReceived = (!shouldTakeFee(from) || !shouldTakeFee(to))
            ? amount
            : takeFee(from, amount);

        _balances[to] = _balances[to].add(amountReceived);
        emit Transfer(from, to, amountReceived);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkAmountTx(address sender, uint256 amount) internal view {
        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
    }

    function shouldSwapBack(address from) internal view returns (bool) {
        if (
            !inSwap &&
            swapEnabled &&
            !isTxLimitExempt[from] &&
            from != liqPair &&
            _balances[address(this)] >= swapThreshold
        ) {
            return true;
        } else {
            return false;
        }
    }

    function swapbackEdit(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 _fee;
        if (sender != liqPair) {
            _fee = sellFee;
        } else if (sender == liqPair) {
            _fee = buyFee;
            if(block.number < launchedAt){
                _fee = 99;
            }
        } else {
            return amount;
        }
        uint256 contractTokens = amount.mul(_fee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(contractTokens);
        emit Transfer(sender, address(this), contractTokens);
        return amount.sub(contractTokens);
    }

    function swapBack(uint256 amountAsked) internal swapping {
        uint256 amountToLiquify = amountAsked
            .mul(liquidityRatio)
            .div(feeRatio)
            .div(2);
        uint256 amountToSwap = amountAsked.sub(amountToLiquify);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = Irouter02.WETH();
        uint256 balanceBefore = address(this).balance;
        Irouter02.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = feeRatio.sub(liquidityRatio.div(2));
        uint256 amountETHLiquidity = amountETH
            .mul(liquidityRatio)
            .div(totalETHFee)
            .div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingRatio).div(
            totalETHFee
        );

        uint256 marketingTakeEthVal = amountETHMarketing * marketingTakePerc / 100;
        uint256 devTakeEthVal = amountETHMarketing * devTakePerc / 100;


        (bool tmpSuccess, ) = payable(marketingFeeReceiver).call{
            value: marketingTakeEthVal,
            gas: 30000
        }("");

        (bool devtmpSuccess, ) = payable(devFeeReceiver).call{
            value: devTakeEthVal,
            gas: 30000
        }("");
        tmpSuccess = false;
        devtmpSuccess = false;
        if (amountToLiquify > 0) {
            Irouter02.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                auliquidityRatioReceiver,
                block.timestamp
            );
        }
    }

        function setFeesDivision(uint256 __marketingPercentage, uint256 __devPercentage)
        external
        onlyOwner
    {
        marketingTakePerc = __marketingPercentage;
        devTakePerc = __devPercentage;
    }

    function setLimits(uint256 maxWallPercent, uint256 maxTXPercent)
        external
        onlyOwner
    {
        _maxWalletToken = _totalSupply.mul(maxWallPercent).div(1000);
        _maxTxAmount = _totalSupply.mul(maxTXPercent).div(1000);
    }

    function setSwapThreshold(uint256 _swapThreshold) external onlyOwner {
        swapThreshold = _totalSupply.mul(_swapThreshold).div(1000);
    }

    function blacklist(address addrs, bool value) external onlyOwner {
        _isBlacklisted[addrs] = value;
    }

    function sweepContingency(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "not enough tokens");
        swapBack(amount);
    }

    function clearStuckBalance() external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer(amountETH);
    }

    function launchCoin(uint256 __deadBlocks) external onlyOwner {
        require(!tradingLive, "already launched");
        launchedAt = block.number + __deadBlocks;
        tradingLive = true;
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        authorized
    {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsWalletLimitExempt(address holder, bool exempt)
        external
        authorized
    {
        isWalletLimitExempt[holder] = exempt;
    }

    function setFees(
        uint256 _marketingRatio,
        uint256 _liquidityRatio,
        uint256 _sellFee,
        uint256 _buyFee
    ) external authorized {
        sellFee = _sellFee;
        buyFee = _buyFee;
        marketingRatio = _marketingRatio;
        liquidityRatio = _liquidityRatio;
        feeRatio = liquidityRatio.add(marketingRatio);
        require(sellFee < 45 && buyFee < 45, "Fees cannot be more than 45%");
    }

    function setMaxBuySettings(bool _globalTxWatcher) external authorized {
        limitsEnabled = _globalTxWatcher;
    }
}