//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IStaking.sol";

contract Staking is IStaking, AccessControl {
    using SafeERC20 for IERC20Metadata;

    error IncorrectAmount(uint256 amountRequested, uint256 amountAvailable);
    error InsufficientAmount(uint256 amount, uint256 amountRequired);
    error ExecutedEarly(uint256 requiredTime);
    error OnlyStaker();

    /// 100% in basis points
    uint256 public constant MAX_PERCENTAGE = 10000;
    /// Precision for ppt
    uint256 public constant PRECISION = 1e18;
    /// 1 year in seconds
    uint256 public constant YEAR = 365 * 24 * 60 * 60;
    /// Role for extending unstake time for staker
    bytes32 public constant UNSTAKE_EXTENDER_ROLE = keccak256("UNSTAKE_EXTENDER_ROLE");

    /// Total staked to the contract
    uint256 public totalStaked;
    /// Total reward produced
    uint256 public rewardProduced;
    /// Minimum amount for claiming rewards
    uint256 public minClaimAmount;
    /// Minimum amount to stake in order to get min apy
    uint256 public minAmountForMinApy;
    /// Lock period for staked tokens
    uint256 public stakeLockPeriod;
    /// Unlock period for claiming rewards
    uint256 public claimUnlockPeriod;
    /// Extend period for sale participation
    uint256 public unstakeExtendPeriod;
    /// Fine percentage for unstaking early (in basis points)
    uint256 public earlyUnstakeFine;
    /// Minimum staking apy for staking to count valid
    uint256 public minStakingApy;
    /// Maximum apy earnable from the staking
    uint256 public maxStakingApy;
    /// Index of ppt
    uint256 public pptIndex;
    /// Treasury address
    address public treasuryAddress;

    /// Staked token
    IERC20Metadata public tokenStaking;

    /**
     * @dev This struct holds information about staker
     * @param amountStaked Amount staked
     * @param availableReward Available reward for the stake holder
     * @param unstakeTime Timestamp to unstake
     * @param lastUpdateTime Stakers latest update time
     */
    struct Staker {
        uint256 amountStaked;
        uint256 availableReward;
        uint128 unstakeTime;
        uint128 lastUpdateTime;
    }

    /**
     * @dev This struct holds information about percent per token
     * @param ppt Percent per token (by token: 10**token.decimals(), NOT WEI!)
     * @param startTime Start time of given ppt
     * @param endTime End time of given ppt
     */
    struct Ppt {
        uint256 ppt;
        uint128 startTime;
        uint128 endTime;
    }

    /// A mapping for storing claim timestamp
    mapping(address => uint256) private _claimTimes;
    /// A mapping for storing staker information
    mapping(address => Staker) private _stakers;
    /// A mapping for storing ppt values
    mapping(uint256 => Ppt) private _ppts;

    /**
     * @dev Emitted when stake holder staked tokens
     * @param stakeHolder The address of the stake holder
     * @param amount The amount staked
     */
    event Staked(address indexed stakeHolder, uint256 amount);

    /**
     * @dev Emitted when stake holder unstaked tokens
     * @param stakeHolder The address of the stake holder
     * @param amount The amount unstaked
     */
    event Unstaked(address indexed stakeHolder, uint256 amount);

    /**
     * @dev Emitted when stake holder claimed reward tokens
     * @param stakeHolder The address of the stake holder
     * @param amount The amount of reward tokens claimed
     */
    event Claimed(address indexed stakeHolder, uint256 amount);

    /**
     * @dev Emitted when stake holder unstake tokens before unstake time
     * @param stakeHolder The address of the stake holder
     * @param amount The amount unstaked
     * @param fine The amount fined
     * @param burnedRewards The burned rewards amount
     */
    event EmergencyUnstaked(address indexed stakeHolder, uint256 amount, uint256 fine, uint256 burnedRewards);

    /**
     * @dev Emitted when ppt updated
     * @param newPpt The new ppt value
     */
    event PptUpdated(uint256 newPpt);

    constructor(
        address _tokenStaking,
        address _treasuryAddress,
        uint256 _ppt,
        uint256 _minClaimAmount,
        uint256 _minAmountForMinApy,
        uint256 _stakeLockPeriod,
        uint256 _claimUnlockPeriod,
        uint256 _unstakeExtendPeriod,
        uint256 _earlyUnstakeFine,
        uint256 _minStakingApy,
        uint256 _maxStakingApy
    ) {
        tokenStaking = IERC20Metadata(_tokenStaking);
        treasuryAddress = _treasuryAddress;

        Ppt storage ppt = _ppts[pptIndex];
        ppt.startTime = uint128(block.timestamp);
        ppt.ppt = _ppt;

        minClaimAmount = _minClaimAmount;
        minAmountForMinApy = _minAmountForMinApy;
        stakeLockPeriod = _stakeLockPeriod;
        claimUnlockPeriod = _claimUnlockPeriod;
        unstakeExtendPeriod = _unstakeExtendPeriod;
        earlyUnstakeFine = _earlyUnstakeFine;
        minStakingApy = _minStakingApy;
        maxStakingApy = _maxStakingApy;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyStaker() {
        if (_stakers[msg.sender].amountStaked == 0) revert OnlyStaker();
        _;
    }

    function updateTreasuryAddress(address _treasuryAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        treasuryAddress = _treasuryAddress;
    }

    function updatePpt(uint256 _ppt) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _ppts[pptIndex].endTime = uint128(block.timestamp);

        pptIndex++;
        Ppt storage ppt = _ppts[pptIndex];
        ppt.startTime = uint128(block.timestamp);
        ppt.ppt = _ppt;

        emit PptUpdated(_ppt);
    }

    function updateMinClaimAmount(uint256 _minClaimAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minClaimAmount = _minClaimAmount;
    }

    function updateMinAmountForMinApy(uint256 _minAmountForMinApy) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minAmountForMinApy = _minAmountForMinApy;
    }

    function updateStakeLockPeriod(uint256 _stakeLockPeriod) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakeLockPeriod = _stakeLockPeriod;
    }

    function updateClaimUnlockPeriod(uint256 _claimUnlockPeriod) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimUnlockPeriod = _claimUnlockPeriod;
    }

    function updateUnstakeExtendPeriod(uint256 _unstakeExtendPeriod) external onlyRole(DEFAULT_ADMIN_ROLE) {
        unstakeExtendPeriod = _unstakeExtendPeriod;
    }

    function updateEarlyUnstakeFine(uint256 _earlyUnstakeFine) external onlyRole(DEFAULT_ADMIN_ROLE) {
        earlyUnstakeFine = _earlyUnstakeFine;
    }

    function stake(uint256 amount) external {
        _updateStakerValues();

        totalStaked += amount;

        Staker storage staker = _stakers[msg.sender];
        staker.amountStaked += amount;
        staker.unstakeTime = uint128(block.timestamp + stakeLockPeriod);

        // if its first stake of user set claim unlock period
        if (_claimTimes[msg.sender] == 0) _claimTimes[msg.sender] = block.timestamp + claimUnlockPeriod;

        tokenStaking.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external onlyStaker {
        _updateStakerValues();

        Staker storage staker = _stakers[msg.sender];
        if (amount > staker.amountStaked)
            revert IncorrectAmount({ amountRequested: amount, amountAvailable: staker.amountStaked });
        if (block.timestamp < staker.unstakeTime) revert ExecutedEarly({ requiredTime: staker.unstakeTime });

        totalStaked -= amount;
        staker.amountStaked -= amount;

        tokenStaking.safeTransfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() external {
        _updateStakerValues();
        Staker storage staker = _stakers[msg.sender];

        if (block.timestamp < _claimTimes[msg.sender]) revert ExecutedEarly({ requiredTime: _claimTimes[msg.sender] });
        if (staker.availableReward < minClaimAmount)
            revert InsufficientAmount({ amount: staker.availableReward, amountRequired: minClaimAmount });

        uint256 reward = staker.availableReward;
        rewardProduced += reward;
        staker.availableReward = 0;

        tokenStaking.safeTransferFrom(treasuryAddress, address(this), reward);
        tokenStaking.safeTransfer(msg.sender, reward);

        emit Claimed(msg.sender, reward);
    }

    function emergencyUnstake() external onlyStaker {
        _updateStakerValues();

        Staker storage staker = _stakers[msg.sender];

        totalStaked -= staker.amountStaked;

        uint256 burnedRewards = staker.availableReward;
        staker.availableReward = 0;

        uint256 fine = (staker.amountStaked * earlyUnstakeFine) / MAX_PERCENTAGE;
        uint256 unstakeAmount = staker.amountStaked - fine;

        staker.amountStaked = 0;

        tokenStaking.safeTransfer(treasuryAddress, fine);
        tokenStaking.safeTransfer(msg.sender, unstakeAmount);

        emit EmergencyUnstaked(msg.sender, unstakeAmount, fine, burnedRewards);
    }

    function unstakeExtend(address _staker) external onlyRole(UNSTAKE_EXTENDER_ROLE) {
        Staker storage staker = _stakers[_staker];

        if (block.timestamp < staker.unstakeTime) staker.unstakeTime += uint128(unstakeExtendPeriod);
        else staker.unstakeTime = uint128(block.timestamp + unstakeExtendPeriod);
    }

    function getStakerDetails(address _staker)
        external
        view
        returns (
            uint256 amountStaked,
            uint256 availableReward,
            uint128 unstakeTime,
            uint128 lastUpdateTime,
            uint256 claimTime
        )
    {
        Staker memory staker = _stakers[_staker];
        amountStaked = staker.amountStaked;
        availableReward = staker.availableReward + _calculateTotalRewards(staker);
        unstakeTime = staker.unstakeTime;
        lastUpdateTime = staker.lastUpdateTime;
        claimTime = _claimTimes[_staker];
    }

    function getPptDetails(uint256 _pptIndex) external view returns (Ppt memory ppt) {
        ppt = _ppts[_pptIndex];
    }

    function _updateStakerValues() private {
        Staker storage staker = _stakers[msg.sender];

        // if not new user
        if (staker.lastUpdateTime != 0) staker.availableReward += _calculateTotalRewards(staker);

        staker.lastUpdateTime = uint128(block.timestamp);
    }

    function _calculateTotalRewards(Staker memory staker) private view returns (uint256 totalRewards) {
        for (uint256 i = 0; i <= pptIndex; i++) {
            Ppt memory ppt = _ppts[i];
            if (ppt.endTime != 0 && staker.lastUpdateTime > ppt.endTime) {
                continue;
            }

            uint256 startTime = ppt.startTime;
            if (staker.lastUpdateTime > ppt.startTime) startTime = staker.lastUpdateTime;

            uint256 endTime = ppt.endTime;
            if (ppt.endTime == 0) endTime = block.timestamp;

            uint256 deltaTime = endTime - startTime;
            totalRewards += _calculateRewards(deltaTime, staker.amountStaked, ppt.ppt);
        }
    }

    function _calculateRewards(
        uint256 deltaTime,
        uint256 amount,
        uint256 ppt
    ) private view returns (uint256 reward) {
        if (amount < minAmountForMinApy) reward = 0;
        else {
            uint256 remainingAmount = amount - minAmountForMinApy;
            uint256 percentage = minStakingApy + ((remainingAmount * ppt) / 10**tokenStaking.decimals());
            if (percentage > maxStakingApy) percentage = maxStakingApy;

            uint256 multiplier = (percentage * deltaTime) / YEAR;
            reward = (amount * multiplier) / PRECISION;
        }
    }
}