// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "EnumerableSet.sol";

import "BaseAuthorizer.sol";

/// @title ArgusRootAuthorizer - Default root authorizers for Argus platform.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @notice ArgusRootAuthorizer is a authorizer manager which dispatch the correct
///         sub authorizer according to role of delegate and call type.
///         Hint is supported here so user can get the hint, the correct authorizer
///         in this case,  off-chain (this can be expensive on-chain) and preform
///         on-chain transaction to save gas.
contract ArgusRootAuthorizer is BaseAuthorizer, IAuthorizerSupportingHint {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using TxFlags for uint256;
    using AuthFlags for uint256;

    bytes32 public constant NAME = "ArgusRootAuthorizer";
    uint256 public constant VERSION = 1;
    bytes32 public constant override TYPE = AuthType.SET;

    /// @dev This changes when authorizer adds.
    uint256 private _unionFlag;

    // Roles used in the authorizer.
    EnumerableSet.Bytes32Set roles;

    // `isDelegateCall` => `Role` => `Authorizer address set`
    // true for delegatecall, false for call.
    mapping(bool => mapping(bytes32 => EnumerableSet.AddressSet)) internal authorizerSet;

    // Authorizers who implement process handler (with flag `HAS_POST_PROC_MASK` or `HAS_POST_PROC_MASK`)
    // will added into `processSet` and will be invoked unconditionally at each tx.
    mapping(bool => EnumerableSet.AddressSet) internal processSet;

    /// Events.
    event NewAuthorizerAdded(bool indexed isDelegateCall, bytes32 indexed role, address indexed authorizer);
    event NewProcessAdded(bool indexed isDelegateCall, address indexed authorizer);
    event AuthorizerRemoved(bool indexed isDelegateCall, bytes32 indexed role, address indexed authorizer);
    event ProcessRemoved(bool indexed isDelegateCall, address indexed authorizer);

    constructor(address _owner, address _caller, address _account) BaseAuthorizer(_owner, _caller) {
        // We need role manager.
        account = _account;
    }

    /// @dev pack/unpack should match.
    function _packHint(bytes32 role, address auth, bytes memory subHint) internal pure returns (bytes memory hint) {
        return abi.encodePacked(abi.encode(role, auth), subHint);
    }

    function _unpackHint(bytes calldata hint) internal pure returns (bytes32 role, address auth, bytes memory subHint) {
        (role, auth) = abi.decode(hint[0:64], (bytes32, address));
        subHint = hint[64:];
    }

    /// @dev Catch error of sub authorizers to prevent the case when one authorizer fails reverts the entire
    ///      check chain process.
    function _safePreExecCheck(
        address auth,
        TransactionData calldata transaction
    ) internal returns (AuthorizerReturnData memory preData) {
        try IAuthorizer(auth).preExecCheck(transaction) returns (AuthorizerReturnData memory _preData) {
            return _preData;
        } catch Error(string memory reason) {
            preData.result = AuthResult.FAILED;
            preData.message = reason;
        } catch (bytes memory reason) {
            preData.result = AuthResult.FAILED;
            preData.message = string(reason);
        }
    }

    function _safePostExecCheck(
        address auth,
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData memory preData
    ) internal returns (AuthorizerReturnData memory postData) {
        try IAuthorizer(auth).postExecCheck(transaction, callResult, preData) returns (
            AuthorizerReturnData memory _postData
        ) {
            return _postData;
        } catch Error(string memory reason) {
            postData.result = AuthResult.FAILED;
            postData.message = reason;
        } catch (bytes memory reason) {
            postData.result = AuthResult.FAILED;
            postData.message = string(reason);
        }
    }

    function _safeCollectHint(
        address auth,
        AuthorizerReturnData memory preData,
        AuthorizerReturnData memory postData
    ) internal returns (bytes memory subHint) {
        try IAuthorizerSupportingHint(auth).collectHint(preData, postData) returns (bytes memory _subHint) {
            return _subHint;
        } catch {
            return subHint;
        }
    }

    /// @dev preExecCheck and postExecCheck use extractly the same hint thus
    /// the same sub authorizer is called.
    function _preExecCheckWithHint(
        TransactionData calldata transaction
    ) internal returns (AuthorizerReturnData memory authData) {
        (bytes32 role, address auth, bytes memory subHint) = _unpackHint(transaction.hint);
        uint256 _flag = IAuthorizer(auth).flag();

        // The authorizer from hint should have either PreCheck or PostCheck.
        require(_flag.isValid(), Errors.INVALID_AUTHORIZER_FLAG);

        if (!_flag.hasPreCheck()) {
            // If pre check handler not exist, default success.
            authData.result = AuthResult.SUCCESS;
            return authData;
        }

        // Important: Validate the hint.
        // (1) The role from hint should be validated.
        require(_hasRole(transaction, role), Errors.INVALID_HINT);

        // (2) The authorizer from hint should have been registered with the role.
        bool isDelegateCall = transaction.flag.isDelegateCall();
        require(authorizerSet[isDelegateCall][role].contains(auth), Errors.INVALID_HINT);

        // Cut the hint to sub hint.
        TransactionData memory txn = transaction;
        txn.hint = subHint;

        // In hint path, this should never revert so `_safePreExecCheck()` is not used here.
        return IAuthorizer(auth).preExecCheck(txn);
    }

    function _postExecCheckWithHint(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) internal returns (AuthorizerReturnData memory authData) {
        (bytes32 role, address auth, bytes memory subHint) = _unpackHint(transaction.hint);
        uint256 _flag = IAuthorizer(auth).flag();

        require(_flag.isValid(), Errors.INVALID_AUTHORIZER_FLAG);
        if (!_flag.hasPostCheck()) {
            // If post check handler not exist, default success.
            authData.result = AuthResult.SUCCESS;
            return authData;
        }

        // Important: Validate the hint.
        // (1) The role from hint should be validated.
        require(_hasRole(transaction, role), Errors.INVALID_HINT);

        // (2) The authorizer from hint should have been registered with the role.
        bool isDelegateCall = transaction.flag.isDelegateCall();
        require(authorizerSet[isDelegateCall][role].contains(auth), Errors.INVALID_HINT);

        TransactionData memory txn = transaction;
        txn.hint = subHint;
        return IAuthorizer(auth).postExecCheck(txn, callResult, preData);
    }

    struct PreCheckData {
        bytes32 role;
        address authorizer;
        AuthorizerReturnData authData;
    }

    // This is very expensive on-chain.
    // Should only used to collect hint off-chain.
    PreCheckData[] internal preCheckDataCache;

    function _preExecCheck(
        TransactionData calldata transaction
    ) internal override returns (AuthorizerReturnData memory authData) {
        if (transaction.hint.length > 0) {
            return _preExecCheckWithHint(transaction);
        }

        authData.result = AuthResult.FAILED;
        bytes32[] memory txRoles = _authenticate(transaction);
        uint256 roleLength = txRoles.length;
        if (roleLength == 0) {
            authData.message = Errors.EMPTY_ROLE_SET;
            return authData;
        }

        bool isDelegateCall = transaction.flag.isDelegateCall();
        for (uint256 i = 0; i < roleLength; ++i) {
            bytes32 role = txRoles[i];
            EnumerableSet.AddressSet storage authSet = authorizerSet[isDelegateCall][role];

            uint256 length = authSet.length();

            // Run all pre checks and record auth results.
            for (uint256 j = 0; j < length; ++j) {
                address auth = authSet.at(j);
                AuthorizerReturnData memory preData = _safePreExecCheck(auth, transaction);

                if (preData.result == AuthResult.SUCCESS) {
                    authData.result = AuthResult.SUCCESS;

                    // Only save success results.
                    preCheckDataCache.push(PreCheckData(role, auth, preData));
                }
            }
        }

        if (authData.result == AuthResult.SUCCESS) {
            // Temporary data for post checker to collect hint.
            authData.data = abi.encode(preCheckDataCache);
        } else {
            authData.message = Errors.ALL_AUTH_FAILED;
        }

        delete preCheckDataCache; // gas refund.
    }

    function _postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) internal override returns (AuthorizerReturnData memory postData) {
        if (transaction.hint.length > 0) {
            return _postExecCheckWithHint(transaction, callResult, preData);
        }

        // Get pre check results from preData.
        PreCheckData[] memory preResults = abi.decode(preData.data, (PreCheckData[]));
        uint256 length = preResults.length;

        // We should have reverted in preExecCheck. But safer is better.
        require(length > 0, Errors.INVALID_HINT_COLLECTED);

        bool isDelegateCall = transaction.flag.isDelegateCall();

        for (uint256 i = 0; i < length; ++i) {
            bytes32 role = preResults[i].role;
            address authAddress = preResults[i].authorizer;

            require(authorizerSet[isDelegateCall][role].contains(authAddress), Errors.INVALID_HINT_COLLECTED);

            // Run post check.
            AuthorizerReturnData memory preCheckData = preResults[i].authData;
            postData = _safePostExecCheck(authAddress, transaction, callResult, preCheckData);

            // If pre and post both succeeded, we pass.
            if (postData.result == AuthResult.SUCCESS) {
                // Collect hint of sub authorizer if needed.
                bytes memory subHint;
                if (IAuthorizer(authAddress).flag().supportHint()) {
                    subHint = _safeCollectHint(authAddress, preCheckData, postData);
                }
                postData.data = _packHint(role, authAddress, subHint);
                return postData;
            }
        }
        postData.result = AuthResult.FAILED;
        postData.message = Errors.ALL_AUTH_FAILED;
    }

    function collectHint(
        AuthorizerReturnData calldata preAuthData,
        AuthorizerReturnData calldata postAuthData
    ) public view returns (bytes memory hint) {
        // Use post data as hint.
        hint = postAuthData.data;
    }

    /// @dev All sub preExecProcess / postExecProcess handlers are supposed be called.
    function _preExecProcess(TransactionData calldata transaction) internal virtual override {
        if (!_unionFlag.hasPreProcess()) return;

        bool isDelegateCall = transaction.flag.isDelegateCall();

        EnumerableSet.AddressSet storage procSet = processSet[isDelegateCall];
        uint256 length = procSet.length();
        for (uint256 i = 0; i < length; i++) {
            IAuthorizer auth = IAuthorizer(procSet.at(i));
            if (auth.flag().hasPreProcess()) {
                // Ignore reverts.
                try auth.preExecProcess(transaction) {} catch {}
            }
        }
    }

    function _postExecProcess(
        TransactionData calldata transaction,
        TransactionResult calldata callResult
    ) internal virtual override {
        if (!_unionFlag.hasPostProcess()) return;

        bool isDelegateCall = transaction.flag.isDelegateCall();

        EnumerableSet.AddressSet storage procSet = processSet[isDelegateCall];
        uint256 length = procSet.length();
        for (uint256 i = 0; i < length; i++) {
            IAuthorizer auth = IAuthorizer(procSet.at(i));
            if (auth.flag().hasPostProcess()) {
                // Ignore reverts.
                try auth.postExecProcess(transaction, callResult) {} catch {}
            }
        }
    }

    /// External / Public funtions.
    function addAuthorizer(bool isDelegateCall, bytes32 role, address authorizer) external onlyOwner {
        uint256 _flag = IAuthorizer(authorizer).flag();

        if (authorizerSet[isDelegateCall][role].add(authorizer)) {
            emit NewAuthorizerAdded(isDelegateCall, role, authorizer);

            // Collect flag.
            _unionFlag |= _flag;

            if (_flag.hasPreProcess() || _flag.hasPostProcess()) {
                // An authorizer with process handler can NOT be installed twice as this cause
                // confusion when running process handler twice in one transaction.
                require(processSet[isDelegateCall].add(authorizer), Errors.SAME_PROCESS_TWICE);

                emit NewProcessAdded(isDelegateCall, authorizer);
            }
        }
    }

    function removeAuthorizer(bool isDelegateCall, bytes32 role, address authorizer) external onlyOwner {
        uint256 _flag = IAuthorizer(authorizer).flag();

        if (authorizerSet[isDelegateCall][role].remove(authorizer)) {
            emit AuthorizerRemoved(isDelegateCall, role, authorizer);

            if (_flag.hasPreProcess() || _flag.hasPostProcess()) {
                // It is ok to remove here as we has checked duplication in `addAuthorizer()`.
                if (processSet[isDelegateCall].remove(authorizer)) {
                    emit ProcessRemoved(isDelegateCall, authorizer);

                    if (processSet[isDelegateCall].length() == 0 && processSet[!isDelegateCall].length() == 0) {
                        _unionFlag -= (_unionFlag & (AuthFlags.HAS_PRE_PROC_MASK | AuthFlags.HAS_POST_PROC_MASK));
                    }
                }
            }
        }
    }

    /// External view funtions.

    function flag() external view returns (uint256) {
        return _unionFlag | AuthFlags.SUPPORT_HINT_MASK;
    }

    function authorizerSize(bool isDelegateCall, bytes32 role) external view returns (uint256) {
        return authorizerSet[isDelegateCall][role].length();
    }

    function hasAuthorizer(bool isDelegateCall, bytes32 role, address auth) external view returns (bool) {
        return authorizerSet[isDelegateCall][role].contains(auth);
    }

    function getAuthorizer(bool isDelegateCall, bytes32 role, uint256 i) external view returns (address) {
        return authorizerSet[isDelegateCall][role].at(i);
    }

    /// @dev View function allow user to specify the range in case we have very big set
    ///      which can exhaust the gas of block limit when enumerating the entire list.
    function getAuthorizers(
        bool isDelegateCall,
        bytes32 role,
        uint256 start,
        uint256 end
    ) external view returns (address[] memory auths) {
        uint256 authorizerSetSize = authorizerSet[isDelegateCall][role].length();
        if (end > authorizerSetSize) end = authorizerSetSize;
        auths = new address[](end - start);
        for (uint256 i = 0; i < end - start; i++) {
            auths[i] = authorizerSet[isDelegateCall][role].at(start + i);
        }
    }

    function getAllAuthorizers(bool isDelegateCall, bytes32 role) external view returns (address[] memory) {
        return authorizerSet[isDelegateCall][role].values();
    }

    function getAllRoles() external view returns (bytes32[] memory) {
        return roles.values();
    }
}