// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC721.sol";
import "SafeERC20.sol";
import "SafeMath.sol";
import "ReentrancyGuard.sol";
import "AccessControl.sol";

contract BoardroomContractEF is ReentrancyGuard, AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // governance
    bool public isInitialized;

    // Info of each user.
    struct UserInfo {
        bool status; //walletStatus
        // uint256 lastClaimedEpoch;
        uint256 totalAmount; // How many  tokens the user has provided.
        uint256 accruedCoin; // Interest accrued till date.
        uint256 claimedCoin; // Interest claimed till date
        uint256 lastAccrued; // Last date when the interest was claimed
        uint256 lastAccruedBlock; //Last block user intracted
        uint256 lastClaimedBlock;
    }

    // Info of each pool
    struct PoolInfo {
        bool isStarted; // if lastRewardTime has passed
        uint256 maximumStakingAllowed;
        uint256 epoch_length;
        uint256 minimum_lockup_blocks;
        uint256 total_staked;
        address stakeToken;
        address rewardToken;
        address nft_token;
        uint256 poolStartTime;
        uint256 poolEndTime;
        uint256 rewardsBalance;
        address treasury;
    }

    //snapshot struct`
    struct Snapshot {
        uint256 blockNumber;
        uint256 nextReward;
        uint256 totalMinerStaked;
    }

    // Info of each pool
    PoolInfo[] public poolInfo;

    mapping(uint256 => Snapshot[]) public snapshots;
    mapping(uint256 => uint256) public next_reward;
    mapping(uint256 => uint256) public lastRun;

    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant TRANSFER_OUT_ROLE =
        keccak256("TRANSFER_OUT_OPERATOR_ROLE");

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event RewardPaid(address indexed user, uint256 amount);

    function initialize() external {
        require(!isInitialized, "Already Initialized");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setupRole(TRANSFER_OUT_ROLE, msg.sender);
        isInitialized = true;
    }

    function checkRole(address account, bytes32 role) public view {
        require(hasRole(role, account), "Role Does Not Exist");
    }

    function giveRole(address wallet, uint256 _roleId) public {
        require(_roleId >= 0 && _roleId < 2, "Invalid roleId");
        checkRole(msg.sender, DEFAULT_ADMIN_ROLE);
        bytes32 _role;
        if (_roleId == 0) {
            _role = OPERATOR_ROLE;
        } else if (_roleId == 1) {
            _role = TRANSFER_OUT_ROLE;
        }
        grantRole(_role, wallet);
    }

    function revokeRole(address wallet, uint256 _roleId) public {
        require(_roleId >= 0 && _roleId < 2, "Invalid roleId");
        checkRole(msg.sender, DEFAULT_ADMIN_ROLE);
        bytes32 _role;
        if (_roleId == 0) {
            _role = OPERATOR_ROLE;
        } else if (_roleId == 1) {
            _role = TRANSFER_OUT_ROLE;
        }
        revokeRole(_role, wallet);
    }

    function renounceOwnership() public {
        checkRole(msg.sender, DEFAULT_ADMIN_ROLE);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new farm to the pool. Can only be called by the owner.
    function add(
        uint256 _pid,
        uint256 _maximumStakingAllowed,
        uint256 _epoch_length,
        uint256 _minimum_lockup_blocks,
        address _stakeToken,
        address _rewardToken,
        address _nft_token,
        uint256 _poolStartTime,
        uint256 _poolEndTime,
        address _treasury
    ) public {
        checkRole(msg.sender, OPERATOR_ROLE);

        // checkPoolDuplicate(_stakeToken);
        poolInfo.push(
            PoolInfo({
                isStarted: false,
                maximumStakingAllowed: _maximumStakingAllowed,
                minimum_lockup_blocks: _minimum_lockup_blocks,
                epoch_length: _epoch_length,
                total_staked: 0,
                stakeToken: _stakeToken,
                rewardToken: _rewardToken,
                nft_token: _nft_token,
                poolStartTime: _poolStartTime,
                poolEndTime: _poolEndTime,
                rewardsBalance: 0,
                treasury: _treasury
            })
        );
        lastRun[_pid] = block.number;
    }

    function setTokens(
        uint256 _pid,
        address _miner,
        address _e_usd,
        address _nft_token
    ) public {
        checkRole(msg.sender, OPERATOR_ROLE);
        PoolInfo storage _poolInfo = poolInfo[_pid];
        _poolInfo.stakeToken = _miner;
        _poolInfo.rewardToken = _e_usd;
        _poolInfo.nft_token = _nft_token;
    }

    // Enable or disable Wallet
    function setWalletStatus(
        uint256 _pid,
        address _user,
        bool _setStatus
    ) public {
        checkRole(msg.sender, OPERATOR_ROLE);
        UserInfo storage user = userInfo[_pid][_user];
        user.status = _setStatus;
    }

    // Public function to be called both internally and externally
    function allocateSeigniorage(uint256 _pid) public {
        if (block.number >= lastRun[_pid] + poolInfo[_pid].epoch_length) {
            // Calculate the number of times allocateSeigniorageHelper should be called
            uint256 numRuns = ((block.number).sub(lastRun[_pid])).div(
                poolInfo[_pid].epoch_length
            );
            for (uint256 i = 1; i <= numRuns; i++) {
                // Call allocateSeigniorageHelper with the block number for each run
                allocateSeigniorageHelper(
                    _pid,
                    lastRun[_pid] + (poolInfo[_pid].epoch_length * i)
                );
            }
            lastRun[_pid] += numRuns.mul(poolInfo[_pid].epoch_length);
            // Update lastRun to current block number
        }
    }

    // Internal function to take a snapshot
    function allocateSeigniorageHelper(uint256 _pid, uint256 blockNumber)
        internal
    {
        // Create a new snapshot and store it in the array
        snapshots[_pid].push(
            Snapshot({
                blockNumber: blockNumber,
                nextReward: next_reward[_pid],
                totalMinerStaked: poolInfo[_pid].total_staked
            })
        );
    }

    function setNextReward(uint256 _pid, uint256 _amount) public {
        checkRole(msg.sender, OPERATOR_ROLE);
        // allocateSeigniorage(_pid);
        next_reward[_pid] = _amount;
    }

    // Update maxStaking. Can only be called by the owner.
    function setMaximumStakingAllowed(
        uint256 _pid,
        uint256 _maximumStakingAllowed
    ) external {
        checkRole(msg.sender, OPERATOR_ROLE);
        PoolInfo storage pool = poolInfo[_pid];
        pool.maximumStakingAllowed = _maximumStakingAllowed;
    }

    function updatePoolInfo(
        uint256 _pid,
        uint256 _epoch_length,
        uint256 _minimum_lockup_block
    ) external {
        checkRole(msg.sender, OPERATOR_ROLE);
        PoolInfo storage pool = poolInfo[_pid];
        pool.epoch_length = _epoch_length;
        pool.minimum_lockup_blocks = _minimum_lockup_block;
    }

    function claimRewards(uint256 _pid) public nonReentrant {
        allocateSeigniorage(_pid);
        address _sender = msg.sender;
        // retrieve user's information
        UserInfo storage user = userInfo[_pid][_sender];
        require(
            IERC721(poolInfo[_pid].nft_token).balanceOf(_sender) >= 1,
            "You must have a Mining Permit"
        );
        require(!user.status, "Your wallet is disabled by admin");
        require(
            user.totalAmount != 0,
            "Can't generate reward: No miner staked in pool"
        );
        require(
            block.number >=
                user.lastAccruedBlock + poolInfo[_pid].minimum_lockup_blocks,
            "Lockup period not over"
        );

        // calculate the current block epoch

        uint256 currentEpoch = block.number.div(poolInfo[_pid].epoch_length);
        // epoch_length is the number of blocks per epoch

        uint256 _pending = getGeneratedReward(_pid, _sender);
        //getGeneratedReward(_pid, user.amount, user.lastAccrued, block.timestamp);

        user.accruedCoin += _pending;
        user.lastAccrued = block.timestamp;
        user.lastAccruedBlock = block.number;
        _pending = (user.accruedCoin).sub(user.claimedCoin);
        if (_pending > 0) {
            user.claimedCoin += _pending;
            // user.lastClaimedEpoch = currentEpoch;
            user.lastClaimedBlock = block.number;
            //updating the lastClaimedEpoch of a user(dipanshu)
            safeECoinTransfer(_pid, _sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
    }

    // View function to see pending miner on frontend.
    function pendingShare(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        return getGeneratedReward(_pid, _user);
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount) external {
        allocateSeigniorage(_pid);
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(
            block.timestamp >= pool.poolStartTime,
            "Pool has not started yet!"
        );
        require(
            IERC721(pool.nft_token).balanceOf(_sender) >= 1,
            "You must have a Mining Permit"
        );

        require(!user.status, "Your wallet is disabled by admin");
        require(
            user.totalAmount + _amount <= pool.maximumStakingAllowed,
            "Maximum staking limit reached"
        );

        if (user.totalAmount > 0) {
            uint256 _pending = getGeneratedReward(_pid, _sender);
            if (_pending > 0) {
                user.accruedCoin += _pending;
                user.lastAccrued = block.timestamp;
                user.lastAccruedBlock = block.number;
                _pending = (user.accruedCoin).sub(user.claimedCoin);
                user.claimedCoin += _pending;
                user.lastClaimedBlock = block.number;
                safeECoinTransfer(_pid, _sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        } else {
            user.lastClaimedBlock = block.number;
            user.lastAccruedBlock = block.number;
        }
        if (_amount > 0) {
            user.totalAmount = user.totalAmount.add(_amount);
            user.lastAccrued = block.timestamp;
            user.lastAccruedBlock = block.number;
            pool.total_staked = pool.total_staked.add(_amount);
            IERC20(pool.stakeToken).safeTransferFrom(
                _sender,
                pool.treasury,
                _amount
            );
        }
        // allocateSeigniorage(_pid);
        emit Deposit(_sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        allocateSeigniorage(_pid);
        address _sender = msg.sender;
        require(
            IERC721(poolInfo[_pid].nft_token).balanceOf(_sender) >= 1,
            "You must have a NFT"
        );
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(!user.status, "Your wallet is disabled by admin");
        require(user.totalAmount >= _amount, "Withdrawal: Invalid");
        require(
            block.number >= user.lastAccruedBlock + pool.minimum_lockup_blocks,
            "Lockup period not over"
        );
        uint256 _pending = getGeneratedReward(_pid, _sender);
        user.accruedCoin += _pending;
        user.lastAccrued = block.timestamp;
        user.lastAccruedBlock = block.number;
        _pending = (user.accruedCoin).sub(user.claimedCoin);
        if (_pending > 0) {
            user.claimedCoin += _pending;
            user.lastClaimedBlock = block.number;
            safeECoinTransfer(_pid, _sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.totalAmount = user.totalAmount.sub(_amount);
            pool.total_staked = pool.total_staked.sub(_amount);
            IERC20(pool.stakeToken).safeTransfer(_sender, _amount);
        }
        emit Withdraw(_sender, _pid, _amount);
    }

    function safeECoinTransfer(
        uint256 _pid,
        address _to,
        uint256 _amount
    ) internal {
        PoolInfo storage _pool = poolInfo[_pid];
        IERC20 rewardToken = IERC20(_pool.rewardToken);
        uint256 _eusd_CoinBal = rewardToken.balanceOf(address(this));
        require(
            _eusd_CoinBal >= _amount && _pool.rewardsBalance >= _amount,
            "Insufficient rewards balance, ask dev to add more EUSD to the gen pool"
        );

        if (_eusd_CoinBal > 0) {
            if (_amount > _eusd_CoinBal) {
                _pool.rewardsBalance -= _eusd_CoinBal;
                rewardToken.safeTransfer(_to, _eusd_CoinBal);
            } else {
                _pool.rewardsBalance -= _amount;
                rewardToken.safeTransfer(_to, _amount);
            }
        }
    }

    function getGeneratedReward(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        // retrieve user's information
        UserInfo memory user = userInfo[_pid][_user];
        require(!user.status, "Your wallet is disabled by admin");
        require(
            IERC721(poolInfo[_pid].nft_token).balanceOf(_user) >= 1,
            "You must have a Mining Permit"
        );
        uint256 totalRewards = 0;
        Snapshot[] memory snapShotsByPool = snapshots[_pid];
        if (snapshots[_pid].length > 0) {
            // loop through the snapshot array backwards until we reach the user's last claimed epoch
            uint256 snapShotsIndexes = snapShotsByPool.length - 1;
            // uint256 epochLength = poolInfo[_pid].epoch_length;
            uint256 rewards = 0;

            while (
                user.lastClaimedBlock <=
                snapShotsByPool[snapShotsIndexes].blockNumber
            ) {
                if (snapShotsByPool[snapShotsIndexes].totalMinerStaked > 0) {
                    rewards = (
                        snapShotsByPool[snapShotsIndexes].nextReward.mul(
                            user.totalAmount
                        )
                    ).div(snapShotsByPool[snapShotsIndexes].totalMinerStaked);
                }
                totalRewards = totalRewards.add(rewards);

                if (snapShotsIndexes == 0) {
                    break;
                } else {
                    snapShotsIndexes--;
                }
            }
        }
        return totalRewards;
    }

    // @notice Sets the pool end time to extend the gen pools if required.
    function setPoolEndTime(uint256 _pid, uint256 _pool_end_time) external {
        checkRole(msg.sender, OPERATOR_ROLE);
        poolInfo[_pid].poolEndTime = _pool_end_time;
    }

    function setPoolStartTime(uint256 _pid, uint256 _pool_start_time) external {
        checkRole(msg.sender, OPERATOR_ROLE);
        poolInfo[_pid].poolStartTime = _pool_start_time;
    }

    // @notice imp. only use this function to replenish rewards
    // need to change for eusd coin(dipanshu)
    function replenishReward(uint256 _pid, uint256 _value) external {
        checkRole(msg.sender, OPERATOR_ROLE);
        require(_value > 0, "replenish value must be greater than 0");
        IERC20(poolInfo[_pid].rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _value
        );
        poolInfo[_pid].rewardsBalance += _value;
    }

    function replenishStakes(uint256 _pid, uint256 _value) external {
        checkRole(msg.sender, OPERATOR_ROLE);
        require(_value > 0, "replenish value must be greater than 0");
        IERC20(poolInfo[_pid].stakeToken).safeTransferFrom(
            msg.sender,
            address(this),
            _value
        );
    }

    // @notice can only transfer out the rewards balance and not user fund.
    function transferOutECoin(
        uint256 _pid,
        address _to,
        uint256 _value
    ) external {
        checkRole(msg.sender, TRANSFER_OUT_ROLE);
        require(
            _value <= poolInfo[_pid].rewardsBalance,
            "Trying to transfer out more miner than available"
        );
        poolInfo[_pid].rewardsBalance -= _value;
        IERC20(poolInfo[_pid].stakeToken).safeTransfer(_to, _value);
    }

    // @notice sets a pool's isStarted to true and increments total allocated points
    function startPool(uint256 _pid) public {
        checkRole(msg.sender, OPERATOR_ROLE);
        PoolInfo storage pool = poolInfo[_pid];
        if (!pool.isStarted) {
            pool.isStarted = true;
        }
    }

    // @notice calls startPool for all pools
    function startAllPools() external {
        checkRole(msg.sender, OPERATOR_ROLE);
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            startPool(pid);
        }
    }

    // View function to see rewards balance.
    function getRewardsBalance(uint256 _pid) external view returns (uint256) {
        return poolInfo[_pid].rewardsBalance;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function getBlocksSinceLastAction(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        UserInfo memory user_info = userInfo[_pid][_user];
        PoolInfo memory pool_info = poolInfo[_pid];
        if (
            block.number >=
            (user_info.lastAccruedBlock + pool_info.minimum_lockup_blocks)
        ) {
            return 0;
        } else {
            return
                (user_info.lastAccruedBlock + pool_info.minimum_lockup_blocks) -
                block.number;
        }
    }

    function getRewardTimeBasedOnLastAction(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        UserInfo memory user_info = userInfo[_pid][_user];
        PoolInfo memory pool_info = poolInfo[_pid];
        if(user_info.lastAccruedBlock > 0){
            return pool_info.epoch_length.sub(block.number.sub(user_info.lastAccruedBlock) % pool_info.epoch_length);
        }else{
            return 0;
        }
    }

    function setLastRun(uint256 _pid, uint256 _blockNumber) public {
        checkRole(msg.sender, OPERATOR_ROLE);
        lastRun[_pid] = _blockNumber;
    }

    function setTreasury(uint256 _pid, address _treasury) external {
        checkRole(msg.sender, OPERATOR_ROLE);
        poolInfo[_pid].treasury = _treasury;
    }
}