// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IAnteTest.sol";

/// @title The interface for Ante V0.6 Ante Pool
/// @notice The Ante Pool handles interactions with connected Ante Test
interface IAntePool {
    /// @notice Emitted when a user adds to the stake pool
    /// @param staker The address of user
    /// @param amount Amount being added in wei
    /// @param commitTime The minimum staking time commitment
    event Stake(address indexed staker, uint256 amount, uint256 commitTime);

    /// @notice Emitted when a user extends his stake commitment
    /// @param staker The address of user
    /// @param additionalTime The additional commitment time
    /// @param commitTime The new minimum staking time commitment
    event ExtendStake(address indexed staker, uint256 additionalTime, uint256 commitTime);

    /// @notice Emitted when a user adds to the challenge pool
    /// @param challenger The address of user
    /// @param amount Amount being added in wei
    event RegisterChallenge(address indexed challenger, uint256 amount);

    /// @notice Emitted when a challenging user confirms their challenge
    /// @param challenger The address of user
    /// @param confirmedShares The amount of shares that were confirmed in wei
    event ConfirmChallenge(address indexed challenger, uint256 confirmedShares);

    /// @notice Emitted when a user removes from the stake or challenge pool
    /// @param staker The address of user
    /// @param amount Amount being removed in wei
    /// @param isChallenger Whether or not this is removed from the challenger pool
    event Unstake(address indexed staker, uint256 amount, bool indexed isChallenger);

    /// @notice Emitted when the connected Ante Test's invariant gets verified
    /// @param checker The address of challenger who called the verification
    event TestChecked(address indexed checker);

    /// @notice Emitted when the connected Ante Test has failed test verification
    /// @param checker The address of challenger who called the verification
    event FailureOccurred(address indexed checker);

    /// @notice Emitted when a challenger claims their payout for a failed test
    /// @param claimer The address of challenger claiming their payout
    /// @param amount Amount being claimed in wei
    event ClaimPaid(address indexed claimer, uint256 amount);

    /// @notice Emitted when the test author claims their reward for a test
    /// @param author The address of auther claiming their reward
    /// @param amount Amount being claimed in wei
    event RewardPaid(address indexed author, uint256 amount);

    /// @notice Emitted when a staker has withdrawn their stake after the 24 hour wait period
    /// @param staker The address of the staker removing their stake
    /// @param amount Amount withdrawn in wei
    event WithdrawStake(address indexed staker, uint256 amount);

    /// @notice Emitted when a staker cancels their withdraw action before the 24 hour wait period
    /// @param staker The address of the staker cancelling their withdraw
    /// @param amount Amount cancelled in wei
    event CancelWithdraw(address indexed staker, uint256 amount);

    /// @notice emited when decay paid to stakers is updated
    /// @param decayThisUpdate total decay accrued to stakers this update
    /// @param challengerMultiplier new challenger decay multiplier
    /// @param stakerMultiplier new staker decay multiplier
    event DecayUpdated(uint256 decayThisUpdate, uint256 challengerMultiplier, uint256 stakerMultiplier);

    /// @notice emited when decay starts to accumulate
    event DecayStarted();

    /// @notice emited when decay stops being accumulated
    event DecayPaused();

    /// @notice Initializes Ante Pool with the connected Ante Test
    /// @param _anteTest The Ante Test that will be connected to the Ante Pool
    /// @param _token The ERC20 token used for transacting with the Ante Pool
    /// @param _decayRate The annualized challenger decay rate expressed as precentage (x%) of total challenge
    /// @param _payoutRatio The minimum totalStake:totalChallenge ratio allowed for the Ante Pool
    /// @param _testAuthorRewardRate The test author reward rate expressed as a percentage (x%) of the decay
    /// @dev This function requires that the Ante Test address is valid and that
    /// the invariant validation currently passes
    function initialize(
        IAnteTest _anteTest,
        IERC20 _token,
        uint256 _tokenMinimum,
        uint256 _decayRate,
        uint256 _payoutRatio,
        uint256 _testAuthorRewardRate
    ) external;

    /// @notice Cancels a withdraw action of a staker
    /// @dev This is called when a staker has initiated a withdraw stake action but
    /// then decides to cancel that withdraw
    function cancelPendingWithdraw() external;

    /// @notice Runs the verification of the invariant of the connected Ante Test
    /// without updating the state
    /// @dev Can only be called by a challenger who has challenged the Ante Test
    function checkTest() external;

    /// @notice Runs the verification of the invariant of the connected Ante Test
    /// @param _testState The encoded data required to set the test state
    /// @dev Can only be called by a challenger who has challenged the Ante Test
    function checkTestWithState(bytes memory _testState) external;

    /// @notice Claims the payout of a failed Ante Test
    /// @dev To prevent double claiming, the challenger balance is checked before
    /// claiming and that balance is zeroed out once the claim is done
    function claim() external;

    /// @notice Claims the reward for an Ante Test
    /// @dev To prevent double claiming, the author reward is checked before
    /// claiming and that balance is zeroed out once the claim is done
    function claimReward() external;

    /// @notice Adds a users's stake to the staker pool
    /// @param amount Amount to stake
    /// @param commitTime Time in seconds before the stake can be unstaked again
    function stake(uint256 amount, uint256 commitTime) external;

    /// @notice Extend a staker commitment time by additional time
    /// @param additionalTime Time in seconds to add to the current commitment lock
    function extendStakeLock(uint256 additionalTime) external;

    /// @notice Registers a user's challenge to the challenger pool
    /// @dev confirmChallenge() must be called after MIN_CHALLENGER_DELAY to confirm
    /// the challenge.
    /// @param amount The amount to challenge, denominated in the ERC20 Token of the AntePool
    function registerChallenge(uint256 amount) external;

    /// @notice Confirms a challenger's previously registered challenge
    /// @dev Must be called after at least MIN_CHALLENGER_DELAY seconds to confirm
    /// the challenge.
    function confirmChallenge() external;

    /// @notice Removes a user's stake or challenge from the staker or challenger pool
    /// @param amount Amount being removed in wei
    /// @param isChallenger Flag for if this is a challenger
    function unstake(uint256 amount, bool isChallenger) external;

    /// @notice Removes all of a user's stake or challenge from the respective pool
    /// @param isChallenger Flag for if this is a challenger
    function unstakeAll(bool isChallenger) external;

    /// @notice Updates the decay multipliers and amounts for the total staked and challenged pools
    /// @dev This function is called in most other functions as well to keep the
    /// decay amounts and pools accurate
    function updateDecay() external;

    /// @notice Updates the verified state of this pool when a verification is triggered
    /// @param _verifier The address of who called the test verification
    /// @dev This function is called from the AntePoolFactory to set the pool's verification state.
    function updateVerifiedState(address _verifier) external;

    /// @notice Updates the failure state of this pool after the associated ante test has failed
    /// @param _verifier The address of who called the test verification
    /// @dev This function is called from the AntePoolFactory to propagate the failure state to
    /// all linked ante pools as soon as a checkTest() call has failed on a single AntePool
    function updateFailureState(address _verifier) external;

    /// @notice Initiates the withdraw process for a staker, starting the 24 hour waiting period
    /// @dev During the 24 hour waiting period, the value is locked to prevent
    /// users from removing their stake when a challenger is going to verify test
    function withdrawStake() external;

    /// @notice Returns the Ante Test connected to this Ante Pool
    /// @return IAnteTest The Ante Test interface
    function anteTest() external view returns (IAnteTest);

    /// @notice Returns the annualized challenger decay rate expressed as a precentage (x%) of challenger pool
    /// @return The decay rate of the challenger side
    function decayRate() external view returns (uint256);

    /// @notice Returns the minimum totalStake:totalChallenge ratio allowed for the Ante Pool
    /// @return The challenger payout ratio
    function challengerPayoutRatio() external view returns (uint256);

    /// @notice Returns the test author reward rate on this Ante Pool, expressed as a percentage (x%) of the decay
    /// @return The test author reward rate
    function testAuthorRewardRate() external view returns (uint256);

    /// @notice Returns the available rewards to be claimed by the test author
    /// @return The amount of tokens available to be claimed
    function getTestAuthorReward() external view returns (uint256);

    /// @notice Get the info for the challenger pool
    /// @return numUsers The total number of challengers in the challenger pool
    ///         totalAmount The total value locked in the challenger pool in wei
    ///         decayMultiplier The current multiplier for decay
    function challengerInfo() external view returns (uint256 numUsers, uint256 totalAmount, uint256 decayMultiplier);

    /// @notice Get the info for the staker pool
    /// @return numUsers The total number of stakers in the staker pool
    ///         totalAmount The total value locked in the staker pool in wei
    ///         decayMultiplier The current multiplier for decay
    function stakingInfo() external view returns (uint256 numUsers, uint256 totalAmount, uint256 decayMultiplier);

    /// @notice Get the total value eligible for payout
    /// @dev This is used so that challengers must have challenged for at least
    /// 12 blocks to receive payout, this is to mitigate other challengers
    /// from trying to stick in a challenge right before the verification
    /// @return eligibleAmount Total value eligible for payout in wei
    function eligibilityInfo() external view returns (uint256 eligibleAmount);

    /// @notice Returns the Ante Pool factory address that created this Ante Pool
    /// @return Address of Ante Pool factory
    function factory() external view returns (address);

    /// @notice Returns the block at which the connected Ante Test failed
    /// @dev This is only set when a verify test action is taken, so the test could
    /// have logically failed beforehand, but without having a user initiating
    /// the verify test action
    /// @return Block number where Ante Test failed
    function failedBlock() external view returns (uint256);

    /// @notice Returns the timestamp at which the connected Ante Test failed
    /// @dev This is only set when a verify test action is taken, so the test could
    /// have logically failed beforehand, but without having a user initiating
    /// the verify test action
    /// @return Seconds since epoch when Ante Test failed
    function failedTimestamp() external view returns (uint256);

    /// @notice Returns info for a specific challenger
    /// @param challenger Address of challenger
    function getChallengerInfo(
        address challenger
    )
        external
        view
        returns (
            uint256 startAmount,
            uint256 lastStakedTimestamp,
            uint256 claimableShares,
            uint256 claimableSharesStartMultiplier
        );

    /// @notice Returns the payout amount for a specific challenger
    /// @param challenger Address of challenger
    /// @dev If this is called before an Ante Test has failed, then it's return
    /// value is an estimate
    /// @return Amount that could be claimed by challenger in wei
    function getChallengerPayout(address challenger) external view returns (uint256);

    /// @notice Returns the timestamp for when the staker's 24 hour wait period is over
    /// @param _user Address of withdrawing staker
    /// @dev This is timestamp is 24 hours after the time when the staker initaited the
    /// withdraw process
    /// @return Timestamp for when the value is no longer locked and can be removed
    function getPendingWithdrawAllowedTime(address _user) external view returns (uint256);

    /// @notice Returns the timestamp for when the staker's time commitment expires
    /// @param _user Address of staker
    /// @dev This timestamp is the commitTime after the time the staker initially staked
    /// @return Timestamp for when the stake is no longer locked and can be unstaked
    function getUnstakeAllowedTime(address _user) external view returns (uint256);

    /// @notice Returns the amount a staker is attempting to withdraw
    /// @param _user Address of withdrawing staker
    /// @return Amount which is being withdrawn in wei
    function getPendingWithdrawAmount(address _user) external view returns (uint256);

    /// @notice Returns the stored balance of a user in their respective pool
    /// @param _user Address of user
    /// @param isChallenger Flag if user is a challenger
    /// @dev This function calculates decay and returns the stored value after the
    /// decay has been either added (staker) or subtracted (challenger)
    /// @return Balance that the user has currently in wei
    function getStoredBalance(address _user, bool isChallenger) external view returns (uint256);

    /// @notice Returns total value of eligible payout for challengers
    /// @return Amount eligible for payout in wei
    function getTotalChallengerEligibleBalance() external view returns (uint256);

    /// @notice Returns total value locked of all challengers
    /// @return Total amount challenged in wei
    function getTotalChallengerStaked() external view returns (uint256);

    /// @notice Returns total value of all stakers who are withdrawing their stake
    /// @return Total amount waiting for withdraw in wei
    function getTotalPendingWithdraw() external view returns (uint256);

    /// @notice Returns total value locked of all stakers
    /// @return Total amount staked in wei
    function getTotalStaked() external view returns (uint256);

    /// @notice Returns a user's starting amount added in their respective pool
    /// @param _user Address of user
    /// @param isChallenger Flag if user is a challenger
    /// @dev This value is updated as decay is caluclated or additional value
    /// added to respective side
    /// @return User's starting amount in wei
    function getUserStartAmount(address _user, bool isChallenger) external view returns (uint256);

    /// @notice Returns a user's starting decay multiplier
    /// @param _user Address of user
    /// @param isChallenger Flag if user is a challenger
    /// @dev This value is updated as decay is calculated or additional value
    /// added to respective side
    /// @return User's starting decay multiplier
    function getUserStartDecayMultiplier(address _user, bool isChallenger) external view returns (uint256);

    /// @notice Returns the verifier bounty amount
    /// @dev Currently this is 5% of the total staked amount
    /// @return Bounty amount rewarded to challenger who verifies test in wei
    function getVerifierBounty() external view returns (uint256);

    /// @notice Returns the cutoff block when challenger can call verify test
    /// @dev This is currently 12 blocks after a challenger has challenged the test
    /// @return Block number of when verify test can be called by challenger
    function getCheckTestAllowedBlock(address _user) external view returns (uint256);

    /// @notice Returns the most recent block number where decay was updated
    /// @dev This is generally updated on most actions that interact with the Ante
    /// Pool contract
    /// @return Block number of when contract was last updated
    function lastUpdateBlock() external view returns (uint256);

    /// @notice Returns the most recent timestamp where decay was updated
    /// @dev This is generally updated on most actions that interact with the Ante
    /// Pool contract
    /// @return Number of seconds since epoch of when contract was last updated
    function lastUpdateTimestamp() external view returns (uint256);

    /// @notice Returns the minimum allowed challenger stake
    /// @dev Minimum challenger stake is token based and is configured in AntePoolFactoryController
    /// @return The minimum amount that a challenger can stake
    function minChallengerStake() external view returns (uint256);

    /// @notice Returns the minimum allowed support stake
    /// @dev Minimum support stake is derived from the challengerPayoutRatio and minChallengerStake
    /// @return The minimum amount that a supporter can stake
    function minSupporterStake() external view returns (uint256);

    /// @notice Returns the most recent block number where a challenger verified test
    /// @dev This is updated whenever the verify test is activated, whether or not
    /// the Ante Test fails
    /// @return Block number of last verification attempt
    function lastVerifiedBlock() external view returns (uint256);

    /// @notice Returns the most recent timestamp when a challenger verified test
    /// @dev This is updated whenever the verify test is activated, whether or not
    /// the Ante Test fails
    /// @return Seconds since epoch of last verification attempt
    function lastVerifiedTimestamp() external view returns (uint256);

    /// @notice Returns the number of challengers that have claimed their payout
    /// @return Number of challengers
    function numPaidOut() external view returns (uint256);

    /// @notice Returns the number of times that the Ante Test has been verified
    /// @return Number of verifications
    function numTimesVerified() external view returns (uint256);

    /// @notice Returns if the connected Ante Test has failed
    /// @return True if the connected Ante Test has failed, False if not
    function pendingFailure() external view returns (bool);

    /// @notice Returns the total value of payout to challengers that have been claimed
    /// @return Value of claimed payouts in wei
    function totalPaidOut() external view returns (uint256);

    /// @notice Returns the ERC20 token used for transacting with the pool
    /// @return IERC20 interface of the token
    function token() external view returns (IERC20);

    /// @notice Returns if the decay accumulation is active
    /// @return True if decay accumulation is active
    function isDecaying() external view returns (bool);

    /// @notice Returns the address of verifier who successfully activated verify test
    /// @dev This is the user who will receive the verifier bounty
    /// @return Address of verifier challenger
    function verifier() external view returns (address);

    /// @notice Returns the total value of stakers who are withdrawing
    /// @return totalAmount total amount pending to be withdrawn in wei
    function withdrawInfo() external view returns (uint256 totalAmount);
}