// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "BaseOwnable.sol";
import "Errors.sol";
import "IAuthorizer.sol";
import "IAccount.sol";
import "IRoleManager.sol";

/// @title BaseAuthorizer - A basic pausable authorizer with caller restriction.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @dev Base contract to extend to implement specific authorizer.
abstract contract BaseAuthorizer is IAuthorizer, BaseOwnable {
    /// @dev Override such constants while extending BaseAuthorizer.

    bool public paused = false;

    // Often used for off-chain system.
    // Each contract instance has its own value.
    bytes32 public tag = "";

    // The caller which is able to call this contract's pre/postExecProcess
    // and pre/postExecCheck having side-effect.
    // It is usually the account or the parent authorizer(set) on higher level.
    address public caller;

    // This is the account this authorizer works for.
    // Currently used to lookup `roleManager`.
    // If not used it is OK to keep it unset.
    address public account;

    event CallerSet(address indexed caller);
    event AccountSet(address indexed account);
    event TagSet(bytes32 indexed tag);
    event PausedSet(bool indexed status);

    constructor(address _owner, address _caller) BaseOwnable(_owner) {
        caller = _caller;
    }

    function initialize(address _owner, address _caller) public {
        initialize(_owner);
        caller = _caller;
        emit CallerSet(_caller);
    }

    function initialize(address _owner, address _caller, address _account) public {
        initialize(_owner, _caller);
        account = _account;
        emit AccountSet(_account);
    }

    modifier onlyCaller() virtual {
        require(msg.sender == caller, Errors.INVALID_CALLER);
        _;
    }

    /// @notice Change the caller.
    /// @param _caller the caller which calls the authorizer.
    function setCaller(address _caller) external onlyOwner {
        caller = _caller;
        emit CallerSet(_caller);
    }

    /// @notice Change the account.
    /// @param _account the account which the authorizer get role manager from.
    function setAccount(address _account) external onlyOwner {
        account = _account;
        emit AccountSet(_account);
    }

    /// @notice Change the tag for the contract instance.
    /// @dev For off-chain index.
    /// @param _tag the tag
    function setTag(bytes32 _tag) external onlyOwner {
        tag = _tag;
        emit TagSet(_tag);
    }

    /// @notice Set the pause status. Authorizer just denies all when paused.
    /// @param _paused the paused status: true or false.
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit PausedSet(_paused);
    }

    /// @notice Function check if a transaction can be executed.
    /// @param transaction Transaction data which contains from,to,value,data,delegate
    /// @return authData Return check status, error message and hint (if needed)
    function preExecCheck(
        TransactionData calldata transaction
    ) external virtual onlyCaller returns (AuthorizerReturnData memory authData) {
        if (paused) {
            authData.result = AuthResult.FAILED;
            authData.message = Errors.AUTHORIZER_PAUSED;
        } else {
            authData = _preExecCheck(transaction);
        }
    }

    /// @notice Check after transaction execution.
    /// @param transaction Transaction data which contains from,to,value,data,delegate
    /// @param callResult Transaction call status and return data.
    function postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) external virtual onlyCaller returns (AuthorizerReturnData memory authData) {
        if (paused) {
            authData.result = AuthResult.FAILED;
            authData.message = Errors.AUTHORIZER_PAUSED;
        } else {
            authData = _postExecCheck(transaction, callResult, preData);
        }
    }

    /// @dev Perform actions before the transaction execution.
    /// `onlyCaller` check forced here or attacker can call this directly
    /// to pollute our data.
    function preExecProcess(TransactionData calldata transaction) external virtual onlyCaller {
        if (!paused) _preExecProcess(transaction);
    }

    /// @dev Perform actions after the transaction execution.
    /// `onlyCaller` check forced here or attacker can call this directly
    /// to pollute our data.
    function postExecProcess(
        TransactionData calldata transaction,
        TransactionResult calldata callResult
    ) external virtual onlyCaller {
        if (!paused) _postExecProcess(transaction, callResult);
    }

    /// @dev Extract the roles of the delegate. If no roleManager set return empty lists.
    function _authenticate(TransactionData calldata transaction) internal view returns (bytes32[] memory roles) {
        return _authenticate(transaction.delegate);
    }

    function _authenticate(address delegate) internal view returns (bytes32[] memory roles) {
        require(account != address(0), Errors.ACCOUNT_NOT_SET);
        address roleManager = IAccount(account).roleManager();
        require(roleManager != address(0), Errors.ROLE_MANAGER_NOT_SET);
        roles = IRoleManager(roleManager).getRoles(delegate);
    }

    /// @dev Call `roleManager` to validate the role of delegate.
    function _hasRole(TransactionData calldata transaction, bytes32 role) internal view returns (bool) {
        return _hasRole(transaction.delegate, role);
    }

    function _hasRole(address delegate, bytes32 role) internal view returns (bool) {
        require(account != address(0), Errors.ACCOUNT_NOT_SET);
        address roleManager = IAccount(account).roleManager();
        require(roleManager != address(0), Errors.ROLE_MANAGER_NOT_SET);
        return IRoleManager(roleManager).hasRole(delegate, role);
    }

    /// @dev Override this to implement new authorization.
    ///      NOTE: If your check involves side-effect, onlyCaller should be used.
    function _preExecCheck(
        TransactionData calldata transaction
    ) internal virtual returns (AuthorizerReturnData memory authData) {}

    /// @dev Override this to implement new authorization.
    function _postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) internal virtual returns (AuthorizerReturnData memory) {}

    function _preExecProcess(TransactionData calldata transaction) internal virtual {}

    function _postExecProcess(
        TransactionData calldata transaction,
        TransactionResult calldata callResult
    ) internal virtual {}

    /// @dev Override this if you implement new type of authorizer.
    function TYPE() external view virtual returns (bytes32) {
        return AuthType.COMMON;
    }
}