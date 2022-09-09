//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../external/IERC677Receiver.sol";
import "../external/IERC677Token.sol";
import "../lib/Utils.sol";
import "../upgrade/FsBase.sol";

/// @notice `TokenLocker` allows for tokens to be locked up by the user for a
///         selected period of time.
///
///         Users receive portion of the locked function that is 1/(X^2), where X is the lock time
///         divided by the max lock time.  This way, locking for half of the max lock time would
///         give the user 1/4 of the locked balance.  And locking for the full max time will provide
///         all of the balance.
///
///         Excessive balance is transferred to the `treasury`.
contract TokenLocker is FsBase, IERC677Receiver {
    using SafeERC20 for IERC20;

    /// @notice The staking token that this contract uses
    IERC20 public rewardsToken;

    /// @notice The max lockup time which will yield 100% reward to users
    uint256 public maxLockupTime;

    /// @notice The address of the treasury of the FST protocol
    address public treasury;

    /// @notice A mapping of rewards mapped by user address and checkoutId
    ///         The newest checkout id can be obtained from requestIdByAddress
    mapping(address => mapping(uint256 => Lockup)) public lockupByAddressById;
    /// @notice The latest unused checkout id for an address
    mapping(address => uint256) public requestIdByAddress;

    // A lockup of tokens that is available to the user after a given timestamp
    struct Lockup {
        // The amount of tokens that will be available
        uint128 amount;
        // The timstamp at which the lockup can be checked out
        uint64 availTimestamp;
    }

    // Struct used for onTokenTransfer to start a lockup
    struct AddLockup {
        // The duration of the lockup
        uint256 lockupTime;
        // The receiver of the tokens once the lockup time has passed
        address receiver;
    }

    /// @dev Initialize a new TokenLocker
    /// @param _treasury The address of the treasury, forfeited tokens are sent to this address
    /// @param _rewardToken The address of the rewards token
    function initialize(address _treasury, address _rewardToken) external initializer {
        maxLockupTime = 52 weeks;
        // slither-disable-next-line missing-zero-check
        treasury = nonNull(_treasury);
        // slither-disable-next-line missing-zero-check
        rewardsToken = IERC20(nonNull(_rewardToken));

        initializeFsOwnable();
    }

    /// @notice Accepts token transfers together with lockup data
    /// @notice _amount The amount of token being transferred in
    /// @notice _data An endcoded version of AddLockup struct
    function onTokenTransfer(
        address,
        uint256 _amount,
        bytes calldata _data
    ) external override returns (bool success) {
        require(msg.sender == address(rewardsToken), "WT");

        AddLockup memory al = abi.decode(_data, (AddLockup));

        address account = al.receiver;
        uint256 lockupTime = al.lockupTime;

        // If there is no lockup time send the tokens directly to the user
        if (maxLockupTime == 0) {
            IERC20(rewardsToken).safeTransfer(account, _amount);
            return true;
        }

        if (lockupTime > maxLockupTime) {
            lockupTime = maxLockupTime;
        }

        uint256 base = (lockupTime * 1 ether) / maxLockupTime;
        uint256 squared = (base * base) / 1 ether;
        uint256 tokensReceived = (squared * _amount) / 1 ether;
        uint256 tokensForfeited = _amount - tokensReceived;

        require(tokensReceived > 0, "no tokens");

        uint256 time = getTime() + lockupTime;
        uint256 requestId = requestIdByAddress[account]++;

        lockupByAddressById[account][requestId] = Lockup(
            SafeCast.toUint128(tokensReceived),
            SafeCast.toUint64(time)
        );

        emit TokensLockedUp(account, requestId, tokensReceived, time, tokensForfeited);

        // We control the rewardsToken so there is no reentrancy attack, but we
        // defensively order the transfer last anyway.
        if (tokensForfeited > 0) {
            rewardsToken.safeTransfer(treasury, tokensForfeited);
        }

        return true;
    }

    /// @notice Update the max lock up time for rewards tokens
    ///         Note setting a time of zero disables lockup all together and the contract
    ///         directly sends tokens to users on claim
    /// @param _maxLockupTime The new time
    function setMaxLockupTime(uint256 _maxLockupTime) external onlyOwner {
        emit MaxLockupTimeChange(maxLockupTime, _maxLockupTime);
        maxLockupTime = _maxLockupTime;
    }

    /// @notice Returns rewards for a given account and rewardsId
    /// @param _account The account to look up
    /// @param _rewardsId The rewards id to look up
    function getRewards(address _account, uint256 _rewardsId)
        external
        view
        returns (uint256 amount, uint256 availableTimestamp)
    {
        Lockup memory lockup = lockupByAddressById[_account][_rewardsId];
        amount = lockup.amount;
        availableTimestamp = lockup.availTimestamp;
    }

    /// @notice Checkout rewards token for a given account
    /// @param _account the account to claim for
    /// @param _rewardsId index of the claim made
    function checkout(address _account, uint256 _rewardsId) external {
        Lockup storage lockup = lockupByAddressById[_account][_rewardsId];

        require(lockup.amount > 0, "no reward");

        require(getTime() >= lockup.availTimestamp, "Not available yet");

        uint256 amount = lockup.amount;
        lockup.amount = 0;

        emit Checkout(_account, _rewardsId, amount);

        // Note: Ordering in this method matters:
        // We need to ensure that balances are deducted from storage variables
        // before calling the transfer function since we potentially would
        // be susceptible to a reentrancy attack pulling out funds multiple times.
        rewardsToken.safeTransfer(_account, amount);
    }

    function setRewardsToken(address newRewardsToken) external onlyOwner {
        address oldRewardsToken = address(rewardsToken);
        rewardsToken = IERC20(FsUtils.nonNull(newRewardsToken));
        emit RewardsTokenUpdated(oldRewardsToken, address(newRewardsToken));
    }

    // Only overriden in tests
    // Not really sure why Slither detects this as dead code.  It is used in a number of other
    // functions in this contract.  Maybe it is the `virtual` that is confusing it.
    // slither-disable-next-line dead-code
    function getTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @notice Emitted when a user adds tokens to a lockup
    /// @param account The account claiming tokens
    /// @param requestId The request id for the account
    /// @param amount The amount of tokens being claimed
    /// @param availTimestamp when the tokens will be available for checkout
    /// @param tokensForfeited Tokens that have been sent to the treasury
    event TokensLockedUp(
        address indexed account,
        uint256 requestId,
        uint256 amount,
        uint256 availTimestamp,
        uint256 tokensForfeited
    );

    /// @notice Emitted when a user checkouts their locked tokens
    /// @param account The account claiming the tokens
    /// @param requestId The request id for the account
    /// @param amount The amount of tokens being claimed
    event Checkout(address indexed account, uint256 requestId, uint256 amount);

    /// @notice Emitted when maxLockupTime is changed
    /// @param oldMaxLockupTime The old lockup time
    /// @param newMaxLockupTime The new lockup time
    event MaxLockupTimeChange(uint256 oldMaxLockupTime, uint256 newMaxLockupTime);

    /// @notice Event emitted the rewards token is updated.
    /// @param oldRewardsToken The rewards token before the update.
    /// @param newRewardsToken The rewards token after the update.
    event RewardsTokenUpdated(address oldRewardsToken, address newRewardsToken);
}