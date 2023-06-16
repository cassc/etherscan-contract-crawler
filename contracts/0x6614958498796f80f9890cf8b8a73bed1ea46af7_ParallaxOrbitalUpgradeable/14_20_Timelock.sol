//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./CheckerZeroAddr.sol";

abstract contract Timelock is
    Initializable,
    ContextUpgradeable,
    CheckerZeroAddr
{
    struct Transaction {
        address dest;
        uint256 value;
        string signature;
        bytes data;
        uint256 exTime;
    }

    enum ProccessType {
        ADDED,
        REMOVED,
        COMPLETED
    }

    /// @notice This event is emitted wwhen something happens with a transaction.
    /// @param transaction information about transaction
    /// @param proccessType action type
    event ProccessTransaction(
        Transaction transaction,
        ProccessType indexed proccessType
    );

    /// @notice error about that the set time is less than the delay
    error MinDelay();

    /// @notice error about that the transaction does not exist
    error NonExistTransaction();

    /// @notice error about that the minimum interval has not passed
    error ExTimeLessThanNow();

    /// @notice error about that the signature is null
    error NullSignature();

    /// @notice error about that the calling transaction is reverted
    error TransactionExecutionReverted(string revertReason);

    uint256 public constant DELAY = 2 days;

    mapping(bytes32 => bool) public transactions;

    modifier onlyInternalCall() {
        _onlyInternalCall();
        _;
    }

    function _addTransaction(
        Transaction memory transaction
    ) internal onlyNonZeroAddress(transaction.dest) returns (bytes32) {
        if (transaction.exTime < block.timestamp + DELAY) {
            revert MinDelay();
        }

        if (bytes(transaction.signature).length == 0) {
            revert NullSignature();
        }

        bytes32 txHash = _getHash(transaction);

        transactions[txHash] = true;

        emit ProccessTransaction(transaction, ProccessType.ADDED);

        return txHash;
    }

    function _removeTransaction(Transaction memory transaction) internal {
        bytes32 txHash = _getHash(transaction);

        transactions[txHash] = false;

        emit ProccessTransaction(transaction, ProccessType.REMOVED);
    }

    function _executeTransaction(
        Transaction memory transaction
    ) internal returns (bytes memory) {
        bytes32 txHash = _getHash(transaction);

        if (!transactions[txHash]) {
            revert NonExistTransaction();
        }

        if (block.timestamp < transaction.exTime) {
            revert ExTimeLessThanNow();
        }

        transactions[txHash] = false;

        bytes memory callData = abi.encodePacked(
            bytes4(keccak256(bytes(transaction.signature))),
            transaction.data
        );
        (bool success, bytes memory result) = transaction.dest.call{
            value: transaction.value
        }(callData);

        if (!success) {
            revert TransactionExecutionReverted(string(result));
        }

        emit ProccessTransaction(transaction, ProccessType.COMPLETED);

        return result;
    }

    function __Timelock_init_unchained() internal onlyInitializing {}

    function _onlyInternalCall() internal view {
        require(_msgSender() == address(this), "Timelock: only internal call");
    }

    function _getHash(
        Transaction memory transaction
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    transaction.dest,
                    transaction.value,
                    transaction.signature,
                    transaction.data,
                    transaction.exTime
                )
            );
    }

    uint256[50] private __gap;
}