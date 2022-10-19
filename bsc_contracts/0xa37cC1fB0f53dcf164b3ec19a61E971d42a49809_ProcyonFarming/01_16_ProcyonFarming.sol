// SPDX-License-Identifier: MIT

// ######  ######  #######  #####  #     # ####### #     # 
// #     # #     # #     # #     #  #   #  #     # ##    # 
// #     # #     # #     # #         # #   #     # # #   # 
// ######  ######  #     # #          #    #     # #  #  # 
// #       #   #   #     # #          #    #     # #   # # 
// #       #    #  #     # #     #    #    #     # #    ## 
// #       #     # #######  #####     #    ####### #     # 

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./libs/IBEP20.sol";
import "./libs/SafeBEP20.sol";
import "./libs/IProcyonFarmingReferral.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./PCYToken.sol";

contract ProcyonFarming is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. PCYs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that PCYs distribution occurs.
        uint256 accPCYPerShare;   // Accumulated PCYs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    // Bonus muliplier for early pcy makers.
    uint256 public constant bonusMultiplier = 1;
    // Max deposit fee: 3%.
    uint16 public constant maxDepositFee = 300;
    // Max referral commission rate: 4%.
    uint16 public constant maxReferralCommissionRate = 400;

    // The PCY TOKEN!
    PCYToken public pcy;
    // The PCY TOKEN!
    uint256 public pcyID;
    // Dev address.
    address public devAddress;
    // Deposit Fee address
    address public feeAddress;
    // PCY tokens created per block.
    uint256 public pcyPerBlock;
    // Info of each pool.

    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when PCY mining starts.
    uint256 public startBlock;

    // PCY referral contract address.
    IProcyonFarmingReferral public procyonFarmingReferral;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 400;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);
    event Compounded(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        PCYToken _pcy,
        uint256 _startBlock,
        uint256 _pcyPerBlock
    ) public {
        pcy = _pcy;
        startBlock = _startBlock;
        pcyPerBlock = _pcyPerBlock;
        devAddress = msg.sender;
        feeAddress = msg.sender;
    }

    function currentBlock() external view returns (uint256) {
        return block.number;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= maxDepositFee, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accPCYPerShare: 0,
            depositFeeBP: _depositFeeBP
        }));
    }

    // Update the given pool's PCY allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= maxDepositFee, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

        // Safe pcy transfer function, just in case if rounding error causes pool to not have enough PCYs.
    function safePCYTransfer(address _to, uint256 _amount) internal {
        uint256 pcyBal = pcy.balanceOf(address(this));
        if (_amount > pcyBal) {
            pcy.transfer(_to, pcyBal);
        } else {
            pcy.transfer(_to, _amount);
        }
    }

    // Deposit LP tokens to ProcyonFarming for PCY allocation.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (_amount > 0 && address(procyonFarmingReferral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            procyonFarmingReferral.recordReferral(msg.sender, _referrer);
        }

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accPCYPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safePCYTransfer(msg.sender, pending);
                payReferralCommission(msg.sender, pending);
            }
        }

        if (_amount > 0) {
            uint256 beforeDeposit = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 afterDeposit = pool.lpToken.balanceOf(address(this));
            _amount = afterDeposit.sub(beforeDeposit); 

            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(1e4);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accPCYPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }
    
    // Withdraw LP tokens from ProcyonFarming.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);

        uint256 pending = user.amount.mul(pool.accPCYPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safePCYTransfer(msg.sender, pending);
            payReferralCommission(msg.sender, pending);
        }

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accPCYPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(bonusMultiplier);
    }

    // View function to see pending PCYs on frontend.
    function pendingPCY(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPCYPerShare = pool.accPCYPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 pcyReward = multiplier.mul(pcyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accPCYPerShare = accPCYPerShare.add(pcyReward.mul(1e12).div(lpSupply));
        }
        uint256 pending = user.amount.mul(accPCYPerShare).div(1e12).sub(user.rewardDebt);
        return pending;
    }

    // Only update before start of farm
    function updateStartBlock(uint256 _startBlock) external onlyOwner {
	    require(startBlock > block.number, "updateStartBlock: Farming already started");
        startBlock = _startBlock;
        
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardBlock = startBlock;
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 pcyReward = multiplier.mul(pcyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pcy.mint(devAddress, pcyReward.div(10));
        pcy.mint(address(this), pcyReward);
        pool.accPCYPerShare = pool.accPCYPerShare.add(pcyReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update dev address by the previous dev.
    function setDevAddress(address _devAddress) public {
        require(msg.sender == devAddress, "setDevAddress: FORBIDDEN");
        require(_devAddress != address(0), "setDevAddress: ZERO");
        devAddress = _devAddress;
    }
    
    // Update Fee Address
    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
    }

    // Pancake has to add hidden dummy pools in order to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _pcyPerBlock) public onlyOwner {
        massUpdatePools();
        emit EmissionRateUpdated(msg.sender, pcyPerBlock, _pcyPerBlock);
        pcyPerBlock = _pcyPerBlock;
    }

    function updatePcyID(uint256 _pcyID) public onlyOwner {
        pcyID = _pcyID;
    }

    // Update the pcy referral contract address by the owner
    function setProcyonFarmingReferral(IProcyonFarmingReferral _procyonFarmingReferral) public onlyOwner {
        procyonFarmingReferral = _procyonFarmingReferral;
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate) public onlyOwner {
        require(_referralCommissionRate <= maxReferralCommissionRate, "setReferralCommissionRate: invalid referral commission rate basis points");
        referralCommissionRate = _referralCommissionRate;
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(procyonFarmingReferral) != address(0) && referralCommissionRate > 0) {
            address referrer = procyonFarmingReferral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(1e4);

            if (referrer != address(0) && commissionAmount > 0) {
                pcy.mint(referrer, commissionAmount);
                procyonFarmingReferral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }

    function compound(uint256 _pid, uint256 amount) external {
        _compound(_pid, msg.sender, amount);
    }

    function _compound(
        uint256 _pid,
        address user,
        uint256 amount
    ) internal {
        require(amount == 0, "amount cannot be zero");
        require(_pid < poolInfo.length, "_pid must lower than pool length");

        if (_pid != pcyID) {
            PoolInfo storage _poolInfo = poolInfo[_pid];
            UserInfo storage _userInfo = userInfo[_pid][user];
            updatePool(_pid);

            PoolInfo storage stakingPool = poolInfo[pcyID];
            UserInfo storage stakingUser = userInfo[pcyID][user];
            updatePool(pcyID);

            require(address(stakingPool.lpToken) == address(pcy), "Wrong PCY ID");

            uint256 pending = 0;
            uint256 stakingPending = 0;

            if (_userInfo.amount != 0) {
                pending = ( _userInfo.amount * _poolInfo.accPCYPerShare / 1e12 ) - _userInfo.rewardDebt;
            }

            require(pending == 0, "pending reward cannot be zero");

            if (stakingUser.amount != 0) {
                stakingPending = ( stakingUser.amount * stakingPool.accPCYPerShare / (1e12) ) - stakingUser.rewardDebt;
            }

            require(stakingPending == 0, "stakingPending reward cannot be zero");

            pending = _userInfo.amount.mul(_poolInfo.accPCYPerShare).div(1e12).sub(_userInfo.rewardDebt);
            _userInfo.amount = _userInfo.amount.sub(pending);
            _userInfo.rewardDebt = _userInfo.amount.mul(_poolInfo.accPCYPerShare).div(1e12);

            stakingPending = stakingUser.amount.mul(stakingPool.accPCYPerShare).div(1e12).sub(stakingUser.rewardDebt);
            stakingUser.amount = stakingUser.amount.add(pending).add(stakingPending);
            stakingUser.rewardDebt = stakingUser.amount.mul(stakingPool.accPCYPerShare).div(1e12);
            emit Compounded(user, _pid, amount);

        }
        else
        {
            PoolInfo storage stakingPool = poolInfo[pcyID];
            UserInfo storage stakingUser = userInfo[pcyID][user];
            updatePool(pcyID);

            require(address(stakingPool.lpToken) == address(pcy), "Wrong PCY ID");

            uint256 stakingPending = 0;

            if (stakingUser.amount != 0) {
                stakingPending = ( stakingUser.amount * stakingPool.accPCYPerShare / (1e12) ) - stakingUser.rewardDebt;
            }

            require(stakingPending == 0, "stakingPending reward cannot be zero");

            stakingPending = stakingUser.amount.mul(stakingPool.accPCYPerShare).div(1e12).sub(stakingUser.rewardDebt);
            stakingUser.amount = stakingUser.amount.add(stakingPending);
            stakingUser.rewardDebt = stakingUser.amount.mul(stakingPool.accPCYPerShare).div(1e12);
            emit Compounded(user, _pid, amount);
        }
    }
}