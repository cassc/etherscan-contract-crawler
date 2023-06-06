// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity =0.8.19;

import { Module } from "@gnosis.pm/zodiac/contracts/core/Module.sol";
import { IBaseStrategy } from "./interfaces/IBaseStrategy.sol";
import { IAzorius, Enum } from "./interfaces/IAzorius.sol";

/**
 * A Safe module which allows for composable governance.
 * Azorius conforms to the [Zodiac pattern](https://github.com/gnosis/zodiac) for Safe modules.
 *
 * The Azorius contract acts as a central manager of DAO Proposals, maintaining the specifications
 * of the transactions that comprise a Proposal, but notably not the state of voting.
 *
 * All voting details are delegated to [BaseStrategy](./BaseStrategy.md) implementations, of which an Azorius DAO can
 * have any number.
 */
contract Azorius is Module, IAzorius {

    /**
     * The sentinel node of the linked list of enabled [BaseStrategies](./BaseStrategy.md).
     *
     * See https://en.wikipedia.org/wiki/Sentinel_node.
     */
    address internal constant SENTINEL_STRATEGY = address(0x1);

    /**
     * ```
     * keccak256(
     *      "EIP712Domain(uint256 chainId,address verifyingContract)"
     * );
     * ```
     *
     * A unique hash intended to prevent signature collisions.
     *
     * See https://eips.ethereum.org/EIPS/eip-712.
     */
    bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH =
        0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

    /**
     * ```
     * keccak256(
     *      "Transaction(address to,uint256 value,bytes data,uint8 operation,uint256 nonce)"
     * );
     * ```
     *
     * See https://eips.ethereum.org/EIPS/eip-712.
     */
    bytes32 public constant TRANSACTION_TYPEHASH =
        0x72e9670a7ee00f5fbf1049b8c38e3f22fab7e9b85029e85cf9412f17fdd5c2ad;

    /** Total number of submitted Proposals. */
    uint32 public totalProposalCount;

    /** Delay (in blocks) between when a Proposal is passed and when it can be executed. */
    uint32 public timelockPeriod;

    /** Time (in blocks) between when timelock ends and the Proposal expires. */
    uint32 public executionPeriod;

    /** Proposals by `proposalId`. */
    mapping(uint256 => Proposal) internal proposals;

    /** A linked list of enabled [BaseStrategies](./BaseStrategy.md). */
    mapping(address => address) internal strategies;

    event AzoriusSetUp(
        address indexed creator,
        address indexed owner,
        address indexed avatar,
        address target
    );
    event ProposalCreated(
        address strategy,
        uint256 proposalId,
        address proposer,
        Transaction[] transactions,
        string metadata
    );
    event ProposalExecuted(uint32 proposalId, bytes32[] txHashes);
    event EnabledStrategy(address strategy);
    event DisabledStrategy(address strategy);
    event TimelockPeriodUpdated(uint32 timelockPeriod);
    event ExecutionPeriodUpdated(uint32 executionPeriod);

    error InvalidStrategy();
    error StrategyEnabled();
    error StrategyDisabled();
    error InvalidProposal();
    error InvalidProposer();
    error ProposalNotExecutable();
    error InvalidTxHash();
    error TxFailed();
    error InvalidTxs();
    error InvalidArrayLengths();

    constructor() {
      _disableInitializers();
    }

    /**
     * Initial setup of the Azorius instance.
     *
     * @param initializeParams encoded initialization parameters: `address _owner`, 
     * `address _avatar`, `address _target`, `address[] memory _strategies`,
     * `uint256 _timelockPeriod`, `uint256 _executionPeriod`
     */
    function setUp(bytes memory initializeParams) public override initializer {
        (
            address _owner,
            address _avatar,
            address _target,                
            address[] memory _strategies,   // enabled BaseStrategies
            uint32 _timelockPeriod,        // initial timelockPeriod
            uint32 _executionPeriod        // initial executionPeriod
        ) = abi.decode(
                initializeParams,
                (address, address, address, address[], uint32, uint32)
            );
        __Ownable_init();
        avatar = _avatar;
        target = _target;
        _setUpStrategies(_strategies);
        transferOwnership(_owner);
        _updateTimelockPeriod(_timelockPeriod);
        _updateExecutionPeriod(_executionPeriod);

        emit AzoriusSetUp(msg.sender, _owner, _avatar, _target);
    }

    /** @inheritdoc IAzorius*/
    function updateTimelockPeriod(uint32 _timelockPeriod) external onlyOwner {
        _updateTimelockPeriod(_timelockPeriod);
    }

    /** @inheritdoc IAzorius*/
    function updateExecutionPeriod(uint32 _executionPeriod) external onlyOwner {
        _updateExecutionPeriod(_executionPeriod);
    }

    /** @inheritdoc IAzorius*/
    function submitProposal(
        address _strategy,
        bytes memory _data,
        Transaction[] calldata _transactions,
        string calldata _metadata
    ) external {
        if (!isStrategyEnabled(_strategy)) revert StrategyDisabled();
        if (!IBaseStrategy(_strategy).isProposer(msg.sender))
            revert InvalidProposer();

        bytes32[] memory txHashes = new bytes32[](_transactions.length);
        uint256 transactionsLength = _transactions.length;
        for (uint256 i; i < transactionsLength; ) {
            txHashes[i] = getTxHash(
                _transactions[i].to,
                _transactions[i].value,
                _transactions[i].data,
                _transactions[i].operation
            );
            unchecked {
                ++i;
            }
        }

        proposals[totalProposalCount].strategy = _strategy;
        proposals[totalProposalCount].txHashes = txHashes;
        proposals[totalProposalCount].timelockPeriod = timelockPeriod;
        proposals[totalProposalCount].executionPeriod = executionPeriod;

        // not all strategy contracts will necessarily use the txHashes and _data values
        // they are encoded to support any strategy contracts that may need them
        IBaseStrategy(_strategy).initializeProposal(
            abi.encode(totalProposalCount, txHashes, _data)
        );

        emit ProposalCreated(
            _strategy,
            totalProposalCount,
            msg.sender,
            _transactions,
            _metadata
        );

        totalProposalCount++;
    }

    /** @inheritdoc IAzorius*/
    function executeProposal(
        uint32 _proposalId,
        address[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _data,
        Enum.Operation[] memory _operations
    ) external {
        if (_targets.length == 0) revert InvalidTxs();
        if (
            _targets.length != _values.length ||
            _targets.length != _data.length ||
            _targets.length != _operations.length
        ) revert InvalidArrayLengths();
        if (
            proposals[_proposalId].executionCounter + _targets.length >
            proposals[_proposalId].txHashes.length
        ) revert InvalidTxs();
        uint256 targetsLength = _targets.length;
        bytes32[] memory txHashes = new bytes32[](targetsLength);
        for (uint256 i; i < targetsLength; ) {
            txHashes[i] = _executeProposalTx(
                _proposalId,
                _targets[i],
                _values[i],
                _data[i],
                _operations[i]
            );
            unchecked {
                ++i;
            }
        }
        emit ProposalExecuted(_proposalId, txHashes);
    }

    /** @inheritdoc IAzorius*/
    function getStrategies(
        address _startAddress,
        uint256 _count
    ) external view returns (address[] memory _strategies, address _next) {
        // init array with max page size
        _strategies = new address[](_count);

        // populate return array
        uint256 strategyCount = 0;
        address currentStrategy = strategies[_startAddress];
        while (
            currentStrategy != address(0x0) &&
            currentStrategy != SENTINEL_STRATEGY &&
            strategyCount < _count
        ) {
            _strategies[strategyCount] = currentStrategy;
            currentStrategy = strategies[currentStrategy];
            strategyCount++;
        }
        _next = currentStrategy;
        // set correct size of returned array
        assembly {
            mstore(_strategies, strategyCount)
        }
    }

    /** @inheritdoc IAzorius*/
    function getProposalTxHash(uint32 _proposalId, uint32 _txIndex) external view returns (bytes32) {
        return proposals[_proposalId].txHashes[_txIndex];
    }

    /** @inheritdoc IAzorius*/
    function getProposalTxHashes(uint32 _proposalId) external view returns (bytes32[] memory) {
        return proposals[_proposalId].txHashes;
    }

    /** @inheritdoc IAzorius*/
    function getProposal(uint32 _proposalId) external view
        returns (
            address _strategy,
            bytes32[] memory _txHashes,
            uint32 _timelockPeriod,
            uint32 _executionPeriod,
            uint32 _executionCounter
        )
    {
        _strategy = proposals[_proposalId].strategy;
        _txHashes = proposals[_proposalId].txHashes;
        _timelockPeriod = proposals[_proposalId].timelockPeriod;
        _executionPeriod = proposals[_proposalId].executionPeriod;
        _executionCounter = proposals[_proposalId].executionCounter;
    }

    /** @inheritdoc IAzorius*/
    function enableStrategy(address _strategy) public override onlyOwner {
        if (_strategy == address(0) || _strategy == SENTINEL_STRATEGY)
            revert InvalidStrategy();
        if (strategies[_strategy] != address(0)) revert StrategyEnabled();

        strategies[_strategy] = strategies[SENTINEL_STRATEGY];
        strategies[SENTINEL_STRATEGY] = _strategy;

        emit EnabledStrategy(_strategy);
    }

    /** @inheritdoc IAzorius*/
    function disableStrategy(address _prevStrategy, address _strategy) public onlyOwner {
        if (_strategy == address(0) || _strategy == SENTINEL_STRATEGY)
            revert InvalidStrategy();
        if (strategies[_prevStrategy] != _strategy) revert StrategyDisabled();

        strategies[_prevStrategy] = strategies[_strategy];
        strategies[_strategy] = address(0);

        emit DisabledStrategy(_strategy);
    }

    /** @inheritdoc IAzorius*/
    function isStrategyEnabled(address _strategy) public view returns (bool) {
        return
            SENTINEL_STRATEGY != _strategy &&
            strategies[_strategy] != address(0);
    }

    /** @inheritdoc IAzorius*/
    function proposalState(uint32 _proposalId) public view returns (ProposalState) {
        Proposal memory _proposal = proposals[_proposalId];

        if (_proposal.strategy == address(0)) revert InvalidProposal();

        IBaseStrategy _strategy = IBaseStrategy(_proposal.strategy);

        uint256 votingEndBlock = _strategy.votingEndBlock(_proposalId);

        if (block.number <= votingEndBlock) {
            return ProposalState.ACTIVE;
        } else if (!_strategy.isPassed(_proposalId)) {
            return ProposalState.FAILED;
        } else if (_proposal.executionCounter == _proposal.txHashes.length) {
            // a Proposal with 0 transactions goes straight to EXECUTED
            // this allows for the potential for on-chain voting for 
            // "off-chain" executed decisions
            return ProposalState.EXECUTED;
        } else if (block.number <= votingEndBlock + _proposal.timelockPeriod) {
            return ProposalState.TIMELOCKED;
        } else if (
            block.number <=
            votingEndBlock +
                _proposal.timelockPeriod +
                _proposal.executionPeriod
        ) {
            return ProposalState.EXECUTABLE;
        } else {
            return ProposalState.EXPIRED;
        }
    }

    /** @inheritdoc IAzorius*/
    function generateTxHashData(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation,
        uint256 _nonce
    ) public view returns (bytes memory) {
        uint256 chainId = block.chainid;
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_SEPARATOR_TYPEHASH, chainId, this)
        );
        bytes32 transactionHash = keccak256(
            abi.encode(
                TRANSACTION_TYPEHASH,
                _to,
                _value,
                keccak256(_data),
                _operation,
                _nonce
            )
        );
        return
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                domainSeparator,
                transactionHash
            );
    }

    /** @inheritdoc IAzorius*/
    function getTxHash(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation
    ) public view returns (bytes32) {
        return keccak256(generateTxHashData(_to, _value, _data, _operation, 0));
    }

    /**
     * Executes the specified transaction in a Proposal, by index.
     * Transactions in a Proposal must be called in order.
     *
     * @param _proposalId identifier of the proposal
     * @param _target contract to be called by the avatar
     * @param _value ETH value to pass with the call
     * @param _data data to be executed from the call
     * @param _operation Call or Delegatecall
     */
    function _executeProposalTx(
        uint32 _proposalId,
        address _target,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation
    ) internal returns (bytes32 txHash) {
        if (proposalState(_proposalId) != ProposalState.EXECUTABLE)
            revert ProposalNotExecutable();
        txHash = getTxHash(_target, _value, _data, _operation);
        if (
            proposals[_proposalId].txHashes[
                proposals[_proposalId].executionCounter
            ] != txHash
        ) revert InvalidTxHash();

        proposals[_proposalId].executionCounter++;
        
        if (!exec(_target, _value, _data, _operation)) revert TxFailed();
    }

    /**
     * Enables the specified array of [BaseStrategy](./BaseStrategy.md) contract addresses.
     *
     * @param _strategies array of `BaseStrategy` contract addresses to enable
     */
    function _setUpStrategies(address[] memory _strategies) internal {
        strategies[SENTINEL_STRATEGY] = SENTINEL_STRATEGY;
        uint256 strategiesLength = _strategies.length;
        for (uint256 i; i < strategiesLength; ) {
            enableStrategy(_strategies[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * Updates the `timelockPeriod` for future Proposals.
     *
     * @param _timelockPeriod new timelock period (in blocks)
     */
    function _updateTimelockPeriod(uint32 _timelockPeriod) internal {
        timelockPeriod = _timelockPeriod;
        emit TimelockPeriodUpdated(_timelockPeriod);
    }

    /**
     * Updates the `executionPeriod` for future Proposals.
     *
     * @param _executionPeriod new execution period (in blocks)
     */
    function _updateExecutionPeriod(uint32 _executionPeriod) internal {
        executionPeriod = _executionPeriod;
        emit ExecutionPeriodUpdated(_executionPeriod);
    }
}