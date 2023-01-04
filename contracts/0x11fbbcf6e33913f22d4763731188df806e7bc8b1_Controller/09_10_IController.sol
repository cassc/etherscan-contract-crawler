// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAnnotated} from "./IAnnotated.sol";
import {ICommonErrors} from "./ICommonErrors.sol";

interface IController is IAnnotated, ICommonErrors {
    event AllowPauser(address pauser);
    event DenyPauser(address pauser);

    /// @notice The attempted low level call failed.
    error ExecFailed(bytes data);

    /// @notice Given a Controllable contract address, set a named dependency
    /// to the given contract address.
    /// @param _contract address of the Controllable contract.
    /// @param _name bytes32 name of the dependency to set.
    /// @param _dependency address of the dependency.
    function setDependency(address _contract, bytes32 _name, address _dependency) external;

    /// @notice Given an AllowList contract address, add an address to the
    /// allowlist.
    /// @param _allowList address of the AllowList contract.
    /// @param _caller address to allow.
    function allow(address _allowList, address _caller) external;

    /// @notice Given an AllowList contract address, remove an address from the
    /// allowlist.
    /// @param _allowList address of the AllowList contract.
    /// @param _caller address to deny.
    function deny(address _allowList, address _caller) external;

    /// @notice Pause a Pausable contract by address.
    function pause(address _contract) external;

    /// @notice Unpause a Pausable contract by address.
    function unpause(address _contract) external;

    /// @notice Allow an address to call pause and unpause.
    /// @param pauser address to allow.
    function allowPauser(address pauser) external;

    /// @notice Deny an address from calling pause and unpause.
    /// @param pauser address to deny.
    function denyPauser(address pauser) external;

    /// @notice Execute a low level call to `receiver` with the given encoded
    /// `data`.
    /// @param receiver address of the call target.
    /// @param data encoded calldata bytes.
    /// @return Call returndata.
    function exec(address receiver, bytes calldata data) external payable returns (bytes memory);
}