// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import "../contracts/utils/Enum.sol";

interface IGnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);
    
    function getOwners() external view returns (address[] memory);

    function isOwner(address owner) external view returns (bool);

    function enableModule(address module) external;

    function checkSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) external view;

    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes32);

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) external payable virtual returns (bool success);

    function signedMessages(bytes32) external view returns(uint256);

    function domainSeparator() external view returns (bytes32);

    function addOwnerWithThreshold(address owner, uint256 _threshold) external;

    function removeOwner(
        address prevOwner,
        address owner,
        uint256 _threshold
    ) external;

    function approveHash(bytes32 hashToApprove) external;

    function getModules() external view returns (address[] memory);

    function changeThreshold(uint256 _threshold) external;
    
}