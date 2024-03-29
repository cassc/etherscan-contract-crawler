//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./DividendDistributor.sol";

contract EARN is IERC20, Ownable {
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    address public REWARD = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC

    string constant _name = "EARN";
    string constant _symbol = "$EARN";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100000000000 * (10**_decimals); // One hundred billions

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isDividendExempt;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isMaxBuyLimitExcluded;
    mapping(address => bool) public isMaxSellLimitExcluded;
    mapping(address => bool) public isAuthorized;

    address public marketingWallet;
    address public buyBackWallet;
    address public lpReceiver;

    // Fees
    uint256 public rewardFee = 11;

    uint256 public buyLiquidityFee = 1;
    uint256 public buyBuyBackFee = 1;
    uint256 public buyMarketingFee = 2;
    uint256 public buyTotalFee = 15;

    uint256 public sellLiquidityFee = 1;
    uint256 public sellBuyBackFee = 1;
    uint256 public sellMarketingFee = 2;
    uint256 public sellTotalFee = 15;

    uint256 public swapLiquidityFee = 1;
    uint256 public swapBuyBackFee = 1;
    uint256 public swapMarketingFee = 2;
    uint256 public swapTotalFee = 15;

    IUniswapV2Router02 public router;
    address public pair;

    DividendDistributor public dividendTracker;

    uint256 distributorGas = 500000;

    uint256 public maxSellLimit = 0;
    uint256 public maxBuyLimit = 0;

    bool public isSellCoolDownEnabled = true;
    uint256 public sellCoolDownTime = 15 minutes;

    uint256 public lastSwapTime;

    uint256 public swapThreshold = (_totalSupply * 1) / 10000; // 0.001% of supply
    bool public contractSwapEnabled = true;
    bool public isTradeEnabled = false;
    bool inContractSwap;
    modifier swapping() {
        inContractSwap = true;
        _;
        inContractSwap = false;
    }

    event SetIsDividendExempt(address holder, bool status);
    event SetIsFeeExempt(address holder, bool status);
    event AddAuthorizedWallet(address holder, bool status);
    event SetDoContractSwap(bool status);
    event DoContractSwap(uint256 amount, uint256 time);
    event ChangeDistributionCriteria(
        uint256 minPeriod,
        uint256 minDistribution
    );

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);

    constructor() {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = type(uint256).max;

        dividendTracker = new DividendDistributor(REWARD);

        marketingWallet = 0xBA3944d8f9057e4fA32c80039385d21b1A689e59;
        buyBackWallet = 0x3193669b46F25a63ed6D32024C1409b12a26563E;
        lpReceiver = 0x91b1DC8443848314FA9B1f3F16497521A16b59ca;

        address deployer = 0x4958122d53756655616262168867B4AaB7496BA8;

        isFeeExempt[deployer] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[marketingWallet] = true;
        isFeeExempt[buyBackWallet] = true;
        isFeeExempt[lpReceiver] = true;

        isDividendExempt[deployer] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[ZERO] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[lpReceiver] = true;
        isDividendExempt[buyBackWallet] = true;
        isDividendExempt[marketingWallet] = true;

        isAuthorized[deployer] = true;
        isAuthorized[pair] = true;
        isAuthorized[address(this)] = true;
        isAuthorized[ZERO] = true;
        isAuthorized[DEAD] = true;
        isAuthorized[lpReceiver] = true;
        isAuthorized[buyBackWallet] = true;
        isAuthorized[marketingWallet] = true;

        isMaxBuyLimitExcluded[deployer] = true;
        isMaxSellLimitExcluded[deployer] = true;

        _balances[deployer] = _totalSupply;
        emit Transfer(address(0), deployer, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function getHolderDetails(address holder)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getHolderDetails(holder);
    }

    function getLastProcessedIndex() public view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfTokenHolders() public view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function totalDistributedRewards() public view returns (uint256) {
        return dividendTracker.totalDistributedRewards();
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
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
            require(
                _allowances[sender][msg.sender] >= amount,
                "Insufficient Allowance"
            );
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(
            !isBlacklisted[sender] && !isBlacklisted[recipient],
            "Blacklisted users"
        );
        if (!isTradeEnabled) require(isAuthorized[sender], "Trading disabled");
        if (inContractSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldDoContractSwap()) {
            doContractSwap();
        }
        {
            if (
                sender == pair &&
                !isMaxBuyLimitExcluded[recipient] &&
                maxBuyLimit != 0
            ) require(amount <= maxBuyLimit, "Max buy limit exceeded");

            if (
                recipient == pair &&
                !isMaxSellLimitExcluded[sender] &&
                maxSellLimit != 0
            ) require(amount <= maxSellLimit, "Max sell limit exceeded");
        }

        require(_balances[sender] >= amount, "Insufficient Balance");
        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, amount)
            : amount;
        _balances[recipient] = _balances[recipient] + amountReceived;

        if (!isDividendExempt[sender]) {
            try dividendTracker.setShare(sender, _balances[sender]) {} catch {}
        }

        if (!isDividendExempt[recipient]) {
            try
                dividendTracker.setShare(recipient, _balances[recipient])
            {} catch {}
        }

        try dividendTracker.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeToken;

        if (recipient == pair) feeToken = (amount * sellTotalFee) / 100;
        else feeToken = (amount * buyTotalFee) / 100;

        _balances[address(this)] = _balances[address(this)] + feeToken;
        emit Transfer(sender, address(this), feeToken);

        return (amount - feeToken);
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(_balances[sender] >= amount, "Insufficient Balance");
        _balances[sender] = _balances[sender] - amount;

        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender, address to)
        internal
        view
        returns (bool)
    {
        if (isFeeExempt[sender] || isFeeExempt[to]) {
            return false;
        } else {
            return true;
        }
    }

    function shouldDoContractSwap() internal view returns (bool) {
        return (msg.sender != pair &&
            !inContractSwap &&
            contractSwapEnabled &&
            (lastSwapTime + sellCoolDownTime) <= block.timestamp &&
            _balances[address(this)] >= swapThreshold);
    }

    // Claim manually
    function ___claimRewards(bool tryAll) public {
        dividendTracker.claimDividend();
        if (tryAll) {
            try dividendTracker.process(distributorGas) {} catch {}
        }
    }

    // Clear the queue manually
    function claimProcess() public {
        try dividendTracker.process(distributorGas) {} catch {}
    }

    function isRewardExcluded(address _wallet) public view returns (bool) {
        return isDividendExempt[_wallet];
    }

    function isFeeExcluded(address _wallet) public view returns (bool) {
        return isFeeExempt[_wallet];
    }

    function doContractSwap() internal swapping {
        uint256 contractTokenBalance = _balances[address(this)];

        uint256 tokensToLp = (contractTokenBalance * swapLiquidityFee) /
            swapTotalFee;
        uint256 tokensToReward = (contractTokenBalance * rewardFee) /
            swapTotalFee;

        uint256 buyBackAndMarketingFee = swapBuyBackFee + swapMarketingFee;

        uint256 tokensToSwap = contractTokenBalance -
            tokensToLp -
            tokensToReward;

        if (tokensToReward > 0) {
            swapTokensForTokens(tokensToReward, REWARD);

            uint256 swappedRewardTokens = IERC20(REWARD).balanceOf(
                address(this)
            );
            IERC20(REWARD).transfer(
                address(dividendTracker),
                swappedRewardTokens
            );
            try dividendTracker.deposit(swappedRewardTokens) {} catch {}
        }
        if (tokensToSwap > 0 && buyBackAndMarketingFee > 0) {
            swapTokensForEth(tokensToSwap);

            uint256 swappedTokens = address(this).balance;

            uint256 tokensForMarketing = (swappedTokens * swapMarketingFee) /
                buyBackAndMarketingFee;

            uint256 tokensForBuyBack = swappedTokens - tokensForMarketing;

            if (tokensForMarketing > 0)
                payable(marketingWallet).transfer(tokensForMarketing);

            if (tokensForBuyBack > 0)
                payable(buyBackWallet).transfer(tokensForBuyBack);
        }

        if (tokensToLp > 0) swapAndLiquify(tokensToLp);

        lastSwapTime = block.timestamp;
    }

    // All tax wallets receive BUSD instead of BNB
    function swapTokensForTokens(uint256 tokenAmount, address tokenToSwap)
        private
    {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = router.WETH();
        path[2] = tokenToSwap;
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of tokens
            path,
            address(this),
            block.timestamp
        );
    }

    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit AutoLiquify(newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpReceiver,
            block.timestamp
        );
    }

    function setIsDividendExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        require(
            holder != address(this) && holder != pair,
            "can not add pair and token address as share holder"
        );
        isDividendExempt[holder] = exempt;
        if (exempt) {
            dividendTracker.setShare(holder, 0);
        } else {
            dividendTracker.setShare(holder, _balances[holder]);
        }

        emit SetIsDividendExempt(holder, exempt);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;

        emit SetIsFeeExempt(holder, exempt);
    }

    function setDoContractSwap(bool _enabled) external onlyOwner {
        contractSwapEnabled = _enabled;

        emit SetDoContractSwap(_enabled);
    }

    function blackListWallets(address _wallet, bool _status)
        external
        onlyOwner
    {
        isBlacklisted[_wallet] = _status;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external onlyOwner {
        dividendTracker.setDistributionCriteria(_minPeriod, _minDistribution);

        emit ChangeDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }

    function changeMarketingWallet(address _wallet) external onlyOwner {
        marketingWallet = _wallet;
    }

    function changeBuyBackWallet(address _wallet) external onlyOwner {
        buyBackWallet = _wallet;
    }

    function changeLPWallet(address _wallet) external onlyOwner {
        lpReceiver = _wallet;
    }

    function changeBuyFees(
        uint256 _liquidityFee,
        uint256 _buyBackFee,
        uint256 _marketingFee
    ) external onlyOwner {
        buyLiquidityFee = _liquidityFee;
        buyBuyBackFee = _buyBackFee;
        buyMarketingFee = _marketingFee;

        buyTotalFee = rewardFee + _liquidityFee + _buyBackFee + _marketingFee;

        require(buyTotalFee <= 15, "Total fees can not greater than 15%");
    }

    function changeSellFees(
        uint256 _liquidityFee,
        uint256 _buyBackFee,
        uint256 _marketingFee
    ) external onlyOwner {
        sellLiquidityFee = _liquidityFee;
        sellBuyBackFee = _buyBackFee;
        sellMarketingFee = _marketingFee;

        sellTotalFee = rewardFee + _liquidityFee + _buyBackFee + _marketingFee;

        require(sellTotalFee <= 15, "Total fees can not greater than 15%");
    }

    function changeSwapFees(
        uint256 _liquidityFee,
        uint256 _buyBackFee,
        uint256 _marketingFee
    ) external onlyOwner {
        swapLiquidityFee = _liquidityFee;
        swapBuyBackFee = _buyBackFee;
        swapMarketingFee = _marketingFee;

        swapTotalFee = rewardFee + _liquidityFee + _buyBackFee + _marketingFee;

        require(swapTotalFee <= 15, "Total fees can not greater than 15%");
    }

    function setSellCollDown(bool _status, uint256 _coolDownTime)
        external
        onlyOwner
    {
        isSellCoolDownEnabled = _status;
        sellCoolDownTime = _coolDownTime;
    }

    function changeSellLimit(uint256 _limit) external onlyOwner {
        if (_limit > 0)
            require(
                _limit >= 100 * 10**6 * 10**_decimals,
                "Limit can not less than 250 million"
            );

        maxSellLimit = _limit;
    }

    function changeBuyLimit(uint256 _limit) external onlyOwner {
        if (_limit > 0)
            require(
                _limit >= 100 * 10**6 * 10**_decimals,
                "Limit can not less than 250 million"
            );
        maxBuyLimit = _limit;
    }

    function excludeFromMaxSell(address _wallet, bool _status)
        external
        onlyOwner
    {
        isMaxSellLimitExcluded[_wallet] = _status;
    }

    function excludeFromMaxBuy(address _wallet, bool _status)
        external
        onlyOwner
    {
        isMaxBuyLimitExcluded[_wallet] = _status;
    }

    function enableTrading() external onlyOwner {
        isTradeEnabled = true;
    }

    function setAuthorizedWallets(address _wallet, bool _status)
        external
        onlyOwner
    {
        isAuthorized[_wallet] = _status;
    }

    function rescueEth() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No enough ETH to transfer");

        payable(msg.sender).transfer(balance);
    }

    function purgeBeforeSwitch() public onlyOwner {
        dividendTracker.purge(msg.sender);
    }

    function depositRewards(uint256 _rewardAmount) external onlyOwner {
        IERC20(REWARD).transferFrom(
            msg.sender,
            address(dividendTracker),
            _rewardAmount
        );

        try dividendTracker.deposit(_rewardAmount) {} catch {}
    }
}