// commit 598fda85684ba6303bcecbf60867cf3b0e842650
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
    uint256 public constant VERSION = 2;

    constructor(address _owner) BaseAccount(_owner) {}

    /// @notice The Safe of the CoboSafeAccount.
    function safe() public view returns (address) {
        return owner;
    }

    /// @dev Execute the transaction from the Safe.
    function _executeTransaction(
        TransactionData memory transaction
    ) internal override returns (TransactionResult memory result) {
        // execute the transaction from Gnosis Safe, note this call will bypass
        // Safe owners confirmation.
        (result.success, result.data) = IGnosisSafe(payable(safe())).execTransactionFromModuleReturnData(
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.flag.isDelegateCall() ? Enum.Operation.DelegateCall : Enum.Operation.Call
        );
    }

    /// @dev The account address is the Safe address.
    function _getAccountAddress() internal view override returns (address account) {
        account = safe();
    }
}