// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import "../interfaces/IERC20Mintable.sol";
import '../core/SafeOwnable.sol';

contract MasterChef is SafeOwnable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;     
        uint256 rewardDebt; 
    }

    struct PoolInfo {
        IERC20 lpToken;           
        uint256 allocPoint;       
        uint256 lastRewardBlock;  
        uint256 accPerShare; 
    }

    IERC20Mintable public rewardToken;
    uint256 public rewardPerBlock;
    uint256 public BONUS_MULTIPLIER;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => uint256) public pidOfLP;
    mapping(address => bool) public existsLP;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when CAKE mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event NewRewardPerBlock(uint oldReward, uint newReward);
    event NewMultiplier(uint oldMultiplier, uint newMultiplier);
    event NewPool(uint pid, address lpToken, uint allocPoint, uint totalPoint);

    modifier validatePoolByPid(uint256 _pid) {
        require (_pid < poolInfo.length, "Pool does not exist");
        _;
    }

    constructor (
        IERC20Mintable _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock
    ) SafeOwnable (msg.sender) {
        require(address(_rewardToken) != address(0), "illegal rewardToken");
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        BONUS_MULTIPLIER = 1;
    }

    function updateMultiplier(uint256 multiplierNumber, bool withUpdate) external onlyOwner {
        if (withUpdate) {
            massUpdatePools();
        }
        emit NewMultiplier(BONUS_MULTIPLIER, multiplierNumber);
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function updateRewardPerBlock(uint256 _rewardPerBlock, bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        emit NewRewardPerBlock(rewardPerBlock, _rewardPerBlock);
        rewardPerBlock = _rewardPerBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) external onlyOwner {
        require(address(_lpToken) != address(rewardToken), "can not add reward");
        require(!existsLP[address(_lpToken)], "lp already exist");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        pidOfLP[address(_lpToken)] = poolInfo.length;
        existsLP[address(_lpToken)] = true;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accPerShare: 0
        }));
        emit NewPool(poolInfo.length - 1, address(_lpToken), _allocPoint, totalAllocPoint);
    }

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyOwner validatePoolByPid(_pid) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
        }
        emit NewPool(_pid, address(poolInfo[_pid].lpToken), _allocPoint, totalAllocPoint);
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function pending(uint256 _pid, address _user) external validatePoolByPid(_pid) view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPerShare = pool.accPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 rewardReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accPerShare = accPerShare.add(rewardReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accPerShare).div(1e12).sub(user.rewardDebt);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 rewardReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        rewardReward = rewardToken.mint(address(this), rewardReward);
        pool.accPerShare = pool.accPerShare.add(rewardReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) external nonReentrant validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pendingAmount = user.amount.mul(pool.accPerShare).div(1e12).sub(user.rewardDebt);
            if(pendingAmount > 0) {
                safeRewardTransfer(msg.sender, pendingAmount);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pendingAmount = user.amount.mul(pool.accPerShare).div(1e12).sub(user.rewardDebt);
        if(pendingAmount > 0) {
            safeRewardTransfer(msg.sender, pendingAmount);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) external nonReentrant validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint currentBalance = IERC20(rewardToken).balanceOf(address(this));
        if (currentBalance < _amount) {
            _amount = currentBalance;
        }
        IERC20(rewardToken).safeTransfer(_to, _amount);
    }

}