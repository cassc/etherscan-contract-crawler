// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IDIVAOwnershipShared} from "../interfaces/IDIVAOwnershipShared.sol";

interface IDIVAOwnershipMain is IDIVAOwnershipShared {
    // Thrown in constructor if zero address is provided for initial owner.
    error ZeroOwnerAddress();

    // Thrown in constructor if zero address is provided for the DIVA Token.
    error ZeroDIVATokenAddress();
    
    // Thrown in `stake` or `unstake` if called during the ownership claim
    // submission period
    error WithinSubmitOwnershipClaimPeriod(
        uint256 _timestampBlock,
        uint256 _submitOwnershipClaimPeriodEnd
    );

    // Thrown in `submitOwnershipClaim` if called outside of the ownership
    // claim submission period
    error NotWithinSubmitOwnershipClaimPeriod();

    // Thrown in `triggerElectionCycle` if called during an on-going election cycle
    error WithinElectionCycle(
        uint256 _timestampBlock,
        uint256 _submitOwnershipClaimPeriodEnd
    );

    // Thrown in `triggerElectionCycle` if called during the cooldown period (7 days
    // following the election cycle end)
    error WithinCooldownPeriod(
        uint256 _timestampBlock,
        uint256 _cooldownPeriodEnd
    );

    // Thrown in `unstake` if minimum staking period has not expired yet
    error MinStakingPeriodNotExpired(
        uint256 _timestampBlock,
        uint256 _minStakingPeriodEnd
    );

    // Thrown in `triggerElectionCycle` if `msg.sender` has not strictly more stake
    // than the current owner
    error InsufficientStakingSupport();

    // Thrown in `submitOwnershipClaim` if another candidate has more stake or
    // was already triggered by another candidate that has the same stake
    error NotLeader();

    /**
     * @notice Emitted when a user stakes for a candidate.
     * @param by The address of the user that staked.
     * @param candidate The address of the candidate that was staked for.
     * @param amount The voting token amount staked.
     */
    event Staked(address indexed by, address indexed candidate, uint256 amount);

    /**
     * @notice Emitted when a user reduces his stake for a candidate.
     * @param by The address of the user that unstaked.
     * @param candidate The address of the candidate that stake was reduced for.
     * @param amount The voting token amount unstaked.
     */
    event Unstaked(address indexed by, address indexed candidate, uint256 amount);

    /**
     * @notice Emitted when a candidate triggers the election cycle.
     * @param candidate The address that triggered the election cycle.
     * @param startTime Start time of the election cycle.
     */
    event ElectionCycleTriggered(address indexed candidate, uint256 startTime);

    /**
     * @notice Emitted when a candidate submits an ownership claim.
     * @param candidate The address of the candidate that submitted the
     * ownership claim.
     */
    event OwnershipClaimSubmitted(address indexed candidate);

    /**
     * @notice Function to stake voting tokens for a contract owner candidate. Requires
     * prior approval from `msg.sender` to transfer voting token.
     * @dev To protect against flash loans triggering voting rounds,
     * a minimum staking period of 7 days has been implemented. Staking is
     * disabled during ownership claim submission periods.
     * @param _candidate Address of contract owner candidate to stake fore.
     * @param _amount Incremental boting token amount to stake.
     */
    function stake(address _candidate, uint256 _amount) external;

    /**
     * @notice Function to reduce the stake for a contract owner candidate.
     * @param _candidate Address of candidate to reduce stake for.
     * @param _amount Staking amount to reduce.
     */
    function unstake(address _candidate, uint256 _amount) external;

    /**
     * @notice Function to trigger an election cycle. Can be triggered by anyone
     * that has strictly more stake than the current contract owner.
     */
    function triggerElectionCycle() external;

    /**
     * @notice Function for candidates to submit their ownership claim.
     * Reverts if `msg.sender`'s stake is smaller than the current leading candidate's one.
     * Note that in the event that the existing contract owner maintains the majority,
     * it is not necessary to trigger this function as they are set as the leading
     * candidate when `triggerElectionCycle` is triggered.
     */
    function submitOwnershipClaim() external;

    /**
     * @notice Function to return the amount staked by a given `_voter` for a given `_candidate`.
     * @param _voter Voter address.
     * @param _candidate Candidate address.
     * @return Staked amount for `_candidate` by `_voter`.
     */
    function getStakedAmount(address _voter, address _candidate)
        external
        view
        returns (uint256);

    /**
     * @notice Function to return the amount staked for a given `_candidate`.
     * @param _candidate Candidate address.
     * @return Staked amount for `_candidate`.
     */
    function getStakedAmount(address _candidate)
        external
        view
        returns (uint256);

    /**
     * @notice Function to get the timestamp of the last stake operation for a
     * given `_user` and `candidate`.
     * @return Timestamp in seconds since epoch.
     */
    function getTimestampLastStakedForCandidate(
        address _user,
        address _candidate
    )
        external
        view
        returns (uint256);

    /**
     * @notice Function to return the showdown period end.
     * @return Timestamp in seconds since epoch.
     */
    function getShowdownPeriodEnd() external view returns (uint256);

    /**
     * @notice Function to return the ownership claim submission period end.
     * @return Timestamp in seconds since epoch.
     */
    function getSubmitOwnershipClaimPeriodEnd() external view returns (uint256);

    /**
     * @notice Function to return the cooldown period end.
     * @return Timestamp in seconds since epoch.
     */
    function getCooldownPeriodEnd() external view returns (uint256);

    /**
     * @notice Function to return the DIVA token address that is used for voting.
     * @return The address of the DIVA token.
     */
    function getDIVAToken() external view returns (address);

    /**
     * @notice Function to return the showdown period length in seconds (30 days).
     * @return Period length in seconds.
     */
    function getShowdownPeriod() external pure returns (uint256);

    /**
     * @notice Function to return the ownership claim submission period length
     * in seconds (7 days).
     * @return Period length in seconds.
     */
    function getSubmitOwnershipClaimPeriod() external pure returns (uint256);

    /**
     * @notice Function to return the cooldown period length in seconds (7 days)
     * during which no new election cycle can be triggered following the end of an
     * election cycle.
     * @return Period length in seconds.
     */
    function getCooldownPeriod() external pure returns (uint256);

    /**
     * @notice Function to return the minimum staking period (7 days).
     * @return Period length in seconds.
     */
    function getMinStakingPeriod() external pure returns (uint256);
}