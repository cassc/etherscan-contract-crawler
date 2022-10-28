// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// Interfaces.
import "./interfaces/IVault.sol";

/**
 * @title Vote
 * @author Steve Harmeyer
 * @notice This is the Furio voting contract.
 */

/// @custom:security-contact [email protected]
contract Vote is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
        minimumVaultBalance = 25e18;
    }

    using Counters for Counters.Counter;

    /**
     * Initiative id tracker.
     */
    Counters.Counter private _initiativeIdTracker;

    /**
     * Properties.
     */
    uint256 public minimumVaultBalance;

    /**
     * Mappings.
     */
    mapping (uint256 => string) private _initiatives;
    mapping (uint256 => string) private _descriptions;
    mapping (uint256 => uint256) private _startTime;
    mapping (uint256 => uint256) private _endTime;
    mapping (uint256 => uint256) private _totalVotes;
    mapping (uint256 => uint256) private _yesVotes;
    mapping (address => mapping(uint256 => bool)) private _voted;

    /**
     * Events.
     */
    event InitiativeCreated(uint256 initiativeId, string name, string description, uint256 startTime, uint256 endTime);
    event VoteCast(uint256 initiativeId, address voter, bool vote);

    /**
     * Create initiative.
     * @param name_ Initiative name.
     * @param description_ Initiative description.
     * @param startTime_ Start time.
     * @param endTime_ End time.
     * @dev Creates an initiative.
     */
    function createInitiave(string memory name_, string memory description_, uint256 startTime_, uint256 endTime_) external onlyOwner
    {
        require(endTime_ > startTime_ && endTime_ > block.timestamp, "Invalid end time");
        _initiativeIdTracker.increment();
        _initiatives[_initiativeIdTracker.current()] = name_;
        _descriptions[_initiativeIdTracker.current()] = description_;
        _startTime[_initiativeIdTracker.current()] = startTime_;
        _endTime[_initiativeIdTracker.current()] = endTime_;
        emit InitiativeCreated(_initiativeIdTracker.current(), name_, description_, startTime_, endTime_);
    }

    /**
     * Get initiave.
     * @param initiative_ Initiative id.
     * @return (string memory, string memory, uint256, uint256, uint256, uint256)
     *     - Name, description, start time, end time, total votes, yes votes.
     */
    function getInitiative(uint256 initiative_) external view returns (string memory, string memory, uint256, uint256, uint256, uint256)
    {
        return (
            _initiatives[initiative_],
            _descriptions[initiative_],
            _startTime[initiative_],
            _endTime[initiative_],
            _totalVotes[initiative_],
            _yesVotes[initiative_]
        );
    }

    /**
     * Vote.
     * @param initiative_ Initiative id.
     * @param vote_ Vote.
     */
    function vote(uint256 initiative_, bool vote_) external
    {
        require(_startTime[initiative_] <= block.timestamp && _endTime[initiative_] >= block.timestamp, "Voting period has not started yet");
        require(!_voted[msg.sender][initiative_], "Already voted");
        require(IVault(addressBook.get("vault")).participantBalance(msg.sender) >= minimumVaultBalance, "Vault balance too low");
        _voted[msg.sender][initiative_] = true;
        _totalVotes[initiative_] ++;
        if(vote_)
        {
            _yesVotes[initiative_] ++;
        }
        emit VoteCast(initiative_, msg.sender, vote_);
    }

    /**
     * Results.
     * @param initiative_ Initiative id.
     * @return bool True if passed.
     */
    function results(uint256 initiative_) external view returns (bool)
    {
        return _yesVotes[initiative_] > _totalVotes[initiative_] / 2;
    }

    /**
     * Yes votes.
     * @param initiative_ Initiative id.
     * @return uint256 Yes votes.
     */
    function yesVotes(uint256 initiative_) external view returns (uint256)
    {
        return _yesVotes[initiative_];
    }

    /**
     * Total votes.
     * @param initiative_ Initiative id.
     * @return uint256 Total votes.
     */
    function totalVotes(uint256 initiative_) external view returns (uint256)
    {
        return _totalVotes[initiative_];
    }

    /**
     * Voted.
     * @param initiative_ Initiative id.
     * @param participant_ Participant address.
     * @return bool True if voted.
     */
    function voted(uint256 initiative_, address participant_) external view returns (bool)
    {
        return _voted[participant_][initiative_];
    }
}