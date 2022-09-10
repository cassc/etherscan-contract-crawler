// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./structs/DelegateMapView.sol";
import "./structs/Signature.sol";

/**
 *   @title Manages the state of an accounts delegation settings.
 *   Allows for various methods of validation as well as enabling
 *   different system functions to be delegated to different accounts
 */
interface IDelegateFunction {
    struct AllowedFunctionSet {
        bytes32 id;
    }

    struct FunctionsListPayload {
        bytes32[] sets;
        uint256 nonce;
    }

    struct DelegatePayload {
        DelegateMap[] sets;
        uint256 nonce;
    }

    struct DelegateMap {
        bytes32 functionId;
        address otherParty;
        bool mustRelinquish;
    }

    struct Destination {
        address otherParty;
        bool mustRelinquish;
        bool pending;
    }

    struct DelegatedTo {
        address originalParty;
        bytes32 functionId;
    }

    event AllowedFunctionsSet(AllowedFunctionSet[] functions);
    event PendingDelegationAdded(address from, address to, bytes32 functionId, bool mustRelinquish);
    event PendingDelegationRemoved(
        address from,
        address to,
        bytes32 functionId,
        bool mustRelinquish
    );
    event DelegationRemoved(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationRelinquished(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationAccepted(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationRejected(address from, address to, bytes32 functionId, bool mustRelinquish);

    /// @notice Pause all delegating operations
    function pause() external;

    /// @notice Unpause all delegating operations
    function unpause() external;

    /// @notice Get the current nonce a contract wallet should use
    /// @param account Account to query
    /// @return nonce Nonce that should be used for next call
    function contractWalletNonces(address account) external returns (uint256 nonce);

    /// @notice Get an accounts current delegations
    /// @dev These may be in a pending state
    /// @param from Account that is delegating functions away
    /// @return maps List of delegations in various states of approval
    function getDelegations(address from) external view returns (DelegateMapView[] memory maps);

    /// @notice Get an accounts delegation of a specific function
    /// @dev These may be in a pending state
    /// @param from Account that is the delegation functions away
    /// @return map Delegation info
    function getDelegation(address from, bytes32 functionId)
        external
        view
        returns (DelegateMapView memory map);

    /// @notice Initiate delegation of one or more system functions to different account(s)
    /// @param sets Delegation instructions for the contract to initiate
    function delegate(DelegateMap[] memory sets) external;

    /// @notice Initiate delegation on behalf of a contract that supports ERC1271
    /// @param contractAddress Address of the ERC1271 contract used to verify the given signature
    /// @param delegatePayload Sets of DelegateMap objects
    /// @param signature Signature data
    /// @param signatureType Type of signature used (EIP712|EthSign)
    function delegateWithEIP1271(
        address contractAddress,
        DelegatePayload memory delegatePayload,
        bytes memory signature,
        SignatureType signatureType
    ) external;

    /// @notice Accept one or more delegations from another account
    /// @param incoming Delegation details being accepted
    function acceptDelegation(DelegatedTo[] calldata incoming) external;

    /// @notice Remove one or more delegation that you have previously setup
    function removeDelegation(bytes32[] calldata functionIds) external;

    /// @notice Remove one or more delegations that you have previously setup on behalf of a contract supporting EIP1271
    /// @param contractAddress Address of the ERC1271 contract used to verify the given signature
    /// @param functionsListPayload Sets of FunctionListPayload objects ({sets: bytes32[]})
    /// @param signature Signature data
    /// @param signatureType Type of signature used (EIP712|EthSign)
    function removeDelegationWithEIP1271(
        address contractAddress,
        FunctionsListPayload calldata functionsListPayload,
        bytes memory signature,
        SignatureType signatureType
    ) external;

    /// @notice Reject one or more delegations being sent to you
    /// @param rejections Delegations to reject
    function rejectDelegation(DelegatedTo[] calldata rejections) external;

    /// @notice Remove one or more delegations that you have previously accepted
    function relinquishDelegation(DelegatedTo[] calldata relinquish) external;

    /// @notice Cancel one or more delegations you have setup but that has not yet been accepted
    /// @param functionIds System functions you wish to retain control of
    function cancelPendingDelegation(bytes32[] calldata functionIds) external;

    /// @notice Cancel one or more delegations you have setup on behalf of a contract that supported EIP1271, but that has not yet been accepted
    /// @param contractAddress Address of the ERC1271 contract used to verify the given signature
    /// @param functionsListPayload Sets of FunctionListPayload objects ({sets: bytes32[]})
    /// @param signature Signature data
    /// @param signatureType Type of signature used (EIP712|EthSign)
    function cancelPendingDelegationWithEIP1271(
        address contractAddress,
        FunctionsListPayload calldata functionsListPayload,
        bytes memory signature,
        SignatureType signatureType
    ) external;

    /// @notice Add to the list of system functions that are allowed to be delegated
    /// @param functions New system function ids
    function setAllowedFunctions(AllowedFunctionSet[] calldata functions) external;
}