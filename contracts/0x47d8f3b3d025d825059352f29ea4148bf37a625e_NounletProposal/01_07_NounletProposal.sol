// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {INounletProposal as IProposal} from "../interfaces/INounletProposal.sol";
import {INounsToken as INouns} from "../interfaces/INounsToken.sol";

/// @title NounletProposal
/// @author Tessera
/// @notice Target contract for executing proposal actions
contract NounletProposal is IProposal {
    /// @notice Address of NounsDAOProxy contract
    address public immutable nounsDAO;
    /// @notice Address of NounsToken contract
    address public immutable nounsToken;

    /// @dev Initializes address of NounsDAOProxy and NounsToken contracts
    constructor(address _nounsDAO, address _nounsToken) {
        nounsDAO = _nounsDAO;
        nounsToken = _nounsToken;
    }

    /// @notice Cancels a given proposal
    /// @param _proposalId ID of the proposal
    function cancel(uint256 _proposalId) external {
        IProposal(nounsDAO).cancel(_proposalId);
    }

    /// @notice Casts a vote on a given proposal
    /// @param _proposalId ID of the proposal
    /// @param _support Decision value for the vote (0=against, 1=for, 2=abstain)
    function castVote(uint256 _proposalId, uint8 _support) external {
        IProposal(nounsDAO).castVote(_proposalId, _support);
    }

    /// @notice Casts a vote on a given proposal with reason
    /// @param _proposalId ID of the proposal
    /// @param _support Decision value for the vote (0=against, 1=for, 2=abstain)
    /// @param _reason Reason given for voting decision
    function castVoteWithReason(
        uint256 _proposalId,
        uint8 _support,
        string calldata _reason
    ) external {
        IProposal(nounsDAO).castVoteWithReason(_proposalId, _support, _reason);
    }

    /// @notice Delegates voting power to a given address
    /// @param _delegatee Address of the delegatee
    function delegate(address _delegatee) external {
        INouns(nounsToken).delegate(_delegatee);
    }

    /// @notice Creates a new proposal
    /// @param _targets Target addresses for proposal calls
    /// @param _values Eth values for proposal calls
    /// @param _signatures Function signatures for proposal calls
    /// @param _calldatas Calldatas for proposal calls
    /// @param _description String description of the proposal
    function propose(
        address[] calldata _targets,
        uint256[] calldata _values,
        string[] calldata _signatures,
        bytes[] calldata _calldatas,
        string calldata _description
    ) external {
        IProposal(nounsDAO).propose(_targets, _values, _signatures, _calldatas, _description);
    }
}