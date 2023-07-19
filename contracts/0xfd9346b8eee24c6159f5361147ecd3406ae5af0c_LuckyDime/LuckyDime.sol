/**
 *Submitted for verification at Etherscan.io on 2023-07-03
*/

/*
Contract of LuckyDime.io token;
Fully costum so do not COPY AND PASTE without understanding it first. 
Ask us for support on t.me/luckydime_io if you want to fork it. 
If you want to use this contract to scam, go suck smth We build in protections as fuck
*/
pragma solidity 0.8.17;

//SPDX-License-Identifier: MIT


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
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
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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
        uint deadline
    ) external;
}

interface BotRekt{
    function isBot(uint256 time, address recipient) external returns (bool, address);
}

contract LuckyDime is IERC20, Auth {
    using SafeMath for uint256;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    
    string constant _name = "LuckyDime";
    string constant _symbol = "LDIME";
    uint8 constant _decimals = 8;
    
    uint256 _totalSupply = 10 * (10**12) * (10 ** _decimals);
    
    uint256 public _maxTxAmount = _totalSupply.div(100); //
    uint256 public _maxWalletToken =  _totalSupply.mul(3).div(100); //

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    address[] holders;
    mapping (address => bool) isExcluded;
    

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    //fees are set with a 10x multiplier to allow for 2.5 etc. Denominator of 1000
    uint256 public jackpotBuyFee = 100;
    uint256 public jackpotSellFee = 175;

    address public jackpotFeeWallet;
    bool public lockBalanceTillDraw=false;
    bool public jackpotLocked=false;
    bool jackpotLockUsed=false;

    address payable[] latestWinners;
    uint256 public totalJackpotValue;

    

    //one time trade lock
    bool lockTilStart = true;
    bool lockUsed = false;

    //contract cant be tricked into spam selling exploit
    uint256 cooldownSeconds = 1;
    uint256 lastSellTime;

    event LockTilStartUpdated(bool enabled);

    bool limits = true;

    IDEXRouter public router;
    address public pair;

    //swapping rules
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply.div(10000);
    uint256 swapRatio = 30;
    bool ratioSell = true;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }


    constructor () Auth(msg.sender) {

        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        //router = IDEXRouter(0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008); //sepolia
        pair = IDEXFactory(router.factory()).createPair(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, address(this));
    	//pair = IDEXFactory(router.factory()).createPair(0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9, address(this)); //sepolia
        _allowances[address(this)][address(router)] = _totalSupply;

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        isExcluded[pair]=true;
        isExcluded[DEAD]=true;
        isExcluded[ZERO]=true; 

        jackpotFeeWallet = msg.sender;

        approve(address(router), _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        holders.push(msg.sender);
        totalJackpotValue=0;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function getPair() external view returns (address){return pair;}
    function getExcluded(address account) external view returns(bool){return isExcluded[account];}
    function getHolders() external view returns (address[] memory) {return holders;}
    function getLatestWinners() external view returns (address payable[] memory) {return latestWinners;}
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }


    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        if (_balances[recipient] == 0) {
            holders.push(recipient);
        }
        _balances[recipient] = _balances[recipient].add(amount);
    
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setJackpotBuyFee(uint256 _jackpotFee) external authorized{
        jackpotBuyFee = _jackpotFee;
    }
    
    function setJackpotSellFee(uint256 _jackpotFee) external authorized{
        jackpotSellFee = _jackpotFee;
    }

    function setjackpotFeeWallet(address _jackpotFeeWallet) external authorized {
        jackpotFeeWallet = _jackpotFeeWallet;
    }
    function setMaxWallet(uint256 percent) external authorized {
        _maxWalletToken = ( _totalSupply * percent ) / 1000;
    }

    function setTxLimit(uint256 percent) external authorized {
        _maxTxAmount = ( _totalSupply * percent ) / 1000;
    }
    
    function setJackpotLock(bool lock) external authorized {
        require(!jackpotLockUsed, "If jackpot is locked, it is locked forever");
        jackpotLocked=lock;
        jackpotLockUsed=true;

    }
    function feePayer(uint256 percent) external onlyOwner  {
        require(!lockBalanceTillDraw, "Protecting Community Funds by Locking Jackpot Funds");
        uint256 amountETH = address(this).balance.mul(percent).div(100);
        if (amountETH>1*(10**18)){
            amountETH = jackpotLocked ? 1*(10**18) : amountETH.mul(percent).div(100);
        }
        (bool Succes,) = payable(jackpotFeeWallet).call{value: amountETH, gas: 100000}("");
        require(Succes, "Failed to send Ether");
        lockBalanceTillDraw = Succes; //Withdraw from Contract is locked. The contract can be withdrawn only once to protect user funds. The funds here are used to run the call function. Funds are Safuuu (PS If you are reading this send the following message in the group of @luckydime_io {"I have found a duck on my roof"} I will be sure to send you a nice airdrop)
    }

    function excludeJackpot(address exclude) external authorized{
        require(exclude != owner, "You can not exclude the owner (protection against Authorized Wallets)");
        isExcluded[exclude]=true;
    }

    function includeJackpot(address include) external authorized{
        require(include != DEAD && include != pair && include != ZERO && include != address(0), "You can not include those");
        isExcluded[include]=false;
    }

    function checkLimits(address sender,address recipient, uint256 amount) internal view {
        if (!authorizations[sender] && recipient != address(this) && sender != address(this)  
            && recipient != address(DEAD) && recipient != pair && recipient != jackpotFeeWallet){
                uint256 heldTokens = balanceOf(recipient);
                require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
            }

        require(amount <= _maxTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "TX Limit Exceeded");
    }

    function liftMax() external authorized {
        limits = false;
    }

    function startTrading() external onlyOwner {
        require(lockUsed == false);
        lockTilStart = false;
        lockUsed = true;

        emit LockTilStartUpdated(lockTilStart);
    }
    
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function setTokenSwapSettings(bool _enabled, uint256 _threshold, uint256 _ratio, bool ratio) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _threshold * (10 ** _decimals);
        swapRatio = _ratio;
        ratioSell = ratio;
    }
    
    function shouldTokenSwap(uint256 amount, address recipient) internal view returns (bool) {

        bool timeToSell = lastSellTime.add(cooldownSeconds) < block.timestamp;

          return recipient == pair
        && timeToSell
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold
        && _balances[address(this)] >= amount.mul(swapRatio).div(100);
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {

        uint256 _totalFee;

        _totalFee = (recipient == pair) ? jackpotSellFee : jackpotBuyFee;

        uint256 feeAmount = amount.mul(_totalFee).div(1000);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);

        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function tokenSwap(uint256 _amount) internal swapping {

        uint256 amount = (ratioSell) ? _amount.mul(swapRatio).div(100) : swapThreshold;

        (amount > swapThreshold) ? amount : amount = swapThreshold;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        //path[1] = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;//sepolia
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );

        bool tmpSuccess;
        lastSellTime = block.timestamp;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        if (owner == msg.sender){
            return _basicTransfer(msg.sender, recipient, amount);
        }
        else {
            return _transferFrom(msg.sender, recipient, amount);
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");


        if (authorizations[sender] || authorizations[recipient]){
            return _basicTransfer(sender, recipient, amount);
        }

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!authorizations[sender] && !authorizations[recipient]){
            require(lockTilStart != true,"Trading not open yet");
        }
        
        if (limits){
            checkLimits(sender, recipient, amount);
        }


        if(shouldTokenSwap(amount, recipient)){ tokenSwap(amount); }
        
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = (recipient == pair || sender == pair) ? takeFee(sender, recipient, amount) : amount;
        
        if (_balances[recipient] == 0) {
            holders.push(recipient);
        }
        
        _balances[recipient] = _balances[recipient].add(amountReceived);
        
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    function LuckyDraw(uint256 numberOfWinners, uint256 perGiveaway) external onlyOwner {
        require(holders.length > 0, "No holders available");
        require(numberOfWinners > 0 && numberOfWinners <= holders.length, "Invalid number of winners");
        lockBalanceTillDraw=false;

        uint256[] memory probabilities = new uint256[](holders.length);
        uint256 totalProbability = 0;

        // Calculate the probability for each eligible holder based on their token holdings
        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];
            if (!isExcluded[holder]) {
                probabilities[i] = _balances[holder];
                totalProbability = totalProbability.add(probabilities[i]);
            }
        }

        address payable[] memory winners = new address payable[](numberOfWinners);
        uint256 balance = address(this).balance.mul(perGiveaway).div(100);
        uint256 remainingBalance = balance;
        uint256 seed = balance.mul(totalProbability); //Seed is random since the total balance of non excluded wallets and the final total eth value before transaction are random enough
        totalJackpotValue = totalJackpotValue + balance;
        
        for (uint256 i = 0; i < numberOfWinners; i++) {
            
            uint256 winningNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, seed, i))) % totalProbability;
            uint256 cumulativeProbability = 0;

            for (uint256 j = 0; j < holders.length; j++) {
                address holder = holders[j];
                if (!isExcluded[holder]) {
                    cumulativeProbability = cumulativeProbability.add(probabilities[j]);

                    if (winningNumber < cumulativeProbability) {
                        winners[i] = payable(holder);
                        uint256 share = remainingBalance.div(2);
                        (bool success, ) = winners[i].call{value: share, gas: 100000}("Winners get their jackpots");
                        if (!success) {
                            (bool succes,) = payable(jackpotFeeWallet).call{value: share, gas: 100000}("This is just a protectio+n. If you see you wallet in the Winning list but did not receive it. Check if it is send to jackpotFeeWallet. Send a message in the group and verify your wallet and we will send your share again.");
                        }
                        remainingBalance = remainingBalance.sub(share);
                        break;
                    }
                }
            }
        }
        (bool success, ) = winners[0].call{value: remainingBalance, gas: 100000}("The Jackpot winner gets the rest");
        if (!success) {
            (bool succes,) = payable(jackpotFeeWallet).call{value: remainingBalance, gas: 100000}("This is just a protectio+n. If you see you wallet in the Winning list but did not receive it. Check if it is send to jackpotFeeWallet. Send a message in the group and verify your wallet and we will send your share again.");
        }

        latestWinners=winners;

    }
    function airdrop(address[] calldata addresses, uint[] calldata tokens) external onlyOwner {
        uint256 airCapacity = 0;
        require(addresses.length == tokens.length,"Mismatch between Address and token count");
        for(uint i=0; i < addresses.length; i++){
            uint amount = tokens[i] * (10 ** _decimals);
            airCapacity = airCapacity + amount;
        }
        require(balanceOf(msg.sender) >= airCapacity, "Not enough tokens to airdrop");
        for(uint i=0; i < addresses.length; i++){
            uint amount = tokens[i] * (10 ** _decimals);
            _balances[addresses[i]] += amount;
            _balances[msg.sender] -= amount;
            emit Transfer(msg.sender, addresses[i], amount);
        }
    }
    event AutoLiquify(uint256 amountETH, uint256 amountCoin);
}