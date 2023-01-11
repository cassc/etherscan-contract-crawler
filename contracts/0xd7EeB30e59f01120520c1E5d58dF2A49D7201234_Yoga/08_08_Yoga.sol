// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./DividendDistributor.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Auth.sol";

contract Yoga is IERC20, Auth {
    using SafeMath for uint256;

    address private constant ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;

    string private constant _name = "Yoga";
    string private constant _symbol = "YOGA";
    uint8 private constant _decimals = 18;

    uint256 private _totalSupply = 1_000_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.mul(1).div(100); // 1.00% (10_000_000)
    uint256 public _maxWallet = _totalSupply.mul(1).div(100); // 1.00% (10_000_000)

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isDividendExempt;
    mapping(address => bool) public canAddLiquidityBeforeLaunch;

    uint256 private liquidityFee;
    uint256 private buybackFee;
    uint256 private reflectionFee;
    uint256 private investmentFee;
    uint256 private devFee;
    uint256 private totalFee;
    uint256 public feeDenominator = 10000;

    // Buy Fees
    uint256 public reflectionFeeBuy = 250;
    uint256 public investmentFeeBuy = 250;
    uint256 public devFeeBuy = 100;
    uint256 public totalFeeBuy = 600;
    // Sell Fees
    uint256 public reflectionFeeSell = 1000;
    uint256 public investmentFeeSell = 1000;
    uint256 public devFeeSell = 500;
    uint256 public totalFeeSell = 2500;

    IUniswapV2Router02 public router;
    address public pair;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;

    // Fees receivers
    address public investmentFeeReceiver =
        0xfbA3d4dc80d9E5C547084C3F0b338Ca3E59e5609;
    address private devWalletOne;
    address private devWalletTwo;

    DividendDistributor public distributor;
    address public distributorAddress;
    uint256 private distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply.mul(5).div(10000); // 0.05% (500_000)
    bool public inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address _devWalletOne, address _devWalletTwo) Auth(msg.sender) {
        router = IUniswapV2Router02(ROUTER);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = _totalSupply;

        distributor = new DividendDistributor(address(router));
        distributorAddress = address(distributor);

        devWalletOne = _devWalletOne;
        devWalletTwo = _devWalletTwo;

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        canAddLiquidityBeforeLaunch[msg.sender] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        approve(address(router), _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        // Avoid lauchpad buyers from ADD LP before launch
        if (!launched() && recipient == pair && sender == pair) {
            require(canAddLiquidityBeforeLaunch[sender]);
        }

        if (!authorizations[sender] && !authorizations[recipient]) {
            require(launched(), "Trading not open yet");
        }

        // max wallet code
        if (
            !authorizations[sender] &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != pair &&
            recipient != investmentFeeReceiver
        ) {
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= _maxWallet,
                "Total Holding is currently limited, you can not buy that much."
            );
        }

        checkTxLimit(sender, amount);

        // Set Fees
        if (sender == pair) {
            buyFees();
        }
        if (recipient == pair) {
            sellFees();
        }

        //Exchange tokens
        if (shouldSwapBack()) {
            swapBack();
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived = shouldTakeFee(sender)
            ? takeFee(recipient, amount)
            : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        // Dividend tracker
        if (!isDividendExempt[sender]) {
            try distributor.setShare(sender, balanceOf(sender)) {} catch {}
        }
        if (!isDividendExempt[recipient]) {
            try
                distributor.setShare(recipient, balanceOf(recipient))
            {} catch {}
        }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
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

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
    }

    // Internal Functions
    function buyFees() internal {
        reflectionFee = reflectionFeeBuy;
        investmentFee = investmentFeeBuy;
        devFee = devFeeBuy;
        totalFee = totalFeeBuy;
    }

    function sellFees() internal {
        reflectionFee = reflectionFeeSell;
        investmentFee = investmentFeeSell;
        devFee = devFeeSell;
        totalFee = totalFeeSell;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapThreshold,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);

        uint256 amountETHReflection = amountETH.mul(reflectionFee).div(
            totalFee
        );
        uint256 amountETHInvestment = amountETH.mul(investmentFee).div(
            totalFee
        );
        uint256 amountETHDevOne = amountETH.mul(devFee).div(totalFee).div(2);
        uint256 amountETHDevTwo = amountETH
            .sub(amountETHReflection)
            .sub(amountETHInvestment)
            .sub(amountETHDevOne);

        try distributor.deposit{value: amountETHReflection}() {} catch {}
        payable(investmentFeeReceiver).transfer(amountETHInvestment);
        payable(devWalletOne).transfer(amountETHDevOne);
        payable(devWalletTwo).transfer(amountETHDevTwo);
    }

    // Add extra rewards to holders
    function deposit() external payable authorized {
        try distributor.deposit{value: msg.value}() {} catch {}
    }

    // Process rewards distributions to holders
    function process() external authorized {
        try distributor.process(distributorGas) {} catch {}
    }

    // Stuck Balances Functions
    function rescueToken(
        address tokenAddress,
        uint256 tokens
    ) public authorized returns (bool success) {
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function clearStuckBalance(uint256 amountPercentage) external authorized {
        uint256 amountETH = address(this).balance;
        payable(investmentFeeReceiver).transfer(
            (amountETH * amountPercentage) / 100
        );
    }

    function setSellFees(
        uint256 _reflectionFee,
        uint256 _investmentFee,
        uint256 _devFee
    ) external onlyOwner {
        reflectionFeeSell = _reflectionFee;
        investmentFeeSell = _investmentFee;
        devFeeSell = _devFee;
        totalFeeSell = (_reflectionFee) + (_investmentFee) + (_devFee);
    }

    function setBuyFees(
        uint256 _reflectionFee,
        uint256 _investmentFee,
        uint256 _devFee
    ) external onlyOwner {
        reflectionFeeBuy = _reflectionFee;
        investmentFeeBuy = _investmentFee;
        devFeeBuy = _devFee;
        totalFeeBuy = (_reflectionFee) + (_investmentFee) + (_devFee);
    }

    function setFeeReceivers(
        address _investmentFeeReceiver
    ) external authorized {
        investmentFeeReceiver = _investmentFeeReceiver;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() public onlyOwner {
        require(launchedAt == 0, "Already launched boi");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }

    function setMaxWallet(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 1000);
        _maxWallet = amount;
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(
        address holder,
        bool exempt
    ) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(
        address holder,
        bool exempt
    ) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setSwapBackSettings(
        bool _enabled,
        uint256 _amount
    ) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setCanTransferBeforeLaunch(
        address holder,
        bool exempt
    ) external onlyOwner {
        canAddLiquidityBeforeLaunch[holder] = exempt; //Presale Address will be added as Exempt
        isTxLimitExempt[holder] = exempt;
        isFeeExempt[holder] = exempt;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 900000);
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
}