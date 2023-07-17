// commit da41ad6c9caa5295bc268cc21b1b83764db6226a
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "EnumerableSet.sol";

import "BaseAuthorizer.sol";

/// @title FuncAuthorizer - Manages contract, method pairs which can be accessed by delegates.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @notice FuncAuthorizer only checks selector. Use ACL if function arguments check is needed.
contract FuncAuthorizer is BaseAuthorizer {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant NAME = "FuncAuthorizer";
    uint256 public constant VERSION = 1;
    uint256 public constant flag = AuthFlags.HAS_PRE_CHECK_MASK;
    bytes32 public constant override TYPE = AuthType.FUNC;

    /// @dev Tracks the set of contract address.
    EnumerableSet.AddressSet contractSet;

    /// @dev `contract address` => `function selectors`
    mapping(address => EnumerableSet.Bytes32Set) allowContractToFuncs;

    /// Events

    event AddContractFunc(address indexed _contract, string func, address indexed sender);
    event AddContractFuncSig(address indexed _contract, bytes4 indexed funcSig, address indexed sender);
    event RemoveContractFunc(address indexed _contract, string func, address indexed sender);
    event RemoveContractFuncSig(address indexed _contract, bytes4 indexed funcSig, address indexed sender);

    constructor(address _owner, address _caller) BaseAuthorizer(_owner, _caller) {}

    function _preExecCheck(
        TransactionData calldata transaction
    ) internal view override returns (AuthorizerReturnData memory authData) {
        // If calldata size is less than a selector, deny it.
        // Use TransferAuthorizer to check ETH transfer.
        if (transaction.data.length < 4) {
            authData.result = AuthResult.FAILED;
            authData.message = "invalid data length";
            return authData;
        }

        bytes4 selector = _getSelector(transaction.data);

        if (_isAllowedSelector(transaction.to, selector)) {
            authData.result = AuthResult.SUCCESS;
        } else {
            authData.result = AuthResult.FAILED;
            authData.message = "function not allowed";
        }
    }

    function _getSelector(bytes calldata data) internal pure returns (bytes4 selector) {
        assembly {
            selector := calldataload(data.offset)
        }
    }

    function _isAllowedSelector(address target, bytes4 selector) internal view returns (bool) {
        return allowContractToFuncs[target].contains(selector);
    }

    /// @dev Default success.
    function _postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) internal view override returns (AuthorizerReturnData memory authData) {
        authData.result = AuthResult.SUCCESS;
    }

    /// @notice Add contract and related function signature list. The function signature should be
    ///         canonicalized removing argument names and blanks chars.
    ///         ref: https://docs.soliditylang.org/en/v0.8.19/abi-spec.html#function-selector
    /// @dev keccak256 hash is calcuated and only 4 bytes selector is stored to reduce storage usage.
    function addContractFuncs(address _contract, string[] calldata funcList) external onlyOwner {
        require(funcList.length > 0, "empty funcList");

        for (uint256 index = 0; index < funcList.length; index++) {
            bytes4 funcSelector = bytes4(keccak256(bytes(funcList[index])));
            bytes32 funcSelector32 = bytes32(funcSelector);
            if (allowContractToFuncs[_contract].add(funcSelector32)) {
                emit AddContractFunc(_contract, funcList[index], msg.sender);
                emit AddContractFuncSig(_contract, funcSelector, msg.sender);
            }
        }

        contractSet.add(_contract);
    }

    /// @notice Remove contract and its function signature list from access list.
    function removeContractFuncs(address _contract, string[] calldata funcList) external onlyOwner {
        require(funcList.length > 0, "empty funcList");

        for (uint256 index = 0; index < funcList.length; index++) {
            bytes4 funcSelector = bytes4(keccak256(bytes(funcList[index])));
            bytes32 funcSelector32 = bytes32(funcSelector);
            if (allowContractToFuncs[_contract].remove(funcSelector32)) {
                emit RemoveContractFunc(_contract, funcList[index], msg.sender);
                emit RemoveContractFuncSig(_contract, funcSelector, msg.sender);
            }
        }

        if (allowContractToFuncs[_contract].length() == 0) {
            contractSet.remove(_contract);
        }
    }

    /// @notice Similar to `addContractFuncs()` but bytes4 selector is used.
    /// @dev keccak256 hash should be performed off-chain.
    function addContractFuncsSig(address _contract, bytes4[] calldata funcSigList) external onlyOwner {
        require(funcSigList.length > 0, "empty funcList");

        for (uint256 index = 0; index < funcSigList.length; index++) {
            bytes32 funcSelector32 = bytes32(funcSigList[index]);
            if (allowContractToFuncs[_contract].add(funcSelector32)) {
                emit AddContractFuncSig(_contract, funcSigList[index], msg.sender);
            }
        }

        contractSet.add(_contract);
    }

    /// @notice Remove contract and its function selector list from access list.
    function removeContractFuncsSig(address _contract, bytes4[] calldata funcSigList) external onlyOwner {
        require(funcSigList.length > 0, "empty funcList");

        for (uint256 index = 0; index < funcSigList.length; index++) {
            bytes32 funcSelector32 = bytes32(funcSigList[index]);
            if (allowContractToFuncs[_contract].remove(funcSelector32)) {
                emit RemoveContractFuncSig(_contract, funcSigList[index], msg.sender);
            }
        }

        if (allowContractToFuncs[_contract].length() == 0) {
            contractSet.remove(_contract);
        }
    }

    /// @notice Get all the contracts ever associated with any role
    /// @return list of contract addresses
    function getAllContracts() public view returns (address[] memory) {
        return contractSet.values();
    }

    /// @notice Given a contract, list all the function selectors of this contract associated with a role
    /// @param _contract the contract
    /// @return list of function selectors in the contract ever associated with a role
    function getFuncsByContract(address _contract) public view returns (bytes32[] memory) {
        return allowContractToFuncs[_contract].values();
    }
}