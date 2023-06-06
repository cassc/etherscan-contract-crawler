//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

/**
 * A specification for a Safe Guard contract which allows for multi-sig DAOs (Safes)
 * to operate in a fashion similar to [Azorius](../azorius/Azorius.md) token voting DAOs.
 *
 * This Guard is intended to add a timelock period and execution period to a Safe
 * multi-sig contract, allowing parent DAOs to have the ability to properly
 * freeze multi-sig subDAOs.
 *
 * Without a timelock period, a vote to freeze the Safe would not be possible
 * as the multi-sig child could immediately execute any transactions they would like
 * in response.
 *
 * An execution period is also required. This is to prevent executing the transaction after
 * a potential freeze period is enacted. Without it a subDAO could just wait for a freeze
 * period to elapse and then execute their desired transaction.
 *
 * See https://docs.safe.global/learn/safe-core/safe-core-protocol/guards.
 */
interface IMultisigFreezeGuard {

    /**
     * Allows the caller to begin the `timelock` of a transaction.
     *
     * Timelock is the period during which a proposed transaction must wait before being
     * executed, after it has passed.  This period is intended to allow the parent DAO
     * sufficient time to potentially freeze the DAO, if they should vote to do so.
     *
     * The parameters for doing so are identical to [ISafe's](./ISafe.md) `execTransaction` function.
     *
     * @param _to destination address
     * @param _value ETH value
     * @param _data data payload
     * @param _operation Operation type, Call or DelegateCall
     * @param _safeTxGas gas that should be used for the safe transaction
     * @param _baseGas gas costs that are independent of the transaction execution
     * @param _gasPrice max gas price that should be used for this transaction
     * @param _gasToken token address (or 0 if ETH) that is used for the payment
     * @param _refundReceiver address of the receiver of gas payment (or 0 if tx.origin)
     * @param _signatures packed signature data
     * @param _nonce nonce to use for the safe transaction
     */
    function timelockTransaction(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation,
        uint256 _safeTxGas,
        uint256 _baseGas,
        uint256 _gasPrice,
        address _gasToken,
        address payable _refundReceiver,
        bytes memory _signatures,
        uint256 _nonce
    ) external;

    /**
     * Sets the subDAO's timelock period.
     *
     * @param _timelockPeriod new timelock period for the subDAO (in blocks)
     */
    function updateTimelockPeriod(uint32 _timelockPeriod) external;

    /**
     * Updates the execution period.
     *
     * Execution period is the time period during which a subDAO's passed Proposals must be executed,
     * otherwise they will be expired.
     *
     * This period begins immediately after the timelock period has ended.
     *
     * @param _executionPeriod number of blocks a transaction has to be executed within
     */
    function updateExecutionPeriod(uint32 _executionPeriod) external;

    /**
     * Gets the block number that the given transaction was timelocked at.
     *
     * @param _signaturesHash hash of the transaction signatures
     * @return uint32 block number in which the transaction began its timelock period
     */
    function getTransactionTimelockedBlock(bytes32 _signaturesHash) external view returns (uint32);
}