// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "BaseAccount.sol";

contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

interface IGnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations and return data
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    function enableModule(address module) external;

    function isModuleEnabled(address module) external view returns (bool);
}

/// @title CoboSafeAccount - A GnosisSafe module that implements customized access control
/// @author Cobo Safe Dev Team https://www.cobo.com/
contract CoboSafeAccount is BaseAccount {
    using TxFlags for uint256;

    bytes32 public constant NAME = "CoboSafeAccount";
    uint256 public constant VERSION = 1;

    constructor(address _owner) BaseAccount(_owner) {}

    /// @notice The safe of the CoboSafeAccount.
    function safe() public view returns (address) {
        return owner;
    }

    /// @dev Execute the transaction from the safe.
    function _executeTransaction(
        TransactionData memory transaction
    ) internal override returns (TransactionResult memory result) {
        // execute the transaction from Gnosis Safe, note this call will bypass
        // safe owners confirmation.
        (result.success, result.data) = IGnosisSafe(payable(safe())).execTransactionFromModuleReturnData(
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.flag.isDelegateCall() ? Enum.Operation.DelegateCall : Enum.Operation.Call
        );
    }

    /// @dev Account address is the safe address.
    function _getAccountAddress() internal view override returns (address account) {
        account = safe();
    }
}