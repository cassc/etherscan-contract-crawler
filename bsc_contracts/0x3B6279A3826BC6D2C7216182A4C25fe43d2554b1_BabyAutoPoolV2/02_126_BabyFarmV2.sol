// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../core/SafeOwnable.sol';
import '../token/BabyVault.sol';

contract BabyFarmV2 is SafeOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that CAKEs distribution occurs.
        uint256 accRewardPerShare; // Accumulated CAKEs per share, times 1e12. See below.
    }

    enum FETCH_VAULT_TYPE {
        FROM_ALL,
        FROM_BALANCE,
        FROM_TOKEN
    }

    IERC20 public immutable rewardToken;
    uint256 public startBlock;

    BabyVault public vault;
    uint256 public rewardPerBlock;

    PoolInfo[] public poolInfo;
    mapping(IERC20 => bool) public pairExist;
    mapping(uint => bool) public pidInBlacklist;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    uint256 public totalAllocPoint = 0;
    FETCH_VAULT_TYPE public fetchVaultType;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    modifier legalPid(uint _pid) {
        require(_pid > 0 && _pid < poolInfo.length, "illegal farm pid"); 
        _;
    }

    modifier availablePid(uint _pid) {
        require(!pidInBlacklist[_pid], "illegal pid ");
        _;
    }

    function fetch(address _to, uint _amount) internal returns(uint) {
        if (fetchVaultType == FETCH_VAULT_TYPE.FROM_ALL) {
            return vault.mint(_to, _amount);
        } else if (fetchVaultType == FETCH_VAULT_TYPE.FROM_BALANCE) {
            return vault.mintOnlyFromBalance(_to, _amount);
        } else if (fetchVaultType == FETCH_VAULT_TYPE.FROM_TOKEN) {
            return vault.mintOnlyFromToken(_to, _amount);
        } 
        return 0;
    }
    
    constructor(BabyVault _vault, uint256 _rewardPerBlock, uint256 _startBlock, address _owner, uint[] memory _allocPoints, IERC20[] memory _lpTokens) {
        rewardToken = _vault.babyToken();
        require(_startBlock >= block.number, "illegal startBlock");
        startBlock = _startBlock;
        vault = _vault;
        rewardPerBlock = _rewardPerBlock;
        //we skip the zero index pool, and start at index 1
        poolInfo.push(PoolInfo({
            lpToken: IERC20(address(0)),
            allocPoint: 0,
            lastRewardBlock: block.number,
            accRewardPerShare: 0
        }));
        require(_allocPoints.length > 0 && _allocPoints.length == _lpTokens.length, "illegal data");
        for (uint i = 0; i < _allocPoints.length; i ++) {
            require(!pairExist[_lpTokens[i]], "already exist");
            totalAllocPoint = totalAllocPoint.add(_allocPoints[i]);
            poolInfo.push(PoolInfo({
                lpToken: _lpTokens[i],
                allocPoint: _allocPoints[i],
                lastRewardBlock: _startBlock,
                accRewardPerShare: 0
            }));
            pairExist[_lpTokens[i]] = true;
        }
        if (_owner != address(0)) {
            _transferOwnership(_owner);
        }
        fetchVaultType = FETCH_VAULT_TYPE.FROM_ALL;
    }

    function setVault(BabyVault _vault) external onlyOwner {
        require(_vault.babyToken() == rewardToken, "illegal vault");
        vault = _vault;
    }

    function disablePid(uint _pid) external onlyOwner legalPid(_pid) {
        pidInBlacklist[_pid] = true;
    }

    function enablePid(uint _pid) external onlyOwner legalPid(_pid) {
        delete pidInBlacklist[_pid];
    }

    function setRewardPerBlock(uint _rewardPerBlock) external onlyOwner {
        massUpdatePools();
        rewardPerBlock = _rewardPerBlock;
    }

    function setFetchVaultType(FETCH_VAULT_TYPE _newType) external onlyOwner {
        fetchVaultType = _newType;
    }

    function setStartBlock(uint _newStartBlock) external onlyOwner {
        require(block.number < startBlock && _newStartBlock >= block.number, "illegal start Block Number");
        startBlock = _newStartBlock;
        for (uint i = 0; i < poolInfo.length; i ++) {
            poolInfo[i].lastRewardBlock = _newStartBlock;
        }
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function updatePool(uint256 _pid) public legalPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || totalAllocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number.sub(pool.lastRewardBlock);
        uint256 reward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 1; pid < length; ++pid) {
            if (!pidInBlacklist[pid]) {
                updatePool(pid);
            }
        }
    }

    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        require(!pairExist[_lpToken], "already exist");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accRewardPerShare: 0
        }));
        pairExist[_lpToken] = true;
    }

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner legalPid(_pid) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
        }
    }

    function pendingReward(uint256 _pid, address _user) external view legalPid(_pid) returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = block.number.sub(pool.lastRewardBlock);
            uint256 reward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }

    function deposit(uint256 _pid, uint256 _amount) external legalPid(_pid) availablePid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                require(fetch(msg.sender, pending) == pending, "out of token");
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) external legalPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not enough");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            require(fetch(msg.sender, pending) == pending, "out of token");
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) public legalPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }
}