//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

/**
 * The base interface for the Azorius governance Safe module.
 * Azorius conforms to the Zodiac pattern for Safe modules: https://github.com/gnosis/zodiac
 *
 * Azorius manages the state of Proposals submitted to a DAO, along with the associated strategies
 * ([BaseStrategy](../BaseStrategy.md)) for voting that are enabled on the DAO.
 *
 * Any given DAO can support multiple voting BaseStrategies, and these strategies are intended to be
 * as customizable as possible.
 *
 * Proposals begin in the `ACTIVE` state and will ultimately end in either
 * the `EXECUTED`, `EXPIRED`, or `FAILED` state.
 *
 * `ACTIVE` - a new proposal begins in this state, and stays in this state
 *          for the duration of its voting period.
 *
 * `TIMELOCKED` - A proposal that passes enters the `TIMELOCKED` state, during which
 *          it cannot yet be executed.  This is to allow time for token holders
 *          to potentially exit their position, as well as parent DAOs time to
 *          initiate a freeze, if they choose to do so. A proposal stays timelocked
 *          for the duration of its `timelockPeriod`.
 *
 * `EXECUTABLE` - Following the `TIMELOCKED` state, a passed proposal becomes `EXECUTABLE`,
 *          and can then finally be executed on chain by anyone.
 *
 * `EXECUTED` - the final state for a passed proposal.  The proposal has been executed
 *          on the blockchain.
 *
 * `EXPIRED` - a passed proposal which is not executed before its `executionPeriod` has
 *          elapsed will be `EXPIRED`, and can no longer be executed.
 *
 * `FAILED` - a failed proposal (as defined by its [BaseStrategy](../BaseStrategy.md) 
 *          `isPassed` function). For a basic strategy, this would mean it received more 
 *          NO votes than YES or did not achieve quorum. 
 */
interface IAzorius {

    /** Represents a transaction to perform on the blockchain. */
    struct Transaction {
        address to; // destination address of the transaction
        uint256 value; // amount of ETH to transfer with the transaction
        bytes data; // encoded function call data of the transaction
        Enum.Operation operation; // Operation type, Call or DelegateCall
    }

    /** Holds details pertaining to a single proposal. */
    struct Proposal {
        uint32 executionCounter; // count of transactions that have been executed within the proposal
        uint32 timelockPeriod; // time (in blocks) this proposal will be timelocked for if it passes
        uint32 executionPeriod; // time (in blocks) this proposal has to be executed after timelock ends before it is expired
        address strategy; // BaseStrategy contract this proposal was created on
        bytes32[] txHashes; // hashes of the transactions that are being proposed
    }

    /** The list of states in which a Proposal can be in at any given time. */
    enum ProposalState {
        ACTIVE,
        TIMELOCKED,
        EXECUTABLE,
        EXECUTED,
        EXPIRED,
        FAILED
    }

    /**
     * Enables a [BaseStrategy](../BaseStrategy.md) implementation for newly created Proposals.
     *
     * Multiple strategies can be enabled, and new Proposals will be able to be
     * created using any of the currently enabled strategies.
     *
     * @param _strategy contract address of the BaseStrategy to be enabled
     */
    function enableStrategy(address _strategy) external;

    /**
     * Disables a previously enabled [BaseStrategy](../BaseStrategy.md) implementation for new proposals.
     * This has no effect on existing Proposals, either `ACTIVE` or completed.
     *
     * @param _prevStrategy BaseStrategy address that pointed in the linked list to the strategy to be removed
     * @param _strategy address of the BaseStrategy to be removed
     */
    function disableStrategy(address _prevStrategy, address _strategy) external;

    /**
     * Updates the `timelockPeriod` for newly created Proposals.
     * This has no effect on existing Proposals, either `ACTIVE` or completed.
     *
     * @param _timelockPeriod timelockPeriod (in blocks) to be used for new Proposals
     */
    function updateTimelockPeriod(uint32 _timelockPeriod) external;

    /**
     * Updates the execution period for future Proposals.
     *
     * @param _executionPeriod new execution period (in blocks)
     */
    function updateExecutionPeriod(uint32 _executionPeriod) external;

    /**
     * Submits a new Proposal, using one of the enabled [BaseStrategies](../BaseStrategy.md).
     * New Proposals begin immediately in the `ACTIVE` state.
     *
     * @param _strategy address of the BaseStrategy implementation which the Proposal will use
     * @param _data arbitrary data passed to the BaseStrategy implementation. This may not be used by all strategies, 
     * but is included in case future strategy contracts have a need for it
     * @param _transactions array of transactions to propose
     * @param _metadata additional data such as a title/description to submit with the proposal
     */
    function submitProposal(
        address _strategy,
        bytes memory _data,
        Transaction[] calldata _transactions,
        string calldata _metadata
    ) external;

    /**
     * Executes all transactions within a Proposal.
     * This will only be able to be called if the Proposal passed.
     *
     * @param _proposalId identifier of the Proposal
     * @param _targets target contracts for each transaction
     * @param _values ETH values to be sent with each transaction
     * @param _data transaction data to be executed
     * @param _operations Calls or Delegatecalls
     */
    function executeProposal(
        uint32 _proposalId,
        address[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _data,
        Enum.Operation[] memory _operations
    ) external;

    /**
     * Returns whether a [BaseStrategy](../BaseStrategy.md) implementation is enabled.
     *
     * @param _strategy contract address of the BaseStrategy to check
     * @return bool True if the strategy is enabled, otherwise False
     */
    function isStrategyEnabled(address _strategy) external view returns (bool);

    /**
     * Returns an array of enabled [BaseStrategy](../BaseStrategy.md) contract addresses.
     * Because the list of BaseStrategies is technically unbounded, this
     * requires the address of the first strategy you would like, along
     * with the total count of strategies to return, rather than
     * returning the whole list at once.
     *
     * @param _startAddress contract address of the BaseStrategy to start with
     * @param _count maximum number of BaseStrategies that should be returned
     * @return _strategies array of BaseStrategies
     * @return _next next BaseStrategy contract address in the linked list
     */
    function getStrategies(
        address _startAddress,
        uint256 _count
    ) external view returns (address[] memory _strategies, address _next);

    /**
     * Gets the state of a Proposal.
     *
     * @param _proposalId identifier of the Proposal
     * @return ProposalState uint256 ProposalState enum value representing the
     *         current state of the proposal
     */
    function proposalState(uint32 _proposalId) external view returns (ProposalState);

    /**
     * Generates the data for the module transaction hash (required for signing).
     *
     * @param _to target address of the transaction
     * @param _value ETH value to send with the transaction
     * @param _data encoded function call data of the transaction
     * @param _operation Enum.Operation to use for the transaction
     * @param _nonce Safe nonce of the transaction
     * @return bytes hashed transaction data
     */
    function generateTxHashData(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation,
        uint256 _nonce
    ) external view returns (bytes memory);

    /**
     * Returns the `keccak256` hash of the specified transaction.
     *
     * @param _to target address of the transaction
     * @param _value ETH value to send with the transaction
     * @param _data encoded function call data of the transaction
     * @param _operation Enum.Operation to use for the transaction
     * @return bytes32 transaction hash
     */
    function getTxHash(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation
    ) external view returns (bytes32);

    /**
     * Returns the hash of a transaction in a Proposal.
     *
     * @param _proposalId identifier of the Proposal
     * @param _txIndex index of the transaction within the Proposal
     * @return bytes32 hash of the specified transaction
     */
    function getProposalTxHash(uint32 _proposalId, uint32 _txIndex) external view returns (bytes32);

    /**
     * Returns the transaction hashes associated with a given `proposalId`.
     *
     * @param _proposalId identifier of the Proposal to get transaction hashes for
     * @return bytes32[] array of transaction hashes
     */
    function getProposalTxHashes(uint32 _proposalId) external view returns (bytes32[] memory);

    /**
     * Returns details about the specified Proposal.
     *
     * @param _proposalId identifier of the Proposal
     * @return _strategy address of the BaseStrategy contract the Proposal is on
     * @return _txHashes hashes of the transactions the Proposal contains
     * @return _timelockPeriod time (in blocks) the Proposal is timelocked for
     * @return _executionPeriod time (in blocks) the Proposal must be executed within, after timelock ends
     * @return _executionCounter counter of how many of the Proposals transactions have been executed
     */
    function getProposal(uint32 _proposalId) external view
        returns (
            address _strategy,
            bytes32[] memory _txHashes,
            uint32 _timelockPeriod,
            uint32 _executionPeriod,
            uint32 _executionCounter
        );
}