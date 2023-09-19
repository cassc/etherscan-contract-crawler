/**
 *Submitted for verification at Etherscan.io on 2023-08-04
*/

/**

"What happens today will effect your tomorrow."

https://butterflyeffect-erc.vip/
https://t.me/ButterflyEffectCoin
https://twitter.com/Effect_ERC


*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b <= a, errorMessage); return a - b;}}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a / b;}}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a % b;}}}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

interface stakeIntegration {
    function stakingWithdraw(address depositor, uint256 _amount) external;
    function stakingDeposit(address depositor, uint256 _amount) external;
    function stakingClaimToCompound(address sender, address recipient) external;
    function internalClaimRewards(address sender) external;
}

interface tokenStaking {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function compound() external;
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract ButterflyEffect is IERC20, tokenStaking, Ownable {
    using SafeMath for uint256;
    string private constant _name = 'Butterfly Effect';
    string private constant _symbol = 'EFFECT';
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 1000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = ( _totalSupply * 100 ) / 10000;
    uint256 public _maxWalletToken = ( _totalSupply * 100 ) / 10000;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isDividendExempt;
    IRouter router;
    address public pair;
    bool private swapEnabled = true;
    bool private tradingAllowed = false;
    bool public reflectionsEnabled = true;
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 900;
    uint256 private reflectionFee = 100;
    uint256 private developmentFee = 1000;
    uint256 private burnFee = 0;
    uint256 private tokenFee = 0;
    uint256 private totalFee = 2000;
    uint256 private sellFee = 4000;
    uint256 private transferFee = 4000;
    uint256 private denominator = 10000;
    uint256 private swapTimes;
    bool private swapping;
    bool private feeless;
    uint256 private swapAmount = 1;
    uint256 private swapThreshold = ( _totalSupply * 1000 ) / 100000;
    uint256 private minTokenAmount = ( _totalSupply * 10 ) / 100000;
    modifier feelessTransaction {feeless = true; _; feeless = false;}
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    mapping(address => uint256) public amountStaked;
    uint256 public totalStaked;
    uint256 private staking = 0;
    stakeIntegration internal stakingContract;
    address internal token_receiver;
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public currentDividends;
    uint256 public dividendsBeingDistributed;
    uint256 internal dividendsPerShare;
    uint256 internal dividendsPerShareAccuracyFactor = 10 ** 36;
    address[] shareholders; mapping (address => Share) public shares; 
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    struct Share {uint256 amount; uint256 totalExcluded; uint256 totalRealised; }
    uint256 public excessDividends;
    uint256 public eventFeesCollected;
    uint256 public reflectionEvent;
    bool public distributingReflections;
    uint256 internal disbursements;
    bool internal releaseDistributing;
    mapping (address => uint256) public buyMultiplier;
    uint256 internal currentIndex;
    uint256 public gasAmount = 500000;
    uint256 public distributionInterval = 12 hours;
    uint256 public distributionTime;
    uint256 private minBuyAmount = ( _totalSupply * 10 ) / 100000;
    uint256 private maxDropAmount = ( _totalSupply * 500 ) / 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal utility_receiver = 0x6F623E84da9880138DF9362cB596e13291C3C4ae;
    address internal staking_receiver = 0x6F623E84da9880138DF9362cB596e13291C3C4ae; 
    address internal marketing_receiver = 0x3f20cB334FFd23D0Ec8eeFaFAe485728774Ea1b0;
    address internal liquidity_receiver = 0x6F623E84da9880138DF9362cB596e13291C3C4ae;
    mapping (uint256 => mapping (address => uint256)) internal userEventData;
    struct eventData {
        uint256 reflectionAmount;
        uint256 reflectionsDisbursed;
        uint256 eventTimestamp;
        uint256 totalFees;
        uint256 totalExcess;}
    mapping(uint256 => eventData) public eventStats;

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        token_receiver = msg.sender;
        isFeeExempt[address(this)] = true;
        isFeeExempt[liquidity_receiver] = true;
        isFeeExempt[marketing_receiver] = true;
        isFeeExempt[token_receiver] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(stakingContract)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(pair)] = true;
        isDividendExempt[address(DEAD)] = true;
        isDividendExempt[address(0)] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function getOwner() external view override returns (address) { return owner; }
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function availableBalance(address wallet) public view returns (uint256) {return _balances[wallet].sub(amountStaked[wallet]);}
    function circulatingSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function preTxCheck(address sender, address recipient, uint256 amount) internal view {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        preTxCheck(sender, recipient, amount);
        checkTradingAllowed(sender, recipient);
        checkMaxWallet(sender, recipient, amount); 
        checkTxLimit(sender, recipient, amount);
        transactionCounters(sender, recipient);
        setBuyMultiplier(sender, recipient, amount);
        swapBack(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        processRewards(sender, recipient);
    }

    function setStructure(uint256 _liquidity, uint256 _marketing, uint256 _reflections, uint256 _burn, 
        uint256 _token, uint256 _staking, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; reflectionFee = _reflections; staking = _staking; developmentFee = _development;
        burnFee = _burn; totalFee = _total; sellFee = _sell; transferFee = _trans; tokenFee = _token;
        require(totalFee <= denominator && sellFee <= denominator && burnFee <= denominator && tokenFee <= denominator 
            && transferFee <= denominator, "totalFee and sellFee cannot be more than 20%");
    }

    function setParameters(uint256 _buy, uint256 _wallet) external onlyOwner {
        uint256 newTx = totalSupply().mul(_buy).div(uint256(10000));
        uint256 newWallet = totalSupply().mul(_wallet).div(uint256(10000)); uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newWallet >= limit, "ERC20: max TXs and max Wallet cannot be less than .5%");
        _maxTxAmount = newTx; _maxWalletToken = newWallet;
    }

    function internalDeposit(address sender, uint256 amount) internal {
        require(amount <= _balances[sender].sub(amountStaked[sender]), "ERC20: Cannot stake more than available balance");
        stakingContract.stakingDeposit(sender, amount);
        amountStaked[sender] = amountStaked[sender].add(amount);
        totalStaked = totalStaked.add(amount);
    }

    function deposit(uint256 amount) override external {
        internalDeposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) override external {
        require(amount <= amountStaked[msg.sender], "ERC20: Cannot unstake more than amount staked");
        stakingContract.stakingWithdraw(msg.sender, amount);
        amountStaked[msg.sender] = amountStaked[msg.sender].sub(amount);
        totalStaked = totalStaked.sub(amount);
    }

    function compound() override external feelessTransaction {
        uint256 initialToken = balanceOf(msg.sender);
        stakingContract.stakingClaimToCompound(msg.sender, msg.sender);
        uint256 afterToken = balanceOf(msg.sender).sub(initialToken);
        internalDeposit(msg.sender, afterToken);
    }

    function setStakingAddress(address _staking) external onlyOwner {
        stakingContract = stakeIntegration(_staking); isFeeExempt[_staking] = true;
    }

    function checkTradingAllowed(address sender, address recipient) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){require(tradingAllowed, "tradingAllowed");}
    }
    
    function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient] && recipient != address(pair) && recipient != address(DEAD)){
            require((_balances[recipient].add(amount)) <= _maxWalletToken, "Exceeds maximum wallet amount.");}
    }

    function transactionCounters(address sender, address recipient) internal {
        if(recipient == pair && !isFeeExempt[sender] && !swapping){swapTimes += uint256(1);}
    }

    function setBuyMultiplier(address sender, address recipient, uint256 amount) internal {
        if(sender == pair && amount >= minBuyAmount){buyMultiplier[recipient] = buyMultiplier[recipient].add(uint256(1));}
        if(sender == pair && amount < minBuyAmount){buyMultiplier[recipient] = uint256(1);}
        if(recipient == pair){buyMultiplier[sender] = uint256(0);}
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        if(amountStaked[sender] > uint256(0)){require((amount.add(amountStaked[sender])) <= balanceOf(sender), "ERC20: Exceeds maximum allowed not currently staked.");}
        require(amount <= _maxTxAmount || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded");
    }

    function startTrading() external onlyOwner {
        tradingAllowed = true;
        distributionTime = block.timestamp;
    }

    function setSwapbackSettings(uint256 _swapAmount, uint256 _swapThreshold, uint256 _minTokenAmount) external onlyOwner {
        swapAmount = _swapAmount; swapThreshold = totalSupply().mul(_swapThreshold).div(uint256(100000)); minTokenAmount = totalSupply().mul(_minTokenAmount).div(uint256(100000));
    }

    function setUserMultiplier(address user, uint256 multiplier) external onlyOwner {
        buyMultiplier[user] = multiplier;
    }

    function setInternalAddresses(address _marketing, address _liquidity, address _utility, address _token, address _staking) external onlyOwner {
        marketing_receiver = _marketing; liquidity_receiver = _liquidity; utility_receiver = _utility; token_receiver = _token; staking_receiver = _staking;
        isFeeExempt[_marketing] = true; isFeeExempt[_liquidity] = true; isFeeExempt[_utility] = true; isFeeExempt[_token] = true; isFeeExempt[_staking] = true;
    }

    function setisExempt(address _address, bool _enabled) external onlyOwner {
        isFeeExempt[_address] = _enabled;
    }

    function setDividendInfo(uint256 excess, uint256 current, uint256 distributing) external onlyOwner {
        excessDividends = excess; currentDividends = current; dividendsBeingDistributed = distributing;
    }

    function setMinBuyAmount(uint256 amount) external onlyOwner {
        minBuyAmount = _totalSupply.mul(amount).div(100000);
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 _denominator = totalFee.add(1).mul(2);
        if(totalFee == uint256(0)){_denominator = liquidityFee.add(
            marketingFee).add(staking).add(developmentFee).add(1).mul(2);}
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(
            tokensToAddLiquidityWith, ETHToAddLiquidityWith, liquidity_receiver); }
        uint256 stakingAmount = unitBalance.mul(2).mul(staking);
        if(stakingAmount > 0){payable(staking_receiver).transfer(stakingAmount);}
        uint256 marketingAmount = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmount > 0){payable(marketing_receiver).transfer(marketingAmount);}
        uint256 excessAmount = address(this).balance;
        if(excessAmount > uint256(0)){payable(utility_receiver).transfer(excessAmount);}
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount, address receiver) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(receiver),
            block.timestamp);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function shouldSwapBack(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minTokenAmount;
        bool aboveThreshold = viewAvailableBalance() >= swapThreshold;
        return !swapping && swapEnabled && tradingAllowed && aboveMin && !isFeeExempt[sender] 
            && recipient == pair && swapTimes >= swapAmount && aboveThreshold;
    }

    function swapBack(address sender, address recipient, uint256 amount) internal {
        if(shouldSwapBack(sender, recipient, amount)){swapAndLiquify(swapThreshold); swapTimes = uint256(0);}
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair && sellFee > uint256(0)){return sellFee;}
        if(sender == pair && totalFee > uint256(0)){return totalFee;}
        return transferFee;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(getTotalFee(sender, recipient) > 0 && !swapping){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(reflectionFee > uint256(0) && reflectionFee <= getTotalFee(sender, recipient)){
            currentDividends = currentDividends.add((amount.div(denominator).mul(reflectionFee)));
            eventFeesCollected = eventFeesCollected.add((amount.div(denominator).mul(reflectionFee)));}
        if(burnFee > uint256(0) && burnFee <= getTotalFee(sender, recipient)){
            _transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        if(tokenFee > uint256(0) && tokenFee <= getTotalFee(sender, recipient)){
            _transfer(address(this), address(token_receiver), amount.div(denominator).mul(tokenFee));}
        return amount.sub(feeAmount);} return amount;
    }

    function setisDividendExempt(address holder, bool exempt) external onlyOwner {
        isDividendExempt[holder] = exempt;
        if(exempt){setShare(holder, 0);}
        if(buyMultiplier[holder] > 0){setShare(holder, balanceOf(holder).mul(buyMultiplier[holder]));}
        else{setShare(holder, balanceOf(holder));}
    }

    function processRewards(address sender, address recipient) internal {
        if(releaseDistributing){dividendsBeingDistributed = uint256(0);}
        if(shares[recipient].amount > uint256(0)){distributeDividend(recipient);}
        if(shares[sender].amount > uint256(0) && recipient != pair){distributeDividend(sender);}
        if(recipient == pair && shares[sender].amount > uint256(0)){excessDividends = excessDividends.add(getUnpaidEarnings(sender));}
        if(!isDividendExempt[sender]){setShare(sender, balanceOf(sender));}
        if(!isDividendExempt[recipient]){setShare(recipient, balanceOf(recipient));}
        if(!isDividendExempt[recipient] && sender == pair && buyMultiplier[recipient] >= uint256(1)){
            setShare(recipient, balanceOf(recipient).mul(buyMultiplier[recipient]));}
        if(distributionTime.add(distributionInterval) <= block.timestamp && tradingAllowed && 
            currentDividends > uint256(0) && !swapping && reflectionsEnabled){
            createReflectionEvent();}
        processReflections(gasAmount);
        if(shares[recipient].amount > uint256(0)){distributeDividend(recipient);}
    }

    function createReflectionEvent() internal {
            distributingReflections = true;
            eventStats[reflectionEvent].totalExcess = excessDividends;
            excessDividends = uint256(0);
            reflectionEvent = reflectionEvent.add(uint256(1));
            eventStats[reflectionEvent].totalFees = eventFeesCollected;
            eventStats[reflectionEvent].reflectionAmount = currentDividends;
            eventStats[reflectionEvent].eventTimestamp = block.timestamp;
            if(currentDividends > maxDropAmount){currentDividends = maxDropAmount;}
            depositRewards(currentDividends);
            currentDividends = uint256(0);
            eventFeesCollected = uint256(0);
            distributionTime = block.timestamp;
            processReflections(gasAmount);
    }

    function manualReflectionEvent() external onlyOwner {
        createReflectionEvent();
    }

    function rescueERC20(address _address) external onlyOwner {
        uint256 _amount = IERC20(_address).balanceOf(address(this));
        IERC20(_address).transfer(utility_receiver, _amount);
    }

    function setMaxDropAmount(uint256 amount) external onlyOwner {
        maxDropAmount = _totalSupply.mul(amount).div(100000);
    }

    function setDistributionInterval(uint256 interval) external onlyOwner {
        distributionInterval = interval;
    }

    function setReleaseDistributing(bool enable) external onlyOwner {
        releaseDistributing = enable;
    }

    function enableReflections(bool enable) external onlyOwner {
        reflectionsEnabled = enable;
    }

    function setGasAmount(uint256 gas) external onlyOwner {
        gasAmount = gas;
    }

    function closeReflectionEvent() external onlyOwner {
        dividendsBeingDistributed = uint256(0);
    }

    function setShare(address shareholder, uint256 amount) internal {
        if(amount > 0 && shares[shareholder].amount == 0){addShareholder(shareholder);}
        else if(amount == 0 && shares[shareholder].amount > 0){removeShareholder(shareholder); }
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function depositRewards(uint256 amount) internal {
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        dividendsBeingDistributed = amount;
    }

    function rescueETH(uint256 _amount) external {
        payable(utility_receiver).transfer(_amount);
    }

    function setTokenAddress(address _address) external onlyOwner {
        token_receiver = _address;
    }

    function totalReflectionsDistributed(address _wallet) external view returns (uint256) {
        address shareholder = _wallet;
        return uint256(shares[shareholder].totalRealised);
    }

    function claimReflections() external {
        distributeDividend(msg.sender);
    }

    function viewRemainingBeingDisbursed() external view returns (uint256 distributing, uint256 distributed) {
        return(dividendsBeingDistributed, eventStats[reflectionEvent].reflectionsDisbursed);
    }

    function viewDisbursementShareholders() external view returns (uint256 disbursementsAmt, uint256 shareholdersAmt) {
        return(disbursements, shareholders.length);
    }

    function manualProcessReflections(uint256 gas) external onlyOwner {
        processReflections(gas);
    }

    function processReflections(uint256 gas) internal {
        uint256 currentAmount = totalDistributed;
        uint256 shareholderCount = shareholders.length;
        if(shareholderCount == uint256(0)) { return; }
        uint256 gasUsed = uint256(0);
        uint256 gasLeft = gasleft();
        uint256 iterations = uint256(0);
        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = uint256(0);}
                distributeDividend(shareholders[currentIndex]);
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
            disbursements++;}
        if(disbursements >= shareholderCount && totalDistributed > currentAmount){
            distributingReflections = false;
            dividendsBeingDistributed = uint256(0);
            disbursements = uint256(0);}
    }

    function distributeDividend(address shareholder) internal {
        uint256 amount = getUnpaidEarnings(shareholder);
        if(shares[shareholder].amount == 0 || amount > balanceOf(address(this))){ return; }
        if(amount > uint256(0)){
            totalDistributed = totalDistributed.add(amount);
            eventStats[reflectionEvent].reflectionsDisbursed = eventStats[reflectionEvent].reflectionsDisbursed.add(amount);
            _basicTransfer(address(this), shareholder, amount);
            userEventData[reflectionEvent][shareholder] = amount;
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            buyMultiplier[shareholder] = uint256(0);
            setShare(shareholder, balanceOf(shareholder));}
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function balanceInformation() external view returns (uint256 balance, uint256 available, uint256 current, uint256 distributing, uint256 excess) {
        return(balanceOf(address(this)), balanceOf(address(this)).sub(currentDividends).sub(dividendsBeingDistributed), currentDividends, dividendsBeingDistributed, excessDividends);
    }

    function viewAvailableBalance() public view returns (uint256 contractBalance) {
        return balanceOf(address(this)).sub(currentDividends).sub(dividendsBeingDistributed);
    }

    function viewLastFiveReflectionEvents() external view returns (uint256, uint256, uint256, uint256, uint256) {
        return(eventStats[reflectionEvent].reflectionAmount, eventStats[reflectionEvent.sub(1)].reflectionAmount, eventStats[reflectionEvent.sub(2)].reflectionAmount,
            eventStats[reflectionEvent.sub(3)].reflectionAmount, eventStats[reflectionEvent.sub(4)].reflectionAmount);
    }

    function viewUserReflectionStats(uint256 eventNumber, address wallet) external view returns (uint256) {
        return userEventData[eventNumber][wallet];
    }

    function viewMyReflectionStats(uint256 eventNumber) external view returns (uint256) {
        return userEventData[eventNumber][msg.sender];
    }
}