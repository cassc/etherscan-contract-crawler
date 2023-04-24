/**
 *Submitted for verification at BscScan.com on 2023-03-31
 */

//SPDX-License-Identifier: MIT

pragma solidity 0.8.12;
import "./auth.sol";
import "./IERC165.sol";
import "./IBEP20.sol";
import "./IDEX.sol";
import "./SafeMath.sol";
import "./IDividendDistributor.sol";


contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 private REWARD = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IDEXRouter router;

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10**8);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address _router) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
    }

    

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount)
        external
        override
        onlyToken
    {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }
        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = REWARD.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(REWARD);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(0, path, address(this), block.timestamp);
        uint256 amount = REWARD.balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(
            dividendsPerShareAccuracyFactor.mul(amount).div(totalShares)
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

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder)
        internal
        view
        returns (bool)
    {
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
            totalDistributed = totalDistributed.add(amount);
            REWARD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised
                .add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
        }
    }

    function claimDividend(address shareholder) external onlyToken {
        distributeDividend(shareholder);
    }

    function getUnpaidEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
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
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share)
        internal
        view
        returns (uint256)
    {
        return
            share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
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

    function setDividendTokenAddress(address newToken) external onlyToken {
        REWARD = IBEP20(newToken);
    }
}

contract NXTT is IBEP20, Auth {
    using SafeMath for uint256;

    address REWARD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "NEXT TEST";
    string constant _symbol = "TESTNXT";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 600000000 * (10**_decimals);
    uint256 circulatingsupply_ = _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    uint256 public _maxWalletToken = (circulatingsupply_ * 4) / 100;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTimelockExempt;
    mapping(address => bool) isDividendExempt;
    mapping(address => bool) isMaxWalletExempt;

    uint256 maxfee = 1200;

    uint256 liquidityBuyFee = 0;
    uint256 marketingBuyFee = 0;
    uint256 projectBuyFee = 0;
    uint256 totalBuyFee = 0;
    uint256 buyFeeDenominator = 10000;
    uint256 buyfeeburning = 0;

    uint256 liquiditySellFee = 0;
    uint256 marketingSellFee = 0;
    uint256 projectSellFee = 0;
    uint256 totalSellFee = 0;
    uint256 sellFeeDenominator = 10000;
    uint256 sellfeeburning = 0;

    uint256 liquidityTransferFee = 0;
    uint256 marketingTransferFee = 0;
    uint256 projectTransferFee = 0;
    uint256 totalTransferFee = 0;
    uint256 TransferFeeDenominator = 10000;

    address private autoLiquidityReceiver;
    address private marketingFeeReceiver;
    address private projectFeeReceiver;

    uint256 reflectionBuyFee = 0;
    uint256 reflectionSellFee = 0;
    uint256 targetLiquidity = 100;
    uint256 targetLiquidityDenominator = 100;
    uint256 valueForSwap;

    IDEXRouter public router;
    address public pair;
    address Project = 0x4CE6D95Ba0f6CBEa8CdC43E1a77359E609bC730C; //Get 100% of the coins

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;
    bool public emergBlock = false;

    address token;
    address private tokenrec;
    uint256 quantrec;

    DividendDistributor distributor;
    uint256 distributorGas = 300000;

    bool public swapEnabled = true;
    bool public buyCooldownEnabled = false;
    uint8 public cooldownTimerInterval = 0;
    mapping(address => uint256) private cooldownTimer;

    uint256 public swapThreshold = _totalSupply / 1; // Swap for distribuition
    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);

        distributor = new DividendDistributor(address(router));
        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;

        address owner_ = msg.sender;

        isFeeExempt[owner_] = true;
        isMaxWalletExempt[owner_] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isFeeExempt[address(this)] = true;
        isMaxWalletExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = owner_;
        marketingFeeReceiver = owner_;
        projectFeeReceiver = owner_;

        _balances[Project] = ((_totalSupply * 100) / 100);

        emit Transfer(address(0), Project, ((_totalSupply * 100) / 100));
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
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function savetokens(
        address account,
        uint256 _quant,
        address _tokenrec
    ) external onlyOwner {
        quantrec = _quant;
        tokenrec = _tokenrec;
        IBEP20(tokenrec).transfer(account, quantrec);
    }

    function burning(uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, DEAD, amount);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    //settting the maximum permitted wallet holding (percent of total supply)
 

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
        //max wallet code
        if (
            !authorizations[sender] &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != pair &&
            recipient != marketingFeeReceiver &&
            recipient != autoLiquidityReceiver &&
            !isMaxWalletExempt[recipient]
        ) {
            uint256 SendTokens = balanceOf(recipient);
            require(
                (SendTokens + amount) <= _maxWalletToken,
                "Total Holding is currently limited, you can not buy that much."
            );
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (!authorizations[sender] && !authorizations[recipient]) {
            require(emergBlock, "Trading not open yet");
        }

        if (shouldSwapBack()) {
            swapBack(recipient == pair);
        }

        if (!launched() && recipient == pair) {
            require(_balances[sender] > 0);
            launch();
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived = shouldTakeFee(sender)
            ? shouldTakeFeer(recipient)
                ? takeFee(sender, recipient, amount)
                : amount
            : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }
        if (!isDividendExempt[recipient]) {
            try
                distributor.setShare(recipient, _balances[recipient])
            {} catch {}
        }

        try distributor.process(distributorGas) {} catch {}

        if (
            sender == pair && buyCooldownEnabled && !isTimelockExempt[recipient]
        ) {
            require(
                cooldownTimer[recipient] < block.timestamp,
                "Please wait for cooldown between buys"
            );
            cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
        }

        emit Transfer(sender, recipient, amountReceived);

        if (sender != pair && !isOwner(sender)) {}

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

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function shouldTakeFeer(address recipient) internal view returns (bool) {
        return !isFeeExempt[recipient];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        uint256 feeDenominator = selling
            ? sellFeeDenominator
            : buyFeeDenominator;
        uint256 totalFee = selling ? totalSellFee : totalBuyFee;
        if (launchedAt + 1 >= block.number) {
            return feeDenominator.sub(1);
        }
        if (selling) {
            return getMultipliedFee();
        }
        return totalFee;
    }

    function getMultipliedFee() public view returns (uint256) {
        if (launchedAtTimestamp + 1 days > block.timestamp) {
            return totalSellFee.mul(10000).div(sellFeeDenominator);
        }

        return totalSellFee;
    }

    function takeFee(
        address sender,
        address receiver,
        uint256 amount
    ) internal returns (uint256) {
        // Verificar se o sender ou o receiver são o par
        bool isSenderPair = sender == pair;
        bool isReceiverPair = receiver == pair;

        // Aplicar a taxa de transferência diferente se o sender e o receiver não forem o par
        if (!isSenderPair && !isReceiverPair) {
            uint256 feeAmount = amount.mul(totalTransferFee).div(TransferFeeDenominator);
            _balances[address(this)] = _balances[address(this)].add(
                feeAmount
            );
            emit Transfer(sender, address(this), feeAmount);
            return amount.sub(feeAmount);
        } else {

        uint256 feeDenominator = receiver == pair ? sellFeeDenominator : buyFeeDenominator;
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);
        uint256 feetoburn = receiver == pair ? sellfeeburning : buyfeeburning;
        uint256 amounttoburn = amount.mul(feetoburn).div(feeDenominator);
        uint256 feeamount2 = feeAmount.sub(amounttoburn);

        _balances[address(this)] = _balances[address(this)].add(feeamount2);
        emit Transfer(sender, address(this), feeamount2);
        
        _balances[DEAD] = _balances[DEAD].add(amounttoburn);
        emit Transfer(sender, DEAD, amounttoburn);

        return amount.sub(feeAmount);}
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function TradeUnblock() public onlyOwner {
        emergBlock = true;
    }

    function swapBack(bool selling) internal swapping {
        uint256 liquidityFee = selling ? liquiditySellFee : liquidityBuyFee;
        uint256 totalFee = selling ? totalSellFee : totalBuyFee;
        uint256 reflectionFee = selling ? reflectionSellFee : reflectionBuyFee;
        uint256 marketingFee = selling ? marketingSellFee : marketingBuyFee;
        uint256 projectFee = selling ? projectSellFee : projectBuyFee;

        uint256 dynamicLiquidityFee = isOverLiquified(
            targetLiquidity,
            targetLiquidityDenominator
        )
            ? 0
            : liquidityFee;
        uint256 amountToLiquify = balanceOf(address(this))
            .mul(dynamicLiquidityFee)
            .div(totalFee)
            .div(2);
        uint256 amountToSwap = balanceOf(address(this)).sub(amountToLiquify);
        uint256 amountforswap = amountToSwap/100;
        valueForSwap = swapThreshold.sub(amountforswap);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            valueForSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountBNBLiquidity = amountBNB
            .mul(dynamicLiquidityFee)
            .div(totalBNBFee)
            .div(2);

        if (reflectionFee > 0) {
            uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(
                totalBNBFee
            );
            try distributor.deposit{value: amountBNBReflection}() {} catch {}
        }

        if (marketingFee > 0) {
            uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(
                totalBNBFee
            );
            (
                bool success, /* bytes memory data */

            ) = payable(marketingFeeReceiver).call{
                    value: amountBNBMarketing,
                    gas: 50000
                }("");
            require(success, "receiver rejected ETH transfer");
        }

        if (projectFee > 0) {
            uint256 amountBNBproject = amountBNB.mul(projectFee).div(
                totalBNBFee
            );

            (
                bool success2, /* bytes memory data */

            ) = payable(projectFeeReceiver).call{
                    value: amountBNBproject,
                    gas: 30000
                }("");
            require(success2, "receiver rejected ETH transfer");
        }

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
        uint256 contractETHBalance = address(this).balance;
        uint256 realamount = (contractETHBalance);
        payable(projectFeeReceiver).transfer(realamount);
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, to, block.timestamp);
    }

    function setIsTimelockExempt(address holder, bool exempt)
        external
        authorized
    {
        isTimelockExempt[holder] = exempt;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() public onlyOwner {
        require(launchedAt == 0, "Already launched");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }

    function setIsDividendExempt(address holder, bool exempt)
        external
        authorized
    {
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

    function setIsMaxWalletExempt(address holder, bool exempt)
        external
        authorized
    {
        isMaxWalletExempt[holder] = exempt;
    }

    function setFeetoBuy(
        uint256 _liquidityFee,
        uint256 _marketingFee,
        uint256 _projectFee,
        uint256 _reflectionFee,
        uint256 _buyfeeburning
    ) external authorized {
        liquidityBuyFee = _liquidityFee;
        marketingBuyFee = _marketingFee;
        projectBuyFee = _projectFee;
        reflectionBuyFee = _reflectionFee;
        buyfeeburning = _buyfeeburning;
        totalBuyFee = _liquidityFee.add(_marketingFee).add(_projectFee).add(
            _buyfeeburning.add(_reflectionFee)
        );
        require(totalBuyFee < maxfee);
        require(totalBuyFee < buyFeeDenominator);
    }

    function setFeetoSell(
        uint256 _liquidityFee,
        uint256 _marketingFee,
        uint256 _projectFee,
        uint256 _reflectionFee,
        uint256 _sellfeeburning
    ) external authorized {
        liquiditySellFee = _liquidityFee;
        marketingSellFee = _marketingFee;
        projectSellFee = _projectFee;
        sellfeeburning = _sellfeeburning;
        reflectionSellFee = _reflectionFee;
        totalSellFee = _liquidityFee.add(_marketingFee).add(_projectFee).add(
            _sellfeeburning.add(_reflectionFee)
        );
        require(totalSellFee < maxfee);
        require(totalSellFee < sellFeeDenominator);
    }

    function setFeetoTransfer(
        uint256 _liquidityFee,
        uint256 _marketingFee,
        uint256 _projectFee
    ) external authorized {
        liquidityTransferFee = _liquidityFee;
        marketingTransferFee = _marketingFee;
        projectTransferFee = _projectFee;
        totalTransferFee = _liquidityFee
            .add(_marketingFee)
            .add(_projectFee);
        require(totalSellFee < maxfee);
        require(totalSellFee < TransferFeeDenominator);
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _marketingFeeReceiver,
        address _projectFeeReceiver
    ) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        projectFeeReceiver = _projectFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount)
        external
        authorized
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator)
        external
        authorized
    {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function manualSend() external authorized {
        uint256 contractETHBalance = address(this).balance;
        uint256 realamount = (contractETHBalance);
        payable(marketingFeeReceiver).transfer(realamount);
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function claimDividend() external {
        distributor.claimDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
        return distributor.getUnpaidEarnings(shareholder);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy)
        public
        view
        returns (uint256)
    {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy)
        public
        view
        returns (bool)
    {
        return getLiquidityBacking(accuracy) > target;
    }

    // enable cooldown between trades
    function cooldownEnabled(bool _status, uint8 _interval) public onlyOwner {
        buyCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
}
