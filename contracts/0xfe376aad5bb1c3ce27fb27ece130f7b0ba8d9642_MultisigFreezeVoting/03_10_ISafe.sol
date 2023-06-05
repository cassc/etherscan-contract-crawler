//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

/**
 * The specification of methods available on a Safe contract wallet.
 * 
 * This interface does not encompass every available function on a Safe,
 * only those which are used within the Azorius contracts.
 *
 * For the complete set of functions available on a Safe, see:
 * https://github.com/safe-global/safe-contracts/blob/main/contracts/Safe.sol
 */
interface ISafe {

    /**
     * Returns the current transaction nonce of the Safe.
     * Each transaction should has a different nonce to prevent replay attacks.
     *
     * @return uint256 current transaction nonce
     */
    function nonce() external view returns (uint256);

    /**
     * Set a guard contract that checks transactions before execution.
     * This can only be done via a Safe transaction.
     *
     * See https://docs.gnosis-safe.io/learn/safe-tools/guards.
     * See https://github.com/safe-global/safe-contracts/blob/main/contracts/base/GuardManager.sol.
     * 
     * @param _guard address of the guard to be used or the 0 address to disable a guard
     */
    function setGuard(address _guard) external;

    /**
     * Executes an arbitrary transaction on the Safe.
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
     * @return success bool whether the transaction was successful or not
     */
    function execTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data,
        Enum.Operation _operation,
        uint256 _safeTxGas,
        uint256 _baseGas,
        uint256 _gasPrice,
        address _gasToken,
        address payable _refundReceiver,
        bytes memory _signatures
    ) external payable returns (bool success);

    /**
     * Checks whether the signature provided is valid for the provided data and hash. Reverts otherwise.
     *
     * @param _dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param _data That should be signed (this is passed to an external validator contract)
     * @param _signatures Signature data that should be verified. Can be packed ECDSA signature 
     *      ({bytes32 r}{bytes32 s}{uint8 v}), contract signature (EIP-1271) or approved hash.
     */
    function checkSignatures(bytes32 _dataHash, bytes memory _data, bytes memory _signatures) external view;

    /**
     * Returns the pre-image of the transaction hash.
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
     * @param _nonce transaction nonce
     * @return bytes hash bytes
     */
    function encodeTransactionData(
        address _to,
        uint256 _value,
        bytes calldata _data,
        Enum.Operation _operation,
        uint256 _safeTxGas,
        uint256 _baseGas,
        uint256 _gasPrice,
        address _gasToken,
        address _refundReceiver,
        uint256 _nonce
    ) external view returns (bytes memory);

    /**
     * Returns if the given address is an owner of the Safe.
     *
     * See https://github.com/safe-global/safe-contracts/blob/main/contracts/base/OwnerManager.sol.
     *
     * @param _owner the address to check
     * @return bool whether _owner is an owner of the Safe
     */
    function isOwner(address _owner) external view returns (bool);
}