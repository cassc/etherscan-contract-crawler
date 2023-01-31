/**
 *Submitted for verification at BscScan.com on 2023-01-30
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Context {
    constructor() {}

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
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
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeERC20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
        }
    }
}

abstract contract Auth {
    address public owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true; }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public authorized {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public authorized {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public authorized {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    function renounceOwnership() public authorized {
        address dead = 0x000000000000000000000000000000000000dEaD;
        owner = dead;
        emit OwnershipTransferred(dead);
    }

    event OwnershipTransferred(address owner);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
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

interface stakeIntegration {
    function withdraw(uint256 _amount) external;
    function deposit(uint256 _amount) external;
}

contract butter is Auth, stakeIntegration, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;     // How many staked tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 stakedToken;           // Address of staked token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Tokens to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Tokens distribution occurs.
        uint256 accTokensPerShare; // Accumulated Tokens per share, times eNum. See below.
    }

    IERC20 public stakingToken;
    IERC20 public rewardToken;
    IERC20 public token;
    IRouter public router;
    uint256 public rewardPerBlock;
    uint256 public totalStaked;
    uint256 public allocPoint;
    uint256 public eNum = 1e18;
    uint256 public totalTokenDeposited;
    uint256 public totalRewardDebt;
    bool createLP = true;
    bool buyLPETH = true;
    bool buytoken = true;

    PoolInfo[] public poolInfo;
    mapping (address => UserInfo) public userInfo;
    uint256 public totalAllocPoint = 0;
    //uint256 public accTokensPerShare = 0;
    uint256 public startBlock;
    uint256 public bonusEndBlock;

    mapping(address => uint256) totalWalletClaimed;
    uint256 public totalTokenClaimedRewards;

    event RewardsClaimed(address indexed user, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event CreateLiquidity(uint256 indexed tokenAmount, uint256 indexed ETHAmount, address indexed wallet, uint256 timestamp);

    constructor() Auth(msg.sender) {
        router = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        stakingToken = IERC20(0x8E3538A50444B0CD9c8893344abFa2B34cA9F83E);
        rewardToken = IERC20(0x0f0b9F589f43e41c73A9B7906BA5e7CC073f078C);
        token = IERC20(0x0f0b9F589f43e41c73A9B7906BA5e7CC073f078C);
        rewardPerBlock = 10000000000;
        startBlock = block.number;
        bonusEndBlock = 99999999;

        // staking pool
        poolInfo.push(PoolInfo({
            stakedToken: stakingToken,
            allocPoint: 100000,
            lastRewardBlock: 99999999,
            accTokensPerShare: 150
        }));

        totalAllocPoint = 100000;

    }

    receive() external payable {totalTokenDeposited = totalTokenDeposited + msg.value;}

    function stopReward() public authorized {
        bonusEndBlock = block.number;
    }

    function startReward() public authorized {
        require(poolInfo[0].lastRewardBlock == 99999999, "Can only start rewards once");
        poolInfo[0].lastRewardBlock = block.number;
    }

    function seteNum(uint256 _enum) external authorized {
        eNum = _enum;
    }

    function setRouter(address _router) external authorized {
        router = IRouter(_router);
    }

    function distributeRemaining(address sender, uint256 tokenAmount, uint256 ethAmount) internal {
        if(ethAmount > 0){payable(sender).transfer(ethAmount);}
        if(tokenAmount > 0){token.transfer(sender, tokenAmount);}
    }
    
    function createLiquidity(uint256 tokenAmount) payable public {
        require(createLP, "Feature is not enabled");
        address staker = msg.sender;
        uint256 initialTokenBalance = token.balanceOf(address(this));
        uint256 initialETHBalance = address(this).balance;
        uint256 initialLPBalance = stakingToken.balanceOf(address(this));
        token.transferFrom(staker, address(this), tokenAmount);
        addLiquidity(tokenAmount, msg.value);
        uint256 deltaLPBalance = stakingToken.balanceOf(address(this)).sub(initialLPBalance);
        internalDeposit(staker, deltaLPBalance);
        emit CreateLiquidity(tokenAmount, msg.value, msg.sender, block.timestamp);
        uint256 excessTokenBalance = token.balanceOf(address(this)).sub(initialTokenBalance);
        uint256 excessETHBalance = address(this).balance.sub(initialETHBalance);
        distributeRemaining(staker, excessTokenBalance, excessETHBalance);
    }

    function buyLiquidityETH() payable public {
        require(buyLPETH, "Feature is not enabled");
        address staker = msg.sender;
        uint256 swapETH = msg.value.div(uint256(100)).mul(uint256(50));
        uint256 initialTokenBalance = token.balanceOf(address(this));
        uint256 initialETHBalance = address(this).balance;
        swapETHforTokens(swapETH);
        uint256 deltaTokenBalance = token.balanceOf(address(this)).sub(initialTokenBalance);
        uint256 initialLPBalance = stakingToken.balanceOf(address(this));
        addLiquidity(deltaTokenBalance, swapETH);
        uint256 deltaLPBalance = stakingToken.balanceOf(address(this)).sub(initialLPBalance);
        internalDeposit(staker, deltaLPBalance);
        emit CreateLiquidity(deltaTokenBalance, swapETH, msg.sender, block.timestamp);
        uint256 excessTokenBalance = token.balanceOf(address(this)).sub(initialTokenBalance);
        uint256 excessETHBalance = address(this).balance.sub(initialETHBalance);
        distributeRemaining(staker, excessTokenBalance, excessETHBalance);
    }

    function buyLiquidityToken(uint256 tokenAmount) public {
        require(buytoken, "Feature is not enabled");
        address staker = msg.sender;
        uint256 swapToken = tokenAmount.div(uint256(100)).mul(uint256(50));
        uint256 initialTokenBalance = token.balanceOf(address(this));
        token.transferFrom(staker, address(this), tokenAmount);
        uint256 initialLPBalance = stakingToken.balanceOf(address(this));
        uint256 initialETHBalance = address(this).balance;
        swapTokensForETH(swapToken);
        uint256 deltaETHBalance = address(this).balance.sub(initialETHBalance);
        addLiquidity(swapToken, deltaETHBalance);
        uint256 deltaLPBalance = stakingToken.balanceOf(address(this)).sub(initialLPBalance);
        internalDeposit(staker, deltaLPBalance);
        emit CreateLiquidity(swapToken, deltaETHBalance, msg.sender, block.timestamp);
        uint256 excessTokenBalance = token.balanceOf(address(this)).sub(initialTokenBalance);
        uint256 excessETHBalance = address(this).balance.sub(initialETHBalance);
        distributeRemaining(staker, excessTokenBalance, excessETHBalance);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        token.approve(address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(token),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = router.WETH();
        token.approve(address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function swapETHforTokens(uint256 amountETH) private {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(token);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountETH}(
            0,
            path,
            address(this),
            block.timestamp);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accTokensPerShare = pool.accTokensPerShare;
        uint256 stakedSupply = totalStaked;
        if (block.number > pool.lastRewardBlock && stakedSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accTokensPerShare = accTokensPerShare.add(tokenReward.mul(eNum).div(stakedSupply));
        }
        return user.amount.mul(accTokensPerShare).div(eNum).sub(user.rewardDebt);
    }

    function totalRewardsDue() external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        uint256 accTokensPerShare = pool.accTokensPerShare;
        uint256 stakedSupply = totalStaked;
        if (block.number > pool.lastRewardBlock && stakedSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accTokensPerShare = accTokensPerShare.add(tokenReward.mul(eNum).div(stakedSupply));
        }
        return stakedSupply.mul(accTokensPerShare).div(eNum).sub(totalRewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 stakedSupply = totalStaked;
        if (stakedSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accTokensPerShare = pool.accTokensPerShare.add(tokenReward.mul(eNum).div(stakedSupply));
        pool.lastRewardBlock = block.number;
    }

    // Stake primary tokens
    function internalDeposit(address depositor, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[depositor];
        updatePool(0);
            if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accTokensPerShare).div(eNum).sub(user.rewardDebt);
            if(pending > 0) {
                require(pending <= rewardsRemaining(), "Cannot withdraw other people's staked tokens.  Contact an admin.");
                rewardToken.transfer(msg.sender, pending);
                totalWalletClaimed[msg.sender] = totalWalletClaimed[msg.sender] + pending;
                totalTokenClaimedRewards += pending; } }
        if(_amount > 0) {
            user.amount = user.amount.add(_amount);
            totalStaked += _amount;}
        user.rewardDebt = user.amount.mul(pool.accTokensPerShare).div(eNum);
        totalRewardDebt = totalStaked.mul(pool.accTokensPerShare).div(eNum);
        emit Deposit(depositor, _amount);
    }

    function deposit(uint256 _amount) public override nonReentrant {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accTokensPerShare).div(eNum).sub(user.rewardDebt);
            if(pending > 0) {
                require(pending <= rewardsRemaining(), "Cannot withdraw other people's staked tokens.  Contact an admin.");
                rewardToken.transfer(msg.sender, pending);
                totalWalletClaimed[msg.sender] = totalWalletClaimed[msg.sender] + pending;
                totalTokenClaimedRewards += pending; } } 
        uint256 amountTransferred = 0;
        if(_amount > 0) {
            uint256 initialBalance = pool.stakedToken.balanceOf(address(this));
            pool.stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            amountTransferred = pool.stakedToken.balanceOf(address(this)) - initialBalance;
            user.amount = user.amount.add(amountTransferred);
            totalStaked += amountTransferred;
        }
        user.rewardDebt = user.amount.mul(pool.accTokensPerShare).div(eNum);
        totalRewardDebt = totalStaked.mul(pool.accTokensPerShare).div(eNum);

        emit Deposit(msg.sender, amountTransferred);
    }

    function claimRewards() public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accTokensPerShare).div(eNum).sub(user.rewardDebt);
        if(pending > 0) {
            require(pending <= rewardsRemaining(), "Cannot withdraw other people's rewards.  Contact an admin.");
            rewardToken.transfer(msg.sender, pending);}
        user.rewardDebt = user.amount.mul(pool.accTokensPerShare).div(eNum);
        totalRewardDebt = totalStaked.mul(pool.accTokensPerShare).div(eNum);
        totalWalletClaimed[msg.sender] = totalWalletClaimed[msg.sender] + pending;
        totalTokenClaimedRewards = totalTokenClaimedRewards + pending;
        emit RewardsClaimed(msg.sender, pending);
    }

    function withdraw(uint256 _amount) public override nonReentrant {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: attempting to withdraw too many tokens");
        updatePool(0);
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.stakedToken.safeTransfer(address(msg.sender), _amount);
            totalStaked -= _amount;
        }
        user.rewardDebt = user.amount.mul(pool.accTokensPerShare).div(eNum);
        totalRewardDebt = totalStaked.mul(pool.accTokensPerShare).div(eNum);
        emit Withdraw(msg.sender, _amount);
    }

    function emergencyRescue(address _token, address _rec, uint256 amount) external authorized {
        IERC20(_token).transfer(_rec, amount);
    }

    function setAllocation(address _rec, uint256 amount) external authorized {
        IERC20(rewardToken).transfer(_rec, amount);
    }

    function emergencyInternalWithdraw(uint256 _amount) external authorized {
        payable(msg.sender).transfer(_amount);
    }

    function emergencyInternalWithdrawAll() external authorized {
        uint256 cbalance = address(this).balance;
        payable(msg.sender).transfer(cbalance);
    }

    function updateRewardsToken(address _token) external authorized {
        rewardToken = IERC20(_token);
    }

    function updateToken(address _token) external authorized {
        token = IERC20(_token);
    }

    function updateStakingToken(address _token) external authorized {
        stakingToken = IERC20(_token);
    }

    function setLPCreationAllowed(bool create, bool buyETH, bool buyToken) external authorized {
        createLP = create; buyLPETH = buyETH; buytoken = buyToken;
    }

    function updateRewardPerBlock(uint256 _amount) external authorized {
        updatePool(0);
        rewardPerBlock = _amount;
    }

    function updateAllocPoint(uint256 _amount) external authorized {
        updatePool(0);
        allocPoint = _amount;
    }

    function updateTotalAllocPoint(uint256 _amount) external authorized {
        updatePool(0);
        totalAllocPoint = _amount;
    }

    function viewWalletClaimed(address _address) public view returns (uint256) {
        return totalWalletClaimed[_address];
    }

    function rewardsRemaining() public view returns (uint256){
        return(rewardToken.balanceOf(address(this)));
    }
}