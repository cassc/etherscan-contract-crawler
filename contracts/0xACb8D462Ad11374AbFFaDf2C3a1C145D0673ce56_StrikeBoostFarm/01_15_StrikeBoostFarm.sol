// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IBoostToken.sol";
import "./interfaces/IStrikeBoostFarm.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IVStrike.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/EnumerableSet.sol";
import "./libraries/SafeMath.sol";
import "./libraries/Ownable.sol";
import "./libraries/ReentrancyGuard.sol";

// StrikeFarm is the master of Farm.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once STRIKE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract StrikeBoostFarm is IStrikeBoostFarm, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 pendingAmount; // non-eligible lp amount for reward
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 depositedDate; // Latest deposited date
        //
        // We do some fancy math here. Basically, any point in time, the amount of STRIKEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
        uint256[] boostFactors;
        uint256 boostRewardDebt; // Boost Reward debt. See explanation below.
        uint256 boostedDate; // Latest boosted date
        uint256 accBoostReward;
        uint256 accBaseReward;
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. STRIKEs to distribute per block.
        uint256 lastRewardBlock; // Last block number that STRIKEs distribution occurs.
        uint256 accRewardPerShare; // Accumulated STRIKEs per share, times 1e12. See below.
        uint256 totalBoostCount; // Total valid boosted accounts count.
        uint256 rewardEligibleSupply; // total LP supply of users which staked boost token.
    }
    // The STRIKE TOKEN!
    address public strk;
    // The vSTRIKE TOKEN!
    address public vStrk;
    // The Reward TOKEN!
    address public rewardToken;
    // Block number when bonus STRIKE period ends.
    uint256 public bonusEndBlock;
    // STRIKE tokens created per block.
    uint256 public rewardPerBlock;
    // Bonus muliplier for early STRIKEex makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // VSTRIKE minting rate
    uint256 public constant VSTRK_RATE = 10;
    // Info of each pool.
    PoolInfo[] private poolInfo;
    // Total STRIKE amount deposited in STRIKE single pool. To reduce tx-fee, not included in struct PoolInfo.
    uint256 private lpSupplyOfStrikePool;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // claimable time limit for base reward
    uint256 public claimBaseRewardTime = 1 days;
    uint256 public unstakableTime = 2 days;
    uint256 public initialBoostMultiplier = 20;
    uint256 public boostMultiplierFactor = 10;

    // Boosting Part
    // Minimum vaild boost NFT count
    uint16 public minimumValidBoostCount = 1;
    // Maximum boost NFT count
    uint16 public maximumBoostCount = 20;
    // NFT contract for boosting
    IBoostToken public boostFactor;
    // Boosted with NFT or not
    mapping (uint256 => bool) public isBoosted;
    // claimable time limit for boost reward
    uint256 public claimBoostRewardTime = 30 days;
    // boosted user list
    mapping(uint256 => address[]) private boostedUsers;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when STRIKE mining starts.
    uint256 public startBlock;
    uint256 private accMulFactor = 1e12;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event ClaimBaseRewards(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event ClaimBoostRewards(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event Boost(address indexed user, uint256 indexed pid, uint256 tokenId);
    event UnBoost(address indexed user, uint256 indexed pid, uint256 tokenId);

    constructor(
        address _strk,
        address _rewardToken,
        address _vStrk,
        address _boost,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        strk = _strk;
        rewardToken = _rewardToken;
        vStrk = _vStrk;
        boostFactor = IBoostToken(_boost);
        rewardPerBlock = _rewardPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }


    function getPoolInfo(uint _pid) external view returns (
        IERC20 lpToken,
        uint256 lpSupply,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint accRewardPerShare,
        uint totalBoostCount,
        uint256 rewardEligibleSupply
    ) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 amount;
        if (strk == address(pool.lpToken)) {
            amount = lpSupplyOfStrikePool;
        } else {
            amount = pool.lpToken.balanceOf(address(this));
        }
        return (
            pool.lpToken,
            amount,
            pool.allocPoint,
            pool.lastRewardBlock,
            pool.accRewardPerShare,
            pool.totalBoostCount,
            pool.rewardEligibleSupply
        );
    }

    function getUserInfo(uint256 _pid, address _user) external view returns(
        uint256 amount,
        uint256 pendingAmount,
        uint256 rewardDebt,
        uint256 depositedDate,
        uint256[] memory boostFactors,
        uint256 boostRewardDebt,
        uint256 boostedDate,
        uint256 accBoostReward,
        uint256 accBaseReward
    ) {
        UserInfo storage user = userInfo[_pid][_user];

        return (
            user.amount,
            user.pendingAmount,
            user.rewardDebt,
            user.depositedDate,
            user.boostFactors,
            user.boostRewardDebt,
            user.boostedDate,
            user.accBoostReward,
            user.accBaseReward
        );
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0,
                totalBoostCount: 0,
                rewardEligibleSupply: 0
            })
        );
    }

    // Update the given pool's STRIKE allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Update the given STRIKE per block. Can only be called by the owner.
    function setRewardPerBlock(
        uint256 speed
    ) public onlyOwner {
        rewardPerBlock = speed;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    function getValidBoostFactors(uint256 userBoostFactors) internal view returns (uint256) {
        uint256 validBoostFactors = userBoostFactors > minimumValidBoostCount ? userBoostFactors - minimumValidBoostCount : 0;

        return validBoostFactors;
    }

    function getBoostMultiplier(uint256 boostFactorCount) internal view returns (uint256) {
        if (boostFactorCount <= minimumValidBoostCount) {
            return 0;
        }
        uint256 initBoostCount = boostFactorCount.sub(minimumValidBoostCount + 1);

        return initBoostCount.mul(boostMultiplierFactor).add(initialBoostMultiplier);
    }

    // View function to see pending STRIKEs on frontend.
    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;

        if (block.number > pool.lastRewardBlock && pool.rewardEligibleSupply > 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 reward =
                multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accRewardPerShare = accRewardPerShare.add(
                reward.mul(accMulFactor).div(pool.rewardEligibleSupply)
            );
        }
        uint256 boostMultiplier = getBoostMultiplier(user.boostFactors.length);
        uint256 baseReward = user.amount.mul(accRewardPerShare).div(accMulFactor).sub(user.rewardDebt);
        uint256 boostReward = boostMultiplier.mul(baseReward).div(100).add(user.accBoostReward).sub(user.boostRewardDebt);
        return baseReward.add(boostReward).add(user.accBaseReward);
    }

    // View function to see pending STRIKEs on frontend.
    function pendingBaseReward(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;

        if (block.number > pool.lastRewardBlock && pool.rewardEligibleSupply > 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 reward =
                multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accRewardPerShare = accRewardPerShare.add(
                reward.mul(accMulFactor).div(pool.rewardEligibleSupply)
            );
        }

        uint256 newReward = user.amount.mul(accRewardPerShare).div(accMulFactor).sub(user.rewardDebt);
        return newReward.add(user.accBaseReward);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (pool.rewardEligibleSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 reward =
            multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        pool.accRewardPerShare = pool.accRewardPerShare.add(
            reward.mul(accMulFactor).div(pool.rewardEligibleSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Check the eligible user or not for reward
    function checkRewardEligible(uint boost) internal view returns(bool) {
        if (boost >= minimumValidBoostCount) {
            return true;
        }

        return false;
    }

    // Check claim eligible
    function checkRewardClaimEligible(uint depositedTime) internal view returns(bool) {
        if (block.timestamp - depositedTime > claimBaseRewardTime) {
            return true;
        }

        return false;
    }

    // Claim base lp reward
    function _claimBaseRewards(uint256 _pid, address _user) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        bool claimEligible = checkRewardClaimEligible(user.depositedDate);

        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 boostMultiplier = getBoostMultiplier(user.boostFactors.length);

        uint256 baseReward = user.amount.mul(accRewardPerShare).div(accMulFactor).sub(user.rewardDebt);
        uint256 boostReward = boostMultiplier.mul(baseReward).div(100);
        user.accBoostReward = user.accBoostReward.add(boostReward);
        uint256 rewards;

        if (claimEligible && baseReward > 0) {
            rewards = baseReward.add(user.accBaseReward);
            safeRewardTransfer(_user, rewards);
            user.accBaseReward = 0;
        } else {
            rewards = 0;
            user.accBaseReward = baseReward.add(user.accBaseReward);
        }

        emit ClaimBaseRewards(_user, _pid, rewards);

        user.depositedDate = block.timestamp;
    }

    function claimBaseRewards(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        bool claimEligible = checkRewardClaimEligible(user.depositedDate);
        require(claimEligible == true, "not claim eligible");
        updatePool(_pid);
        _claimBaseRewards(_pid, msg.sender);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
    }

    // Deposit LP tokens to STRIKEswap for STRIKE allocation.
    function deposit(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        bool rewardEligible = checkRewardEligible(user.boostFactors.length);

        _claimBaseRewards(_pid, msg.sender);

        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        if (strk == address(pool.lpToken)) {
            lpSupplyOfStrikePool = lpSupplyOfStrikePool.add(_amount);
        }
        if (rewardEligible) {
            user.amount = user.amount.add(user.pendingAmount).add(_amount);
            pool.rewardEligibleSupply = pool.rewardEligibleSupply.add(_amount);
            user.pendingAmount = 0;
        } else {
            user.pendingAmount = user.pendingAmount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
        if (_amount > 0) {
            IVStrike(vStrk).mint(msg.sender, _amount.mul(VSTRK_RATE));
        }
        user.boostedDate = block.timestamp;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from STRIKEexFarm.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount + user.pendingAmount >= _amount, "withdraw: not good");
        require(block.timestamp - user.depositedDate > unstakableTime, "not eligible to withdraw");
        updatePool(_pid);
        _claimBaseRewards(_pid, msg.sender);
        if (user.amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.rewardEligibleSupply = pool.rewardEligibleSupply.sub(_amount);
        } else {
            user.pendingAmount = user.pendingAmount.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
        // will loose unclaimed boost reward
        user.accBoostReward = 0;
        user.boostRewardDebt = 0;
        user.boostedDate = block.timestamp;
        if (strk == address(pool.lpToken)) {
            lpSupplyOfStrikePool = lpSupplyOfStrikePool.sub(_amount);
        }
        if (_amount > 0) {
            IVStrike(vStrk).burnFrom(msg.sender, _amount.mul(VSTRK_RATE));
        }
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // transfer VSTRIKE
    function move(uint256 _pid, address _sender, address _recipient, uint256 _vstrikeAmount) override external nonReentrant {
        require(vStrk == msg.sender);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage sender = userInfo[_pid][_sender];
        UserInfo storage recipient = userInfo[_pid][_recipient];

        uint256 amount = _vstrikeAmount.div(VSTRK_RATE);

        require(sender.amount + sender.pendingAmount >= amount, "transfer exceeds amount");
        require(block.timestamp - sender.depositedDate > unstakableTime, "not eligible to undtake");
        updatePool(_pid);
        _claimBaseRewards(_pid, _sender);

        if (sender.amount > 0) {
            sender.amount = sender.amount.sub(amount);
        } else {
            sender.pendingAmount = sender.pendingAmount.sub(amount);
        }
        sender.rewardDebt = sender.amount.mul(pool.accRewardPerShare).div(accMulFactor);
        sender.boostedDate = block.timestamp;
        // will loose unclaimed boost reward
        sender.accBoostReward = 0;
        sender.boostRewardDebt = 0;

        bool claimEligible = checkRewardClaimEligible(recipient.depositedDate);
        bool rewardEligible = checkRewardEligible(recipient.boostFactors.length);

        if (claimEligible && rewardEligible) {
            _claimBaseRewards(_pid, _recipient);
        }

        if (rewardEligible) {
            recipient.amount = recipient.amount.add(recipient.pendingAmount).add(amount);
            recipient.pendingAmount = 0;
        } else {
            recipient.pendingAmount = recipient.pendingAmount.add(amount);
        }
        recipient.rewardDebt = recipient.amount.mul(pool.accRewardPerShare).div(accMulFactor);
        recipient.boostedDate = block.timestamp;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount.add(user.pendingAmount));
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        if (user.amount > 0) {
            pool.rewardEligibleSupply = pool.rewardEligibleSupply.sub(user.amount);
        }
        user.amount = 0;
        user.pendingAmount = 0;
        user.rewardDebt = 0;
        user.boostRewardDebt = 0;
        user.accBoostReward = 0;
    }

    // Safe rewardToken transfer function, just in case if rounding error causes pool to not have enough STRIKEs.
    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 availableBal = IERC20(rewardToken).balanceOf(address(this));

        // Protect users liquidity
        if (strk == rewardToken) {
            if (availableBal > lpSupplyOfStrikePool) {
                availableBal = availableBal - lpSupplyOfStrikePool;
            } else {
                availableBal = 0;
            }
        }

        if (_amount > availableBal) {
            IERC20(rewardToken).transfer(_to, availableBal);
        } else {
            IERC20(rewardToken).transfer(_to, _amount);
        }
    }

    function setAccMulFactor(uint256 _factor) external onlyOwner {
        accMulFactor = _factor;
    }

    function updateInitialBoostMultiplier(uint _initialBoostMultiplier) external onlyOwner {
        initialBoostMultiplier = _initialBoostMultiplier;
    }

    function updatedBoostMultiplierFactor(uint _boostMultiplierFactor) external onlyOwner {
        boostMultiplierFactor = _boostMultiplierFactor;
    }

    // Update reward token address by owner.
    function updateRewardToken(address _reward) external onlyOwner {
        rewardToken = _reward;
    }

    // Update claimBaseRewardTime
    function updateClaimBaseRewardTime(uint256 _claimBaseRewardTime) external onlyOwner {
        claimBaseRewardTime = _claimBaseRewardTime;
    }

    // Update unstakableTime
    function updateUnstakableTime(uint256 _unstakableTime) external onlyOwner {
        unstakableTime = _unstakableTime;
    }

    // NFT Boosting
    // get boosted users
    function getBoostedUserCount(uint256 _pid) external view returns(uint256) {
        return boostedUsers[_pid].length;
    }

    // View function to see pending STRIKEs on frontend.
    function pendingBoostReward(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;

        if (block.number > pool.lastRewardBlock && pool.rewardEligibleSupply > 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 reward =
                multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accRewardPerShare = accRewardPerShare.add(
                reward.mul(accMulFactor).div(pool.rewardEligibleSupply)
            );
        }

        uint256 boostMultiplier = getBoostMultiplier(user.boostFactors.length);
        uint256 baseReward = user.amount.mul(accRewardPerShare).div(accMulFactor).sub(user.rewardDebt);
        uint256 boostReward = boostMultiplier.mul(baseReward).div(100);
        return user.accBoostReward.sub(user.boostRewardDebt).add(boostReward);
    }

    // for deposit reward token to contract
    function getTotalPendingBoostRewards() external view returns (uint256) {
        uint256 totalRewards;
        for (uint i; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            uint256 accRewardPerShare = pool.accRewardPerShare;

            for (uint j; j < boostedUsers[i].length; j++) {
                UserInfo storage user = userInfo[i][boostedUsers[i][j]];

                if (block.number > pool.lastRewardBlock && pool.rewardEligibleSupply > 0) {
                    uint256 multiplier =
                        getMultiplier(pool.lastRewardBlock, block.number);
                    uint256 reward =
                        multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(
                            totalAllocPoint
                        );
                    accRewardPerShare = accRewardPerShare.add(
                        reward.mul(accMulFactor).div(pool.rewardEligibleSupply)
                    );
                }
                uint256 boostMultiplier = getBoostMultiplier(user.boostFactors.length);
                uint256 baseReward = user.amount.mul(accRewardPerShare).div(accMulFactor).sub(user.rewardDebt);
                uint256 initBoostReward = boostMultiplier.mul(baseReward).div(100);
                uint256 boostReward = user.accBoostReward.sub(user.boostRewardDebt).add(initBoostReward);
                totalRewards = totalRewards.add(boostReward);
            }
        }

        return totalRewards;
    }

    // for deposit reward token to contract
    function getClaimablePendingBoostRewards() external view returns (uint256) {
        uint256 totalRewards;
        for (uint i; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            uint256 accRewardPerShare = pool.accRewardPerShare;

            for (uint j; j < boostedUsers[i].length; j++) {
                UserInfo storage user = userInfo[i][boostedUsers[i][j]];

                if (block.timestamp - user.boostedDate >= claimBoostRewardTime) {
                    if (block.number > pool.lastRewardBlock && pool.rewardEligibleSupply > 0) {
                        uint256 multiplier =
                            getMultiplier(pool.lastRewardBlock, block.number);
                        uint256 reward =
                            multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(
                                totalAllocPoint
                            );
                        accRewardPerShare = accRewardPerShare.add(
                            reward.mul(accMulFactor).div(pool.rewardEligibleSupply)
                        );
                    }
                    uint256 boostMultiplier = getBoostMultiplier(user.boostFactors.length);
                    uint256 baseReward = user.amount.mul(accRewardPerShare).div(accMulFactor).sub(user.rewardDebt);
                    uint256 initBoostReward = boostMultiplier.mul(baseReward).div(100);
                    uint256 boostReward = user.accBoostReward.sub(user.boostRewardDebt).add(initBoostReward);
                    totalRewards = totalRewards.add(boostReward);
                }
            }
        }

        return totalRewards;
    }

    // Claim boost reward
    function claimBoostReward(uint256 _pid) external {
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(block.timestamp - user.boostedDate > claimBoostRewardTime, "not eligible to claim");
        PoolInfo storage pool = poolInfo[_pid];
        updatePool(_pid);
        _claimBaseRewards(_pid, msg.sender);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
        uint256 boostReward = user.accBoostReward.sub(user.boostRewardDebt);
        safeRewardTransfer(msg.sender, boostReward);
        emit ClaimBoostRewards(msg.sender, _pid, boostReward);
        user.boostRewardDebt = user.boostRewardDebt.add(boostReward);
        user.boostedDate = block.timestamp;
    }

    function _boost(uint256 _pid, uint _tokenId) internal {
        require (isBoosted[_tokenId] == false, "already boosted");

        boostFactor.transferFrom(msg.sender, address(this), _tokenId);
        // boostFactor.updateStakeTime(_tokenId, true);

        isBoosted[_tokenId] = true;

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.pendingAmount > 0) {
            user.amount = user.pendingAmount;
            pool.rewardEligibleSupply = pool.rewardEligibleSupply.add(user.amount);
            user.pendingAmount = 0;
        }
        user.boostFactors.push(_tokenId);
        pool.totalBoostCount = pool.totalBoostCount + 1;

        emit Boost(msg.sender, _pid, _tokenId);
    }

    function boost(uint256 _pid, uint _tokenId) external {
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount + user.pendingAmount > 0, "no stake tokens");
        require(user.boostFactors.length + 1 <= maximumBoostCount);
        PoolInfo storage pool = poolInfo[_pid];
        if (user.boostFactors.length == 0) {
            boostedUsers[_pid].push(msg.sender);
        }
        updatePool(_pid);
        _claimBaseRewards(_pid, msg.sender);

        _boost(_pid, _tokenId);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
        user.boostedDate = block.timestamp;
    }

    function boostPartially(uint _pid, uint tokenAmount) external {
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount + user.pendingAmount > 0, "no stake tokens");
        require(user.boostFactors.length + tokenAmount <= maximumBoostCount);
        PoolInfo storage pool = poolInfo[_pid];
        if (user.boostFactors.length == 0) {
            boostedUsers[_pid].push(msg.sender);
        }
        uint256 ownerTokenCount = boostFactor.balanceOf(msg.sender);
        require(tokenAmount <= ownerTokenCount);
        updatePool(_pid);
        _claimBaseRewards(_pid, msg.sender);

        for (uint i; i < tokenAmount; i++) {
            uint _tokenId = boostFactor.tokenOfOwnerByIndex(msg.sender, 0);

            _boost(_pid, _tokenId);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
        user.boostedDate = block.timestamp;
    }

    function boostAll(uint _pid, uint256[] memory _tokenIds) external {
        uint256 tokenIdLength = _tokenIds.length;
        require(tokenIdLength > 0, "");
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount + user.pendingAmount > 0, "no stake tokens");
        uint256 ownerTokenCount = boostFactor.balanceOf(msg.sender);
        require(ownerTokenCount > 0, "");
        PoolInfo storage pool = poolInfo[_pid];
        if (user.boostFactors.length == 0) {
            boostedUsers[_pid].push(msg.sender);
        }
        uint256 availableTokenAmount = maximumBoostCount - user.boostFactors.length;
        require(availableTokenAmount > 0, "overflow maximum boosting");

        if (tokenIdLength < availableTokenAmount) {
            availableTokenAmount = tokenIdLength;
        }
        updatePool(_pid);
        _claimBaseRewards(_pid, msg.sender);

        for (uint256 i; i < availableTokenAmount; i++) {
            _boost(_pid, _tokenIds[i]);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
        user.boostedDate = block.timestamp;
    }

    function _unBoost(uint _pid, uint _tokenId) internal {
        require (isBoosted[_tokenId] == true);

        boostFactor.transferFrom(address(this), msg.sender, _tokenId);
        // boostFactor.updateStakeTime(_tokenId, false);

        isBoosted[_tokenId] = false;

        emit UnBoost(msg.sender, _pid, _tokenId);
    }

    function unBoost(uint _pid, uint _tokenId) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.boostFactors.length > 0, "");
        uint factorLength = user.boostFactors.length;

        updatePool(_pid);
        _claimBaseRewards(_pid, msg.sender);

        bool found = false;
        uint dfId; // will be deleted factor index
        for (uint j; j < factorLength; j++) {
            if (_tokenId == user.boostFactors[j]) {
                dfId = j;
                found = true;
                break;
            }
        }
        require(found, "not found boosted tokenId");
        _unBoost(_pid, _tokenId);
        user.boostFactors[dfId] = user.boostFactors[factorLength - 1];
        user.boostFactors.pop();
        pool.totalBoostCount = pool.totalBoostCount - 1;

        user.boostedDate = block.timestamp;
        // will loose unclaimed boost reward
        user.accBoostReward = 0;
        user.boostRewardDebt = 0;

        uint boostedUserCount = boostedUsers[_pid].length;
        if (user.boostFactors.length == 0) {
            user.pendingAmount = user.amount;
            user.amount = 0;
            pool.rewardEligibleSupply = pool.rewardEligibleSupply.sub(user.pendingAmount);

            uint index;
            for (uint j; j < boostedUserCount; j++) {
                if (address(msg.sender) == address(boostedUsers[_pid][j])) {
                    index = j;
                    break;
                }
            }
            boostedUsers[_pid][index] = boostedUsers[_pid][boostedUserCount - 1];
            boostedUsers[_pid].pop();
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
    }

    function unBoostPartially(uint _pid, uint tokenAmount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.boostFactors.length > 0, "");
        require(tokenAmount <= user.boostFactors.length, "");
        uint factorLength = user.boostFactors.length;

        updatePool(_pid);
        _claimBaseRewards(_pid, msg.sender);

        for (uint i = 1; i <= tokenAmount; i++) {
            uint index = factorLength - i;
            uint _tokenId = user.boostFactors[index];

            _unBoost(_pid, _tokenId);
            user.boostFactors.pop();
            pool.totalBoostCount = pool.totalBoostCount - 1;
        }
        user.boostedDate = block.timestamp;
        // will loose unclaimed boost reward
        user.accBoostReward = 0;
        user.boostRewardDebt = 0;

        uint boostedUserCount = boostedUsers[_pid].length;
        if (user.boostFactors.length == 0) {
            user.pendingAmount = user.amount;
            user.amount = 0;
            pool.rewardEligibleSupply = pool.rewardEligibleSupply.sub(user.pendingAmount);

            uint index;
            for (uint j; j < boostedUserCount; j++) {
                if (address(msg.sender) == address(boostedUsers[_pid][j])) {
                    index = j;
                    break;
                }
            }
            boostedUsers[_pid][index] = boostedUsers[_pid][boostedUserCount - 1];
            boostedUsers[_pid].pop();
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
    }

    function unBoostAll(uint _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint factorLength = user.boostFactors.length;
        require(factorLength > 0, "");

        updatePool(_pid);
        _claimBaseRewards(_pid, msg.sender);

        for (uint i = 0; i < factorLength; i++) {
            uint _tokenId = user.boostFactors[i];
            _unBoost(_pid, _tokenId);
        }
        delete user.boostFactors;
        pool.totalBoostCount = pool.totalBoostCount - factorLength;
        user.boostedDate = block.timestamp;

        // will loose unclaimed boost reward
        user.accBoostReward = 0;
        user.boostRewardDebt = 0;

        uint boostedUserCount = boostedUsers[_pid].length;
        if (user.boostFactors.length == 0) {
            user.pendingAmount = user.amount;
            user.amount = 0;
            pool.rewardEligibleSupply = pool.rewardEligibleSupply.sub(user.pendingAmount);

            uint index;
            for (uint j; j < boostedUserCount; j++) {
                if (address(msg.sender) == address(boostedUsers[_pid][j])) {
                    index = j;
                    break;
                }
            }
            boostedUsers[_pid][index] = boostedUsers[_pid][boostedUserCount - 1];
            boostedUsers[_pid].pop();
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
    }

    // Update boostFactor address. Can only be called by the owner.
    function setBoostFactor(
        address _address
    ) external onlyOwner {
        boostFactor = IBoostToken(_address);
    }

    // Update claimBoostRewardTime
    function updateClaimBoostRewardTime(uint256 _claimBoostRewardTime) external onlyOwner {
        claimBoostRewardTime = _claimBoostRewardTime;
    }

    // Update minimum valid boost token count. Can only be called by the owner.
    function updateMinimumValidBoostCount(uint16 _count) external onlyOwner {
        minimumValidBoostCount = _count;
    }

    // Update maximum valid boost token count. Can only be called by the owner.
    function updateMaximumBoostCount(uint16 _count) external onlyOwner {
        maximumBoostCount = _count;
    }
}