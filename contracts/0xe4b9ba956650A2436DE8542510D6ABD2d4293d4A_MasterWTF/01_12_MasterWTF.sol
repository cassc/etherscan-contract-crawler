// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../refs/CoreRef.sol";
import "../interfaces/IMasterWTF.sol";
import "../interfaces/IVotingEscrow.sol";

contract MasterWTF is IMasterWTF, CoreRef, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 cid;
        uint256 earned;
    }

    struct PoolInfo {
        uint256 allocPoint;
    }

    struct PoolStatus {
        uint256 totalSupply;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }

    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");
    address public override votingEscrow;
    address public override rewardToken;
    uint256 public override rewardPerBlock;
    uint256 public override totalAllocPoint = 0;
    uint256 public override startBlock;
    uint256 public override endBlock;
    uint256 public override cycleId = 0;
    bool public override rewarding = false;

    PoolInfo[] public override poolInfo;
    // pid => address => UserInfo
    mapping(uint256 => mapping(address => UserInfo)) public override userInfo;
    // cid => pid => PoolStatus
    mapping(uint256 => mapping(uint256 => PoolStatus)) public override poolSnapshot;

    modifier validatePid(uint256 _pid) {
        require(_pid < poolInfo.length, "validatePid: Not exist");
        _;
    }

    event UpdateEmissionRate(uint256 rewardPerBlock);
    event Claim(address indexed user, uint256 pid, uint256 amount);
    event ClaimAll(address indexed user, uint256 amount);

    constructor(
        address _core,
        address _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256[] memory _pools,
        address _votingEscrow
    ) public CoreRef(_core) {
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
        votingEscrow = _votingEscrow;
        IERC20(_rewardToken).safeApprove(votingEscrow, uint256(-1));
        uint256 total = 0;
        for (uint256 i = 0; i < _pools.length; i++) {
            total = total.add(_pools[i]);
            poolInfo.push(PoolInfo({allocPoint: _pools[i]}));
        }
        totalAllocPoint = total;
    }

    function poolLength() public view override returns (uint256) {
        return poolInfo.length;
    }

    function add(uint256 _allocPoint) public override onlyGovernor {
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({allocPoint: _allocPoint}));
    }

    function setVotingEscrow(address _votingEscrow) public override onlyTimelock {
        require(_votingEscrow != address(0), "Zero address");
        IERC20(rewardToken).safeApprove(votingEscrow, 0);
        votingEscrow = _votingEscrow;
        IERC20(rewardToken).safeApprove(votingEscrow, uint256(-1));
    }

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public override onlyTimelock validatePid(_pid) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
        }
    }

    function getMultiplier(uint256 _from, uint256 _to) public view override returns (uint256) {
        return _to.sub(_from);
    }

    function pendingReward(address _user, uint256 _pid) public view override validatePid(_pid) returns (uint256) {
        PoolInfo storage info = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        PoolStatus storage pool = poolSnapshot[user.cid][_pid];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        if (cycleId == user.cid && rewarding && block.number > pool.lastRewardBlock && pool.totalSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number >= endBlock ? endBlock : block.number
            );
            uint256 reward = multiplier.mul(rewardPerBlock).mul(info.allocPoint).div(totalAllocPoint);
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(pool.totalSupply));
        }
        return user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt).add(user.earned);
    }

    function massUpdatePools() public override {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public override validatePid(_pid) {
        if (!rewarding) {
            return;
        }
        PoolInfo storage info = poolInfo[_pid];
        PoolStatus storage pool = poolSnapshot[cycleId][_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.lastRewardBlock >= endBlock) {
            return;
        }
        uint256 lastRewardBlock = block.number >= endBlock ? endBlock : block.number;
        if (pool.totalSupply == 0 || info.allocPoint == 0) {
            pool.lastRewardBlock = lastRewardBlock;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, lastRewardBlock);
        uint256 reward = multiplier.mul(rewardPerBlock).mul(info.allocPoint).div(totalAllocPoint);
        pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e12).div(pool.totalSupply));
        pool.lastRewardBlock = lastRewardBlock;
    }

    function updateStake(
        uint256 _pid,
        address _account,
        uint256 _amount
    ) public override onlyRole(MASTER_ROLE) validatePid(_pid) nonReentrant {
        UserInfo storage user = userInfo[_pid][_account];
        PoolStatus storage pool = poolSnapshot[user.cid][_pid];

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            user.earned = user.earned.add(pending);
        }

        if (cycleId == user.cid) {
            pool.totalSupply = pool.totalSupply.sub(user.amount).add(_amount);
            user.amount = _amount;
            user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        } else {
            pool = poolSnapshot[cycleId][_pid];
            pool.totalSupply = pool.totalSupply.add(_amount);
            user.amount = _amount;
            user.cid = cycleId;
            user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        }
    }

    function start(uint256 _endBlock) public override onlyRole(MASTER_ROLE) nonReentrant {
        require(!rewarding, "cycle already active");
        require(_endBlock > block.number, "endBlock less");
        rewarding = true;
        endBlock = _endBlock;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            PoolStatus storage pool = poolSnapshot[cycleId][i];
            pool.lastRewardBlock = block.number;
            pool.accRewardPerShare = 0;
        }
    }

    function next(uint256 _cid) public override onlyRole(MASTER_ROLE) nonReentrant {
        require(rewarding, "cycle not active");
        massUpdatePools();
        endBlock = block.number + 1;
        rewarding = false;
        cycleId = _cid;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            poolSnapshot[cycleId][i] = PoolStatus({totalSupply: 0, lastRewardBlock: 0, accRewardPerShare: 0});
        }
    }

    function _lockRewards(
        address _rewardBeneficiary,
        uint256 _rewardAmount,
        uint256 _lockDurationIfLockNotExists,
        uint256 _lockDurationIfLockExists
    ) internal {
        require(_rewardAmount > 0, "WTF Reward is zero");
        uint256 lockedAmountWTF = IVotingEscrow(votingEscrow).getLockedAmount(_rewardBeneficiary);

        // if no lock exists
        if (lockedAmountWTF == 0) {
            require(_lockDurationIfLockNotExists > 0, "Lock duration can't be zero");
            IVotingEscrow(votingEscrow).createLockFor(_rewardBeneficiary, _rewardAmount, _lockDurationIfLockNotExists);
        } else {
            // check if expired
            bool lockExpired = IVotingEscrow(votingEscrow).isLockExpired(_rewardBeneficiary);
            if (lockExpired) {
                require(_lockDurationIfLockExists > 0, "New lock expiry timestamp can't be zero");
            }
            IVotingEscrow(votingEscrow).increaseTimeAndAmountFor(
                _rewardBeneficiary,
                _rewardAmount,
                _lockDurationIfLockExists
            );
        }
    }

    function claim(
        uint256 _pid,
        uint256 _lockDurationIfLockNotExists,
        uint256 _lockDurationIfLockExists
    ) public override nonReentrant {
        uint256 pending;
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolStatus storage pool = poolSnapshot[user.cid][_pid];

        if (cycleId == user.cid) {
            updatePool(_pid);
        }

        pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        if (user.earned > 0) {
            pending = pending.add(user.earned);
            user.earned = 0;
        }
        if (pending > 0) {
            _lockRewards(msg.sender, pending, _lockDurationIfLockNotExists, _lockDurationIfLockExists);
            emit Claim(msg.sender, _pid, pending);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
    }

    function claimAll(uint256 _lockDurationIfLockNotExists, uint256 _lockDurationIfLockExists)
        public
        override
        nonReentrant
    {
        uint256 pending = 0;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            UserInfo storage user = userInfo[i][msg.sender];
            PoolStatus storage pool = poolSnapshot[user.cid][i];
            if (cycleId == user.cid) {
                updatePool(i);
            }
            if (user.earned > 0) {
                pending = pending.add(user.earned);
                user.earned = 0;
            }
            pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt).add(pending);
            user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        }

        if (pending > 0) {
            _lockRewards(msg.sender, pending, _lockDurationIfLockNotExists, _lockDurationIfLockExists);
            emit ClaimAll(msg.sender, pending);
        }
    }

    function safeRewardTransfer(address _to, uint256 _amount) internal returns (uint256) {
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        uint256 amount;
        if (_amount > balance) {
            amount = balance;
        } else {
            amount = _amount;
        }

        require(IERC20(rewardToken).transfer(_to, amount), "safeRewardTransfer: Transfer failed");
        return amount;
    }

    function updateRewardPerBlock(uint256 _rewardPerBlock) public override onlyTimelock {
        massUpdatePools();
        rewardPerBlock = _rewardPerBlock;
        emit UpdateEmissionRate(_rewardPerBlock);
    }
}