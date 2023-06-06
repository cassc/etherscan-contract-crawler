//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { IMultisigFreezeGuard } from "./interfaces/IMultisigFreezeGuard.sol";
import { IBaseFreezeVoting } from "./interfaces/IBaseFreezeVoting.sol";
import { ISafe } from "./interfaces/ISafe.sol";
import { IGuard } from "@gnosis.pm/zodiac/contracts/interfaces/IGuard.sol";
import { FactoryFriendly } from "@gnosis.pm/zodiac/contracts/factory/FactoryFriendly.sol";
import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import { BaseGuard } from "@gnosis.pm/zodiac/contracts/guard/BaseGuard.sol";

/**
 * Implementation of [IMultisigFreezeGuard](./interfaces/IMultisigFreezeGuard.md).
 */
contract MultisigFreezeGuard is FactoryFriendly, IGuard, IMultisigFreezeGuard, BaseGuard {

    /** Timelock period (in blocks). */
    uint32 public timelockPeriod;

    /** Execution period (in blocks). */
    uint32 public executionPeriod;

    /**
     * Reference to the [IBaseFreezeVoting](./interfaces/IBaseFreezeVoting.md)
     * implementation that determines whether the Safe is frozen.
     */
    IBaseFreezeVoting public freezeVoting;

    /** Reference to the Safe that can be frozen. */
    ISafe public childGnosisSafe;

    /** Mapping of signatures hash to the block during which it was timelocked. */
    mapping(bytes32 => uint32) internal transactionTimelockedBlock;

    event MultisigFreezeGuardSetup(
        address creator,
        address indexed owner,
        address indexed freezeVoting,
        address indexed childGnosisSafe
    );
    event TransactionTimelocked(
        address indexed timelocker,
        bytes32 indexed transactionHash,
        bytes indexed signatures
    );
    event TimelockPeriodUpdated(uint32 timelockPeriod);
    event ExecutionPeriodUpdated(uint32 executionPeriod);

    error AlreadyTimelocked();
    error NotTimelocked();
    error Timelocked();
    error Expired();
    error DAOFrozen();

    constructor() {
      _disableInitializers();
    }

    /**
     * Initialize function, will be triggered when a new instance is deployed.
     *
     * @param initializeParams encoded initialization parameters: `uint256 _timelockPeriod`,
     * `uint256 _executionPeriod`, `address _owner`, `address _freezeVoting`, `address _childGnosisSafe`
     */
    function setUp(bytes memory initializeParams) public override initializer {
        __Ownable_init();
        (
            uint32 _timelockPeriod,
            uint32 _executionPeriod,
            address _owner,
            address _freezeVoting,
            address _childGnosisSafe
        ) = abi.decode(
                initializeParams,
                (uint32, uint32, address, address, address)
            );

        _updateTimelockPeriod(_timelockPeriod);
        _updateExecutionPeriod(_executionPeriod);
        transferOwnership(_owner);
        freezeVoting = IBaseFreezeVoting(_freezeVoting);
        childGnosisSafe = ISafe(_childGnosisSafe);

        emit MultisigFreezeGuardSetup(
            msg.sender,
            _owner,
            _freezeVoting,
            _childGnosisSafe
        );
    }

    /** @inheritdoc IMultisigFreezeGuard*/
    function timelockTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        uint256 nonce
    ) external {
        bytes32 signaturesHash = keccak256(signatures);

        if (transactionTimelockedBlock[signaturesHash] != 0)
            revert AlreadyTimelocked();

        bytes memory transactionHashData = childGnosisSafe
            .encodeTransactionData(
                to,
                value,
                data,
                operation,
                safeTxGas,
                baseGas,
                gasPrice,
                gasToken,
                refundReceiver,
                nonce
            );

        bytes32 transactionHash = keccak256(transactionHashData);

        // if signatures are not valid, this will revert
        childGnosisSafe.checkSignatures(
            transactionHash,
            transactionHashData,
            signatures
        );

        transactionTimelockedBlock[signaturesHash] = uint32(block.number);

        emit TransactionTimelocked(msg.sender, transactionHash, signatures);
    }

    /** @inheritdoc IMultisigFreezeGuard*/
    function updateTimelockPeriod(uint32 _timelockPeriod) external onlyOwner {
        _updateTimelockPeriod(_timelockPeriod);
    }

    /** @inheritdoc IMultisigFreezeGuard*/
    function updateExecutionPeriod(uint32 _executionPeriod) external onlyOwner {
        executionPeriod = _executionPeriod;
    }

    /**
     * Called by the Safe to check if the transaction is able to be executed and reverts
     * if the guard conditions are not met.
     */
    function checkTransaction(
        address,
        uint256,
        bytes memory,
        Enum.Operation,
        uint256,
        uint256,
        uint256,
        address,
        address payable,
        bytes memory signatures,
        address
    ) external view override(BaseGuard, IGuard) {
        bytes32 signaturesHash = keccak256(signatures);

        if (transactionTimelockedBlock[signaturesHash] == 0)
            revert NotTimelocked();

        if (
            block.number <
            transactionTimelockedBlock[signaturesHash] + timelockPeriod
        ) revert Timelocked();

        if (
            block.number >
            transactionTimelockedBlock[signaturesHash] +
                timelockPeriod +
                executionPeriod
        ) revert Expired();

        if (freezeVoting.isFrozen()) revert DAOFrozen();
    }

    /**
     * A callback performed after a transaction is executed on the Safe. This is a required
     * function of the `BaseGuard` and `IGuard` interfaces that we do not make use of.
     */
    function checkAfterExecution(bytes32, bool) external view override(BaseGuard, IGuard) {
        // not implementated
    }

    /** @inheritdoc IMultisigFreezeGuard*/
    function getTransactionTimelockedBlock(bytes32 _signaturesHash) public view returns (uint32) {
        return transactionTimelockedBlock[_signaturesHash];
    }

    /** Internal implementation of `updateTimelockPeriod` */
    function _updateTimelockPeriod(uint32 _timelockPeriod) internal {
        timelockPeriod = _timelockPeriod;
        emit TimelockPeriodUpdated(_timelockPeriod);
    }

    /** Internal implementation of `updateExecutionPeriod` */
    function _updateExecutionPeriod(uint32 _executionPeriod) internal {
        executionPeriod = _executionPeriod;
        emit ExecutionPeriodUpdated(_executionPeriod);
    }
}