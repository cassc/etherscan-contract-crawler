// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@ensofinance/weiroll/contracts/VM.sol";
import "./access/AccessController.sol";
import "./wallet/ERC1271.sol";
import "./wallet/MinimalWallet.sol";
import "./interfaces/IEnsoWallet.sol";

contract EnsoWallet is IEnsoWallet, VM, AccessController, ERC1271, MinimalWallet {
    using StorageAPI for bytes32;

    // Using same slot generation technique as eip-1967 -- https://eips.ethereum.org/EIPS/eip-1967
    bytes32 internal constant SALT = bytes32(uint256(keccak256("enso.wallet.salt")) - 1);

    error AlreadyInit();

    // @notice Initialize wallet by setting state and permissions
    // @dev A wallet is considered initialized if the SALT is set in state. Subsequent calls to this function will fail.
    // @param owner The address of the wallet owner
    // @param salt The salt used to deploy the proxy that uses this contract as it's implementation
    // @param shortcutId The bytes32 value representing a shortcut
    // @param commands The optional commands for executing a shortcut
    // @param state The optional state for executing a shortcut
    function initialize(
        address owner,
        bytes32 salt,
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) external override payable {
        if (SALT.getBytes32() != bytes32(0)) revert AlreadyInit();
        SALT.setBytes32(salt);
        _setPermission(OWNER_ROLE, owner, true);
        _setPermission(EXECUTOR_ROLE, owner, true);
        if (commands.length != 0) {
            _executeShortcut(shortcutId, commands, state);
        }
    }

    // @notice A function to execute an arbitrary call on another contract
    // @param target The address of the target contract
    // @param value The ether value that is to be sent with the call
    // @param data The call data to be sent to the target
    function execute(
        address target,
        uint256 value,
        bytes memory data
    ) external payable isPermitted(EXECUTOR_ROLE) returns (bool success) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := call(gas(), target, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    // @notice Execute a shortcut from this contract
    // @param shortcutId The bytes32 value representing a shortcut
    // @param commands An array of bytes32 values that encode calls
    // @param state An array of bytes that are used to generate call data for each command
    function executeShortcut(
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    )
        external
        payable
        isPermitted(EXECUTOR_ROLE)
        returns (bytes[] memory returnData)
    {
        returnData = _executeShortcut(shortcutId, commands, state);
    }

    // @notice Internal function to execute a shortcut from this contract
    // @param shortcutId The bytes32 value representing a shortcut
    // @param commands An array of bytes32 values that encode calls
    // @param state An array of bytes that are used to generate call data for each command
    function _executeShortcut(
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    )
        internal
        returns (bytes[] memory returnData)
    {
        (shortcutId); // ShortcutId just needs to be retrieved from call data, can support events in future upgrade
        returnData = _execute(commands, state);
    }


    // @notice Internal function for checking the ERC-1271 signer
    // @param signer The address that signed a message
    function _checkSigner(address signer) internal view override returns (bool) {
        return _getPermission(OWNER_ROLE, signer);
    }
}