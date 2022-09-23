// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {NounletToken as Nounlet} from "../NounletToken.sol";
import {INounletRegistry as IRegistry} from "../interfaces/INounletRegistry.sol";
import {INounletGovernance as IGovernance, Permission, Proposal} from "../interfaces/INounletGovernance.sol";
import {INounletProposal as IProposal} from "../interfaces/INounletProposal.sol";
import {INounsToken as INouns} from "../interfaces/INounsToken.sol";
import {IVault} from "../interfaces/IVault.sol";

/// @title NounletGovernance
/// @author Tessera
/// @notice Module contract for tracking token governance
contract NounletGovernance is IGovernance {
    /// @notice Address of NounletProposal target contract
    address public immutable proposal;
    /// @notice Address of NounletRegistry contract
    address public immutable registry;
    /// @notice Mapping of vault address to current delegate
    mapping(address => address) public currentDelegate;

    /// @dev Initializes NounletRegistry and NounletProposal contracts
    constructor(address _registry, address _proposal) {
        registry = _registry;
        proposal = _proposal;
    }

    /// @dev Modifier that checks if caller is current delegate of the vault
    /// @param _vault Address of the vault
    modifier onlyDelegate(address _vault) {
        if (msg.sender != currentDelegate[_vault]) revert NotDelegate();
        _;
    }

    /// @notice Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold
    /// @param _vault Address of the vault
    /// @param _proposalId The id of the proposal to cancel
    /// @param _cancelProof Merkle proof for cancel
    function cancel(
        address _vault,
        uint256 _proposalId,
        bytes32[] calldata _cancelProof
    ) external onlyDelegate(_vault) {
        bytes memory data = abi.encodeCall(IProposal.cancel, (_proposalId));

        IVault(payable(_vault)).execute(proposal, data, _cancelProof);
        emit ProposalCancelled(_vault, _proposalId);
    }

    /// @notice Function to cast vote on Nouns DAO proposal
    /// @param _vault Address of the vault
    /// @param _proposalId ID of the proposal
    /// @param _support Decision value for the vote (0=against, 1=for, 2=abstain)
    /// @param _castVoteProof Merkle proof for castVote
    function castVote(
        address _vault,
        uint256 _proposalId,
        uint8 _support,
        bytes32[] calldata _castVoteProof
    ) external onlyDelegate(_vault) {
        bytes memory data = abi.encodeCall(IProposal.castVote, (_proposalId, _support));

        IVault(payable(_vault)).execute(proposal, data, _castVoteProof);
        emit VoteCast(_vault, _proposalId, _support);
    }

    /// @notice Function to cast vote on Nouns DAO proposal with reason
    /// @param _vault Address of the vault
    /// @param _proposalId ID of the proposal
    /// @param _support Decision value for the vote (0=against, 1=for, 2=abstain)
    /// @param _reason Reason given for voting decision
    /// @param _castVoteWithReasonProof Merkle proof for castVoteWithReason
    function castVoteWithReason(
        address _vault,
        uint256 _proposalId,
        uint8 _support,
        string calldata _reason,
        bytes32[] calldata _castVoteWithReasonProof
    ) external onlyDelegate(_vault) {
        bytes memory data = abi.encodeCall(
            IProposal.castVoteWithReason,
            (_proposalId, _support, _reason)
        );

        IVault(payable(_vault)).execute(proposal, data, _castVoteWithReasonProof);
        emit VoteCastWithReason(_vault, _proposalId, _support, _reason);
    }

    /// @notice Claims delegate status of a given vault
    /// @dev Caller must have more votes than current delegate
    /// @param _vault Address of the vault
    /// @param claimer Address of the new delegate
    function claimDelegate(address _vault, address claimer) external {
        uint256 previousBlock = block.number - 1;
        address token = IRegistry(registry).vaultToToken(_vault);
        address current = currentDelegate[_vault];

        uint256 claimerVotes = Nounlet(token).getPriorVotes(claimer, previousBlock);
        uint256 delegateVotes = Nounlet(token).getPriorVotes(current, previousBlock);

        if (delegateVotes >= claimerVotes) revert InsufficientVotes();
        currentDelegate[_vault] = claimer;
        emit ClaimDelegate(_vault, claimer, current);
    }

    /// @notice Delegates voting power for a given vault
    /// @param _vault Address of the vault
    /// @param _delegatee Address of the delegatee
    function delegate(
        address _vault,
        address _delegatee,
        bytes32[] calldata _delegateProof
    ) external onlyDelegate(_vault) {
        bytes memory data = abi.encodeCall(INouns.delegate, (_delegatee));
        IVault(payable(_vault)).execute(proposal, data, _delegateProof);
        emit NounDelegated(_vault, _delegatee);
    }

    /// @notice Creates a new proposal
    /// @dev Vault must have delegates above the proposal threshold
    /// @param _vault Address of the vault
    /// @param _proposeProof Merkle proof for creating proposals
    /// @param _proposal Function signatures for proposal calls
    function propose(
        address _vault,
        bytes32[] calldata _proposeProof,
        Proposal calldata _proposal
    ) external onlyDelegate(_vault) {
        bytes memory data = abi.encodeCall(
            IProposal.propose,
            (
                _proposal.targets,
                _proposal.values,
                _proposal.signatures,
                _proposal.calldatas,
                _proposal.description
            )
        );
        IVault(payable(_vault)).execute(proposal, data, _proposeProof);
        emit ProposalSubmitted(_vault, _proposal);
    }

    /// @notice Gets the list of leaf nodes used to generate a merkle tree
    /// @dev Leaf nodes are hashed permissions of the merkle tree
    /// @return nodes A list of leaf nodes
    function getLeafNodes() external view returns (bytes32[] memory nodes) {
        // Gets list of permissions from this module
        Permission[] memory permissions = getPermissions();
        nodes = new bytes32[](permissions.length);
        for (uint256 i; i < permissions.length; ) {
            // Hashes permission into leaf node
            nodes[i] = keccak256(abi.encode(permissions[i]));
            // Can't overflow since loop is a fixed size
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Gets the list of permissions installed on a vault
    /// @dev Permissions consist of a module contract, target contract, and function selector
    /// @return permissions A list of Permission Structs
    function getPermissions() public view returns (Permission[] memory permissions) {
        permissions = new Permission[](5);
        // castVote function selector from NounletProposal contract
        permissions[0] = Permission(address(this), proposal, IProposal.castVote.selector);
        // castVoteWithReason function selector from NounletProposal contract
        permissions[1] = Permission(address(this), proposal, IProposal.castVoteWithReason.selector);
        // cancel function selector from NounletProposal contract
        permissions[2] = Permission(address(this), proposal, IProposal.cancel.selector);
        // propose function selector from NounletProposal contract
        permissions[3] = Permission(address(this), proposal, IProposal.propose.selector);
        // delegate function selector from NounsToken contract
        permissions[4] = Permission(address(this), proposal, INouns.delegate.selector);
    }
}