// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IStaking {
    /// @notice This event is emitted when the controller is set.
    /// @param controller Controller address
    event ControllerSet(address controller);

    /// @notice This event is emitted when a staker adds stake to the pool.
    /// @param staker Staker address
    /// @param newStake New principal amount staked
    /// @param totalStake Total principal amount staked
    event Staked(address staker, uint256 newStake, uint256 totalStake);
    /// @notice This event is emitted when a staker exits the pool.
    /// @param staker Staker address
    /// @param principal Principal amount frozen after unstaking
    /// @param baseReward base reward earned
    /// @param delegationReward delegation reward earned, if any
    event Unstaked(address staker, uint256 principal, uint256 baseReward, uint256 delegationReward);

    /// @notice This event is emitted when a staker claims base reward.
    /// @param staker Staker address
    /// @param baseReward Base reward amount claimed
    event RewardClaimed(address staker, uint256 baseReward);

    /// @notice This event is emitted when a staker claims frozen principal.
    /// @param staker Staker address
    /// @param principal Principal amount claimed
    event FrozenPrincipalClaimed(address staker, uint256 principal);

    /// @notice This error is thrown whenever an address does not have access
    /// to successfully execute a transaction
    error AccessForbidden();

    /// @notice This error is thrown whenever a zero-address is supplied when
    /// a non-zero address is required
    error InvalidZeroAddress();

    /// @notice This error is thrown whenever the sender is not controller contract
    error SenderNotController();

    /// @notice This function allows stakers to stake.
    function stake(uint256 amount) external;

    /// @notice This function allows stakers to unstake.
    /// It returns base and delegation rewards, and makes principle frozen for later claiming.
    function unstake(uint256 amount) external;

    /// @notice This function allows community stakers to claim base rewards and frozen principals(if any).
    function claim() external;

    /// @notice This function allows stakers to claim base rewards.
    function claimReward() external;

    /// @notice This function allows stakers to claim frozen principals.
    function claimFrozenPrincipal() external;

    /// @return address ARPA token contract's address that is used by the pool
    function getArpaToken() external view returns (address);

    /// @param staker address
    /// @return uint256 staker's staked principal amount
    function getStake(address staker) external view returns (uint256);

    /// @notice Returns true if an address is an operator
    function isOperator(address staker) external view returns (bool);

    /// @notice The staking pool starts closed and only allows
    /// stakers to stake once it's opened
    /// @return bool pool status
    function isActive() external view returns (bool);

    /// @return uint256 current maximum staking pool size
    function getMaxPoolSize() external view returns (uint256);

    /// @return uint256 minimum amount that can be staked by a community staker
    /// @return uint256 maximum amount that can be staked by a community staker
    function getCommunityStakerLimits() external view returns (uint256, uint256);

    /// @return uint256 amount that should be staked by an operator
    function getOperatorLimit() external view returns (uint256);

    /// @return uint256 reward initialization timestamp
    /// @return uint256 reward expiry timestamp
    function getRewardTimestamps() external view returns (uint256, uint256);

    /// @return uint256 current reward rate, expressed in arpa weis per second
    function getRewardRate() external view returns (uint256);

    /// @return uint256 current delegation rate
    function getDelegationRateDenominator() external view returns (uint256);

    /// @return uint256 total amount of ARPA tokens made available for rewards in
    /// ARPA wei
    /// @dev This reflects how many rewards were made available over the
    /// lifetime of the staking pool.
    function getAvailableReward() external view returns (uint256);

    /// @return uint256 amount of base rewards earned by a staker in ARPA wei
    function getBaseReward(address) external view returns (uint256);

    /// @return uint256 amount of delegation rewards earned by an operator in ARPA wei
    function getDelegationReward(address) external view returns (uint256);

    /// @notice Total delegated amount is calculated by dividing the total
    /// community staker staked amount by the delegation rate, i.e.
    /// totalDelegatedAmount = pool.totalCommunityStakedAmount / delegationRateDenominator
    /// @return uint256 staked amount that is used when calculating delegation rewards in ARPA wei
    function getTotalDelegatedAmount() external view returns (uint256);

    /// @notice Delegates count increases after an operator is added to the list
    /// of operators and stakes the required amount.
    /// @return uint256 number of staking operators that are eligible for delegation rewards
    function getDelegatesCount() external view returns (uint256);

    /// @notice This count all community stakers that have a staking balance greater than 0.
    /// @return uint256 number of staking community stakers that are eligible for base rewards
    function getCommunityStakersCount() external view returns (uint256);

    /// @return uint256 total amount staked by community stakers and operators in ARPA wei
    function getTotalStakedAmount() external view returns (uint256);

    /// @return uint256 total amount staked by community stakers in ARPA wei
    function getTotalCommunityStakedAmount() external view returns (uint256);

    /// @return uint256 the sum of frozen operator principals that have not been
    /// withdrawn from the staking pool in ARPA wei.
    /// @dev Used to make sure that contract's balance is correct.
    /// total staked amount + total frozen amount + available rewards = current balance
    function getTotalFrozenAmount() external view returns (uint256);

    /// @return amounts total amounts of ARPA wei that is currently frozen by the staker
    /// @return unlockTimestamps timestamps when the frozen principal can be withdrawn
    function getFrozenPrincipal(address)
        external
        view
        returns (uint96[] memory amounts, uint256[] memory unlockTimestamps);

    /// @return uint256 amount of ARPA wei that can be claimed as frozen principal by a staker
    function getClaimablePrincipalAmount(address) external view returns (uint256);

    /// @return address controller contract's address that is used by the pool
    function getController() external view returns (address);
}