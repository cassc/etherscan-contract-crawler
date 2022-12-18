// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import './IStakingLockable.sol';
import '../interfaces/ILevelManager.sol';
import './StandaloneTreasury.sol';
import '../AdminableUpgradeable.sol';

contract LaunchpadLockableStaking is Initializable, AdminableUpgradeable, IStakingLockable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ILevelManager public levelManager;
    // Keeps reward tokens
    StandaloneTreasury public treasury;

    struct PoolInfo {
        IERC20Upgradeable stakingToken;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }

    struct Fees {
        address collectorAddress;
        // base 1000, 20% = 200
        uint256 depositFee;
        uint256 withdrawFee;
        uint256 collectedDepositFees;
        uint256 collectedWithdrawFees;
    }

    bool public halted;

    PoolInfo public liquidityMining;
    IERC20Upgradeable public rewardToken;
    // Should be with the same decimals number as the token decimals.
    uint256 public rewardPerBlock;
    uint256 private divider;

    mapping(address => UserInfo) public userInfo;
    Fees public fees;
    // If true, locked tokens cannot be withdrawn at all when locked
    bool public allowEarlyWithdrawal;
    uint256 public stakersCount;

    // For how long users token are locked after triggering the lock (first deposit or expired stake)
    uint256 public lockPeriod;
    // 1% = 100. If specified, we calculate rewardPerBlock based on the given apr and maturity duration
    uint256 public fixedApr;
    // The date of user staking first for the first time.
    // Every time it's updated, MUST fixate pendingRewards and MUST reset reward debt.
    mapping(address => uint256) public depositLockStart;
    bool public alwaysLockOnRegister;
    address[] public higherPools;
    // How many days to add on register
    uint8 public extendLockDaysOnRegister;
    IStaking public secondaryStaking;

    // account -> timestamp
    mapping(address => uint256) public lastClaimedAt;
    bool public waitForRewardMaturity;
    // Optional, if not specified, it's the same as lockPeriod
    uint256 public rewardMaturityDuration;

    struct ClaimFees {
        address collectorAddress;
        // base 1000, 20% = 200
        uint256 fee;
        uint256 collectedFees;
    }

    ClaimFees public claimFees;

    event Deposit(address indexed user, uint256 amount, uint256 feeAmount);

    event Withdraw(address indexed user, uint256 amount, uint256 feeAmount, bool locked);
    event UppedLockPool(address indexed user, uint256 amount, address targetPool);
    event Claim(address indexed user, uint256 amount, uint256 feeAmount);
    event StakedPending(address indexed user, uint256 amount);
    event Halted(bool status);
    event FeesUpdated(uint256 depositFee, uint256 withdrawFee, uint256 claimFee);
    event EarlyWithdrawalUpdated(bool allowEarlyWithdrawal);
    event RewardPerBlockUpdated(uint256 rewardPerBlock);

    event Locked(address indexed user, uint256 amount, uint256 lockPeriod, uint256 rewardPerBlock);

    modifier onlyLevelManager() {
        require(msg.sender == address(levelManager), 'Only LevelManager can lock');
        _;
    }

    function initialize(
        address _levelManager,
        address _treasury,
        address _feeAddress,
        uint256 _depositFee,
        uint256 _withdrawFee,
        uint256 _lockPeriod,
        uint256 _fixedApr
    ) public initializer {
        AdminableUpgradeable.initialize();

        levelManager = ILevelManager(_levelManager);
        setTreasury(_treasury);

        setFees(_feeAddress, _depositFee, _withdrawFee, _feeAddress, 0);
        divider = 1e12;
        allowEarlyWithdrawal = false;
        lockPeriod = _lockPeriod;
        fixedApr = _fixedApr;
        waitForRewardMaturity = true;
    }

    function isLocked(address account) public view override returns (bool) {
        return block.timestamp < depositLockStart[account] + lockPeriod;
    }

    function getLockPeriod() external view override returns (uint256) {
        return lockPeriod;
    }

    function getUnlocksAt(address account) external view override returns (uint256) {
        return depositLockStart[account] + lockPeriod;
    }

    function getLockedAmount(address account) external view override returns (uint256) {
        return userInfo[account].amount;
    }

    function getUserInfo(address account) external view override returns (UserInfo memory) {
        return userInfo[account];
    }

    // Reward per block calculates separately for each user based on the amount and lock period
    function getRewardPerBlock(address account) public view returns (uint256) {
        if (fixedApr == 0) {
            return 0;
        }
        if (userInfo[account].amount == 0 || !isLocked(account)) {
            return 0;
        }
        return getRewardPerSecond(account) * 3;
    }

    function getRewardPerSecond(address account) public view returns (uint256) {
        return (userInfo[account].amount * fixedApr) / 100 / 100 / (365 * 24 * 3600);
    }

    function setLevelManager(address _address) external override onlyOwner {
        levelManager = ILevelManager(_address);
    }

    function setTreasury(address _address) public onlyOwner {
        treasury = StandaloneTreasury(_address);
    }

    function setFixedApr(uint256 _apr) public onlyOwner {
        fixedApr = _apr;
        rewardPerBlock = 0;
    }

    function setLockPeriod(uint256 _lockPeriod) external override onlyOwner {
        lockPeriod = _lockPeriod;
    }

    function setExtendLockDaysOnRegister(uint8 _extendLock) external onlyOwner {
        extendLockDaysOnRegister = _extendLock;
    }

    function setSecondaryStaking(address _address) external onlyOwner {
        secondaryStaking = IStaking(_address);
    }

    function setFees(
        address _feeAddress,
        uint256 _depositFee,
        uint256 _withdrawFee,
        address _claimFeeAddress,
        uint256 _claimFee
    ) public onlyOwner {
        require(_feeAddress != address(0), 'Fees collector address is not specified');
        require(_depositFee < 700, 'Max deposit fee: 70%');
        require(_withdrawFee < 700, 'Max withdraw fee: 70%');
        require(_claimFee < 700, 'Max claim fee: 70%');

        fees.collectorAddress = _feeAddress;
        fees.depositFee = _depositFee;
        fees.withdrawFee = _withdrawFee;

        claimFees.collectorAddress = _claimFeeAddress;
        claimFees.fee = _claimFee;

        emit FeesUpdated(_depositFee, _withdrawFee, _claimFee);
    }

    function setWithdrawFee(uint256 _withdrawFee) external onlyOwner {
        fees.withdrawFee = _withdrawFee;
        emit FeesUpdated(fees.depositFee, fees.withdrawFee, claimFees.fee);
    }

    function setAllowEarlyWithdrawal(bool status) public onlyOwner {
        allowEarlyWithdrawal = status;
        emit EarlyWithdrawalUpdated(status);
    }

    /**
     * If duration is 0, but enabled = true, the reward will mature at the end of the lock period.
     */
    function setWaitForMaturity(bool enabled, uint256 duration) public onlyOwner {
        waitForRewardMaturity = enabled;
        rewardMaturityDuration = duration;
    }

    function halt(bool status) external onlyOwnerOrAdmin {
        halted = status;
        emit Halted(status);
    }

    function setRewardPerBlock(uint256 _rewardPerBlock) external onlyOwnerOrAdmin {
        rewardPerBlock = _rewardPerBlock;
        fixedApr = 0;
        emit RewardPerBlockUpdated(rewardPerBlock);
    }

    function setAlwaysLockOnRegister(bool status) external onlyOwnerOrAdmin {
        alwaysLockOnRegister = status;
    }

    function deposit(uint256 amount) external override {
        require(!halted, 'Deposits are paused');

        address account = msg.sender;
        UserInfo storage user = userInfo[account];
        uint256 fee;

        if (address(secondaryStaking) != address(0)) {
            secondaryStaking.deposit(amount);
        }

        if (!isLocked(account)) {
            depositLockStart[account] = block.timestamp;
            lastClaimedAt[account] = block.timestamp;
            user.rewardDebt = 0;
            emit Locked(account, amount, lockPeriod, 0);
        }

        updateUserPending(account);

        if (amount > 0) {
            // Transfer deposit
            liquidityMining.stakingToken.safeTransferFrom(address(account), address(this), amount);

            // Collect fee
            (amount, fee) = takeFee(amount, fees.depositFee, fees.collectorAddress);
            fees.collectedDepositFees += fee;

            stakersCount += user.amount == 0 ? 1 : 0;
            user.amount += amount;
            user.lastStakedAt = block.timestamp;
        }

        updateUserDebt(account);
        emit Deposit(account, amount, fee);
    }

    function withdraw(uint256 amount) external override {
        address account = msg.sender;
        UserInfo storage user = userInfo[account];
        bool tokensLocked = isLocked(account);
        uint256 fee;

        require(allowEarlyWithdrawal || !tokensLocked, 'Account is locked');
        require(user.amount >= amount, 'Withdrawing more than you have!');

        if (address(secondaryStaking) != address(0)) {
            try secondaryStaking.withdraw(amount) {} catch {}
        }

        updateUserPending(account);

        if (amount > 0) {
            user.amount -= amount;
            user.lastUnstakedAt = block.timestamp;
            stakersCount -= user.amount == 0 && stakersCount > 0 ? 1 : 0;

            // Collect fee if tokens are locked and we allow early withdrawal
            if (allowEarlyWithdrawal && tokensLocked) {
                (amount, fee) = takeFee(amount, fees.withdrawFee, fees.collectorAddress);
                fees.collectedWithdrawFees += fee;
            }

            // Transfer withdrawal
            liquidityMining.stakingToken.safeTransfer(address(account), amount);
        }

        updateUserDebt(account);
        emit Withdraw(account, amount, fee, tokensLocked);
    }

    function claim() external override {
        address account = msg.sender;
        UserInfo storage user = userInfo[account];
        require(isRewardMatured(account), 'Rewards are not matured yet');

        updateUserPending(account);
        if (user.pendingRewards > 0) {
            uint256 fee;
            if (claimFees.fee > 0) {
                fee = (user.pendingRewards * claimFees.fee) / 1000;
                user.pendingRewards -= fee;
                claimFees.collectedFees += fee;
                safeRewardTransfer(claimFees.collectorAddress, fee);
            }

            uint256 claimedAmount = safeRewardTransfer(account, user.pendingRewards);
            user.pendingRewards -= claimedAmount;
            lastClaimedAt[account] = rewardMaturityDuration > 0 ? block.timestamp : depositLockStart[account];

            emit Claim(account, claimedAmount, fee);
        }

        updateUserDebt(account);
    }

    /**
     * Allows to stake the current pending rewards which might be not claimable otherwise due to the maturity period.
     */
    function stakePendingRewards() external {
        address account = msg.sender;
        UserInfo storage user = userInfo[account];
//        require(isRewardMatured(account), 'Rewards are not matured yet');

        updateUserPending(account);
        uint256 amount = user.pendingRewards;
        user.pendingRewards = 0;
        user.amount += amount;

        if (!isLocked(account)) {
            depositLockStart[account] = block.timestamp;
            user.rewardDebt = 0;
            emit Locked(account, amount, lockPeriod, 0);
        }

        updateUserDebt(account);

        if (address(secondaryStaking) != address(0)) {
            secondaryStaking.deposit(amount);
        }

        emit StakedPending(account, amount);
    }

    function isRewardMatured(address account) internal returns (bool) {
        uint256 matureAt = lastClaimedAt[account] + (rewardMaturityDuration > 0 ? rewardMaturityDuration : lockPeriod);
        return !waitForRewardMaturity || block.timestamp > matureAt;
    }

    function takeFee(
        uint256 amount,
        uint256 feePercent,
        address feesAddress
    ) internal returns (uint256, uint256) {
        if (feePercent == 0) {
            return (amount, 0);
        }

        uint256 feeAmount = (amount * feePercent) / 1000;
        liquidityMining.stakingToken.safeTransfer(feesAddress, feeAmount);

        return (amount - feeAmount, feeAmount);
    }

    function updateUserPending(address account) internal {
        UserInfo storage user = userInfo[account];
        if (user.amount == 0) {
            return;
        }
        uint256 totalPending = user.pendingRewards + getFixedAprPendingReward(account);
        if (totalPending < user.rewardDebt) {
            user.pendingRewards = 0;
        } else {
            user.pendingRewards = totalPending - user.rewardDebt;
        }
    }

    // Uses two parameters:
    // - depositLockStart
    // - user.amount
    function getFixedAprPendingReward(address account) public view returns (uint256) {
        if (depositLockStart[account] == 0 || depositLockStart[account] == block.timestamp) {
            return 0;
        }

        // Pending tokens with fixed APR is limited to the APR matching the lock period,
        // e.g. 15% APR for 7 days = 15 / 365 * 7 = 0,28767123%
        uint256 passedTime = block.timestamp >= depositLockStart[account] + lockPeriod
            ? lockPeriod
            : block.timestamp - depositLockStart[account];

        // When lock reached maturity, it unlocks and stops generating rewards
        return passedTime * getRewardPerSecond(account);
    }

    function updateUserDebt(address account) internal {
        UserInfo storage user = userInfo[account];
        user.rewardDebt = getFixedAprPendingReward(account);
    }

    function setPoolInfo(IERC20Upgradeable _rewardToken, IERC20Upgradeable _stakingToken) external onlyOwner {
        require(
            address(rewardToken) == address(0) && address(liquidityMining.stakingToken) == address(0),
            'Token is already set'
        );
        rewardToken = _rewardToken;
        liquidityMining = PoolInfo({stakingToken: _stakingToken, lastRewardBlock: 0, accRewardPerShare: 0});
    }

    function safeRewardTransfer(address to, uint256 amount) internal returns (uint256) {
        uint256 balance = rewardToken.balanceOf(address(treasury));
        require(amount > 0, 'Reward amount must be more than zero');
        require(balance > 0, 'Not enough reward tokens for transfer');
        if (amount > balance) {
            rewardToken.safeTransferFrom(address(treasury), to, balance);
            return balance;
        }

        rewardToken.safeTransferFrom(address(treasury), to, amount);
        return amount;
    }

    function pendingRewards(address _user) external view override returns (uint256) {
        UserInfo storage user = userInfo[_user];
        return user.pendingRewards + getFixedAprPendingReward(_user) - user.rewardDebt;
    }

    /**
     * When tokens are sent to the contract by mistake: withdraw the specified token.
     */
    function withdrawToken(address token, uint256 amount) external onlyOwnerOrAdmin {
        IERC20Upgradeable(token).transfer(msg.sender, amount);
    }

    function lock(address account, uint256 saleStart) external override onlyLevelManager {
        bool isUserLocked = isLocked(account);
        if (userInfo[account].amount == 0 || (isUserLocked && !alwaysLockOnRegister && extendLockDaysOnRegister == 0)) {
            return;
        }

        if (isUserLocked && extendLockDaysOnRegister > 0) {
            uint256 lockEnd = depositLockStart[account] + lockPeriod;
            uint256 lockExtension = uint256(extendLockDaysOnRegister) * 24 * 3600;
            if (lockEnd < block.timestamp + lockExtension) {
                uint256 newLockStart = (saleStart + lockExtension) - lockPeriod;
                updateDepositLockStart(account, newLockStart < block.timestamp ? newLockStart : block.timestamp);
            }
        } else {
            updateDepositLockStart(account, block.timestamp);
            lastClaimedAt[account] = block.timestamp;
        }
        emit Locked(account, userInfo[account].amount, lockPeriod, 0);
    }

    /**
     * Moves all user staked tokens to the next (or any higher?) pool higher:
     * - only one of the configured pools is allowed
     * - moves all the tokens to the selected pool, adding to already staked
     * - re-locks, the new lock starts from now
     * - leaves rewards in the old pool
     */
    function upPool(address targetPool) external {
        // Only allow to one of the configured pools (one of higher pools)
        require(targetPool != address(0) && targetPool != address(this), 'Must specify target pool');
        require(higherPools.length > 0, 'Must have higherPools configured');
        bool poolAllowed = false;
        for (uint256 i = 0; i < higherPools.length; i++) {
            if (higherPools[i] == targetPool) {
                poolAllowed = true;
            }
        }
        require(poolAllowed, 'Pool not allowed');

        address account = msg.sender;
        UserInfo storage user = userInfo[account];
        require(user.amount > 0, 'No tokens locked');

        // Persists latest rewards
        updateUserPending(account);

        // Move tokens to the higher pool and lock it
        liquidityMining.stakingToken.approve(targetPool, user.amount);
        LaunchpadLockableStaking(targetPool).receiveUpPool(account, user.amount);

        emit UppedLockPool(account, user.amount, targetPool);

        // Unlock
        user.amount = 0;
        depositLockStart[account] = 0;
        updateUserDebt(account);
        lastClaimedAt[account] = 0;
    }

    /**
     * Accepts the "up pool" request from another pool:
     * - moves the specified amount of tokens from user
     * - re-locks, the new lock starts from now
     */
    function receiveUpPool(address account, uint256 amount) external {
        require(account != address(0), 'Must specify valid account');
        require(amount > 0, 'Must specify non-zero amount');

        UserInfo storage user = userInfo[account];

        // Re-lock
        // With lock start == block.timestamp, rewardDebt will be reset to 0 - marking the new locking period rewards countup.
        updateDepositLockStart(account, block.timestamp);
        emit Locked(account, amount, lockPeriod, 0);

        // Transfer deposit
        liquidityMining.stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        stakersCount += user.lastStakedAt > 0 ? 0 : 1;
        user.amount += amount;
        user.lastStakedAt = block.timestamp;
        lastClaimedAt[account] = block.timestamp;

        emit Deposit(account, amount, 0);

        if (address(secondaryStaking) != address(0)) {
            secondaryStaking.deposit(amount);
        }
    }

    function updateDepositLockStart(address account, uint256 lockStart) internal {
        updateUserPending(account);
        depositLockStart[account] = lockStart;
        updateUserDebt(account);
    }

    function setHigherPools(address[] calldata pools) external onlyOwnerOrAdmin {
        higherPools = pools;
    }

    function batchSyncLockStatus(address[] calldata addresses) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            if (!isLocked(addr)) {
                updateUserPending(addr);
                (, uint256 time) = levelManager.getUserLatestRegistration(addr);
                if (time > block.timestamp) {
                    depositLockStart[addr] = block.timestamp;
                    userInfo[addr].rewardDebt = 0;
                }
            }
        }
    }

    function batchFixateRewardsBefore(address[] calldata addresses) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            if (userInfo[addr].amount > 0) {
                updateUserPending(addr);
                updateUserDebt(addr);
            }
        }
    }

    function batchFixateDebtAfter(address[] calldata addresses) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            if (userInfo[addr].amount > 0) {
                updateUserDebt(addr);
            }
        }
    }

    function unlock(address account) external onlyOwnerOrAdmin {
        updateDepositLockStart(account, 0);
    }

    function transferAccountBalance(address oldAccount, address newAccount) external onlyOwner {
        depositLockStart[newAccount] = depositLockStart[oldAccount];
        depositLockStart[oldAccount] = 0;

        userInfo[newAccount].amount += userInfo[oldAccount].amount;
        userInfo[oldAccount].amount = 0;

        userInfo[newAccount].pendingRewards += userInfo[oldAccount].pendingRewards;
        userInfo[oldAccount].pendingRewards = 0;

        updateUserDebt(newAccount);
        userInfo[oldAccount].rewardDebt = 0;
    }
}