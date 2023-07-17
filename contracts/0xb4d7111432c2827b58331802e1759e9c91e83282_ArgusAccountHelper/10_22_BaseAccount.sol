// commit da41ad6c9caa5295bc268cc21b1b83764db6226a
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "EnumerableSet.sol";

import "Types.sol";
import "BaseOwnable.sol";
import "IAuthorizer.sol";
import "IAccount.sol";

/// @title BaseAccount - A basic smart contract wallet with access control supported.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @dev Extend this and implement `_executeTransaction()` and `_getFromAddress()`.
abstract contract BaseAccount is IAccount, BaseOwnable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using TxFlags for uint256;
    using AuthFlags for uint256;

    address public roleManager;
    address public authorizer;

    // Simple and basic delegate check.
    EnumerableSet.AddressSet delegates;

    event RoleManagerSet(address indexed roleManager);
    event AuthorizerSet(address indexed authorizer);
    event DelegateAdded(address indexed delegate);
    event DelegateRemoved(address indexed delegate);
    event TransactionExecuted(
        address indexed to,
        bytes4 indexed selector,
        uint256 indexed value,
        TransactionData transaction
    );

    /// @param _owner Who owns the wallet.
    constructor(address _owner) BaseOwnable(_owner) {}

    /// @dev Only used in proxy mode. Can be called only once.
    function initialize(address _owner, address _roleManager, address _authorizer) public {
        initialize(_owner);
        _setRoleManager(_roleManager);
        _setAuthorizer(_authorizer);
    }

    /// Modifiers

    /// @dev Only added delegates are allowed to call `execTransaction`. This provides a kind
    ///      of catch-all rule and simple but strong protection from malicious/compromised/buggy
    ///      authorizers which permit any operations.
    modifier onlyDelegate() {
        require(hasDelegate(msg.sender), Errors.INVALID_DELEGATE);
        _;
    }

    // Public/External functions.
    function setRoleManager(address _roleManager) external onlyOwner {
        _setRoleManager(_roleManager);
    }

    function setAuthorizer(address _authorizer) external onlyOwner {
        _setAuthorizer(_authorizer);
    }

    function addDelegate(address _delegate) external onlyOwner {
        _addDelegate(_delegate);
    }

    function addDelegates(address[] calldata _delegates) external onlyOwner {
        for (uint256 i = 0; i < _delegates.length; i++) {
            _addDelegate(_delegates[i]);
        }
    }

    function removeDelegate(address _delegate) external onlyOwner {
        _removeDelegate(_delegate);
    }

    function removeDelegates(address[] calldata _delegates) external onlyOwner {
        for (uint256 i = 0; i < _delegates.length; i++) {
            _removeDelegate(_delegates[i]);
        }
    }

    /// @notice Called by authenticated delegates to execute transaction on behalf of the wallet account.
    function execTransaction(
        CallData calldata callData
    ) external onlyDelegate returns (TransactionResult memory result) {
        TransactionData memory transaction;
        transaction.from = _getAccountAddress();
        transaction.delegate = msg.sender;
        transaction.flag = callData.flag;
        transaction.to = callData.to;
        transaction.value = callData.value;
        transaction.data = callData.data;
        transaction.hint = callData.hint;
        transaction.extra = callData.extra;

        result = _executeTransactionWithCheck(transaction);
        emit TransactionExecuted(callData.to, bytes4(callData.data), callData.value, transaction);
    }

    /// @notice A Multicall method.
    /// @param callDataList `CallData` array to execute in sequence.
    function execTransactions(
        CallData[] calldata callDataList
    ) external onlyDelegate returns (TransactionResult[] memory resultList) {
        TransactionData memory transaction;
        transaction.from = _getAccountAddress();
        transaction.delegate = msg.sender;

        resultList = new TransactionResult[](callDataList.length);

        for (uint256 i = 0; i < callDataList.length; i++) {
            CallData calldata callData = callDataList[i];
            transaction.to = callData.to;
            transaction.value = callData.value;
            transaction.data = callData.data;
            transaction.flag = callData.flag;
            transaction.hint = callData.hint;
            transaction.extra = callData.extra;

            resultList[i] = _executeTransactionWithCheck(transaction);

            emit TransactionExecuted(callData.to, bytes4(callData.data), callData.value, transaction);
        }
    }

    /// Public/External view functions.

    function hasDelegate(address _delegate) public view returns (bool) {
        return delegates.contains(_delegate);
    }

    function getAllDelegates() external view returns (address[] memory) {
        return delegates.values();
    }

    /// @notice The real address of your smart contract wallet address where
    ///         stores your assets and sends transactions from.
    function getAccountAddress() external view returns (address account) {
        account = _getAccountAddress();
    }

    /// Internal functions.

    function _addDelegate(address _delegate) internal {
        if (delegates.add(_delegate)) {
            emit DelegateAdded(_delegate);
        }
    }

    function _removeDelegate(address _delegate) internal {
        if (delegates.remove(_delegate)) {
            emit DelegateRemoved(_delegate);
        }
    }

    function _setRoleManager(address _roleManager) internal {
        roleManager = _roleManager;
        emit RoleManagerSet(_roleManager);
    }

    function _setAuthorizer(address _authorizer) internal {
        authorizer = _authorizer;
        emit AuthorizerSet(_authorizer);
    }

    /// @dev Override this if we prefer not to revert the entire transaction in
    //       out wallet contract implementation.
    function _preExecCheck(
        TransactionData memory transaction
    ) internal virtual returns (AuthorizerReturnData memory authData) {
        authData = IAuthorizer(authorizer).preExecCheck(transaction);
        require(authData.result == AuthResult.SUCCESS, authData.message);
    }

    function _revertIfTxFails(TransactionResult memory callResult) internal pure {
        bool success = callResult.success;
        bytes memory data = callResult.data;
        if (!success) {
            assembly {
                revert(add(data, 32), data)
            }
        }
    }

    function _postExecCheck(
        TransactionData memory transaction,
        TransactionResult memory callResult,
        AuthorizerReturnData memory predata
    ) internal virtual returns (AuthorizerReturnData memory authData) {
        _revertIfTxFails(callResult);
        authData = IAuthorizer(authorizer).postExecCheck(transaction, callResult, predata);
        require(authData.result == AuthResult.SUCCESS, authData.message);
    }

    function _preExecProcess(TransactionData memory transaction) internal virtual {
        IAuthorizer(authorizer).preExecProcess(transaction);
    }

    function _postExecProcess(
        TransactionData memory transaction,
        TransactionResult memory callResult
    ) internal virtual {
        IAuthorizer(authorizer).postExecProcess(transaction, callResult);
    }

    function _executeTransactionWithCheck(
        TransactionData memory transaction
    ) internal virtual returns (TransactionResult memory result) {
        require(authorizer != address(0), Errors.AUTHORIZER_NOT_SET);
        uint256 flag = IAuthorizer(authorizer).flag();
        bool doCollectHint = transaction.hint.length == 0;

        // Ensures either _preExecCheck or _postExecCheck (or both) will run.
        require(flag.isValid(), Errors.INVALID_AUTHORIZER_FLAG);

        // 1. Do pre check, revert the entire txn if failed.
        AuthorizerReturnData memory preData;
        if (doCollectHint || flag.hasPreCheck()) {
            // Always run _preExecCheck When collecting hint.
            // If not collecting hint, only run if the sub authorizer requires.
            preData = _preExecCheck(transaction);
        }

        // 2. Do pre process.
        if (flag.hasPreProcess()) _preExecProcess(transaction);

        // 3. Execute the transaction.
        result = _executeTransaction(transaction);

        // 4. Do post check, revert the entire txn if failed.
        AuthorizerReturnData memory postData;
        if (doCollectHint || flag.hasPostCheck()) {
            postData = _postExecCheck(transaction, result, preData);
        }

        // 5. Do post process.
        if (flag.hasPostProcess()) _postExecProcess(transaction, result);

        // 6. Collect hint if when (1) no hint provided and (2) the authorizer supports hint mode.
        if (doCollectHint && flag.supportHint()) {
            result.hint = IAuthorizerSupportingHint(authorizer).collectHint(preData, postData);
        }
    }

    /// @dev Instance should implement at least two `virtual` function below.

    /// @param transaction Transaction to execute.
    /// @return result `TransactionResult` which contains call status and return/revert data.
    function _executeTransaction(
        TransactionData memory transaction
    ) internal virtual returns (TransactionResult memory result);

    /// @dev The address of wallet which sends the transaction a.k.a `msg.sender`
    function _getAccountAddress() internal view virtual returns (address account);

    // To receive ETH as a wallet.
    receive() external payable {}
}