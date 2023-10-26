//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Firewall
/// @author Figment
/// @notice This interface exposes methods to accept calls to admin-level functions of an underlying contract.
interface IFirewall {
    /// @notice The stored executor address has been changed
    /// @param executor The new executor address
    event SetExecutor(address indexed executor);

    /// @notice The stored destination address has been changed
    /// @param destination The new destination address
    event SetDestination(address indexed destination);

    /// @notice The storage permission for a selector has been changed
    /// @param selector The 4 bytes method selector
    /// @param status True if executor is allowed
    event SetExecutorPermissions(bytes4 selector, bool status);

    /// @notice Retrieve the executor address
    /// @return The executor address
    function executor() external view returns (address);

    /// @notice Retrieve the destination address
    /// @return The destination address
    function destination() external view returns (address);

    /// @notice Returns true if the executor is allowed to perform a call on the given selector
    /// @param _selector The selector to verify
    /// @return True if executor is allowed to call
    function executorCanCall(bytes4 _selector) external view returns (bool);

    /// @notice Sets the executor address
    /// @param _newExecutor New address for the executor
    function setExecutor(address _newExecutor) external;

    /// @notice Sets the permission for a function selector
    /// @param _functionSelector Method signature on which the permission is changed
    /// @param _executorCanCall True if selector is callable by the executor
    function allowExecutor(bytes4 _functionSelector, bool _executorCanCall) external;

    /// @notice Fallback method. All its parameters are forwarded to the destination if caller is authorized
    fallback() external payable;

    /// @notice Receive fallback method. All its parameters are forwarded to the destination if caller is authorized
    receive() external payable;
}