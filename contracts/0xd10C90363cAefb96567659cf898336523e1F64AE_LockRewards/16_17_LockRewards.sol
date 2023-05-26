// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/security/Pausable.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/access/AccessControl.sol";

import "./interfaces/ILockRewards.sol";

/**
 * @title Lock tokens and receive rewards in
 * 2 different tokens
 *  @author gcontarini jocorrei
 *  @notice The locking mechanism is based on epochs.
 * How long each epoch is going to last is up to the
 * contract owner to decide when setting an epoch with
 * the amount of rewards needed. To receive rewards, the
 * funds must be locked before the epoch start and will
 * become claimable at the epoch end. Relocking with
 * more tokens increases the amount received moving forward.
 * But it also can relock ALL funds for longer periods.
 *  @dev Contract follows a simple owner access control implemented
 * by the Ownable contract. The contract deployer is the owner at
 * start.
 */
contract LockRewards is ILockRewards, ReentrancyGuard, Ownable, Pausable, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant EPOCH_SETTER_ROLE = keccak256("EPOCH_SETTER_ROLE");
    bytes32 public constant PAUSE_SETTER_ROLE = keccak256("PAUSE_SETTER_ROLE");

    /// @dev Account hold all user information
    mapping(address => Account) public accounts;
    /// @dev Total amount of lockTokes that the contract holds
    uint256 public totalAssets;
    address public lockToken;

    /// @dev Hold all rewardToken information like token address
    address[] public rewardTokens;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public rewardsPaid;

    /// @dev If false, allows users to withdraw their tokens before the locking end period
    bool public enforceTime = true;

    /// @dev Hold all epoch information like rewards and balance locked for each user
    mapping(uint256 => Epoch) public epochs;
    uint256 public currentEpoch = 1;
    uint256 public nextUnsetEpoch = 1;
    uint256 public defaultEpochDurationInDays = 7;
    /// @dev In epochs;
    uint256 public lockDuration = 16;
    /// @dev Contract owner can whitelist an ERC20 token and withdraw its funds
    mapping(address => bool) public whitelistRecoverERC20;

    /**
     *  @dev Owner is the deployer
     *  @param _lockToken: token address which users can deposit to receive rewards
     *  @param _rewards: token address used to pay users rewards (Governance token)
     *  @param _defaultEpochDurationInDays: epoch duration in days
     *  @param _lockDuration: deposit duration in epochs
     */
    constructor(
        address _lockToken,
        address[] memory _rewards,
        uint256 _defaultEpochDurationInDays,
        uint256 _lockDuration,
        address _admin,
        address _epochSetter,
        address _pauseSetter
    ) {
        lockToken = _lockToken;
        defaultEpochDurationInDays = _defaultEpochDurationInDays;
        lockDuration = _lockDuration;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(EPOCH_SETTER_ROLE, _epochSetter);
        _grantRole(PAUSE_SETTER_ROLE, _pauseSetter);

        for (uint256 i = 0; i < _rewards.length;) {
            _setReward(_rewards[i]);

            unchecked {
                ++i;
            }
        }
    }

    /* ========== VIEWS ========== */

    /**
     *  @notice Total deposited for address in lockTokens
     *  @dev Show the total balance, not necessary it's all locked
     *  @param owner: user address
     *  @return balance: total balance of address
     */
    function balanceOf(address owner) external view returns (uint256) {
        return accounts[owner].balance;
    }

    /**
     *  @notice Shows the total of tokens locked in an epoch for an user
     *  @param owner: user address
     *  @param epochId: the epoch number
     *  @return balance: total of tokens locked for an epoch
     */
    function balanceOfInEpoch(address owner, uint256 epochId) external view returns (uint256) {
        return epochs[epochId].balanceLocked[owner];
    }

    /**
     *  @notice Total assets that contract holds
     *  @dev Not all tokens are actually locked
     *  @return totalAssets: amount of lock Tokens deposit in this contract
     */
    function totalLocked() external view returns (uint256) {
        return totalAssets;
    }

    /**
     *  @notice Show all information for on going epoch
     */
    function getCurrentEpoch()
        external
        view
        returns (uint256 start, uint256 finish, uint256 locked, uint256[] memory rewards, bool isSet)
    {
        return _getEpoch(currentEpoch);
    }

    /**
     *  @notice Show all information for next epoch
     *  @dev If next epoch is not set, return all zeros and nulls
     */
    function getNextEpoch()
        external
        view
        returns (uint256 start, uint256 finish, uint256 locked, uint256[] memory rewards, bool isSet)
    {
        if (currentEpoch == nextUnsetEpoch) {
            return (0, 0, 0, new uint256[](rewardTokens.length), false);
        }
        return _getEpoch(currentEpoch + 1);
    }

    /**
     *  @notice Show information for a given epoch
     *  @dev Start and finish values are seconds
     *  @param epochId: number of epoch
     */
    function getEpoch(uint256 epochId)
        external
        view
        returns (uint256 start, uint256 finish, uint256 locked, uint256[] memory rewards, bool isSet)
    {
        return _getEpoch(epochId);
    }

    /**
     *  @notice Show balance locked for called
     *  @param epochId: number of epoch
     */
    function getEpochBalanceLocked(uint256 epochId) external view returns (uint256 balanceLocked) {
        return _getEpochBalanceLocked(epochId);
    }

    /**
     *  @notice Show information for an account
     *  @dev LastEpochPaid tell when was the last epoch in each
     * this accounts was updated, which means receive rewards.
     *  @param owner: address for account
     */
    function getAccount(address owner)
        external
        view
        returns (uint256 balance, uint256 lockEpochs, uint256 lastEpochPaid, uint256[] memory rewards)
    {
        return _getAccount(owner);
    }

    /*
    @dev
    If you have a public state variable of array type,
    then you can only retrieve single elements of the array via the generated getter function.
    Therefore the entire array can only be returned by a function
    */
    function getRewardTokens() public view returns (address[] memory) {
        address[] memory addresses = new address[](rewardTokens.length);
        for (uint256 i = 0; i < rewardTokens.length;) {
            addresses[i] = rewardTokens[i];

            unchecked {
                ++i;
            }
        }

        return addresses;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     *  @notice Update caller account state (grant rewards if available)
     */
    function updateAccount()
        external
        whenNotPaused
        updateEpoch
        updateReward(msg.sender)
        returns (uint256 balance, uint256 lockEpochs, uint256 lastEpochPaid, uint256[] memory rewards)
    {
        return _getAccount(msg.sender);
    }

    /**
     *  @notice Deposit tokens to receive rewards.
     * In case of a relock, it will increase the total locked epochs
     * for the total amount of tokens deposited. The contract doesn't
     * allow different unlock periods for same address. Also, all
     * deposits will grant rewards for the next epoch, not the
     * current one if setted by the owner.
     *  @param amount: the amount of lock tokens to deposit
     */
    function deposit(uint256 amount) external nonReentrant whenNotPaused updateEpoch updateReward(msg.sender) {
        _deposit(amount, lockDuration);
    }

    /**
     *  @notice Redeposit increases user deposit without increasing epochs locked
     *  @param amount: the amount of lock tokens to deposit
     */
    function redeposit(uint256 amount) external nonReentrant whenNotPaused updateEpoch updateReward(msg.sender) {
        if (accounts[msg.sender].balance == 0) {
            revert InsufficientDeposit();
        }

        _deposit(amount, 0);
    }

    /**
     *  @notice Allows withdraw after lockEpochs is zero
     *  @param amount: tokens to caller receive
     */
    function withdraw(uint256 amount) external nonReentrant whenNotPaused updateEpoch updateReward(msg.sender) {
        _withdraw(amount);
    }

    /**
     *  @notice User can receive its claimable rewards
     */
    function claimRewards()
        external
        nonReentrant
        whenNotPaused
        updateEpoch
        updateReward(msg.sender)
        returns (uint256[] memory)
    {
        return _claim();
    }

    /**
     * @notice User can receive its claimable reward
     * @param reward: address of reward token to be claimed
     */
    function claimReward(address reward)
        external
        nonReentrant
        whenNotPaused
        updateEpoch
        updateReward(msg.sender)
        returns (uint256)
    {
        return _claim(reward);
    }

    /**
     *  @notice User withdraw all its funds and receive all available rewards
     *  @dev If user funds it's still locked, all transaction will revert
     */
    function exit()
        external
        nonReentrant
        whenNotPaused
        updateEpoch
        updateReward(msg.sender)
        returns (uint256[] memory)
    {
        _withdraw(accounts[msg.sender].balance);
        return _claim();
    }

    /**
     * @notice User withdraw all its funds and receive all available rewards and remove all upcoming rewards
     * @dev It's available only when user funds are locked for more than twice default lock period, only possible in case
     * where protocol haven't set upcoming epochs for extended period of time.
     */
    function emergencyExit()
        external
        nonReentrant
        whenNotPaused
        updateEpoch
        updateReward(msg.sender)
        returns (uint256[] memory)
    {
        _emergencyUnlock();
        return _claim();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Pause contract. Can only be called by the contract owner.
     * @dev If contract is already paused, transaction will revert
     */
    function pause() external onlyRole(PAUSE_SETTER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause contract. Can only be called by the contract owner.
     * @dev If contract is already unpaused, transaction will revert
     */
    function unpause() external onlyRole(PAUSE_SETTER_ROLE) {
        _unpause();
    }

    /**
     * @notice Set lock period for users
     * @dev If same lock period is already set transaction will revert
     * @param duration: number of epochs that deposit will lock for
     */
    function setLockDuration(uint256 duration) external onlyOwner updateEpoch {
        if (duration == lockDuration) {
            revert IncorrectLockDuration();
        }

        _setLockDuration(duration);
    }

    /**
     * @notice Set new reward token reward
     * @dev If reward token already on the list or is token that is locked transaction will revert
     * @param rewardToken: address of token that will be added
     */
    function setReward(address rewardToken) external onlyOwner updateEpoch {
        if (rewardToken == lockToken) {
            revert RewardTokenCannotBeLockToken(rewardToken);
        }
        for (uint256 i = 0; i < rewardTokens.length;) {
            if (rewardTokens[i] == rewardToken) revert RewardTokenAlreadyExists(rewardToken);

            unchecked {
                ++i;
            }
        }

        _setReward(rewardToken);
    }

    /**
     * @notice Remove token from rewards
     * @dev If reward token does not exist transaction will revert
     * @param rewardToken: address of token that will be removed
     */
    function removeReward(address rewardToken) external onlyOwner updateEpoch {
        uint256 index;
        bool exist;
        for (uint256 i = 0; i < rewardTokens.length;) {
            if (rewardTokens[i] == rewardToken) {
                exist = true;
                index = i;
                break;
            }

            unchecked {
                ++i;
            }
        }

        if (exist == false) revert RewardTokenDoesNotExist(rewardToken);

        _removeReward(index);
    }

    /**
     *  @notice Set a new epoch with default duration. The amount needed of tokens
     * should be transfered before calling setNextEpoch. Can only
     * have 2 epochs set, the on going one and the next.
     *  @dev Can set a start epoch different from now when there's
     * no epoch on going. If there's an epoch on going, can
     * only set the start after the finish of current epoch.
     *  @param values: the amount of rewards to be distributed tokens
     */
    function setNextEpoch(uint256[] calldata values) external onlyRole(EPOCH_SETTER_ROLE) updateEpoch {
        if (values.length != rewardTokens.length) {
            revert IncorrectRewards(values.length, rewardTokens.length);
        }
        _setEpoch(values, defaultEpochDurationInDays, block.timestamp);
    }

    /**
     *  @notice Set a new epoch. The amount needed of tokens
     * should be transfered before calling setNextEpoch. Can only
     * have 2 epochs set, the on going one and the next.
     *  @dev Can set a start epoch different from now when there's
     * no epoch on going. If there's an epoch on going, can
     * only set the start after the finish of current epoch.
     *  @param values: the amount of rewards to be distributed tokens
     *  @param epochDurationInDays: how long the epoch will last
     * in days
     *  @param epochStart: the epoch start date in unix epoch (seconds)
     */
    function setNextEpoch(uint256[] calldata values, uint256 epochDurationInDays, uint256 epochStart)
        external
        onlyRole(EPOCH_SETTER_ROLE)
        updateEpoch
    {
        if (values.length != rewardTokens.length) {
            revert IncorrectRewards(values.length, rewardTokens.length);
        }
        _setEpoch(values, epochDurationInDays, epochStart);
    }

    /**
     *  @notice Set a new epoch. The amount needed of tokens
     * should be transfered before calling setNextEpoch. Can only
     * have 2 epochs set, the on going one and the next.
     *  @dev If epoch is finished and there isn't a new to start,
     * the contract will hold. But in that case, when the next
     * epoch is set it'll already start (meaning: start will be
     * the current block timestamp).
     *  @param values: the amount of rewards to be distributed tokens
     *  @param epochDurationInDays: how long the epoch will last
     * in days
     */
    function setNextEpoch(uint256[] calldata values, uint256 epochDurationInDays)
        external
        onlyRole(EPOCH_SETTER_ROLE)
        updateEpoch
    {
        if (values.length != rewardTokens.length) {
            revert IncorrectRewards(values.length, rewardTokens.length);
        }
        _setEpoch(values, epochDurationInDays, block.timestamp);
    }

    /**
     *  @notice To recover ERC20 sent by accident.
     * All funds are only transfered to contract owner.
     *  @dev To allow a withdraw, first the token must be whitelisted
     *  @param tokenAddress: token to transfer funds
     *  @param tokenAmount: the amount to transfer to owner
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        if (whitelistRecoverERC20[tokenAddress] == false) revert NotWhitelisted();

        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (balance < tokenAmount) revert InsufficientBalance();

        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit RecoveredERC20(tokenAddress, tokenAmount);
    }

    /**
     *  @notice  Add or remove a token from recover whitelist,
     * cannot whitelist governance token
     *  @dev Only contract owner are allowed. Emits an event
     * allowing users to perceive the changes in contract rules.
     * The contract allows to whitelist the underlying tokens
     * (both lock token and rewards tokens). This can be exploited
     * by the owner to remove all funds deposited from all users.
     * This is done bacause the owner is mean to be a multisig or
     * treasury wallet from a DAO
     *  @param flag: set true to allow recover
     */
    function changeRecoverWhitelist(address tokenAddress, bool flag) external onlyOwner {
        if (tokenAddress == lockToken) revert CannotWhitelistLockedToken(lockToken);
        if (tokenAddress == rewardTokens[0]) revert CannotWhitelistGovernanceToken(rewardTokens[0]);
        whitelistRecoverERC20[tokenAddress] = flag;
        emit ChangeERC20Whiltelist(tokenAddress, flag);
    }

    /**
     *  @notice Allows recover for NFTs
     */
    function recoverERC721(address tokenAddress, uint256 tokenId) external onlyOwner {
        IERC721(tokenAddress).transferFrom(address(this), owner(), tokenId);
        emit RecoveredERC721(tokenAddress, tokenId);
    }

    /**
     *  @notice Allows owner change rule to allow users' withdraw
     * before the lock period is over
     *  @dev In case a major flaw, do this to prevent users from losing
     * their funds. Also, if no more epochs are going to be setted allows
     * users to withdraw their assets
     *  @param flag: set false to allow withdraws
     */
    function changeEnforceTime(bool flag) external onlyOwner {
        enforceTime = flag;
        emit ChangeEnforceTime(block.timestamp, flag);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     *  @notice Allows owner to change for how long user has to lock their deposit
     *  @param duration: new value for lockDuration
     */
    function _setLockDuration(uint256 duration) internal {
        lockDuration = duration;
        emit SetLockDuration(duration);
    }

    /**
     *  @notice Implements internal set reward logic
     *  @param rewardToken: address of token that will be added to rewards
     */
    function _setReward(address rewardToken) internal {
        rewardTokens.push(rewardToken);

        emit NewRewardToken(rewardToken);
    }

    /**
     *  @notice Implements internal remove reward logic
     *  @param index: index in reward tokens array of token to be removed
     */
    function _removeReward(uint256 index) internal {
        address addr = rewardTokens[index];
        rewardTokens[index] = rewardTokens[rewardTokens.length - 1];
        rewardTokens.pop();

        emit RemovedRewardToken(addr);
    }

    /**
     *  @notice Implements internal setEpoch logic
     *  @dev Can only set 2 epochs, the on going and
     * the next one. This has to be done in 2 different
     * transactions.
     *  @param values: the amount of rewards to be distributed
     * in days
     *  @param epochStart: the epoch start date in unix epoch (seconds)
     */
    function _setEpoch(uint256[] calldata values, uint256 epochDurationInDays, uint256 epochStart) internal {
        if (nextUnsetEpoch - currentEpoch > 1) {
            revert EpochMaxReached(2);
        }
        if (epochStart < block.timestamp) {
            revert EpochStartInvalid(epochStart, block.timestamp);
        }

        address[] memory epochTokens = new address[](rewardTokens.length);
        uint256[] memory epochRewards = new uint256[](rewardTokens.length);

        for (uint256 i = 0; i < rewardTokens.length;) {
            uint256 unclaimed = rewards[rewardTokens[i]] - rewardsPaid[rewardTokens[i]];
            uint256 balance = IERC20(rewardTokens[i]).balanceOf(address(this));

            if (balance - unclaimed < values[i]) {
                revert InsufficientFundsForRewards(rewardTokens[i], balance - unclaimed, values[i]);
            }

            rewards[rewardTokens[i]] += values[i];
            epochTokens[i] = rewardTokens[i];
            epochRewards[i] = values[i];

            unchecked {
                ++i;
            }
        }

        uint256 next = nextUnsetEpoch;

        if (currentEpoch == next || epochStart > epochs[next - 1].finish + 1) {
            epochs[next].start = epochStart;
        } else {
            epochs[next].start = epochs[next - 1].finish + 1;
        }
        epochs[next].finish = epochs[next].start + epochDurationInDays * 86400; // Seconds in a day

        epochs[next].tokens = epochTokens;
        epochs[next].rewards = epochRewards;
        epochs[next].isSet = true;

        nextUnsetEpoch += 1;
        emit SetNextReward(next, values, epochs[next].start, epochs[next].finish);
    }

    /**
     *  @notice Implements internal deposit logic
     *  @dev The deposit is always done in name of caller
     *  @param amount: the amount of lock tokens to deposit
     *  @param lock: how many epochs to lock
     */
    function _deposit(uint256 amount, uint256 lock) internal {
        IERC20 lToken = IERC20(lockToken);

        uint256 oldLockEpochs = accounts[msg.sender].lockEpochs;
        // Increase lockEpochs for user
        accounts[msg.sender].lockEpochs += lock;
        accounts[msg.sender].lockStart = block.timestamp;

        // This is done to save gas in case of a relock
        // Also, emits a different event for deposit or relock
        if (amount > 0) {
            lToken.safeTransferFrom(msg.sender, address(this), amount);
            totalAssets += amount;
            accounts[msg.sender].balance += amount;

            emit Deposit(msg.sender, amount, lockDuration);
        } else {
            emit Relock(msg.sender, accounts[msg.sender].balance, lockDuration);
        }

        // Check if current epoch is in course
        // Then, set the deposit for the upcoming ones
        uint256 _currEpoch = currentEpoch;
        uint256 next = epochs[_currEpoch].isSet ? _currEpoch + 1 : _currEpoch;

        // Since all funds will be locked for the same period
        // Update all future lock epochs for this new value
        uint256 lockBoundary;
        if (!epochs[_currEpoch].isSet || oldLockEpochs == 0) {
            lockBoundary = accounts[msg.sender].lockEpochs;
        } else {
            lockBoundary = accounts[msg.sender].lockEpochs - 1;
        }
        uint256 newBalance = accounts[msg.sender].balance;
        for (uint256 i = 0; i < lockBoundary;) {
            epochs[i + next].totalLocked += newBalance - epochs[i + next].balanceLocked[msg.sender];
            epochs[i + next].balanceLocked[msg.sender] = newBalance;

            unchecked {
                ++i;
            }
        }
    }

    /**
     *  @notice Implements internal withdraw logic
     *  @dev The withdraw is always done in name
     * of caller for caller
     *  @param amount: amount of tokens to withdraw
     */
    function _withdraw(uint256 amount) internal {
        if (amount == 0 || accounts[msg.sender].balance < amount) revert InsufficientAmount();
        if (accounts[msg.sender].lockEpochs > 0 && enforceTime) revert FundsInLockPeriod(accounts[msg.sender].balance);
        totalAssets -= amount;
        accounts[msg.sender].balance -= amount;
        IERC20(lockToken).safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    /**
     *  @notice Implements internal emergency unlock logic
     *  @dev The emergency unlock is always done in name
     * of caller for caller, it removes all further rewards.
     */

    function _emergencyUnlock() internal {
        if (accounts[msg.sender].lockStart + lockDuration * defaultEpochDurationInDays * 86400 * 2 > block.timestamp) {
            revert FundsInLockPeriod(accounts[msg.sender].balance);
        }

        uint256 current = currentEpoch;
        uint256 lockEpochs = accounts[msg.sender].lockEpochs;
        uint256 lastEpochPaid = accounts[msg.sender].lastEpochPaid;

        uint256 limit = lastEpochPaid + lockEpochs;

        for (uint256 i = lastEpochPaid; i < limit;) {
            epochs[i].totalLocked -= epochs[i].balanceLocked[msg.sender];
            epochs[i].balanceLocked[msg.sender] = 0;
            unchecked {
                ++i;
            }
        }

        accounts[msg.sender].lockEpochs = 0;

        _withdraw(accounts[msg.sender].balance);
    }

    /**
     *  @notice Implements internal claim reward logic
     *  @dev The claim reward is always done in name
     * of caller for caller
     *  @param addr: address of token for which reward will be claimed
     *  @return reward token amount claimed
     */
    function _claim(address addr) internal returns (uint256 reward) {
        reward = accounts[msg.sender].rewards[addr];
        if (reward > 0) {
            accounts[msg.sender].rewards[addr] = 0;
            IERC20(addr).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, addr, reward);
        }

        return reward;
    }
    /**
     *  @notice Implements internal claim rewards logic
     *  @dev The claim is always done in name
     * of caller for caller
     *  @return rewards of rewards transfer in token 1
     */

    function _claim() internal returns (uint256[] memory rewards) {
        rewards = new uint256[](accounts[msg.sender].rewardTokens.length);

        for (uint256 i = 0; i < accounts[msg.sender].rewardTokens.length;) {
            address addr = accounts[msg.sender].rewardTokens[i];
            uint256 reward = accounts[msg.sender].rewards[addr];
            rewards[i] = reward;
            if (reward > 0) {
                accounts[msg.sender].rewards[addr] = 0;
                IERC20(addr).safeTransfer(msg.sender, reward);
                emit RewardPaid(msg.sender, addr, reward);
            }
            unchecked {
                ++i;
            }
        }

        accounts[msg.sender].rewardTokens = new address[](0);

        return rewards;
    }

    /**
     *  @notice Implements internal getAccount logic
     *  @param owner: address to check informations
     */
    function _getAccount(address owner)
        internal
        view
        returns (uint256 balance, uint256 lockEpochs, uint256 lastEpochPaid, uint256[] memory rewards)
    {
        rewards = new uint256[](rewardTokens.length);
        for (uint256 i = 0; i < accounts[owner].rewardTokens.length;) {
            address addr = accounts[owner].rewardTokens[i];
            rewards[i] = accounts[owner].rewards[addr];

            unchecked {
                ++i;
            }
        }

        return (accounts[owner].balance, accounts[owner].lockEpochs, accounts[owner].lastEpochPaid, rewards);
    }

    /**
     *  @notice Implements internal getEpoch logic
     *  @param epochId: the number of the epoch
     */
    function _getEpoch(uint256 epochId)
        internal
        view
        returns (uint256 start, uint256 finish, uint256 locked, uint256[] memory rewards, bool isSet)
    {
        return (
            epochs[epochId].start,
            epochs[epochId].finish,
            epochs[epochId].totalLocked,
            epochs[epochId].rewards,
            epochs[epochId].isSet
        );
    }

    /**
     *  @notice Implements internal getEpochBalanceLocked logic
     *  @param epochId: the number of the epoch
     */
    function _getEpochBalanceLocked(uint256 epochId) internal view returns (uint256 balanceLocked) {
        return (epochs[epochId].balanceLocked[msg.sender]);
    }

    /* ========== MODIFIERS ========== */

    modifier updateEpoch() {
        uint256 current = currentEpoch;

        while (epochs[current].finish <= block.timestamp && epochs[current].isSet == true) {
            current++;
        }
        currentEpoch = current;
        _;
    }

    modifier updateReward(address owner) {
        uint256 current = currentEpoch;
        uint256 lockEpochs = accounts[owner].lockEpochs;
        uint256 lastEpochPaid = accounts[owner].lastEpochPaid;

        // Solve edge case for first epoch
        // since epochs starts on value 1
        if (lastEpochPaid == 0) {
            accounts[owner].lastEpochPaid = 1;
            ++lastEpochPaid;
        }

        uint256 locks = 0;

        uint256 limit = lastEpochPaid + lockEpochs;
        if (limit > current) {
            limit = current;
        }

        for (uint256 i = lastEpochPaid; i < limit;) {
            if (epochs[i].balanceLocked[owner] == 0) {
                unchecked {
                    ++i;
                }
                continue;
            }

            uint256 share = epochs[i].balanceLocked[owner] * 1e18 / epochs[i].totalLocked;

            for (uint256 j = 0; j < epochs[i].rewards.length;) {
                uint256 shareValue = share * epochs[i].rewards[j] / 1e18;
                if (accounts[owner].rewards[epochs[i].tokens[j]] == 0) {
                    accounts[owner].rewardTokens.push(epochs[i].tokens[j]);
                }

                rewardsPaid[epochs[i].tokens[j]] += shareValue;
                accounts[owner].rewards[epochs[i].tokens[j]] += shareValue;
                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++locks;
                ++i;
            }
        }

        accounts[owner].lockEpochs -= locks;

        if (lastEpochPaid != current) {
            accounts[owner].lastEpochPaid = current;
        }

        _;
    }
}