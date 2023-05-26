// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

/// @notice ICVNXGovernance interface for CVNXGovernance contract.
interface ICVNXGovernance {
    enum PollType {PROPOSAL, EXECUTIVE, EVENT, PRIVATE}
    enum PollStatus {PENDING, APPROVED, REJECTED, DRAW}
    enum VoteType {FOR, AGAINST}

    /// @notice Poll structure.
    struct Poll {
        uint64 pollDeadline;
        uint64 pollStopped;
        PollType pollType;
        address pollOwner;
        string pollInfo;
        uint256 forWeight;
        uint256 againstWeight;
    }

    /// @notice Address vote structure.
    struct Vote {
        VoteType voteType;
        uint256 voteWeight;
    }

    /// @notice Return variable isAvailableToCreate.
    function getIsAvailableToCreate() external view returns (bool);

    /// @notice Enable or disable possibility to create new poll in contract.
    function setIsAvailableToCreate() external;

    /// @notice Create PROPOSAL poll.
    /// @param _pollDeadline Poll deadline
    /// @param _pollInfo Info about poll
    function createProposalPoll(uint64 _pollDeadline, string memory _pollInfo) external;

    /// @notice Create EXECUTIVE poll.
    /// @param _pollDeadline Poll deadline
    /// @param _pollInfo Info about poll
    function createExecutivePoll(uint64 _pollDeadline, string memory _pollInfo) external;

    /// @notice Create EVENT poll.
    /// @param _pollDeadline Poll deadline
    /// @param _pollInfo Info about poll
    function createEventPoll(uint64 _pollDeadline, string memory _pollInfo) external;

    /// @notice Create PRIVATE poll.
    /// @param _pollDeadline Poll deadline
    /// @param _pollInfo Info about poll
    /// @param _verifiedAddresses Array of verified addresses for poll
    function createPrivatePoll(
        uint64 _pollDeadline,
        string memory _pollInfo,
        address[] memory _verifiedAddresses
    ) external;

    /// @notice Send tokens as vote in poll. Tokens will be lock.
    /// @param _pollNum Poll number
    /// @param _voteType Vote type (FOR, AGAINST)
    /// @param _voteWeight Vote weight in CVNX tokens
    function vote(
        uint256 _pollNum,
        VoteType _voteType,
        uint256 _voteWeight
    ) external;

    /// @notice Unlock tokens for poll. Poll should be ended.
    /// @param _pollNum Poll number
    function unlockTokensInPoll(uint256 _pollNum) external;

    /// @notice Stop poll before deadline.
    /// @param _pollNum Poll number
    function stopPoll(uint256 _pollNum) external;

    /// @notice Return poll status (PENDING, APPROVED, REJECTED, DRAW).
    /// @param _pollNum Poll number
    /// @return Poll number and status
    function getPollStatus(uint256 _pollNum) external view returns (uint256, PollStatus);

    /// @notice Return the poll expiration timestamp.
    /// @param _pollNum Poll number
    /// @return Poll deadline
    function getPollExpirationTime(uint256 _pollNum) external view returns (uint64);

    /// @notice Return the poll stop timestamp.
    /// @param _pollNum Poll number
    /// @return Poll stop time
    function getPollStopTime(uint256 _pollNum) external view returns (uint64);

    /// @notice Return the complete list of polls an address has voted in.
    /// @param _voter Voter address
    /// @return Index - poll number. True - if address voted in poll
    function getPollHistory(address _voter) external view returns (bool[] memory);

    /// @notice Return the vote info for a given poll for an address.
    /// @param _pollNum Poll number
    /// @param _voter Voter address
    /// @return Info about voter vote
    function getPollInfoForVoter(uint256 _pollNum, address _voter) external view returns (Vote memory);

    /// @notice Checks if a user address has voted for a specific poll.
    /// @param _pollNum Poll number
    /// @param _voter Voter address
    /// @return True if address voted in poll
    function getIfUserHasVoted(uint256 _pollNum, address _voter) external view returns (bool);

    /// @notice Return the amount of tokens that are locked for a given voter address.
    /// @param _voter Voter address
    /// @return Poll number
    function getLockedAmount(address _voter) external view returns (uint256);

    /// @notice Return the amount of locked tokens of the specific poll.
    /// @param _pollNum Poll number
    /// @param _voter Voter address
    /// @return Locked tokens amount for specific poll
    function getPollLockedAmount(uint256 _pollNum, address _voter) external view returns (uint256);
}