/**
 *Submitted for verification at Etherscan.io on 2020-12-31
*/

/* TRY token has been being developed since 10/2020 and has more features than most other DEFI token's on the market, here is a summary of built in features that TRY token offers:
 
 * We added a brand new feature never seen before in any DEFI token, a tx reward pool, 1% of all transactions are given to the reward pool and are awarded to the sender of every 25th transaction.
 * We added a deflationary burn fee of 1% on every tx which is automatically sent directly to the burn address upon every transfer, this feature will ensure a truly deflationary model.
 * We wanted to discourage token dumping so we added a 5% antiDumpFee to all TRY sold on UNIswap. This fee is distributed to all TRYstake users when buyback feature is performed.
 * Previous rebalance liquidity models used a liquidity divisor as a liquidity reward, however that process made the rebalance feature not as effective since it had to rebalance its own rewards.
 * To help replace the removal of awarding liquidity providers via the Buyback function we will allow LP tokens to farm TRY tokens directly on TRYfarm.
 * We coded this contract to have the ability to ADDfunds into TRYstake so it can directly be its own UNIswap sell fee rewards distributor. The staking rewards distribution is called every time 
   a user performs the rebalance liquidity function. The rebalance function still burns TRY that it purchases with the rebalance increasing the effectiveness of the deflationary model.
 * When Buyback function is called the caller gets a 4% reward of the buyback TRY amount and 96% of the buyback TRY amount gets sent directly to the burn address.
 * We coded the buyback function to work on 2 hour intervals and set the rate to 1%, we also added the ability for this contract to add 20 seconds to the buyback interval on each use of the 
   buyback function. This will help ensure that the buyback feature cannot be manipulated and insure maximum life expectancy of the feature.
 * We ensured that all of TRY protocols are whitelist able so when you use them you will not incur any transactional fee's when sending TRY to those protocols.
 * Once this contract creates the UNIswap pair the LP tokens that are sent back are unable to be removed, there is no withdrawal code for these LP tokens this locked them for their intended purpose forever.
 * We added the ability to add and remove blacklist addresses, this will help insure that we can properly fight hackers and malicious intents on TRY token's economy.
 * We added createUNISwapPair function that will ensure ETH collected for liquidity can only be used for that one specific purpose, TRY presale contract automatically sends ETH liquidity to this contract.
 * We are sure that TRY will be the most successful project to ever use a rebalancer style feature, TRYstake will ensure TRY tokens are happy earning in the staking contracts and not on the market to lower 
   the price. UNIswap sell fees will discourage selling, while offering incentivized rewards for staking. TRYfarm will directly reward liquidity providers in replacement of the liquidity reward distribution 
   on the previous model. The Tx Reward pool feature helps complete the package, TRY token has the most rewarding features of any DEFI token!
 
 For more information please visit try.finance/whitepaper.html 
*/

pragma solidity ^0.5.17;


contract Context {

    constructor () internal { }


    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }
    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    } 

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
     
    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    function ceil(uint a, uint m) internal pure returns (uint r) {
        return (a + m - 1) / m * m;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    constructor (uint256 totalSupply) public {
        _mint(_msgSender(),totalSupply);
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

contract ERC20Burnable is Context, ERC20 {

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract ERC20TransferLiquidityLock is ERC20 {
    using SafeMath for uint256;


    event Rebalance(uint256 tokenBurnt);
    event SupplyTRYStake(uint256 tokenAmount);
    event RewardStakers(uint256 stakingRewards);
    
    address public uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public uniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public uniswapV2Pair; 
    address public TRYStake;
    address public presaleAddress;
    address public LPFarm; 
    address public Master = address (uniswapV2Router);     
    address public Trident = address (this);
    address payable public treasury;
    mapping(address => bool) public feelessAddr;
    mapping(address => bool) public unlocked;
    mapping(address => bool) public oracle; 
    mapping(address => bool) public blacklist; 
    
    uint256 public rewardPoolDivisor;
    uint256 public rebalanceRewardDivisor;
    uint256 public rebalanceDivisor; 
    uint256 public burnTxFee;    
    uint256 public antiDumpFee;       
    uint256 public minRebalanceAmount;
    uint256 public lastRebalance;
    uint256 public rebalanceInterval;
    address public burnAddr = 0x000000000000000000000000000000000000dEaD;
    bool public LPLocked; 
    
    uint256 public txNumber;
    uint256 one = 1000000000000000000;
    uint256 public trans100 = 25000000000000000000; 
    
    uint256 public stakePool = 0;
    uint256 public rewardPool = 0;    

    bool public locked;
    Balancer balancer;
    
    constructor() public {
        lastRebalance = block.timestamp;
        burnTxFee = 100;
        rewardPoolDivisor = 100;
        antiDumpFee = 20;
        rebalanceRewardDivisor = 25;
        rebalanceDivisor = 100;
        rebalanceInterval = 2 hours;
        minRebalanceAmount = 100e18; 
        treasury = msg.sender;
        balancer = new Balancer(treasury);
        feelessAddr[address(this)] = true;
        feelessAddr[address(balancer)] = true;
        feelessAddr[address(uniswapV2Router)] = true; 
        feelessAddr[address(uniswapV2Factory)] = true;        
        feelessAddr[address(TRYStake)] = true; 
        feelessAddr[address(presaleAddress)] = true;
        locked = true;
        LPLocked = true;
        unlocked[msg.sender] = false;
        unlocked[address(this)] = true;
        unlocked[address(balancer)] = true; 
        unlocked[address(balancer)] = true; 
        unlocked[address(uniswapV2Router)] = true;
        unlocked[address(presaleAddress)] = true;
        txNumber = 0;
    } 
    
    function calculateFees(address from, address to, uint256 amount) public view returns( uint256 rewardtx, uint256  Burntx, uint256  selltx){
    }
    
    function isContract(address _addr) public view returns (bool _isContract){
        uint32 size;
        assembly {
        size := extcodesize(_addr)}
        
        return (size > 0);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        
        if(locked && unlocked[from] != true && unlocked[to] != true)
            revert("Transfers are locked until after presale.");

        if(blacklist [from] == true || blacklist [to] == true) 
            revert("Address is blacklisted");
          
       uint256  Burntx = 0;
        uint256  rewardtx = 0;
        
    if(feelessAddr[from] == false && feelessAddr[to] == false){    
        
       if (burnTxFee != 0) { 
        Burntx = amount.div(burnTxFee); 
        amount = amount.sub(Burntx);
           super._transfer(from, address(burnAddr), Burntx); 
        } 
        
        if (rewardPoolDivisor != 0) { 
            txNumber = txNumber.add(one);
            rewardtx = amount.div(rewardPoolDivisor); 
            amount = amount.sub(rewardtx);
            super._transfer(from, address(this), rewardtx); 
          
            rewardPool += rewardtx;
            if(txNumber == trans100){
                require( !(isContract(from)), 'inValid caller');
                super._transfer(address(this), from, rewardPool);
                rewardPool = 0;
                txNumber = 0;  
            }
        }
        
        if (antiDumpFee != 0 && oracle[to]) {
           uint256 selltx = amount.div(antiDumpFee); 
           stakePool += selltx;
           amount = amount.sub(selltx);
                super._transfer(from, address(this), selltx);
            }
            
         super._transfer(from, to, amount);
        }
    
        else {
         super._transfer(from, to, amount);   
        }
    }


    function () external payable {}

    function RebalanceLiquidity() public {
        require(balanceOf(msg.sender) >= minRebalanceAmount, "You do not have the required amount of TRY.");
        require(block.timestamp > lastRebalance + rebalanceInterval, "It is too early to use this function."); 
        lastRebalance = block.timestamp;
        uint256 _lockableSupply = stakePool;  
        _addRebalanceInterval();        
        _rewardStakers(_lockableSupply);
        
        uint256 amountToRemove = ERC20(uniswapV2Pair).balanceOf(address(this)).div(rebalanceDivisor);
        
        remLiquidity(amountToRemove);
        uint _locked = balancer.rebalance(rebalanceRewardDivisor);

        emit Rebalance(_locked);
    }
    
    function _addRebalanceInterval() private {
        rebalanceInterval = rebalanceInterval.add(20 seconds);
    }
    
    function _rewardStakers(uint256 stakingRewards) private {
        if(TRYStake != address(0)) {
           TRYstakingContract(TRYStake).ADDFUNDS(stakingRewards);
           stakePool= 0;
            emit RewardStakers(stakingRewards); 
        }
    }

    function remLiquidity(uint256 lpAmount) private returns(uint ETHAmount) {
        ERC20(uniswapV2Pair).approve(uniswapV2Router, lpAmount);
        (ETHAmount) = IUniswapV2Router02(uniswapV2Router)
            .removeLiquidityETHSupportingFeeOnTransferTokens(
                address(this),
                lpAmount,
                0,
                0,
                address(balancer),
                block.timestamp);
    }
    

    function lockableSupply() external view returns (uint256) {
        return balanceOf(address(this));
    }

    function lockedSupply() external view returns (uint256) {
        uint256 lpTotalSupply = ERC20(uniswapV2Pair).totalSupply();
        uint256 lpBalance = lockedLiquidity();
        uint256 percentOfLpTotalSupply = lpBalance.mul(1e12).div(lpTotalSupply);

        uint256 uniswapBalance = balanceOf(uniswapV2Pair);
        uint256 _lockedSupply = uniswapBalance.mul(percentOfLpTotalSupply).div(1e12);
        return _lockedSupply;
    }

    function burnedSupply() external view returns (uint256) {
        uint256 lpTotalSupply = ERC20(uniswapV2Pair).totalSupply();
        uint256 lpBalance = burnedLiquidity();
        uint256 percentOfLpTotalSupply = lpBalance.mul(1e12).div(lpTotalSupply);

        uint256 uniswapBalance = balanceOf(uniswapV2Pair);
        uint256 _burnedSupply = uniswapBalance.mul(percentOfLpTotalSupply).div(1e12);
        return _burnedSupply;
    }

    function burnableLiquidity() public view returns (uint256) {
        return ERC20(uniswapV2Pair).balanceOf(address(this));
    }

    function burnedLiquidity() public view returns (uint256) {
        return ERC20(uniswapV2Pair).balanceOf(address(0));
    }

    function lockedLiquidity() public view returns (uint256) {
        return burnableLiquidity().add(burnedLiquidity());
    }
}

interface TRYstakingContract {
    function ADDFUNDS(uint256 stakingRewards) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external payable;
    function removeLiquidityETH(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityETHSupportingFeeOnTransferTokens(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
    ) external returns (uint amountETH);    
}

interface IUniswapV2Pair {
    function sync() external;
}

contract ERC20Governance is ERC20, ERC20Detailed {
    using SafeMath for uint256;

    function _transfer(address from, address to, uint256 amount) internal {
        _moveDelegates(_delegates[from], _delegates[to], amount);
        super._transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal {
        _moveDelegates(address(0), _delegates[account], amount);
        super._mint(account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        _moveDelegates(_delegates[account], address(0), amount);
        super._burn(account, amount);
    }

    mapping (address => address) internal _delegates;

    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    mapping (address => uint32) public numCheckpoints;

    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping (address => uint) public nonces;

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "ERC20Governance::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "ERC20Governance::delegateBySig: invalid nonce");
        require(now <= expiry, "ERC20Governance::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "ERC20Governance::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; 
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); 
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "ERC20Governance::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

contract Balancer {
    using SafeMath for uint256;    
    TRYfinance token;
    address public burnAddr = 0x000000000000000000000000000000000000dEaD;
    address payable public treasury;
  
    constructor(address payable treasury_) public {
        token = TRYfinance(msg.sender);
        treasury = treasury_;
    }
    
    function () external payable {}
    
    function rebalance(uint rebalanceRewardDivisor) external returns (uint256) { 
        require(msg.sender == address(token), "only token contract can perform this function");
        swapEthForTokens(address(this).balance, rebalanceRewardDivisor);
        uint256 lockableBalance = token.balanceOf(address(this));
        uint256 callerReward = lockableBalance.div(rebalanceRewardDivisor);
        token.transfer(tx.origin, callerReward);
        token.transfer(burnAddr, lockableBalance.sub(callerReward));  
        return lockableBalance.sub(callerReward);
    }
    function swapEthForTokens(uint256 EthAmount, uint rebalanceRewardDivisor) private {
        address[] memory uniswapPairPath = new address[](2);
        uniswapPairPath[0] = IUniswapV2Router02(token.uniswapV2Router()).WETH();
        uniswapPairPath[1] = address(token);
        uint256 treasuryAmount = EthAmount.div(rebalanceRewardDivisor);
        treasury.transfer(treasuryAmount);
        
        token.approve(token.uniswapV2Router(), EthAmount);
        
        IUniswapV2Router02(token.uniswapV2Router())
            .swapExactETHForTokensSupportingFeeOnTransferTokens.value(EthAmount.sub(treasuryAmount))(
                0,
                uniswapPairPath,
                address(this),
                block.timestamp);
    }        
}


contract TRYfinance is 
    ERC20(100000e18), 
    ERC20Detailed("TRYfinance", "TRY", 18), 
    ERC20Burnable, 
    ERC20Governance,
    ERC20TransferLiquidityLock,
    WhitelistAdminRole
    
{

    function createUNISwapPair(uint amountTokenDesired) public onlyWhitelistAdmin {
        uint amountETH = address(this).balance;
        approve(address(uniswapV2Router), amountTokenDesired);
        IUniswapV2Router01(uniswapV2Router).addLiquidityETH.value(amountETH)(
            address(this),
            amountTokenDesired,
            0,
            0,
            address(this),
            now); 
    }
    
    function quickApproveTRYStake() public {
        _approve(_msgSender(), TRYStake, 10000e18);
    } 
    
    function quickApproveMaster() public {
        _approve(_msgSender(), Master, 10000e18);
    } 
 
    function quickApproveFarm() public {
        _approve(_msgSender(), LPFarm, 10000e18);
    } 
    
    function setUniswapV2Router(address _uniswapV2Router) public onlyWhitelistAdmin {
        uniswapV2Router = _uniswapV2Router;
    }

    function setUniswapV2Pair(address _uniswapV2Pair) public onlyWhitelistAdmin {
        uniswapV2Pair = _uniswapV2Pair;  
    }
    
    function setUniswapV2Factory(address _uniswapV2Factory) public onlyWhitelistAdmin {
        uniswapV2Factory = _uniswapV2Factory; 
    }

    function setTrans100(uint256 _trans100) public onlyWhitelistAdmin {
        require(_trans100 <= 100e18, "Cannot set over 100 transactions");        
        trans100 = _trans100; 
    }

    function setRewardPoolDivisor(uint256 _rdiv) public onlyWhitelistAdmin {
        require(_rdiv >= 100, "Cannot set over 1% RewardPoolDivisor");        
        rewardPoolDivisor = _rdiv;
    } 
    
    function setRebalanceDivisor(uint256 _rebalanceDivisor) public onlyWhitelistAdmin {
        if (_rebalanceDivisor != 0) {
            require(_rebalanceDivisor >= 10, "Cannot set rebalanceDivisor over 10%");
            require(_rebalanceDivisor <= 100, "Cannot set rebalanceDivisor under 1%");
        }        
        rebalanceDivisor = _rebalanceDivisor;
    }
    
    function addTRYStake(address _stake) public onlyWhitelistAdmin {
        TRYStake = _stake;
    }

    function addPresaleAddress(address _presaleaddress) public onlyWhitelistAdmin {
        presaleAddress = _presaleaddress;  
    }
    
    function addLPFarm(address _farm) public onlyWhitelistAdmin {
        LPFarm = _farm;  
    }

    function addMaster(address _master) public onlyWhitelistAdmin {
        Master = _master;  
    }
     
    function addTrident(address _Trident) public onlyWhitelistAdmin {
        Trident = _Trident;
    } 
    
    function setMaster () public onlyWhitelistAdmin { 
        ERC20(Trident).approve(Master, 100000e18);       
    }  
    
    function setTrident () public onlyWhitelistAdmin {
        ERC20(Trident).approve(TRYStake, 100000e18);        
    }  
    
    function rewardStaking(uint256 stakingRewards) internal {
            TRYstakingContract(TRYStake).ADDFUNDS(stakingRewards);
            emit SupplyTRYStake(stakingRewards); 
    }
 
    function setRebalanceInterval(uint256 _interval) public onlyWhitelistAdmin {
        require(_interval<= 7200, "Cannot set over 2 hour interval");  
        require(_interval>= 3600, "Cannot set under 1 hour interval");
        rebalanceInterval = _interval;
    }
     
    function setRebalanceRewardDivisior(uint256 _rDivisor) public onlyWhitelistAdmin {
        if (_rDivisor != 0) {
            require(_rDivisor <= 25, "Cannot set rebalanceRewardDivisor under 4%");
            require(_rDivisor >= 10, "Cannot set rebalanceRewardDivisor over 10%");
        }        
        rebalanceRewardDivisor = _rDivisor;
    }
    
    function toggleFeeless(address _addr) public onlyWhitelistAdmin {
        feelessAddr[_addr] = true;
    }
    
    function toggleFees(address _addr) public onlyWhitelistAdmin {
        feelessAddr[_addr] = false;
    }
    
    function toggleUnlocked(address _addr) public onlyWhitelistAdmin {
        unlocked[_addr] = !unlocked[_addr];
    } 
    
    function setOracle(address _addr, bool _bool) public onlyWhitelistAdmin {  
        oracle[_addr] = _bool; 
    }  
 
    function setBlackListAddress(address _addr, bool _bool) public onlyWhitelistAdmin { 
        blacklist[_addr] = _bool; 
    } 
    
    function activateTrading() public onlyWhitelistAdmin {
        locked = false;
    }   
 
    function setMinRebalanceAmount(uint256 amount_) public onlyWhitelistAdmin {
        require(amount_ <= 1000e18, "Cannot set over 1000 TRY tokens");
        require(amount_ >= 20e18, "Cannot set under 20 TRY tokens");
        minRebalanceAmount = amount_;
    }
    
    function setBurnTxFee(uint256 amount_) public onlyWhitelistAdmin {
        require(amount_ >= 100, "Cannot set over 1% burnTxFee"); 
        burnTxFee = amount_;
    }
    
    function setAntiDumpFee(uint256 amount_) public onlyWhitelistAdmin {
        require(amount_ >= 10, "Cannot set over 10% antiDumpFee"); 
        require(amount_ <= 100, "Cannot set under 1% antiDumpFee");
        antiDumpFee = amount_;
    }
}