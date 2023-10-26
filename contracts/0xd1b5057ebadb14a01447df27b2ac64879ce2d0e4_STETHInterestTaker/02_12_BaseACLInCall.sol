// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "EnumerableSet.sol";

import "BaseAuthorizer.sol";

/// @title BaseACL - Basic ACL template which uses the call-self trick to perform function and parameters check.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @dev Steps to extend this:
///        1. Set the NAME, VERSION, TYPE.
///        2. Write ACL functions according the target contract.
///        3. Add a constructor. eg:
///           `constructor(address _owner, address _caller) BaseACL(_owner, _caller) {}`
///        4. Override `contracts()` to only target contracts that you checks. Transactions
////          whose `to` address is not in the list will revert.
///        5. (Optional) If state changing operation in the checking method is required,
///           override `_preExecCheck()` to change `staticcall` to `call`.
///
///      NOTE for ACL developers:
///        1. The checking functions can be defined extractly the same as the target method
///           to control thus developers do not bother to write a lot `abi.decode` code.
///        2. Checking funtions should NOT contain return value, use `require` to perform check.
///        3. BaseACL may serve for multiple target contracts.
///            - Implement contracts() to manage the target contracts set.
///            - Use `onlyContract` modifier or check `_txn().to` in checking functions.
///        4. `onlyOwner` modifier should be used for customized setter functions.

abstract contract BaseACLInCall is BaseAuthorizer {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @dev Set such constants in sub contract.
    // bytes32 public constant NAME = "BaseACL";
    // bytes32 public constant override TYPE = "ACLType";
    // uint256 public constant VERSION = 0;

    /// Only preExecCheck is used in BaseACL and hint is not supported.
    uint256 public constant flag = AuthFlags.HAS_PRE_CHECK_MASK;

    constructor(address _owner, address _caller) BaseAuthorizer(_owner, _caller) {}

    /// Internal functions.
    function _parseReturnData(
        bool success,
        bytes memory revertData
    ) internal pure returns (AuthorizerReturnData memory authData) {
        if (success) {
            // ACL checking functions should not return any bytes which differs from normal view functions.
            require(revertData.length == 0, Errors.ACL_FUNC_RETURNS_NON_EMPTY);
            authData.result = AuthResult.SUCCESS;
        } else {
            if (revertData.length < 68) {
                // 4(Error sig) + 32(offset) + 32(length)
                authData.message = string(revertData);
            } else {
                assembly {
                    // Slice the sighash.
                    revertData := add(revertData, 0x04)
                }
                authData.message = abi.decode(revertData, (string));
            }
        }
    }

    function _contractCheck(TransactionData calldata transaction) internal virtual returns (bool result) {
        // This works as a catch-all check. Sample but safer.
        address to = transaction.to;
        address[] memory _contracts = contracts();
        for (uint i = 0; i < _contracts.length; i++) {
            if (to == _contracts[i]) return true;
        }
        return false;
    }

    function _packTxn(TransactionData calldata transaction) internal pure virtual returns (bytes memory) {
        bytes memory txnData = abi.encode(transaction);
        bytes memory callDataSize = abi.encode(transaction.data.length);
        return abi.encodePacked(transaction.data, txnData, callDataSize);
    }

    function _unpackTxn() internal pure virtual returns (TransactionData memory transaction) {
        uint256 end = msg.data.length;
        uint256 callDataSize = abi.decode(msg.data[end - 32:end], (uint256));
        transaction = abi.decode(msg.data[callDataSize:], (TransactionData));
    }

    // @dev Only valid in self-call checking functions.
    function _txn() internal pure virtual returns (TransactionData memory transaction) {
        return _unpackTxn();
    }

    function _preExecCheck(
        TransactionData calldata transaction
    ) internal virtual override returns (AuthorizerReturnData memory authData) {
        if (!_contractCheck(transaction)) {
            authData.result = AuthResult.FAILED;
            authData.message = Errors.NOT_IN_CONTRACT_LIST;
            return authData;
        }
        (bool success, bytes memory revertData) = address(this).call(_packTxn(transaction));
        return _parseReturnData(success, revertData);
    }

    function _postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) internal virtual override returns (AuthorizerReturnData memory authData) {
        authData.result = AuthResult.SUCCESS;
    }

    // Internal view functions.

    // Utilities for checking functions.
    function _checkRecipient(address _recipient) internal view {
        require(_recipient == _txn().from, "Invalid recipient");
    }

    function _checkContract(address _contract) internal view {
        require(_contract == _txn().to, "Invalid contract");
    }

    // Modifiers.

    modifier onlyContract(address _contract) {
        _checkContract(_contract);
        _;
    }

    modifier nonPayable() {
        require(_txn().value == 0, "Invalid tx value");
        _;
    }

    /// External functions

    /// @dev Implement your own access control checking functions here.

    // example:

    // function transfer(address to, uint256 amount)
    //     onlyContract(USDT_ADDR)
    //     external view
    // {
    //     require(amount > 0 & amount < 10000, "amount not in range");
    // }

    /// @dev Override this cause it is used by `_preExecCheck`.
    /// @notice Target contracts this BaseACL controls.
    function contracts() public view virtual returns (address[] memory _contracts) {}

    fallback() external virtual {
        revert(Errors.METHOD_NOT_ALLOW);
    }
}