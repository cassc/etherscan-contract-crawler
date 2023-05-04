// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IReferral.sol";
import "./MasterchefVault.sol";

// MasterChef is the master of Token. He can make Token and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once TOKEN is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChefV2 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    bool public referrer_is_allowed = true;

    uint public constant PERCENT_DIVIDER = 10000; //100% 
    uint public constant MAX_FEE = 2000; //20%
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardLockedUp; // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        uint unlockDate; //the date in which individuals are allowed to withdraw after investing.
        //
        // We do some fancy math here. Basically, any point in time, the amount of TOKEN
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accTokenPerShare` (and `lastRewardDate`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 tokensPerSecond; // TOKEN tokens created per block.
        uint256 lastRewardDate; // Last block number that TOKEN distribution occurs.
        uint256 accTokenPerShare; // Accumulated TOKEN per share, times 1e12. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
        uint256 harvestInterval; // Harvest interval in seconds
        uint256 seconsForUnlock; //the seconds in which individuals are allowed to invest after creating the pool.
        uint256 initDAte;
    }

    // The TOKEN TOKEN!
    IERC20 public tokenMaster;
    // // The choco TOKEN!
    // IERC20 public chocoToken;

    MasterchefVault public vault;

    // Deposit Fee owner address
    address public investorsAddress;

    // Bonus muliplier for early tokenMaster makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Max harvest interval: 14 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // The block number when TOKEN mining starts.
    uint256 public startDate;
    // Total locked up rewards
    uint256 public totalLockedUpRewards;

    uint totalEmmisionRatePerSecond;

    // Token referral contract address.
    IReferralHandler public ReferralHandler;
    uint public constant REFERRAL_LEVELS = 1;
    // Referral commission rate in basis points.
    uint256[REFERRAL_LEVELS] public REFERRAL_PERCENTS = [100];
    uint256 public referralCommissionRate = 200; //100+50+50 = 2%
    // Max referral commission rate: 10%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 1000; //10%

    mapping(uint => bool) public blockPool;
    mapping(address => uint) public lastBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event ReferralCommissionPaid(
        address indexed user,
        address indexed referrer,
        uint256 indexed level,
        uint256 commissionAmount
    );
    event RewardLockedUp(
        address indexed user,
        uint256 indexed pid,
        uint256 amountLockedUp
    );

    modifier tenBlocks() {
        require(block.number.sub(lastBlock[msg.sender]) > 10, "wait 10 blocks");
        _;
        lastBlock[msg.sender] = block.number;
    }

    modifier isNotContract() {
        require(!isContract(msg.sender), "contract not allowed");
        _;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    constructor(
        address _tokenMaster,
        address _referral,
        address _vault,
        address _investorsAddress
    ) {
        tokenMaster = IERC20(_tokenMaster);
        ReferralHandler = IReferralHandler(_referral);
        vault = MasterchefVault(_vault);
        startDate = block.timestamp;

        investorsAddress = _investorsAddress;
    }

    function setReferrerIsAllowed(
        bool _referrer_is_allowed
    ) external onlyOwner {
        referrer_is_allowed = _referrer_is_allowed;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _tokensPerSecond,
        IERC20 _lpToken,
        uint16 _depositFeeBP,
        uint256 _harvestInterval,
        uint256 _unlockDate,
        bool _withUpdate
    ) external onlyOwner {
        require(
            _depositFeeBP <= MAX_FEE,
            "add: invalid deposit fee basis points"
        );
        require(
            _harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
            "add: invalid harvest interval"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardDate = block.timestamp > startDate
            ? block.timestamp
            : startDate;
        totalEmmisionRatePerSecond = totalEmmisionRatePerSecond.add(
            _tokensPerSecond
        );
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                tokensPerSecond: _tokensPerSecond,
                lastRewardDate: lastRewardDate,
                accTokenPerShare: 0,
                depositFeeBP: _depositFeeBP,
                harvestInterval: _harvestInterval,
                seconsForUnlock: _unlockDate,
                initDAte: block.timestamp
            })
        );
    }

    // Update the given pool's TOKEN allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _tokensPerSecond,
        uint16 _depositFeeBP,
        uint256 _harvestInterval,
        uint256 _unlockDate,
        bool _withUpdate
    ) external onlyOwner {
        //Evan recuerda modificar esto
        require(
            _depositFeeBP <= MAX_FEE,
            "set: invalid deposit fee basis points"
        );
        require(
            _harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
            "set: invalid harvest interval"
        );
        if (_withUpdate) {
            massUpdatePools();
        }

        PoolInfo memory pool = poolInfo[_pid];
        totalEmmisionRatePerSecond = totalEmmisionRatePerSecond
            .sub(pool.tokensPerSecond)
            .add(_tokensPerSecond);
        pool.tokensPerSecond = _tokensPerSecond;
        pool.depositFeeBP = _depositFeeBP;
        pool.harvestInterval = _harvestInterval;

        pool.seconsForUnlock = _unlockDate;
        pool.initDAte = block.timestamp;

        poolInfo[_pid] = pool;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending TOKEN on frontend.
    function pendingToken(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = vault.getTokenBalance(pool.lpToken);
        if (block.timestamp > pool.lastRewardDate && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardDate,
                block.timestamp
            );
            uint256 tokenReward = multiplier.mul(pool.tokensPerSecond);
            accTokenPerShare = accTokenPerShare.add(
                tokenReward.mul(1e12).div(lpSupply)
            );
        }
        uint256 pending = user.amount.mul(accTokenPerShare).div(1e12).sub(
            user.rewardDebt
        );
        return pending.add(user.rewardLockedUp);
    }

    // View function to see if user can harvest TOKEN.
    function canHarvest(
        uint256 _pid,
        address _user
    ) public view returns (bool) {
        UserInfo memory user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardDate) {
            return;
        }
        uint256 lpSupply = vault.getTokenBalance(pool.lpToken);
        if (lpSupply == 0 || pool.tokensPerSecond == 0) {
            pool.lastRewardDate = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(
            pool.lastRewardDate,
            block.timestamp
        );
        uint256 tokenReward = multiplier.mul(pool.tokensPerSecond);
        // safeTokenTransfer(owner(), tokenReward.div(10));
        pool.accTokenPerShare = pool.accTokenPerShare.add(
            tokenReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardDate = block.timestamp;
    }

    // Deposit LP tokens to MasterChef for TOKEN allocation.
    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _referrer
    ) public nonReentrant tenBlocks isNotContract {
        require(poolIsActive(_pid), "pool is not active");
        require(canDepost(_pid), "pool temporarily blocked");
        require(_amount > 0, "amount must be greater than 0");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (
            address(ReferralHandler) != address(0) &&
            _referrer != address(0) &&
            _referrer != msg.sender
        ) {
            ReferralHandler.recordReferral(msg.sender, _referrer);
        }
        payOrLockupPendingToken(_pid);

        uint previousBalance = vault.getTokenBalance(pool.lpToken);
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(vault),
            _amount
        );
        uint newBalance = vault.getTokenBalance(pool.lpToken);
        _amount = newBalance.sub(previousBalance);
        require(_amount > 0, "_amount must be greater than 0");

        if (pool.depositFeeBP > 0) {
            uint256 depositFee = _amount.mul(pool.depositFeeBP).div(
                PERCENT_DIVIDER
            );
            payFees(pool.lpToken, depositFee);
            user.amount = user.amount.add(_amount).sub(depositFee);
        } else {
            user.amount = user.amount.add(_amount);
        }

        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        user.unlockDate = block.timestamp.add(pool.seconsForUnlock);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(
        uint256 _pid,
        uint256 _amount
    ) public nonReentrant tenBlocks isNotContract {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        require(blockPool[_pid] == false, "withdraw: pool is blocked");
        updatePool(_pid);
        payOrLockupPendingToken(_pid);
        if (_amount > 0) {
            require(
                block.timestamp >= user.unlockDate,
                "withdraw: tokens are locked"
            );
            user.amount = user.amount.sub(_amount);
            vault.safeTransfer(pool.lpToken, msg.sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(
        uint256 _pid
    ) public nonReentrant tenBlocks isNotContract {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        delete user.amount;
        delete user.rewardDebt;
        delete user.rewardLockedUp;
        delete user.nextHarvestUntil;
        delete user.unlockDate;
        vault.safeTransfer(pool.lpToken, msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay or lockup pending TOKEN.
    function payOrLockupPendingToken(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }

        uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(
                    user.rewardLockedUp
                );
                delete user.rewardLockedUp;
                user.nextHarvestUntil = block.timestamp.add(
                    pool.harvestInterval
                );

                // send rewards
                safeTokenTransfer(msg.sender, totalRewards);
                // payReferralCommission(msg.sender, totalRewards);
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(
        uint256[REFERRAL_LEVELS] memory _referralCommissionRates
    ) external onlyOwner {
        uint totalReferralPercent;
        for (uint256 i; i < REFERRAL_PERCENTS.length; i++) {
            totalReferralPercent += _referralCommissionRates[i];
        }
        referralCommissionRate = totalReferralPercent;
        require(
            referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE,
            "setReferralCommissionRate: invalid referral commission rate basis points"
        );
        REFERRAL_PERCENTS = _referralCommissionRates;
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (
            referrer_is_allowed &&
            address(ReferralHandler) != address(0) &&
            referralCommissionRate > 0
        ) {
            address upline = ReferralHandler.getReferrer(_user);
            for (uint256 i; i < REFERRAL_PERCENTS.length; i++) {
                if (upline != address(0)) {
                    uint256 amount = _pending.mul(REFERRAL_PERCENTS[i]).div(
                        PERCENT_DIVIDER
                    );
                    if (amount > 0) {
                        safeTokenTransfer(upline, amount);
                        ReferralHandler.recordReferralCommission(
                            upline,
                            amount
                        );
                        emit ReferralCommissionPaid(_user, upline, i, amount);
                        upline = ReferralHandler.getReferrer(upline);
                    }
                } else break;
            }
        }
    }

    function canDepost(uint256 _pid) public view returns (bool) {
        PoolInfo memory pool = poolInfo[_pid];

        if (block.timestamp < pool.initDAte) {
            return false;
        }

        if (blockPool[_pid] == true) {
            return false;
        }

        return true;
    }

    function poolIsActive(uint256 _pid) public view returns (bool) {
        PoolInfo memory pool = poolInfo[_pid];
        return pool.tokensPerSecond > 0;
    }

    function payFees(IERC20 fromToken, uint feeAmt) private {
        vault.safeTransfer(fromToken, investorsAddress, feeAmt);
    }

    function returnPoolPerSecond(uint256 _pid) external view returns (uint) {
        PoolInfo memory pool = poolInfo[_pid];
        uint256 multiplier = getMultiplier(0, 1);
        uint256 tokenReward = multiplier.mul(pool.tokensPerSecond);
        return tokenReward;
    }

    function returnUserPerSecond(
        uint256 _pid,
        address _user
    ) external view returns (uint) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accTokenPerShare;
        uint256 lpSupply = vault.getTokenBalance(pool.lpToken);
        if (block.timestamp > pool.lastRewardDate && lpSupply != 0) {
            uint256 multiplier = getMultiplier(0, 1);
            uint256 tokenReward = multiplier.mul(pool.tokensPerSecond);
            accTokenPerShare = tokenReward.mul(1e12).div(lpSupply);
        }
        uint256 pending = user.amount.mul(accTokenPerShare).div(1e12);
        return pending;
    }

    function returnDepositPerSecond(
        uint256 _pid,
        uint amount
    ) external view returns (uint) {
        PoolInfo memory pool = poolInfo[_pid];
        uint256 accTokenPerShare;
        uint256 lpSupply = vault.getTokenBalance(pool.lpToken);
        if (block.timestamp > pool.lastRewardDate && lpSupply != 0) {
            uint256 multiplier = getMultiplier(0, 1);
            uint256 tokenReward = multiplier.mul(pool.tokensPerSecond);
            accTokenPerShare = tokenReward.mul(1e12).div(lpSupply.add(amount));
        }
        uint256 pending = amount.mul(accTokenPerShare).div(1e12);
        return pending;
    }

    function getDAte() external view returns (uint) {
        return block.timestamp;
    }

    function getTokenAddressBalance(
        address _token
    ) external view returns (uint256) {
        return vault.getTokenAddressBalance(_token);
    }

    function getVAultBalance() external view returns (uint256) {
        return vault.getBalance();
    }

    // Safe tokenMaster transfer function, just in case if rounding error causes pool to not have enough TOKEN.
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = tokenMaster.balanceOf(address(this));
        if (_amount > tokenBal) {
            tokenMaster.transfer(_to, tokenBal);
        } else {
            tokenMaster.transfer(_to, _amount);
        }
    }

    // function takeTokens(address _token, uint _bal) external onlyOwner {
    //     IERC20(_token).transfer(msg.sender, _bal);
    // }

    function SetBlockPool(uint256 _pid, bool _blockPool) external onlyOwner {
        blockPool[_pid] = _blockPool;
    }
}