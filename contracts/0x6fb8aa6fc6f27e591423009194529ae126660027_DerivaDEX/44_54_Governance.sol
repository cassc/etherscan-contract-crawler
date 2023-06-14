// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { SafeMath } from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import { GovernanceDefs } from "../../libs/defs/GovernanceDefs.sol";
import { LibEIP712 } from "../../libs/LibEIP712.sol";
import { LibVoteCast } from "../../libs/LibVoteCast.sol";
import { LibBytes } from "../../libs/LibBytes.sol";
import { SafeMath32 } from "../../libs/SafeMath32.sol";
import { SafeMath96 } from "../../libs/SafeMath96.sol";
import { SafeMath128 } from "../../libs/SafeMath128.sol";
import { MathHelpers } from "../../libs/MathHelpers.sol";
import { LibDiamondStorageDerivaDEX } from "../../storage/LibDiamondStorageDerivaDEX.sol";
import { LibDiamondStorageGovernance } from "../../storage/LibDiamondStorageGovernance.sol";

/**
 * @title Governance
 * @author DerivaDEX (Borrowed/inspired from Compound)
 * @notice This is a facet to the DerivaDEX proxy contract that handles
 *         the logic pertaining to governance. The Diamond storage
 *         will only be affected when facet functions are called via
 *         the proxy contract, no checks are necessary.
 * @dev The Diamond storage will only be affected when facet functions
 *      are called via the proxy contract, no checks are necessary.
 */
contract Governance {
    using SafeMath32 for uint32;
    using SafeMath96 for uint96;
    using SafeMath128 for uint128;
    using SafeMath for uint256;
    using MathHelpers for uint96;
    using MathHelpers for uint256;
    using LibBytes for bytes;

    /// @notice name for this Governance contract
    string public constant name = "DDX Governance"; // solhint-disable-line const-name-snakecase

    /// @notice version for this Governance contract
    string public constant version = "1"; // solhint-disable-line const-name-snakecase

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
    event VoteCast(address indexed voter, uint128 indexed proposalId, bool support, uint96 votes);

    /// @notice Emitted when a proposal has been canceled
    event ProposalCanceled(uint128 indexed id);

    /// @notice Emitted when a proposal has been queued
    event ProposalQueued(uint128 indexed id, uint256 eta);

    /// @notice Emitted when a proposal has been executed
    event ProposalExecuted(uint128 indexed id);

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
     * @notice Limits functions to only be called via governance.
     */
    modifier onlyAdmin {
        LibDiamondStorageDerivaDEX.DiamondStorageDerivaDEX storage dsDerivaDEX =
            LibDiamondStorageDerivaDEX.diamondStorageDerivaDEX();
        require(msg.sender == dsDerivaDEX.admin, "Governance: must be called by Governance admin.");
        _;
    }

    /**
     * @notice This function initializes the state with some critical
     *         information. This can only be called once and must be
     *         done via governance.
     * @dev This function is best called as a parameter to the
     *      diamond cut function. This is removed prior to the selectors
     *      being added to the diamond, meaning it cannot be called
     *      again.
     * @param _quorumVotes Minimum number of for votes required, even
     *        if there's a majority in favor.
     * @param _proposalThreshold Minimum DDX token holdings required
     *        to create a proposal
     * @param _proposalMaxOperations Max number of operations/actions a
     *        proposal can have
     * @param _votingDelay Number of blocks after a proposal is made
     *        that voting begins.
     * @param _votingPeriod Number of blocks voting will be held.
     * @param _skipRemainingVotingThreshold Number of for or against
     *        votes that are necessary to skip the remainder of the
     *        voting period.
     * @param _gracePeriod Period in which a successful proposal must be
     *        executed, otherwise will be expired.
     * @param _timelockDelay Time (s) in which a successful proposal
     *        must be in the queue before it can be executed.
     */
    function initialize(
        uint32 _proposalMaxOperations,
        uint32 _votingDelay,
        uint32 _votingPeriod,
        uint32 _gracePeriod,
        uint32 _timelockDelay,
        uint32 _quorumVotes,
        uint32 _proposalThreshold,
        uint32 _skipRemainingVotingThreshold
    ) external onlyAdmin {
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();

        // Ensure state variable comparisons are valid
        requireValidSkipRemainingVotingThreshold(_skipRemainingVotingThreshold);
        requireSkipRemainingVotingThresholdGtQuorumVotes(_skipRemainingVotingThreshold, _quorumVotes);

        // Set initial variable values
        dsGovernance.proposalMaxOperations = _proposalMaxOperations;
        dsGovernance.votingDelay = _votingDelay;
        dsGovernance.votingPeriod = _votingPeriod;
        dsGovernance.gracePeriod = _gracePeriod;
        dsGovernance.timelockDelay = _timelockDelay;
        dsGovernance.quorumVotes = _quorumVotes;
        dsGovernance.proposalThreshold = _proposalThreshold;
        dsGovernance.skipRemainingVotingThreshold = _skipRemainingVotingThreshold;
        dsGovernance.fastPathFunctionSignatures["setIsPaused(bool)"] = true;
    }

    /**
     * @notice This function allows participants who have sufficient
     *         DDX holdings to create new proposals up for vote. The
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
        LibDiamondStorageDerivaDEX.DiamondStorageDerivaDEX storage dsDerivaDEX =
            LibDiamondStorageDerivaDEX.diamondStorageDerivaDEX();
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();

        // Ensure proposer has sufficient token holdings to propose
        require(
            dsDerivaDEX.ddxToken.getPriorVotes(msg.sender, block.number.sub(1)) >= getProposerThresholdCount(),
            "Governance: proposer votes below proposal threshold."
        );
        require(
            _targets.length == _values.length &&
                _targets.length == _signatures.length &&
                _targets.length == _calldatas.length,
            "Governance: proposal function information parity mismatch."
        );
        require(_targets.length != 0, "Governance: must provide actions.");
        require(_targets.length <= dsGovernance.proposalMaxOperations, "Governance: too many actions.");

        if (dsGovernance.latestProposalIds[msg.sender] != 0) {
            // Ensure proposer doesn't already have one active/pending
            GovernanceDefs.ProposalState proposersLatestProposalState =
                state(dsGovernance.latestProposalIds[msg.sender]);
            require(
                proposersLatestProposalState != GovernanceDefs.ProposalState.Active,
                "Governance: one live proposal per proposer, found an already active proposal."
            );
            require(
                proposersLatestProposalState != GovernanceDefs.ProposalState.Pending,
                "Governance: one live proposal per proposer, found an already pending proposal."
            );
        }

        // Proposal voting starts votingDelay after proposal is made
        uint256 startBlock = block.number.add(dsGovernance.votingDelay);

        // Increment count of proposals
        dsGovernance.proposalCount++;

        // Create new proposal struct and add to mapping
        GovernanceDefs.Proposal memory newProposal =
            GovernanceDefs.Proposal({
                id: dsGovernance.proposalCount,
                proposer: msg.sender,
                delay: getTimelockDelayForSignatures(_signatures),
                eta: 0,
                targets: _targets,
                values: _values,
                signatures: _signatures,
                calldatas: _calldatas,
                startBlock: startBlock,
                endBlock: startBlock.add(dsGovernance.votingPeriod),
                forVotes: 0,
                againstVotes: 0,
                canceled: false,
                executed: false
            });

        dsGovernance.proposals[newProposal.id] = newProposal;

        // Update proposer's latest proposal
        dsGovernance.latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            _targets,
            _values,
            _signatures,
            _calldatas,
            startBlock,
            startBlock.add(dsGovernance.votingPeriod),
            _description
        );
        return newProposal.id;
    }

    /**
     * @notice This function allows any participant to queue a
     *         successful proposal for execution. Proposals are deemed
     *         successful if at any point the number of for votes has
     *         exceeded the skip remaining voting threshold or if there
     *         is a simple majority (and more for votes than the
     *         minimum quorum) at the end of voting.
     * @param _proposalId Proposal id.
     */
    function queue(uint128 _proposalId) external {
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();

        // Ensure proposal has succeeded (i.e. it has either enough for
        // votes to skip the remainder of the voting period or the
        // voting period has ended and there is a simple majority in
        // favor and also above the quorum
        require(
            state(_proposalId) == GovernanceDefs.ProposalState.Succeeded,
            "Governance: proposal can only be queued if it is succeeded."
        );
        GovernanceDefs.Proposal storage proposal = dsGovernance.proposals[_proposalId];

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
            require(!dsGovernance.queuedTransactions[txHash], "Governance: proposal action already queued at eta.");
            dsGovernance.queuedTransactions[txHash] = true;
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
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        // Ensure proposal is queued
        require(
            state(_proposalId) == GovernanceDefs.ProposalState.Queued,
            "Governance: proposal can only be executed if it is queued."
        );
        GovernanceDefs.Proposal storage proposal = dsGovernance.proposals[_proposalId];
        // Ensure proposal has been in the queue long enough
        require(block.timestamp >= proposal.eta, "Governance: proposal hasn't finished queue time length.");

        // Ensure proposal hasn't been in the queue for too long
        require(block.timestamp <= proposal.eta.add(dsGovernance.gracePeriod), "Governance: transaction is stale.");

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
            require(dsGovernance.queuedTransactions[txHash], "Governance: transaction hasn't been queued.");

            dsGovernance.queuedTransactions[txHash] = false;

            // Execute action
            bytes memory callData;
            require(bytes(proposal.signatures[i]).length != 0, "Governance: Invalid function signature.");
            callData = abi.encodePacked(bytes4(keccak256(bytes(proposal.signatures[i]))), proposal.calldatas[i]);
            // solium-disable-next-line security/no-call-value
            (bool success, ) = proposal.targets[i].call{ value: proposal.values[i] }(callData);

            require(success, "Governance: transaction execution reverted.");

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
        LibDiamondStorageDerivaDEX.DiamondStorageDerivaDEX storage dsDerivaDEX =
            LibDiamondStorageDerivaDEX.diamondStorageDerivaDEX();
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        GovernanceDefs.ProposalState state = state(_proposalId);

        // Ensure proposal hasn't executed
        require(state != GovernanceDefs.ProposalState.Executed, "Governance: cannot cancel executed proposal.");

        GovernanceDefs.Proposal storage proposal = dsGovernance.proposals[_proposalId];

        // Ensure proposer's token holdings has dipped below the
        // proposer threshold, leaving their proposal subject to
        // cancellation
        require(
            dsDerivaDEX.ddxToken.getPriorVotes(proposal.proposer, block.number.sub(1)) < getProposerThresholdCount(),
            "Governance: proposer above threshold."
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
            dsGovernance.queuedTransactions[txHash] = false;
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
     */
    function castVote(uint128 _proposalId, bool _support) external {
        return _castVote(msg.sender, _proposalId, _support);
    }

    /**
     * @notice This function allows participants to cast votes with
     *         offline signatures in favor or against a particular
     *         proposal.
     * @param _proposalId Proposal id.
     * @param _support In favor (true) or against (false).
     * @param _signature Signature
     */
    function castVoteBySig(
        uint128 _proposalId,
        bool _support,
        bytes memory _signature
    ) external {
        // EIP712 hashing logic
        bytes32 eip712OrderParamsDomainHash = LibEIP712.hashEIP712Domain(name, version, getChainId(), address(this));
        bytes32 voteCastHash =
            LibVoteCast.getVoteCastHash(
                LibVoteCast.VoteCast({ proposalId: _proposalId, support: _support }),
                eip712OrderParamsDomainHash
            );

        // Recover the signature and EIP712 hash
        uint8 v = uint8(_signature[0]);
        bytes32 r = _signature.readBytes32(1);
        bytes32 s = _signature.readBytes32(33);
        address recovered = ecrecover(voteCastHash, v, r, s);

        require(recovered != address(0), "Governance: invalid signature.");
        return _castVote(recovered, _proposalId, _support);
    }

    /**
     * @notice This function sets the quorum votes required for a
     *         proposal to pass. It must be called via
     *         governance.
     * @param _quorumVotes Quorum votes threshold.
     */
    function setQuorumVotes(uint32 _quorumVotes) external onlyAdmin {
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        requireSkipRemainingVotingThresholdGtQuorumVotes(dsGovernance.skipRemainingVotingThreshold, _quorumVotes);
        dsGovernance.quorumVotes = _quorumVotes;
    }

    /**
     * @notice This function sets the token holdings threshold required
     *         to propose something. It must be called via
     *         governance.
     * @param _proposalThreshold Proposal threshold.
     */
    function setProposalThreshold(uint32 _proposalThreshold) external onlyAdmin {
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        dsGovernance.proposalThreshold = _proposalThreshold;
    }

    /**
     * @notice This function sets the max operations a proposal can
     *         carry out. It must be called via governance.
     * @param _proposalMaxOperations Proposal's max operations.
     */
    function setProposalMaxOperations(uint32 _proposalMaxOperations) external onlyAdmin {
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        dsGovernance.proposalMaxOperations = _proposalMaxOperations;
    }

    /**
     * @notice This function sets the voting delay in blocks from when
     *         a proposal is made and voting begins. It must be called
     *         via governance.
     * @param _votingDelay Voting delay (blocks).
     */
    function setVotingDelay(uint32 _votingDelay) external onlyAdmin {
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        dsGovernance.votingDelay = _votingDelay;
    }

    /**
     * @notice This function sets the voting period in blocks that a
     *         vote will last. It must be called via
     *         governance.
     * @param _votingPeriod Voting period (blocks).
     */
    function setVotingPeriod(uint32 _votingPeriod) external onlyAdmin {
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        dsGovernance.votingPeriod = _votingPeriod;
    }

    /**
     * @notice This function sets the threshold at which a proposal can
     *         immediately be deemed successful or rejected if the for
     *         or against votes exceeds this threshold, even if the
     *         voting period is still ongoing. It must be called
     *         governance.
     * @param _skipRemainingVotingThreshold Threshold for or against
     *        votes must reach to skip remainder of voting period.
     */
    function setSkipRemainingVotingThreshold(uint32 _skipRemainingVotingThreshold) external onlyAdmin {
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        requireValidSkipRemainingVotingThreshold(_skipRemainingVotingThreshold);
        requireSkipRemainingVotingThresholdGtQuorumVotes(_skipRemainingVotingThreshold, dsGovernance.quorumVotes);
        dsGovernance.skipRemainingVotingThreshold = _skipRemainingVotingThreshold;
    }

    /**
     * @notice This function sets the grace period in seconds that a
     *         queued proposal can last before expiring. It must be
     *         called via governance.
     * @param _gracePeriod Grace period (seconds).
     */
    function setGracePeriod(uint32 _gracePeriod) external onlyAdmin {
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        dsGovernance.gracePeriod = _gracePeriod;
    }

    /**
     * @notice This function sets the timelock delay (s) a proposal
     *         must be queued before execution.
     * @param _timelockDelay Timelock delay (seconds).
     */
    function setTimelockDelay(uint32 _timelockDelay) external onlyAdmin {
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        dsGovernance.timelockDelay = _timelockDelay;
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
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        GovernanceDefs.Proposal storage p = dsGovernance.proposals[_proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /**
     * @notice This function allows any participant to retrieve
     *         the receipt for a given proposal and voter.
     * @param _proposalId Proposal id.
     * @param _voter Voter address.
     * @return Voter receipt.
     */
    function getReceipt(uint128 _proposalId, address _voter) external view returns (GovernanceDefs.Receipt memory) {
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        return dsGovernance.proposals[_proposalId].receipts[_voter];
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
            uint96,
            uint96,
            uint128,
            uint256,
            uint256,
            uint256
        )
    {
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        GovernanceDefs.Proposal memory proposal = dsGovernance.proposals[_proposalId];
        return (
            proposal.canceled,
            proposal.executed,
            proposal.proposer,
            proposal.delay,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.id,
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
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        return dsGovernance.queuedTransactions[_txHash];
    }

    /**
     * @notice This function gets the Governance facet's current
     *         parameters.
     * @return Proposal max operations.
     * @return Voting delay.
     * @return Voting period.
     * @return Grace period.
     * @return Timelock delay.
     * @return Quorum votes threshold.
     * @return Proposal threshold.
     * @return Skip remaining voting threshold.
     */
    function getGovernanceParameters()
        external
        view
        returns (
            uint32,
            uint32,
            uint32,
            uint32,
            uint32,
            uint32,
            uint32,
            uint32
        )
    {
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        return (
            dsGovernance.proposalMaxOperations,
            dsGovernance.votingDelay,
            dsGovernance.votingPeriod,
            dsGovernance.gracePeriod,
            dsGovernance.timelockDelay,
            dsGovernance.quorumVotes,
            dsGovernance.proposalThreshold,
            dsGovernance.skipRemainingVotingThreshold
        );
    }

    /**
     * @notice This function gets the proposal count.
     * @return Proposal count.
     */
    function getProposalCount() external view returns (uint128) {
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        return dsGovernance.proposalCount;
    }

    /**
     * @notice This function gets the latest proposal ID for a user.
     * @param _proposer Proposer's address.
     * @return Proposal ID.
     */
    function getLatestProposalId(address _proposer) external view returns (uint128) {
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        return dsGovernance.latestProposalIds[_proposer];
    }

    /**
     * @notice This function gets the quorum vote count given the
     *         quorum vote percentage relative to the total DDX supply.
     * @return Quorum vote count.
     */
    function getQuorumVoteCount() public view returns (uint96) {
        LibDiamondStorageDerivaDEX.DiamondStorageDerivaDEX storage dsDerivaDEX =
            LibDiamondStorageDerivaDEX.diamondStorageDerivaDEX();
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();

        uint96 totalSupply = dsDerivaDEX.ddxToken.totalSupply().safe96("Governance: amount exceeds 96 bits");
        return totalSupply.proportion96(dsGovernance.quorumVotes, 100);
    }

    /**
     * @notice This function gets the quorum vote count given the
     *         quorum vote percentage relative to the total DDX supply.
     * @return Quorum vote count.
     */
    function getProposerThresholdCount() public view returns (uint96) {
        LibDiamondStorageDerivaDEX.DiamondStorageDerivaDEX storage dsDerivaDEX =
            LibDiamondStorageDerivaDEX.diamondStorageDerivaDEX();
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();

        uint96 totalSupply = dsDerivaDEX.ddxToken.totalSupply().safe96("Governance: amount exceeds 96 bits");
        return totalSupply.proportion96(dsGovernance.proposalThreshold, 100);
    }

    /**
     * @notice This function gets the quorum vote count given the
     *         quorum vote percentage relative to the total DDX supply.
     * @return Quorum vote count.
     */
    function getSkipRemainingVotingThresholdCount() public view returns (uint96) {
        LibDiamondStorageDerivaDEX.DiamondStorageDerivaDEX storage dsDerivaDEX =
            LibDiamondStorageDerivaDEX.diamondStorageDerivaDEX();
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();

        uint96 totalSupply = dsDerivaDEX.ddxToken.totalSupply().safe96("Governance: amount exceeds 96 bits");
        return totalSupply.proportion96(dsGovernance.skipRemainingVotingThreshold, 100);
    }

    /**
     * @notice This function retrieves the status for any given
     *         proposal.
     * @param _proposalId Proposal id.
     * @return Status of proposal.
     */
    function state(uint128 _proposalId) public view returns (GovernanceDefs.ProposalState) {
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        require(dsGovernance.proposalCount >= _proposalId && _proposalId > 0, "Governance: invalid proposal id.");
        GovernanceDefs.Proposal storage proposal = dsGovernance.proposals[_proposalId];

        // Note the 3rd conditional where we can escape out of the vote
        // phase if the for or against votes exceeds the skip remaining
        // voting threshold
        if (proposal.canceled) {
            return GovernanceDefs.ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return GovernanceDefs.ProposalState.Pending;
        } else if (
            (block.number <= proposal.endBlock) &&
            (proposal.forVotes < getSkipRemainingVotingThresholdCount()) &&
            (proposal.againstVotes < getSkipRemainingVotingThresholdCount())
        ) {
            return GovernanceDefs.ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < getQuorumVoteCount()) {
            return GovernanceDefs.ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return GovernanceDefs.ProposalState.Succeeded;
        } else if (proposal.executed) {
            return GovernanceDefs.ProposalState.Executed;
        } else if (block.timestamp >= proposal.eta.add(dsGovernance.gracePeriod)) {
            return GovernanceDefs.ProposalState.Expired;
        } else {
            return GovernanceDefs.ProposalState.Queued;
        }
    }

    function _castVote(
        address _voter,
        uint128 _proposalId,
        bool _support
    ) internal {
        LibDiamondStorageDerivaDEX.DiamondStorageDerivaDEX storage dsDerivaDEX =
            LibDiamondStorageDerivaDEX.diamondStorageDerivaDEX();
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();
        require(state(_proposalId) == GovernanceDefs.ProposalState.Active, "Governance: voting is closed.");
        GovernanceDefs.Proposal storage proposal = dsGovernance.proposals[_proposalId];
        GovernanceDefs.Receipt storage receipt = proposal.receipts[_voter];

        // Ensure voter has not already voted
        require(!receipt.hasVoted, "Governance: voter already voted.");

        // Obtain the token holdings (voting power) for participant at
        // the time voting started. They may have gained or lost tokens
        // since then, doesn't matter.
        uint96 votes = dsDerivaDEX.ddxToken.getPriorVotes(_voter, proposal.startBlock);

        // Ensure voter has nonzero voting power
        require(votes > 0, "Governance: voter has no voting power.");
        if (_support) {
            // Increment the for votes in favor
            proposal.forVotes = proposal.forVotes.add96(votes);
        } else {
            // Increment the against votes
            proposal.againstVotes = proposal.againstVotes.add96(votes);
        }

        // Set receipt attributes based on cast vote parameters
        receipt.hasVoted = true;
        receipt.support = _support;
        receipt.votes = votes;

        emit VoteCast(_voter, _proposalId, _support, votes);
    }

    function getTimelockDelayForSignatures(string[] memory _signatures) internal view returns (uint32) {
        LibDiamondStorageGovernance.DiamondStorageGovernance storage dsGovernance =
            LibDiamondStorageGovernance.diamondStorageGovernance();

        for (uint256 i = 0; i < _signatures.length; i++) {
            if (!dsGovernance.fastPathFunctionSignatures[_signatures[i]]) {
                return dsGovernance.timelockDelay;
            }
        }
        return 1;
    }

    function requireSkipRemainingVotingThresholdGtQuorumVotes(uint32 _skipRemainingVotingThreshold, uint32 _quorumVotes)
        internal
        pure
    {
        require(_skipRemainingVotingThreshold > _quorumVotes, "Governance: skip rem votes must be higher than quorum.");
    }

    function requireValidSkipRemainingVotingThreshold(uint32 _skipRemainingVotingThreshold) internal pure {
        require(_skipRemainingVotingThreshold >= 50, "Governance: skip rem votes must be higher than 50pct.");
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}