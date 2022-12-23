// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@1inch/erc20-pods/contracts/ERC20Pods.sol";
import "@1inch/erc20-pods/contracts/Pod.sol";
import "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import "./helpers/VotingPowerCalculator.sol";
import "./interfaces/IVotable.sol";

/**
 * @title 1inch staking contract
 * @notice The contract provides the following features: staking, delegation, farming
 * How lock period works:
 * - balances and voting power
 * - Lock min and max
 * - Add lock
 * - earlyWithdrawal
 * - penalty math
 */
contract St1inch is ERC20Pods, Ownable, VotingPowerCalculator, IVotable {
    using SafeERC20 for IERC20;

    event EmergencyExitSet(bool status);
    event MaxLossRatioSet(uint256 ratio);
    event FeeReceiverSet(address receiver);
    event DefaultFarmSet(address defaultFarm);

    error ApproveDisabled();
    error TransferDisabled();
    error LockTimeMoreMaxLock();
    error LockTimeLessMinLock();
    error UnlockTimeHasNotCome();
    error StakeUnlocked();
    error MinReturnIsNotMet();
    error MaxLossIsNotMet();
    error MaxLossOverflow();
    error LossIsTooBig();
    error RescueAmountIsTooLarge();
    error ExpBaseTooBig();
    error ExpBaseTooSmall();
    error DefaultFarmTokenMismatch();
    error DepositsDisabled();
    error ZeroAddress();

    /// @notice The minimum allowed staking period
    uint256 public constant MIN_LOCK_PERIOD = 30 days;
    /// @notice The maximum allowed staking period
    /// @dev WARNING: It is not enough to change the constant only but voting power decrease curve should be revised also
    uint256 public constant MAX_LOCK_PERIOD = 2 * 365 days;
    /// @notice Voting power decreased to 1/_VOTING_POWER_DIVIDER after lock expires
    /// @dev WARNING: It is not enough to change the constant only but voting power decrease curve should be revised also
    uint256 private constant _VOTING_POWER_DIVIDER = 20;
    uint256 private constant _PODS_LIMIT = 5;
    /// @notice Maximum allowed gas spent by each attached pod. If there not enough gas for pod execution then
    /// transaction is reverted. If pod uses more gas then its execution is reverted silently, not affection the
    /// main transaction
    uint256 private constant _POD_CALL_GAS_LIMIT = 500_000;
    uint256 private constant _ONE = 1e9;

    IERC20 public immutable oneInch;

    /// @notice The stucture to store stake information for a staker
    struct Depositor {
        // Unix time in seconds
        uint40 unlockTime;
        // Staked 1inch token amount
        uint216 amount;
    }

    mapping(address => Depositor) public depositors;

    uint256 public totalDeposits;
    bool public emergencyExit;
    uint256 public maxLossRatio;
    address public feeReceiver;
    address public defaultFarm;

    /**
     * @notice Initializes the contract
     * @param oneInch_ The token to be staked
     * @param expBase_ The rate for the voting power decrease over time
     */
    constructor(IERC20 oneInch_, uint256 expBase_)
        ERC20Pods(_PODS_LIMIT, _POD_CALL_GAS_LIMIT)
        ERC20("Staking 1INCH v2", "st1INCH")
        VotingPowerCalculator(expBase_, block.timestamp)
    {
        // voting power after MAX_LOCK_PERIOD should be equal to staked amount divided by _VOTING_POWER_DIVIDER
        if (_votingPowerAt(1e18, block.timestamp + MAX_LOCK_PERIOD) * _VOTING_POWER_DIVIDER < 1e18) revert ExpBaseTooBig();
        if (_votingPowerAt(1e18, block.timestamp + MAX_LOCK_PERIOD + 1) * _VOTING_POWER_DIVIDER > 1e18) revert ExpBaseTooSmall();
        oneInch = oneInch_;
    }

    /**
     * @notice Sets the new contract that would recieve early withdrawal fees
     * @param feeReceiver_ The receiver contract address
     */
    function setFeeReceiver(address feeReceiver_) external onlyOwner {
        if (feeReceiver_ == address(0)) revert ZeroAddress();
        feeReceiver = feeReceiver_;
        emit FeeReceiverSet(feeReceiver_);
    }

    /**
     * @notice Sets the new farm that all staking users will automatically join after staking for reward farming
     * @param defaultFarm_ The farm contract address
     */
    function setDefaultFarm(address defaultFarm_) external onlyOwner {
        if (defaultFarm_ != address(0) && Pod(defaultFarm_).token() != this) revert DefaultFarmTokenMismatch();
        defaultFarm = defaultFarm_;
        emit DefaultFarmSet(defaultFarm_);
    }

    /**
     * @notice Sets the maximum allowed loss ratio for early withdrawal. If the ratio is not met, actual is more than allowed,
     * then early withdrawal will revert.
     * Example: maxLossRatio = 90% and 1000 staked 1inch tokens means that a user can execute early withdrawal only
     * if his loss is less than or equals 90% of his stake, which is 900 tokens. Thus, if a user loses 900 tokens he is allowed
     * to do early withdrawal and not if the loss is greater.
     * @param maxLossRatio_ The maximum loss allowed (9 decimals).
     */
    function setMaxLossRatio(uint256 maxLossRatio_) external onlyOwner {
        if (maxLossRatio_ > _ONE) revert MaxLossOverflow();
        maxLossRatio = maxLossRatio_;
        emit MaxLossRatioSet(maxLossRatio_);
    }

    /**
     * @notice Sets the emergency exit mode. In emergency mode any stake may withdraw its stake regardless of lock.
     * The mode is intended to use only for migration to a new version of staking contract.
     * @param emergencyExit_ set `true` to enter emergency exit mode and `false` to return to normal operations
     */
    function setEmergencyExit(bool emergencyExit_) external onlyOwner {
        emergencyExit = emergencyExit_;
        emit EmergencyExitSet(emergencyExit_);
    }

    /**
     * @notice Gets the voting power of the provided account
     * @param account The address of an account to get voting power for
     * @return votingPower The voting power available at the block timestamp
     */
    function votingPowerOf(address account) external view returns (uint256) {
        return _votingPowerAt(balanceOf(account), block.timestamp);
    }

    /**
     * @notice Gets the voting power of the provided account at the given timestamp
     * @dev To calculate voting power at any timestamp provided the contract stores each balance
     * as it was staked for the maximum lock time. If a staker locks its stake for less than the maximum
     * then at the moment of deposit its balance is recorded as it was staked for the maximum but time
     * equal to `max lock period-lock time` has passed. It makes available voting power calculation
     * available at any point in time within the maximum lock period.
     * @param account The address of an account to get voting power for
     * @param timestamp The timestamp to calculate voting power at
     * @return votingPower The voting power available at the moment of `timestamp`
     */
    function votingPowerOfAt(address account, uint256 timestamp) external view returns (uint256) {
        return _votingPowerAt(balanceOf(account), timestamp);
    }

    /**
     * @notice Gets the voting power for the provided balance at the current timestamp assuming that
     * the balance is a balance at the moment of the maximum lock time
     * @param balance The balance for the maximum lock time
     * @return votingPower The voting power available at the block timestamp
     */
    function votingPower(uint256 balance) external view returns (uint256) {
        return _votingPowerAt(balance, block.timestamp);
    }

    /**
     * @notice Gets the voting power for the provided balance at the current timestamp assuming that
     * the balance is a balance at the moment of the maximum lock time
     * @param balance The balance for the maximum lock time
     * @param timestamp The timestamp to calculate the voting power at
     * @return votingPower The voting power available at the block timestamp
     */
    function votingPowerAt(uint256 balance, uint256 timestamp) external view returns (uint256) {
        return _votingPowerAt(balance, timestamp);
    }

    /**
     * @notice Stakes given amount and locks it for the given duration
     * @param amount The amount of tokens to stake
     * @param duration The lock period in seconds. If there is a stake locked then the lock period is extended by the duration.
     * To keep the current lock period unchanged pass 0 for the duration.
     */
    function deposit(uint256 amount, uint256 duration) external {
        _deposit(msg.sender, amount, duration);
    }

    /**
     * @notice Stakes given amount and locks it for the given duration with permit
     * @param amount The amount of tokens to stake
     * @param duration The lock period in seconds. If there is a stake locked then the lock period is extended by the duration.
     * To keep the current lock period unchanged pass 0 for the duration
     * @param permit Permit given by the staker
     */
    function depositWithPermit(uint256 amount, uint256 duration, bytes calldata permit) external {
        oneInch.safePermit(permit);
        _deposit(msg.sender, amount, duration);
    }


    /**
     * @notice Stakes given amount on behalf of provided account without locking or extending lock
     * @param account The account to stake for
     * @param amount The amount to stake
     */
    function depositFor(address account, uint256 amount) external {
        _deposit(account, amount, 0);
    }

    /**
     * @notice Stakes given amount on behalf of provided account without locking or extending lock with permit
     * @param account The account to stake for
     * @param amount The amount to stake
     * @param permit Permit given by the caller
     */
    function depositForWithPermit(address account, uint256 amount, bytes calldata permit) external {
        oneInch.safePermit(permit);
        _deposit(account, amount, 0);
    }

    function _deposit(address account, uint256 amount, uint256 duration) private {
        if (emergencyExit) revert DepositsDisabled();
        Depositor memory depositor = depositors[account]; // SLOAD

        uint256 lockedTill = Math.max(depositor.unlockTime, block.timestamp) + duration;
        uint256 lockLeft = lockedTill - block.timestamp;
        if (lockLeft < MIN_LOCK_PERIOD) revert LockTimeLessMinLock();
        if (lockLeft > MAX_LOCK_PERIOD) revert LockTimeMoreMaxLock();
        uint256 balanceDiff = _balanceAt(depositor.amount + amount, lockedTill) / _VOTING_POWER_DIVIDER - balanceOf(account);

        depositor.unlockTime = uint40(lockedTill);
        depositor.amount += uint216(amount);
        depositors[account] = depositor; // SSTORE
        totalDeposits += amount;
        _mint(account, balanceDiff);

        if (amount > 0) {
            oneInch.safeTransferFrom(msg.sender, address(this), amount);
        }

        if (defaultFarm != address(0) && !hasPod(account, defaultFarm)) {
            _addPod(account, defaultFarm);
        }
    }

    /**
     * @notice Withdraw stake before lock period expires at the cost of losing part of a stake.
     * The stake loss is proportional to the time passed from the maximum lock period to the lock expiration and voting power.
     * The more time is passed the less would be the loss.
     * Formula to calculate return amount = (deposit - voting power)) / 0.95
     * @param minReturn The minumum amount of stake acceptable for return. If actual amount is less then the transaction is reverted
     * @param maxLoss The maximum amount of loss acceptable. If actual loss is bigger then the transaction is reverted
     */
    function earlyWithdraw(uint256 minReturn, uint256 maxLoss) external {
        earlyWithdrawTo(msg.sender, minReturn, maxLoss);
    }

    /**
     * @notice Withdraw stake before lock period expires at the cost of losing part of a stake to the specified account
     * The stake loss is proportional to the time passed from the maximum lock period to the lock expiration and voting power.
     * The more time is passed the less would be the loss.
     * Formula to calculate return amount = (deposit - voting power)) / 0.95
     * @param to The account to withdraw the stake to
     * @param minReturn The minumum amount of stake acceptable for return. If actual amount is less then the transaction is reverted
     * @param maxLoss The maximum amount of loss acceptable. If actual loss is bigger then the transaction is reverted
     */
    // ret(balance) = (deposit - vp(balance)) / 0.95
    function earlyWithdrawTo(address to, uint256 minReturn, uint256 maxLoss) public {
        Depositor memory depositor = depositors[msg.sender]; // SLOAD
        if (emergencyExit || block.timestamp >= depositor.unlockTime) revert StakeUnlocked();
        uint256 amount = depositor.amount;
        if (amount > 0) {
            uint256 balance = balanceOf(msg.sender);
            (uint256 loss, uint256 ret) = _earlyWithdrawLoss(amount, balance);
            if (ret < minReturn) revert MinReturnIsNotMet();
            if (loss > maxLoss) revert MaxLossIsNotMet();
            if (loss > amount * maxLossRatio / _ONE) revert LossIsTooBig();

            _withdraw(depositor, balance);
            oneInch.safeTransfer(to, ret);
            oneInch.safeTransfer(feeReceiver, loss);
        }
    }

    /**
     * @notice Gets the loss amount if the staker do early withdrawal at the current block
     * @param account The account to calculate early withdrawal loss for
     * @return loss The loss amount amount
     * @return ret The return amount
     * @return canWithdraw  True if the staker can withdraw without penalty, false otherwise
     */
    function earlyWithdrawLoss(address account) external view returns (uint256 loss, uint256 ret, bool canWithdraw) {
        uint256 amount = depositors[account].amount;
        (loss, ret) = _earlyWithdrawLoss(amount, balanceOf(account));
        canWithdraw = loss <= amount * maxLossRatio / _ONE;
    }

    function _earlyWithdrawLoss(uint256 depAmount, uint256 stBalance) private view returns (uint256 loss, uint256 ret) {
        ret = (depAmount - _votingPowerAt(stBalance, block.timestamp)) * 100 / 95;
        loss = depAmount - ret;
    }

    /**
     * @notice Withdraws stake if lock period expired
     */
    function withdraw() external {
        withdrawTo(msg.sender);
    }

    /**
     * @notice Withdraws stake if lock period expired to the given address
     */
    function withdrawTo(address to) public {
        Depositor memory depositor = depositors[msg.sender]; // SLOAD
        if (!emergencyExit && block.timestamp < depositor.unlockTime) revert UnlockTimeHasNotCome();

        uint256 amount = depositor.amount;
        if (amount > 0) {
            _withdraw(depositor, balanceOf(msg.sender));
            oneInch.safeTransfer(to, amount);
        }
    }

    function _withdraw(Depositor memory depositor, uint256 balance) private {
        totalDeposits -= depositor.amount;
        depositor.amount = 0;
        // keep unlockTime in storage for next tx optimization
        depositor.unlockTime = uint40(Math.min(depositor.unlockTime, block.timestamp));
        depositors[msg.sender] = depositor; // SSTORE
        _burn(msg.sender, balance);
    }

    /**
     * @notice Retrieves funds from the contract in emergency situations
     * @param token The token to retrieve
     * @param amount The amount of funds to transfer
     */
    function rescueFunds(IERC20 token, uint256 amount) external onlyOwner {
        if (address(token) == address(0)) {
            Address.sendValue(payable(msg.sender), amount);
        } else {
            if (token == oneInch) {
                if (amount > oneInch.balanceOf(address(this)) - totalDeposits) revert RescueAmountIsTooLarge();
            }
            token.safeTransfer(msg.sender, amount);
        }
    }

    // ERC20 methods disablers

    function approve(address, uint256) public pure override(IERC20, ERC20) returns (bool) {
        revert ApproveDisabled();
    }

    function transfer(address, uint256) public pure override(IERC20, ERC20) returns (bool) {
        revert TransferDisabled();
    }

    function transferFrom(address, address, uint256) public pure override(IERC20, ERC20) returns (bool) {
        revert TransferDisabled();
    }

    function increaseAllowance(address, uint256) public pure override returns (bool) {
        revert ApproveDisabled();
    }

    function decreaseAllowance(address, uint256) public pure override returns (bool) {
        revert ApproveDisabled();
    }
}