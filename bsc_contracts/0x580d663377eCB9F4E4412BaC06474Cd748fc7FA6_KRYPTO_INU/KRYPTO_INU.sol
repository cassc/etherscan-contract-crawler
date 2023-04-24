/**
 *Submitted for verification at BscScan.com on 2023-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IDexFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

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

interface IERC20Extended {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = payable(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;

    function process(uint256 gas) external;

    function claimDividend(address _user) external;

    function getPaidEarnings(
        address shareholder
    ) external view returns (uint256);

    function getUnpaidEarnings(
        address shareholder
    ) external view returns (uint256);

    function totalDistributed() external view returns (uint256);
}

contract DividendDistributor is IDividendDistributor {
    address public token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20Extended public doge =
        IERC20Extended(0xbA2aE424d960c26247Dd6c32edC70B295c744C43);
    IDexRouter public router;

    address[] public shareholders;
    mapping(address => uint256) public shareholderIndexes;
    mapping(address => uint256) public shareholderClaims;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** doge.decimals());

    uint256 currentIndex;

    bool initialized;
    modifier initializer() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == token);
        _;
    }

    constructor(address router_) {
        token = msg.sender;
        router = IDexRouter(router_);
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(
        address shareholder,
        uint256 amount
    ) external override onlyToken {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares - (shares[shareholder].amount) + (amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = doge.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(doge);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(0, path, address(this), block.timestamp);

        uint256 amount = doge.balanceOf(address(this)) - (balanceBefore);

        totalDividends = totalDividends + (amount);
        dividendsPerShare = dividendsPerShare + (
            (dividendsPerShareAccuracyFactor * amount) / (totalShares)
        );
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed + (gasLeft - (gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(
        address shareholder
    ) internal view returns (bool) {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed + (amount);
            doge.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised
                 + (amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
        }
    }

    function claimDividend(address _user) external {
        distributeDividend(_user);
    }

    function getPaidEarnings(
        address shareholder
    ) public view returns (uint256) {
        return shares[shareholder].totalRealised;
    }

    function getUnpaidEarnings(
        address shareholder
    ) public view returns (uint256) {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends - (shareholderTotalExcluded);
    }

    function getCumulativeDividends(
        uint256 share
    ) internal view returns (uint256) {
        return
            (share * dividendsPerShare) / (dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

// main contract
contract KRYPTO_INU is IERC20Extended, Ownable {

    string private constant _name = "KRYPTO INU";
    string private constant _symbol = "$KRYPTO";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 100_000_000_000 * 10 ** _decimals;

    address public doge = 0xbA2aE424d960c26247Dd6c32edC70B295c744C43;
    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);
    IDexRouter public router;
    address public pair;
    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public buyBackFeeReceiver;

    uint256 _reflectionBuyFee = 3_00;
    uint256 _buyBackBuyFee = 1_00;
    uint256 _marketingBuyFee = 4_00;

    uint256 _reflectionSellFee = 3_00;
    uint256 _buyBackSellFee = 1_00;
    uint256 _marketingSellFee = 4_00;

    uint256 _reflectionFeeCount;
    uint256 _buyBackFeeCount;
    uint256 _marketingFeeCount;

    uint256 public totalBuyFee = 8_00;
    uint256 public totalSellFee = 8_00;
    uint256 public feeDenominator = 100_00;

    DividendDistributor public distributor;
    uint256 public distributorGas = 500000;

    uint256 public maxTxnAmount = _totalSupply;
    uint256 public maxWalletAmount = _totalSupply;
    uint256 public launchedAt;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isLimitExmpt;
    mapping(address => bool) public isWalletExmpt;
    mapping(address => bool) public isDividendExempt;

    uint256 public swapThreshold = _totalSupply / 1000;
    bool public swapEnabled;
    bool public trading;
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);

    constructor() Ownable() {
        address router_ = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = 0x9A38765b185806e4E29175b7bd90C91260A4Eaf9;
        buyBackFeeReceiver = 0x21690cB4F6C52F68AE8f3321D9Dcb1831f0588a5;

        router = IDexRouter(router_);
        pair = IDexFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        distributor = new DividendDistributor(router_);

        isFeeExempt[autoLiquidityReceiver] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isFeeExempt[buyBackFeeReceiver] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(router)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(router)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;

        isLimitExmpt[autoLiquidityReceiver] = true;
        isLimitExmpt[marketingFeeReceiver] = true;
        isLimitExmpt[buyBackFeeReceiver] = true;
        isLimitExmpt[address(this)] = true;
        isLimitExmpt[address(router)] = true;

        isWalletExmpt[autoLiquidityReceiver] = true;
        isWalletExmpt[marketingFeeReceiver] = true;
        isWalletExmpt[buyBackFeeReceiver] = true;
        isWalletExmpt[pair] = true;
        isWalletExmpt[DEAD] = true;
        isWalletExmpt[ZERO] = true;
        isWalletExmpt[address(router)] = true;
        isWalletExmpt[address(this)] = true;

        _allowances[address(this)][address(router)] = _totalSupply;
        _allowances[address(this)][address(pair)] = _totalSupply;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external pure override returns (uint256) {
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
                 - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (!isLimitExmpt[sender] && !isLimitExmpt[recipient]) {
            require(amount <= maxTxnAmount, "Max txn limit exceeds");

            // trading disable till launch
            if (!trading) {
                require(
                    pair != sender && pair != recipient,
                    "Trading is disable"
                );
            }
        }

        if (!isWalletExmpt[recipient]) {
            require(
                balanceOf(recipient) + (amount) <= maxWalletAmount,
                "Max Wallet limit exceeds"
            );
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        _balances[sender] = _balances[sender] - 
            amount;

        uint256 amountReceived;
        if (
            isFeeExempt[sender] ||
            isFeeExempt[recipient] ||
            (sender != pair && recipient != pair)
        ) {
            amountReceived = amount;
        } else {
            uint256 feeAmount;
            if (sender == pair) {
                feeAmount = (amount * totalBuyFee) / (feeDenominator);
                amountReceived = amount - (feeAmount);
                takeFee(sender, feeAmount);
                setBuyAccFee(amount);
            } else {
                feeAmount = (amount * totalSellFee) / (feeDenominator);
                amountReceived = amount - (feeAmount);
                takeFee(sender, feeAmount);
                setSellAccFee(amount);
            }
        }

        _balances[recipient] = _balances[recipient] + (amountReceived);

        if (!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }
        if (!isDividendExempt[recipient]) {
            try
                distributor.setShare(recipient, _balances[recipient])
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
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + (amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, uint256 feeAmount) internal {
        _balances[address(this)] = _balances[address(this)] + (feeAmount);
        emit Transfer(sender, address(this), feeAmount);
    }

    function setBuyAccFee(uint256 _amount) internal {
        _buyBackFeeCount += (_amount * _buyBackBuyFee) / (feeDenominator);
        _reflectionFeeCount += (_amount * _reflectionBuyFee) / (
            feeDenominator
        );
        _marketingFeeCount += (_amount * _marketingBuyFee) / (feeDenominator);
    }

    function setSellAccFee(uint256 _amount) internal {
        _buyBackFeeCount += (_amount * _buyBackSellFee) / (feeDenominator);
        _reflectionFeeCount += (_amount * _reflectionSellFee) / (
            feeDenominator
        );
        _marketingFeeCount += (_amount * _marketingSellFee) / (
            feeDenominator
        );
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 totalFee = _buyBackFeeCount + (_reflectionFeeCount) + (
            _marketingFeeCount
        );

        uint256 amountToSwap = balanceOf(address(this));
        _allowances[address(this)][address(router)] = amountToSwap;
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

        uint256 amountBNBReflection = (amountBNB * _reflectionFeeCount) / (
            totalFee
        );
        if (amountBNBReflection > 0) {
            try distributor.deposit{value: amountBNBReflection}() {} catch {}
        }

        uint256 amountBNBBuyback = (amountBNB * _buyBackFeeCount) / (
            totalFee
        );

        if (amountBNBBuyback > 0) {
            payable(buyBackFeeReceiver).transfer(amountBNBBuyback);
        }

        uint256 amountBNBMarketing = amountBNB - (amountBNBReflection) - (
            amountBNBBuyback
        );

        if (amountBNBMarketing > 0) {
            payable(marketingFeeReceiver).transfer(amountBNBMarketing);
        }

        _reflectionFeeCount = 0;
        _buyBackFeeCount = 0;
        _marketingFeeCount = 0;
    }

    function claimDividend() external {
        distributor.claimDividend(msg.sender);
    }

    function getPaidDividend(
        address shareholder
    ) public view returns (uint256) {
        return distributor.getPaidEarnings(shareholder);
    }

    function getUnpaidDividend(
        address shareholder
    ) external view returns (uint256) {
        return distributor.getUnpaidEarnings(shareholder);
    }

    function getTotalDistributedDividend() external view returns (uint256) {
        return distributor.totalDistributed();
    }

    function setIsDividendExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function enableTrading() external onlyOwner {
        require(!trading, "Already enabled");
        trading = true;
        swapEnabled = true;
        launchedAt = block.timestamp;
    }

    function removeStuckEth(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    function setMaxTxnAmount(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 1000);
        maxTxnAmount = amount;
    }

    function setMaxWalletAmount(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 1000);
        maxWalletAmount = amount;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsLimitExempt(
        address[] memory holders,
        bool exempt
    ) external onlyOwner {
        for (uint256 i; i < holders.length; i++) {
            isLimitExmpt[holders[i]] = exempt;
        }
    }

    function setIsWalletExempt(address holder, bool exempt) external onlyOwner {
        isWalletExmpt[holder] = exempt;
    }

    function setBuyFees(
        uint256 _reflectionFee,
        uint256 _buyBackFee,
        uint256 _marketingFee
    ) public onlyOwner {
        _reflectionBuyFee = _reflectionFee;
        _buyBackBuyFee = _buyBackFee;
        _marketingBuyFee = _marketingFee;
        totalBuyFee = _buyBackFee + (_reflectionFee) + (_marketingFee);
        require(
            totalBuyFee <= (feeDenominator * 15) / (100),
            "Can't be greater than 15%"
        );
    }

    function setSellFees(
        uint256 _buyBackFee,
        uint256 _reflectionFee,
        uint256 _marketingFee
    ) public onlyOwner {
        _buyBackSellFee = _buyBackFee;
        _reflectionSellFee = _reflectionFee;
        _marketingSellFee = _marketingFee;
        totalSellFee = _buyBackFee + (_reflectionFee) + (_marketingFee);
        require(
            totalSellFee <= (feeDenominator * 15) / (100),
            "Can't be greater than 15%"
        );
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _marketingFeeReceiver,
        address _buyBackFeeReceiver
    ) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        buyBackFeeReceiver = _buyBackFeeReceiver;
    }

    function setSwapBackSettings(
        bool _enabled,
        uint256 _amount
    ) external onlyOwner {
        require(swapThreshold > 0);
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000, "Gas must be lower than 750000");
        distributorGas = gas;
    }
}