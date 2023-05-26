// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { IHashes } from "./IHashes.sol";
import { LibBytes } from "./LibBytes.sol";
import { LibDeactivateAuthority } from "./LibDeactivateAuthority.sol";
import { LibEIP712 } from "./LibEIP712.sol";
import { LibSignature } from "./LibSignature.sol";
import { LibVeto } from "./LibVeto.sol";
import { LibVoteCast } from "./LibVoteCast.sol";
import { MathHelpers } from "./MathHelpers.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "./MathHelpers.sol";

/**
 * @title HashesDAO
 * @author DEX Labs
 * @notice This contract handles governance for the HashesDAO and the
 *         Hashes ERC-721 token ecosystem.
 */
contract HashesDAO is Ownable {
    using SafeMath for uint256;
    using MathHelpers for uint256;
    using LibBytes for bytes;

    /// @notice name for this Governance apparatus
    string public constant name = "HashesDAO"; // solhint-disable-line const-name-snakecase

    /// @notice version for this Governance apparatus
    string public constant version = "1"; // solhint-disable-line const-name-snakecase

    // Hashes ERC721 token
    IHashes hashesToken;

    // A boolean reflecting whether or not the authority system is still active.
    bool public authoritiesActive;
    // The minimum number of votes required for any authority actions.
    uint256 public quorumAuthorities;
    // Authority status by address.
    mapping(address => bool) authorities;
    // Proposal struct by ID
    mapping(uint256 => Proposal) proposals;
    // Latest proposal IDs by proposer address
    mapping(address => uint128) latestProposalIds;
    // Whether transaction hash is currently queued
    mapping(bytes32 => bool) queuedTransactions;
    // Max number of operations/actions a proposal can have
    uint32 public immutable proposalMaxOperations;
    // Number of blocks after a proposal is made that voting begins
    // (e.g. 1 block)
    uint32 public immutable votingDelay;
    // Number of blocks voting will be held
    // (e.g. 17280 blocks ~ 3 days of blocks)
    uint32 public immutable votingPeriod;
    // Time window (s) a successful proposal must be executed,
    // otherwise will be expired, measured in seconds
    // (e.g. 1209600 seconds)
    uint32 public immutable gracePeriod;
    // Minimum number of for votes required, even if there's a
    // majority in favor
    // (e.g. 100 votes)
    uint32 public immutable quorumVotes;
    // Minimum Hashes token holdings required to create a proposal
    // (e.g. 2 votes)
    uint32 public immutable proposalThreshold;
    // Time (s) proposals must be queued before executing
    uint32 public immutable timelockDelay;
    // Total number of proposals
    uint128 proposalCount;

    struct Proposal {
        bool canceled;
        bool executed;
        address proposer;
        uint32 delay;
        uint128 id;
        uint256 eta;
        uint256 forVotes;
        uint256 againstVotes;
        address[] targets;
        string[] signatures;
        bytes[] calldatas;
        uint256[] values;
        uint256 startBlock;
        uint256 endBlock;
        mapping(address => Receipt) receipts;
    }

    struct Receipt {
        bool hasVoted;
        bool support;
        uint256 votes;
    }

    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }

    /// @notice Emitted when a new proposal is created
    event ProposalCreated(
        uint128 indexed id,
        address indexed proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /// @notice Emitted when a vote has been cast on a proposal
    event VoteCast(address indexed voter, uint128 indexed proposalId, bool support, uint256 votes);

    /// @notice Emitted when the authority system is deactivated.
    event AuthoritiesDeactivated();

    /// @notice Emitted when a proposal has been canceled
    event ProposalCanceled(uint128 indexed id);

    /// @notice Emitted when a proposal has been executed
    event ProposalExecuted(uint128 indexed id);

    /// @notice Emitted when a proposal has been queued
    event ProposalQueued(uint128 indexed id, uint256 eta);

    /// @notice Emitted when a proposal has been vetoed
    event ProposalVetoed(uint128 indexed id, uint256 quorum);

    /// @notice Emitted when a proposal action has been canceled
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    /// @notice Emitted when a proposal action has been executed
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    /// @notice Emitted when a proposal action has been queued
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    /**
     * @dev Makes functions only accessible when the authority system is still
     *      active.
     */
    modifier onlyAuthoritiesActive() {
        require(authoritiesActive, "HashesDAO: authorities must be active.");
        _;
    }

    /**
     * @notice Constructor for the HashesDAO. Initializes the state.
     * @param _hashesToken The hashes token address. This is the contract that
     *        will be called to check for governance membership.
     * @param _authorities A list of authorities that are able to veto
     *        governance proposals. Authorities can revoke their status, but
     *        new authorities can never be added.
     * @param _proposalMaxOperations Max number of operations/actions a
     *        proposal can have
     * @param _votingDelay Number of blocks after a proposal is made
     *        that voting begins.
     * @param _votingPeriod Number of blocks voting will be held.
     * @param _gracePeriod Period in which a successful proposal must be
     *        executed, otherwise will be expired.
     * @param _timelockDelay Time (s) in which a successful proposal
     *        must be in the queue before it can be executed.
     * @param _quorumVotes Minimum number of for votes required, even
     *        if there's a majority in favor.
     * @param _proposalThreshold Minimum Hashes token holdings required
     *        to create a proposal
     */
    constructor(
        IHashes _hashesToken,
        address[] memory _authorities,
        uint32 _proposalMaxOperations,
        uint32 _votingDelay,
        uint32 _votingPeriod,
        uint32 _gracePeriod,
        uint32 _timelockDelay,
        uint32 _quorumVotes,
        uint32 _proposalThreshold
    )
    Ownable()
    {
        hashesToken = _hashesToken;

        // Set initial variable values
        authoritiesActive = true;
        quorumAuthorities = _authorities.length / 2 + 1;
        address lastAuthority;
        for (uint256 i = 0; i < _authorities.length; i++) {
            require(lastAuthority < _authorities[i], "HashesDAO: authority addresses should monotonically increase.");
            lastAuthority = _authorities[i];
            authorities[_authorities[i]] = true;
        }
        proposalMaxOperations = _proposalMaxOperations;
        votingDelay = _votingDelay;
        votingPeriod = _votingPeriod;
        gracePeriod = _gracePeriod;
        timelockDelay = _timelockDelay;
        quorumVotes = _quorumVotes;
        proposalThreshold = _proposalThreshold;
    }

    /* solhint-disable ordering */
    receive() external payable {

    }

    /**
     * @notice This function allows participants who have sufficient
     *         Hashes holdings to create new proposals up for vote. The
     *         proposals contain the ordered lists of on-chain
     *         executable calldata.
     * @param _targets Addresses of contracts involved.
     * @param _values Values to be passed along with the calls.
     * @param _signatures Function signatures.
     * @param _calldatas Calldata passed to the function.
     * @param _description Text description of proposal.
     */
    function propose(
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) external returns (uint128) {
        // Ensure proposer has sufficient token holdings to propose
        require(
            hashesToken.getPriorVotes(msg.sender, block.number.sub(1)) >= proposalThreshold,
            "HashesDAO: proposer votes below proposal threshold."
        );
        require(
            _targets.length == _values.length &&
            _targets.length == _signatures.length &&
            _targets.length == _calldatas.length,
            "HashesDAO: proposal function information parity mismatch."
        );
        require(_targets.length != 0, "HashesDAO: must provide actions.");
        require(_targets.length <= proposalMaxOperations, "HashesDAO: too many actions.");

        if (latestProposalIds[msg.sender] != 0) {
            // Ensure proposer doesn't already have one active/pending
            ProposalState proposersLatestProposalState =
                state(latestProposalIds[msg.sender]);
            require(
                proposersLatestProposalState != ProposalState.Active,
                "HashesDAO: one live proposal per proposer, found an already active proposal."
            );
            require(
                proposersLatestProposalState != ProposalState.Pending,
                "HashesDAO: one live proposal per proposer, found an already pending proposal."
            );
        }

        // Proposal voting starts votingDelay after proposal is made
        uint256 startBlock = block.number.add(votingDelay);

        // Increment count of proposals
        proposalCount++;

        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.delay = timelockDelay;
        newProposal.targets = _targets;
        newProposal.values = _values;
        newProposal.signatures = _signatures;
        newProposal.calldatas = _calldatas;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = startBlock.add(votingPeriod);

        // Update proposer's latest proposal
        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            _targets,
            _values,
            _signatures,
            _calldatas,
            startBlock,
            startBlock.add(votingPeriod),
            _description
        );
        return newProposal.id;
    }

    /**
     * @notice This function allows any participant to queue a
     *         successful proposal for execution. Proposals are deemed
     *         successful if there is a simple majority (and more for
     *         votes than the minimum quorum) at the end of voting.
     * @param _proposalId Proposal id.
     */
    function queue(uint128 _proposalId) external {
        // Ensure proposal has succeeded (i.e. the voting period has
        // ended and there is a simple majority in favor and also above
        // the quorum
        require(
            state(_proposalId) == ProposalState.Succeeded,
            "HashesDAO: proposal can only be queued if it is succeeded."
        );
        Proposal storage proposal = proposals[_proposalId];

        // Establish eta of execution, which is a number of seconds
        // after queuing at which point proposal can actually execute
        uint256 eta = block.timestamp.add(proposal.delay);
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            // Ensure proposal action is not already in the queue
            bytes32 txHash =
            keccak256(
                abi.encode(
                    proposal.targets[i],
                    proposal.values[i],
                    proposal.signatures[i],
                    proposal.calldatas[i],
                    eta
                )
            );
            require(!queuedTransactions[txHash], "HashesDAO: proposal action already queued at eta.");
            queuedTransactions[txHash] = true;
            emit QueueTransaction(
                txHash,
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                eta
            );
        }
        // Set proposal eta timestamp after which it can be executed
        proposal.eta = eta;
        emit ProposalQueued(_proposalId, eta);
    }

    /**
     * @notice This function allows any participant to execute a
     *         queued proposal. A proposal in the queue must be in the
     *         queue for the delay period it was proposed with prior to
     *         executing, allowing the community to position itself
     *         accordingly.
     * @param _proposalId Proposal id.
     */
    function execute(uint128 _proposalId) external payable {
        // Ensure proposal is queued
        require(
            state(_proposalId) == ProposalState.Queued,
            "HashesDAO: proposal can only be executed if it is queued."
        );
        Proposal storage proposal = proposals[_proposalId];
        // Ensure proposal has been in the queue long enough
        require(block.timestamp >= proposal.eta, "HashesDAO: proposal hasn't finished queue time length.");

        // Ensure proposal hasn't been in the queue for too long
        require(block.timestamp <= proposal.eta.add(gracePeriod), "HashesDAO: transaction is stale.");

        proposal.executed = true;

        // Loop through each of the actions in the proposal
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            bytes32 txHash =
            keccak256(
                abi.encode(
                    proposal.targets[i],
                    proposal.values[i],
                    proposal.signatures[i],
                    proposal.calldatas[i],
                    proposal.eta
                )
            );
            require(queuedTransactions[txHash], "HashesDAO: transaction hasn't been queued.");

            queuedTransactions[txHash] = false;

            // Execute action
            bytes memory callData;
            require(bytes(proposal.signatures[i]).length != 0, "HashesDAO: Invalid function signature.");
            callData = abi.encodePacked(bytes4(keccak256(bytes(proposal.signatures[i]))), proposal.calldatas[i]);
            // solium-disable-next-line security/no-call-value
            (bool success, ) = proposal.targets[i].call{ value: proposal.values[i] }(callData);

            require(success, "HashesDAO: transaction execution reverted.");

            emit ExecuteTransaction(
                txHash,
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice This function allows any participant to cancel any non-
     *         executed proposal. It can be canceled if the proposer's
     *         token holdings has dipped below the proposal threshold
     *         at the time of cancellation.
     * @param _proposalId Proposal id.
     */
    function cancel(uint128 _proposalId) external {
        ProposalState proposalState = state(_proposalId);

        // Ensure proposal hasn't executed
        require(proposalState != ProposalState.Executed, "HashesDAO: cannot cancel executed proposal.");

        Proposal storage proposal = proposals[_proposalId];

        // Ensure proposer's token holdings has dipped below the
        // proposer threshold, leaving their proposal subject to
        // cancellation
        require(
            hashesToken.getPriorVotes(proposal.proposer, block.number.sub(1)) < proposalThreshold,
            "HashesDAO: proposer above threshold."
        );

        proposal.canceled = true;

        // Loop through each of the proposal's actions
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            bytes32 txHash =
            keccak256(
                abi.encode(
                    proposal.targets[i],
                    proposal.values[i],
                    proposal.signatures[i],
                    proposal.calldatas[i],
                    proposal.eta
                )
            );
            queuedTransactions[txHash] = false;
            emit CancelTransaction(
                txHash,
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        emit ProposalCanceled(_proposalId);
    }

    /**
     * @notice This function allows participants to cast either in
     *         favor or against a particular proposal.
     * @param _proposalId Proposal id.
     * @param _support In favor (true) or against (false).
     * @param _deactivate Deactivate tokens (true) or don't (false).
     * @param _deactivateSignature The signature to use when deactivating tokens.
     */
    function castVote(uint128 _proposalId, bool _support, bool _deactivate, bytes memory _deactivateSignature) external {
        return _castVote(msg.sender, _proposalId, _support, _deactivate, _deactivateSignature);
    }

    /**
     * @notice This function allows participants to cast votes with
     *         offline signatures in favor or against a particular
     *         proposal.
     * @param _proposalId Proposal id.
     * @param _support In favor (true) or against (false).
     * @param _deactivate Deactivate tokens (true) or don't (false).
     * @param _deactivateSignature The signature to use when deactivating tokens.
     * @param _signature Signature
     */
    function castVoteBySig(
        uint128 _proposalId,
        bool _support,
        bool _deactivate,
        bytes memory _deactivateSignature,
        bytes memory _signature
    ) external {
        // EIP712 hashing logic
        bytes32 eip712DomainHash = LibEIP712.hashEIP712Domain(name, version, getChainId(), address(this));
        bytes32 voteCastHash =
        LibVoteCast.getVoteCastHash(
            LibVoteCast.VoteCast({ proposalId: _proposalId, support: _support, deactivate: _deactivate }),
            eip712DomainHash
        );

        // Recover the signature and EIP712 hash
        address recovered = LibSignature.getSignerOfHash(voteCastHash, _signature);

        // Cast the vote and return the result
        return _castVote(recovered, _proposalId, _support, _deactivate, _deactivateSignature);
    }

    /**
     * @notice Allows the authorities to veto a proposal.
     * @param _proposalId The ID of the proposal to veto.
     * @param _signatures The signatures of the authorities.
     */
    function veto(uint128 _proposalId, bytes[] memory _signatures) external onlyAuthoritiesActive {
        ProposalState proposalState = state(_proposalId);

        // Ensure proposal hasn't executed
        require(proposalState != ProposalState.Executed, "HashesDAO: cannot cancel executed proposal.");

        Proposal storage proposal = proposals[_proposalId];

        // Ensure that a sufficient amount of authorities have signed to veto
        // this proposal.
        bytes32 eip712DomainHash = LibEIP712.hashEIP712Domain(name, version, getChainId(), address(this));
        bytes32 vetoHash =
            LibVeto.getVetoHash(
                LibVeto.Veto({ proposalId: _proposalId }),
                eip712DomainHash
            );
        _verifyAuthorityAction(vetoHash, _signatures);

        // Cancel the proposal.
        proposal.canceled = true;

        // Loop through each of the proposal's actions
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            bytes32 txHash =
            keccak256(
                abi.encode(
                    proposal.targets[i],
                    proposal.values[i],
                    proposal.signatures[i],
                    proposal.calldatas[i],
                    proposal.eta
                )
            );
            queuedTransactions[txHash] = false;
            emit CancelTransaction(
                txHash,
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        emit ProposalVetoed(_proposalId, _signatures.length);
    }

    /**
     * @notice Allows a quorum of authorities to deactivate the authority
     *         system. This operation can only be performed once and will
     *         prevent all future actions undertaken by the authorities.
     * @param _signatures The authority signatures to use to deactivate.
     * @param _authorities A list of authorities to delete. This isn't
     *        security-critical, but it allows the state to be cleaned up.
     */
    function deactivateAuthorities(bytes[] memory _signatures, address[] memory _authorities) external onlyAuthoritiesActive {
        // Ensure that a sufficient amount of authorities have signed to
        // deactivate the authority system.
        bytes32 eip712DomainHash = LibEIP712.hashEIP712Domain(name, version, getChainId(), address(this));
        bytes32 deactivateHash =
            LibDeactivateAuthority.getDeactivateAuthorityHash(
                LibDeactivateAuthority.DeactivateAuthority({ support: true }),
                eip712DomainHash
            );
        _verifyAuthorityAction(deactivateHash, _signatures);

        // Deactivate the authority system.
        authoritiesActive = false;
        quorumAuthorities = 0;
        for (uint256 i = 0; i < _authorities.length; i++) {
            authorities[_authorities[i]] = false;
        }

        emit AuthoritiesDeactivated();
    }

    /**
     * @notice This function allows any participant to retrieve
     *         the actions involved in a given proposal.
     * @param _proposalId Proposal id.
     * @return targets Addresses of contracts involved.
     * @return values Values to be passed along with the calls.
     * @return signatures Function signatures.
     * @return calldatas Calldata passed to the function.
     */
    function getActions(uint128 _proposalId)
    external
    view
    returns (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    )
    {
        Proposal storage p = proposals[_proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /**
     * @notice This function allows any participant to retrieve the authority
     *         status of an arbitrary address.
     * @param _authority The address to check.
     * @return The authority status of the address.
     */
    function getAuthorityStatus(address _authority) external view returns (bool) {
        return authorities[_authority];
    }

    /**
     * @notice This function allows any participant to retrieve
     *         the receipt for a given proposal and voter.
     * @param _proposalId Proposal id.
     * @param _voter Voter address.
     * @return Voter receipt.
     */
    function getReceipt(uint128 _proposalId, address _voter) external view returns (Receipt memory) {
        return proposals[_proposalId].receipts[_voter];
    }

    /**
     * @notice This function gets a proposal from an ID.
     * @param _proposalId Proposal id.
     * @return Proposal attributes.
     */
    function getProposal(uint128 _proposalId)
    external
    view
    returns (
        bool,
        bool,
        address,
        uint32,
        uint128,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    )
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.canceled,
            proposal.executed,
            proposal.proposer,
            proposal.delay,
            proposal.id,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.eta,
            proposal.startBlock,
            proposal.endBlock
        );
    }

    /**
     * @notice This function gets whether a proposal action transaction
     *         hash is queued or not.
     * @param _txHash Proposal action tx hash.
     * @return Is proposal action transaction hash queued or not.
     */
    function getIsQueuedTransaction(bytes32 _txHash) external view returns (bool) {
        return queuedTransactions[_txHash];
    }

    /**
     * @notice This function gets the proposal count.
     * @return Proposal count.
     */
    function getProposalCount() external view returns (uint128) {
        return proposalCount;
    }

    /**
     * @notice This function gets the latest proposal ID for a user.
     * @param _proposer Proposer's address.
     * @return Proposal ID.
     */
    function getLatestProposalId(address _proposer) external view returns (uint128) {
        return latestProposalIds[_proposer];
    }

    /**
     * @notice This function retrieves the status for any given
     *         proposal.
     * @param _proposalId Proposal id.
     * @return Status of proposal.
     */
    function state(uint128 _proposalId) public view returns (ProposalState) {
        require(proposalCount >= _proposalId && _proposalId > 0, "HashesDAO: invalid proposal id.");
        Proposal storage proposal = proposals[_proposalId];

        // Note the 3rd conditional where we can escape out of the vote
        // phase if the for or against votes exceeds the skip remaining
        // voting threshold
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.eta.add(gracePeriod)) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function _castVote(
        address _voter,
        uint128 _proposalId,
        bool _support,
        bool _deactivate,
        bytes memory _deactivateSignature
    ) internal {
        // Sanity check the input.
        require(!(_support && _deactivate), "HashesDAO: can't support and deactivate simultaneously.");

        require(state(_proposalId) == ProposalState.Active, "HashesDAO: voting is closed.");
        Proposal storage proposal = proposals[_proposalId];
        Receipt storage receipt = proposal.receipts[_voter];

        // Ensure voter has not already voted
        require(!receipt.hasVoted, "HashesDAO: voter already voted.");

        // Obtain the token holdings (voting power) for participant at
        // the time voting started. They may have gained or lost tokens
        // since then, doesn't matter.
        uint256 votes = hashesToken.getPriorVotes(_voter, proposal.startBlock);

        // Ensure voter has nonzero voting power
        require(votes > 0, "HashesDAO: voter has no voting power.");
        if (_support) {
            // Increment the for votes in favor
            proposal.forVotes = proposal.forVotes.add(votes);
        } else {
            // Increment the against votes
            proposal.againstVotes = proposal.againstVotes.add(votes);
        }

        // Set receipt attributes based on cast vote parameters
        receipt.hasVoted = true;
        receipt.support = _support;
        receipt.votes = votes;

        // If necessary, deactivate the voter's hashes tokens.
        if (_deactivate) {
            uint256 deactivationCount = hashesToken.deactivateTokens(_voter, _proposalId, _deactivateSignature);
            if (deactivationCount > 0) {
                // Transfer the voter the activation fee for each of the deactivated tokens.
                (bool sent,) = _voter.call{value: hashesToken.activationFee().mul(deactivationCount)}("");
                require(sent, "Hashes: couldn't re-pay the token owner after deactivating hashes.");
            }
        }

        emit VoteCast(_voter, _proposalId, _support, votes);
    }

    /**
     * @dev Verifies a submission from authorities. In particular, this
     *      validates signatures, authorization status, and quorum.
     * @param _hash The message hash to use during recovery.
     * @param _signatures The authority signatures to verify.
     */
    function _verifyAuthorityAction(bytes32 _hash, bytes[] memory _signatures) internal view {
        address lastAddress;
        for (uint256 i = 0; i < _signatures.length; i++) {
            address recovered = LibSignature.getSignerOfHash(_hash, _signatures[i]);
            require(lastAddress < recovered, "HashesDAO: recovered addresses should monotonically increase.");
            require(authorities[recovered], "HashesDAO: recovered addresses should be authorities.");
            lastAddress = recovered;
        }
        require(_signatures.length >= quorumAuthorities / 2 + 1, "HashesDAO: veto quorum was not reached.");
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}