// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./libs/SafeERC20.sol";
import "./interfaces/IApple.sol";


contract PYEChefV3 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 depositTime;    // The last time when the user deposit funds
        //
        // We do some fancy math here. Basically, any point in time, the amount of APPLEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accApplePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accApplePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. APPLEs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that APPLEs distribution occurs.
        uint256 accApplePerShare; // Accumulated APPLEs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint16 withdrawFeeBP;      // Withdraw fee in basis points
        uint256 lockTime;         // The time for lock funds
    }
    // The APPLE TOKEN!
    IApple public apple;
    // Dev address.
    address public devaddr;
    // Dev fee.
    uint256 public devfee = 1000;
    // APPLE tokens created per block.
    uint256 public applePerBlock;
    // Bonus muliplier for early apple makers.
    uint256 public BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when APPLE mining starts.
    uint256 public startBlock;
    // The time for the lock funds
    uint256 lockTime;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event setLockTime(address indexed user, uint256 lockTime);
    event NewStartBlock(uint256 startBlock);
    constructor(
        address _apple,
        address _devaddr,
        address _feeAddress,
        uint256 _applePerBlock,
        uint256 _startBlock
    ) {
        apple = IApple(_apple);
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        applePerBlock = _applePerBlock;
        startBlock = _startBlock;

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: IERC20(_apple),
            allocPoint: 1,
            lastRewardBlock: startBlock,
            accApplePerShare: 0,
            depositFeeBP : 0,
            withdrawFeeBP : 0,
            lockTime : 0
        }));
        totalAllocPoint = 1;
    }
    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, uint16 _depositFeeBP, uint16 _withdrawFeeBP, uint256 _lockTime, bool _withUpdate) external onlyOwner {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        require(_withdrawFeeBP <= 10000, "add: invalid withdraw fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accApplePerShare: 0,
            depositFeeBP : _depositFeeBP,
            withdrawFeeBP : _withdrawFeeBP,
            lockTime : _lockTime
        }));
    }

    // Update the given pool's APPLE allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, uint16 _withdrawFeeBP, uint256 _lockTime, bool _withUpdate) external onlyOwner {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        require(_withdrawFeeBP <= 10000, "add: invalid withdraw fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].withdrawFeeBP = _withdrawFeeBP;
        poolInfo[_pid].lockTime = _lockTime;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
        }
    }
 
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending APPLEs on frontend.
    function pendingApple(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accApplePerShare = pool.accApplePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 appleReward = multiplier.mul(applePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accApplePerShare = accApplePerShare.add(appleReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accApplePerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePoolsStart() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePoolStart(pid);
        }
    }


    function updateApplePerBlock(uint256 _applePerBlock) external onlyOwner {
        applePerBlock = _applePerBlock;
    }

    /**
     * @notice It allows the admin to update start block
     * @dev This function is only callable by owner.
     * @param _startBlock: the new start block
     */
    function updateStartBlock(uint256 _startBlock) external onlyOwner {
        require(block.number < _startBlock, "New startBlock must be higher than current block");

        startBlock = _startBlock;

        // Set the lastRewardBlock for all pools as the startBlock
        massUpdatePoolsStart();

        emit NewStartBlock(_startBlock);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
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
        uint256 appleReward = multiplier.mul(applePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        apple.mint(devaddr, appleReward.mul(devfee).div(10000));
        apple.mint(address(this), appleReward);
        pool.accApplePerShare = pool.accApplePerShare.add(appleReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePoolStart(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for APPLE allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {

        require (_pid != 0, 'deposit APPLE by staking');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accApplePerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeAppleTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.depositTime = block.timestamp;
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accApplePerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {

        require (_pid != 0, 'withdraw APPLE by unstaking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        require(user.depositTime + pool.lockTime < block.timestamp, "Can not withdraw in lock period");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accApplePerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeAppleTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            uint256 withdrawFee = _amount.mul(pool.withdrawFeeBP).div(10000);
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount.sub(withdrawFee));
            pool.lpToken.safeTransfer(feeAddress, withdrawFee);
        }
        user.rewardDebt = user.amount.mul(pool.accApplePerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Stake APPLE tokens to MasterChef
    function enterStaking(uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accApplePerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeAppleTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.depositTime = block.timestamp;
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accApplePerShare).div(1e12);

        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw APPLE tokens from STAKING.
    function leaveStaking(uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        require(user.depositTime + pool.lockTime < block.timestamp, "Can not withdraw in lock period");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accApplePerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeAppleTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            uint256 withdrawFee = _amount.mul(pool.withdrawFeeBP).div(10000);
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount.sub(withdrawFee));
            pool.lpToken.safeTransfer(feeAddress, withdrawFee);
        }
        user.rewardDebt = user.amount.mul(pool.accApplePerShare).div(1e12);

        emit Withdraw(msg.sender, 0, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe apple transfer function, just in case if rounding error causes pool to not have enough APPLEs.
    function safeAppleTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBalance = apple.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > tokenBalance) {
            transferSuccess = apple.transfer(_to, tokenBalance);
        } else {
            transferSuccess = apple.transfer(_to, _amount);
        }
        require(transferSuccess, "safeTokenTransfer: transfer failed");
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr, uint256 _devfee) external {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
        devfee = _devfee;
    }
    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }
}