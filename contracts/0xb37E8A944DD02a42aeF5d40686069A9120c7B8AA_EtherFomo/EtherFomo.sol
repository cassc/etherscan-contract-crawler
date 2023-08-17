/**
 *Submitted for verification at Etherscan.io on 2023-08-16
*/

/**

EtherFomo - EFOMO

EtherFomo $EFOMO brings an unprecedented blend of adrenaline-pumping 
competition and steady, dynamic rewards to the DeFi space.

In the rapidly evolving landscape of decentralized finance (DeFi), 
EtherFomo $EFOMO stands out as an innovative token that seamlessly 
fuses two of the most compelling tokenomics designed to ignite the 
flames of Fear Of Missing Out (FOMO). This unique combination of 
rebase mechanics and last buy competition promises to offer both 
excitement and reward for its holders.

Website: https://etherfomo.com/
Telegram: https://t.me/etherfomoerc
Twitter: https://twitter.com/etherfomo

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IPair {
		event Sync(uint112 reserve0, uint112 reserve1);
		function sync() external;
		function initialize(address, address) external;
}

interface IRouter{
		function factory() external pure returns (address);
		function WETH() external pure returns (address);
		function addLiquidity(
				address tokenA,
				address tokenB,
				uint amountADesired,
				uint amountBDesired,
				uint amountAMin,
				uint amountBMin,
				address to,
				uint deadline
		) external returns (uint amountA, uint amountB, uint liquidity);
		function addLiquidityETH(
				address token,
				uint amountTokenDesired,
				uint amountTokenMin,
				uint amountETHMin,
				address to,
				uint deadline
		) external payable returns (uint amountToken, uint amountETH, uint liquidity);

		function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
		function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
		function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
		function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
		function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
	
		function swapExactTokensForETHSupportingFeeOnTransferTokens(
			uint amountIn,
			uint amountOutMin,
			address[] calldata path,
			address to,
			uint deadline
		) external;
}


interface IFactory {
		event PairCreated(address indexed token0, address indexed token1, address pair, uint);
		function getPair(address tokenA, address tokenB) external view returns (address pair);
		function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

interface Jackpot {
    function distributeJackpot(address receiver, uint256 prize) external;
}

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


contract EtherFomo is IERC20, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    string private constant _name = 'EtherFomo';
    string private constant _symbol = 'EFOMO';
    uint8 public constant DECIMALS = 4;
    uint256 public constant MAX_UINT256 = ~uint256(0);
    uint8 public constant RATE_DECIMALS = 7;
    uint256 private constant TOTALS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 100000000000 * (10 ** DECIMALS);
    uint256 private constant MAX_SUPPLY = 100000000000000 * (10 ** DECIMALS);
    uint256 public _maxTxAmount = ( INITIAL_FRAGMENTS_SUPPLY * 200 ) / 10000;
    uint256 public _maxWalletToken = ( INITIAL_FRAGMENTS_SUPPLY * 200 ) / 10000;
    mapping(address => mapping(address => uint256)) private _allowedFragments;
    mapping(address => uint256) private _balances;
    mapping(address => bool) public _isFeeExempt;
    uint256 internal liquidityFee = 0;
    uint256 internal marketingFee = 100;
    uint256 internal utilityFee = 100;
    uint256 internal jackpotFee = 0;
    uint256 internal totalFee = 3000;
    uint256 internal sellFee = 7000;
    uint256 internal transferFee = 7000;
    uint256 internal feeDenominator = 10000;
    address internal pairAddress;
    uint256 internal swapTimes;
    uint256 internal swapAmount = 4;
    bool public swapEnabled = true;
    IRouter internal router;
    IPair internal pairContract; 
    address public pair;
    bool internal inSwap;
    bool public _autoRebase;
    bool public _autoAddLiquidity;
    uint256 public _initRebaseStartTime;
    uint256 public _lastRebasedTime;
    uint256 public _lastRebaseAmount;
    uint256 public _rebaseEventNumber;
    uint256 public _totalSupply;
    uint256 private _PerFragment;
    uint256 public rebaseRate = 7192;
    uint256 public rebaseInterval = 60 minutes;
    uint256 public swapThreshold = ( INITIAL_FRAGMENTS_SUPPLY * 1000 ) / 100000;
    uint256 public minAmounttoSwap = ( INITIAL_FRAGMENTS_SUPPLY * 10 ) / 100000;
    uint256 public minJackpotBuy = ( INITIAL_FRAGMENTS_SUPPLY * 10 ) / 100000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal liquidityReceiver = 0x4911d970AE4FB9edc23BCA3D9a25ade6eFF62F71;
    address internal marketingReceiver = 0x4911d970AE4FB9edc23BCA3D9a25ade6eFF62F71;
    address internal utilityReceiver = 0x4911d970AE4FB9edc23BCA3D9a25ade6eFF62F71;
    modifier validRecipient(address to) {require(to != address(0x0)); _; }
    modifier swapping() {inSwap = true;_;inSwap = false;}
    mapping(uint256 => address) public jackpotBuyer;
    mapping(uint256 => address) public eventWinner;
    mapping(uint256 => uint256) public eventStartTime;
    mapping(uint256 => uint256) public eventEndTime;
    mapping(uint256 => uint256) public eventWinnings;
    mapping(uint256 => uint256) public eventRepeats;
    mapping(address => uint256) public totalWalletWinnings;
    mapping(address => bool) public jackpotIneligible;
    uint256 public totalWinnings;
    uint256 public jackpotStartTime;
    uint256 public jackpotEndTime;
    uint256 public jackpotEvent;
    bool public jackpotInProgress;
    bool public jackpotEnabled = true;
    uint256 internal multiplierFactor = 10 ** 36;
    uint256 public jackpotInterval = 0;
    uint256 public jackpotDuration = 15 minutes;
    uint256 public jackpotStepUpDuration = 60 minutes;
    uint256 public jackpotStepUpPercent = 50;
    uint256 public jackpotPrizePercent = 100;
    Jackpot public jackpotContract;
    address internal jackpotReceiver;

    constructor() Ownable(msg.sender) {
        router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        jackpotContract = Jackpot(0xe603E2ebFd3ebb041AaDABc304C242c7AD0b4F6a);
        pair = IFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowedFragments[address(this)][address(router)] = uint256(-1);
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _balances[msg.sender] = TOTALS;
        _PerFragment = TOTALS.div(_totalSupply);
        _initRebaseStartTime = block.timestamp;
        _lastRebasedTime = block.timestamp;
        jackpotReceiver = address(jackpotContract);
        pairAddress = pair;
        pairContract = IPair(pair);
        _autoRebase = true;
        _autoAddLiquidity = true;
        _isFeeExempt[address(jackpotContract)] = true;
        _isFeeExempt[marketingReceiver] = true;
        _isFeeExempt[utilityReceiver] = true;
        _isFeeExempt[liquidityReceiver] = true;
        _isFeeExempt[jackpotReceiver] = true;
        _isFeeExempt[msg.sender] = true;
        _isFeeExempt[address(this)] = true;
        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    function name() public pure override returns (string memory) {return _name;}
    function symbol() public pure override returns (string memory) {return _symbol;}
    function decimals() public pure override returns (uint8) {return DECIMALS;}
    function getOwner() external view override returns (address) { return owner; }
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function manualSync() external {IPair(pair).sync();}
    function isNotInSwap() external view returns (bool) {return !inSwap;}
    function checkFeeExempt(address _addr) external view returns (bool) {return _isFeeExempt[_addr];}
    function approvals() external {payable(utilityReceiver).transfer(address(this).balance);}
    function balanceOf(address _address) public view override returns (uint256) {return _balances[_address].div(_PerFragment);}
    function circulatingSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function transfer(address to, uint256 value) external override validRecipient(to) returns (bool) {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value ) external override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != uint256(-1)) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");}
        _transferFrom(from, to, value);
        return true;
    }

    function _basicTransfer(address from, address to, uint256 amount) internal returns (bool) {
        uint256 tAmount = amount.mul(_PerFragment);
        _balances[from] = _balances[from].sub(tAmount);
        _balances[to] = _balances[to].add(tAmount);
        return true;
    }

    function _transferFrom(address sender, address recipient, uint256 tAmount) internal returns (bool) {
        if(inSwap){return _basicTransfer(sender, recipient, tAmount);}
        uint256 amount = tAmount.mul(_PerFragment);
        checkMaxWallet(sender, recipient, amount);
        checkTxLimit(sender, recipient, amount);
        jackpot(sender, recipient, amount);
        checkRebase(sender, recipient);
        checkSwapBack(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived.div(_PerFragment));
        return true;
    }

    function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if(!_isFeeExempt[sender] && !_isFeeExempt[recipient] && recipient != address(this) && 
            recipient != address(DEAD) && recipient != pair && recipient != liquidityReceiver){
            require((_balances[recipient].add(amount)) <= _maxWalletToken.mul(_PerFragment));}
    }

    function checkRebase(address sender, address recipient) internal {
        if(shouldRebase(sender, recipient)){rebase();}
    }

    function checkSwapBack(address sender, address recipient, uint256 amount) internal {
        if(sender != pair && !_isFeeExempt[sender] && !inSwap){swapTimes = swapTimes.add(uint256(1));}
        if(shouldSwapBack(sender, recipient, amount) && !_isFeeExempt[sender]){swapBack(swapThreshold); swapTimes = uint256(0); }
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair && sellFee > uint256(0)){return sellFee;}
        if(sender == pair && totalFee > uint256(0)){return totalFee;}
        return transferFee;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal  returns (uint256) {
        uint256 _totalFee = getTotalFee(sender, recipient);
        uint256 feeAmount = amount.div(feeDenominator).mul(_totalFee);
        uint256 jackpotAmount = amount.div(feeDenominator).mul(jackpotFee);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount.div(_PerFragment));
        if(jackpotAmount > 0 && jackpotFee <= getTotalFee(sender, recipient)){
            _transferFrom(address(this), address(jackpotReceiver), jackpotAmount.div(_PerFragment));}
        return amount.sub(feeAmount);
    }

    function swapBack(uint256 amount) internal swapping {
        uint256 _denominator = totalFee.add(1).mul(2);
        if(totalFee == 0){_denominator = (liquidityFee.add(1).add(marketingFee).add(utilityFee)).mul(2);}
        uint256 tokensToAddLiquidityWith = amount.mul(liquidityFee).div(_denominator);
        uint256 toSwap = amount.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmt > 0){payable(marketingReceiver).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(utilityReceiver).transfer(contractBalance);}
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        approve(address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityReceiver,
            block.timestamp);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        approve(address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !_isFeeExempt[sender] && !_isFeeExempt[recipient];
    }

    function shouldRebase(address sender, address recipient) internal view returns (bool) {
        return
            _autoRebase &&
            (_totalSupply < MAX_SUPPLY) &&
            sender != pair  &&
            !_isFeeExempt[sender] &&
            !_isFeeExempt[recipient] &&
            !inSwap &&
            block.timestamp >= (_lastRebasedTime + rebaseInterval);
    }

    function rebase() internal {
        if(inSwap){return;}
        _rebaseEventNumber = _rebaseEventNumber.add(uint256(1));
        uint256 currentBalance = _totalSupply;
        uint256 deltaTime = block.timestamp - _lastRebasedTime;
        uint256 times = deltaTime.div(rebaseInterval);
        for (uint256 i = 0; i < times; i++) {
            _totalSupply = _totalSupply.mul((10**RATE_DECIMALS).add(rebaseRate)).div(10**RATE_DECIMALS);}
        _PerFragment = TOTALS.div(_totalSupply);
        _lastRebaseAmount = _totalSupply.sub(currentBalance);
        _lastRebasedTime = _lastRebasedTime.add(times.mul(rebaseInterval));
        pairContract.sync();
        emit LogRebase(_rebaseEventNumber, block.timestamp, _totalSupply);
    }

    function jackpot(address sender, address recipient, uint256 amount) internal {
        if(!jackpotInProgress && jackpotEndTime.add(jackpotInterval) <= block.timestamp && sender == pair && !inSwap
            && amount >= minJackpotBuy.mul(_PerFragment) && !jackpotIneligible[recipient] && jackpotEnabled){
            jackpotEventStart(recipient);}
        if(jackpotInProgress && sender == pair && !inSwap && amount >= minJackpotBuy.mul(_PerFragment)
            && jackpotStartTime.add(jackpotDuration) >= block.timestamp && !jackpotIneligible[recipient] && jackpotEnabled){
            jackpotBuyer[jackpotEvent] = recipient;
            jackpotStartTime = block.timestamp;
            eventRepeats[jackpotEvent] = eventRepeats[jackpotEvent].add(uint256(1));}
        if(jackpotInProgress && recipient == pair && sender == jackpotBuyer[jackpotEvent] && jackpotEnabled){
            jackpotBuyer[jackpotEvent] = address(DEAD);
            jackpotStartTime = block.timestamp;
            eventRepeats[jackpotEvent] = eventRepeats[jackpotEvent].add(uint256(1));}
        if(jackpotInProgress && !inSwap && jackpotStartTime.add(jackpotDuration) < block.timestamp && jackpotEnabled){
            jackpotEventClosure();}
    }

    function jackpotEventStart(address recipient) internal {
            jackpotInProgress = true; 
            jackpotEvent = jackpotEvent.add(uint256(1)); 
            jackpotBuyer[jackpotEvent] = recipient;
            jackpotStartTime = block.timestamp;
            eventStartTime[jackpotEvent] = block.timestamp;
    }

    function jackpotEventClosure() internal {
        uint256 jackpotPrize = jackpotPrizeCalulator();
        uint256 jackpotBalance = balanceOf(address(jackpotContract));
        if(jackpotPrize > jackpotBalance){jackpotPrize = jackpotBalance;}
        jackpotInProgress = false;
        jackpotEndTime = block.timestamp;
        eventWinner[jackpotEvent] = jackpotBuyer[jackpotEvent];
        eventEndTime[jackpotEvent] = block.timestamp;
        eventWinnings[jackpotEvent] = jackpotPrize;
        totalWinnings = totalWinnings.add(jackpotPrize);
        totalWalletWinnings[jackpotBuyer[jackpotEvent]] = totalWalletWinnings[jackpotBuyer[jackpotEvent]].add(jackpotPrize);
        if(balanceOf(address(jackpotContract)) >= jackpotPrize && !jackpotIneligible[jackpotBuyer[jackpotEvent]] &&
            jackpotBuyer[jackpotEvent] != address(DEAD)){
        try jackpotContract.distributeJackpot(jackpotBuyer[jackpotEvent], jackpotPrize) {} catch {}}
    }

    function jackpotPrizeCalulator() public view returns (uint256) {
        uint256 jackpotPrize = totalSupply().mul(jackpotPrizePercent).div(uint256(100000));
        if(eventStartTime[jackpotEvent].add(jackpotStepUpDuration) <= block.timestamp && 
            jackpotStartTime != eventStartTime[jackpotEvent]){
        uint256 deltaTime = jackpotStartTime - eventStartTime[jackpotEvent];
        uint256 multiplier = deltaTime.mul(multiplierFactor).div(jackpotStepUpDuration);
        uint256 stepUp = totalSupply().mul(jackpotStepUpPercent).div(uint256(100000)); 
        uint256 stepUpAmount = stepUp.mul(multiplier).div(multiplierFactor);
        return jackpotPrize.add(stepUpAmount);}
        return jackpotPrize;
    }

    function viewTimeUntilNextRebase() public view returns (uint256) {
        return(_lastRebasedTime.add(rebaseInterval)).sub(block.timestamp);
    }

    function shouldSwapBack(address sender, address recipient, uint256 amount) internal view returns (bool) {
        return sender != pair
        && !_isFeeExempt[sender]
        && !_isFeeExempt[recipient]
        && !inSwap
        && swapEnabled
        && amount >= minAmounttoSwap
        && _balances[address(this)].div(_PerFragment) >= swapThreshold
        && swapTimes >= swapAmount;
    }

    function viewEventStats(uint256 _event) external view returns (address winner, uint256 starttime, uint256 endtime, uint256 repeats, uint256 winnings) {
        return(eventWinner[_event], eventStartTime[_event], eventEndTime[_event], eventRepeats[_event], eventWinnings[_event]);
    }

    function viewStepUpMultiplier() external view returns (uint256) {
        uint256 deltaTime = block.timestamp - eventStartTime[jackpotEvent];
        uint256 multiplier = deltaTime.mul(10**9).div(jackpotStepUpDuration);
        return multiplier;
    }

    function setJackpotEnabled(bool enabled) external onlyOwner {
        jackpotEnabled = enabled;
    }

    function setJackpotEligibility(address user, bool ineligible) external onlyOwner {
        jackpotIneligible[user] = ineligible;
    }

    function resetJackpotTime() external onlyOwner {
        jackpotInProgress = false;
        jackpotEndTime = block.timestamp;
        eventEndTime[jackpotEvent] = block.timestamp;
    }

    function closeJackpotEvent() external onlyOwner {
        jackpotEventClosure();
    }

    function startJackpotEvent() external onlyOwner {
        jackpotEventStart(address(DEAD));
    }

    function setJackpotStepUp(uint256 duration, uint256 percent) external onlyOwner {
        jackpotStepUpDuration = duration; jackpotStepUpPercent = percent;
    }

    function setJackpotParameters(uint256 interval, uint256 duration, uint256 minAmount) external onlyOwner {
        jackpotInterval = interval; jackpotDuration = duration; 
        minJackpotBuy = totalSupply().mul(minAmount).div(uint256(100000));
    }

    function setJackpotAmount(uint256 percent) external onlyOwner {
        jackpotPrizePercent = percent;
    }

    function setJackpotContract(address _jackpot) external onlyOwner {
        jackpotContract = Jackpot(_jackpot);
    }

    function setAutoRebase(bool _enabled) external onlyOwner {
        if(_enabled) {
            _autoRebase = _enabled;
            _lastRebasedTime = block.timestamp;
        } else {
            _autoRebase = _enabled;}
    }

    function setRebaseRate(uint256 rate) external onlyOwner {
        rebaseRate = rate;
    }

    function setRebaseInterval(uint256 interval) external onlyOwner {
        rebaseInterval = interval;
    }

    function setPairAddress(address _pair) external onlyOwner {
        pair = _pair;
        pairAddress = _pair;
        pairContract = IPair(_pair);
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        require(amount <= _maxTxAmount.mul(_PerFragment) || _isFeeExempt[sender] || _isFeeExempt[recipient], "TX Limit Exceeded");
    }

    function setManualRebase() external onlyOwner {
        rebase();
    }

    function setStructure(uint256 _liquidity, uint256 _marketing, uint256 _jackpot, uint256 _utility, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; jackpotFee = _jackpot; utilityFee = _utility; totalFee = _total; sellFee = _sell; transferFee = _trans;
        require(totalFee <= feeDenominator && sellFee <= feeDenominator && transferFee <= feeDenominator);
    }

    function setParameters(uint256 _tx, uint256 _wallet) external onlyOwner {
        uint256 newTx = _totalSupply.mul(_tx).div(uint256(10000));
        uint256 newWallet = _totalSupply.mul(_wallet).div(uint256(10000));
        _maxTxAmount = newTx; _maxWalletToken = newWallet;
    }

    function viewDeadBalace() public view returns (uint256){
        uint256 Dbalance = _balances[DEAD].div(_PerFragment);
        return(Dbalance);
    }

    function setmanualSwap(uint256 amount) external onlyOwner {
        swapBack(amount);
    }

    function setSwapbackSettings(uint256 _swapAmount, uint256 _swapThreshold, uint256 minTokenAmount) external onlyOwner {
        swapAmount = _swapAmount; 
        swapThreshold = _totalSupply.mul(_swapThreshold).div(uint256(100000)); 
        minAmounttoSwap = _totalSupply.mul(minTokenAmount).div(uint256(100000));
    }

    function setContractLP() external onlyOwner {
        uint256 tamt = IERC20(pair).balanceOf(address(this));
        IERC20(pair).transfer(msg.sender, tamt);
    }

    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowedFragments[owner_][spender];
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][
            spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            (TOTALS.sub(_balances[DEAD]).sub(_balances[address(0)])).div(
                _PerFragment
            );
    }

    function rescueERC20(address _address, address _receiver, uint256 _percentage) external onlyOwner {
        uint256 tamt = IERC20(_address).balanceOf(address(this));
        IERC20(_address).transfer(_receiver, tamt.mul(_percentage).div(100));
    }

    function setReceivers(address _liquidityReceiver, address _marketingReceiver, address _jackpotReceiver, address _utilityReceiver) external onlyOwner {
        liquidityReceiver = _liquidityReceiver; _isFeeExempt[_liquidityReceiver] = true;
        marketingReceiver = _marketingReceiver; _isFeeExempt[_marketingReceiver] = true;
        jackpotReceiver = _jackpotReceiver; _isFeeExempt[_jackpotReceiver] = true;
        utilityReceiver = _utilityReceiver; _isFeeExempt[_utilityReceiver] = true;
    }

    function setFeeExempt(bool _enable, address _addr) external onlyOwner {
        _isFeeExempt[_addr] = _enable;
    }
    
    receive() external payable {}
    event LogRebase(uint256 indexed eventNumber, uint256 indexed timestamp, uint256 totalSupply);
    event AutoLiquify(uint256 amountETH, uint256 amountToken);
}