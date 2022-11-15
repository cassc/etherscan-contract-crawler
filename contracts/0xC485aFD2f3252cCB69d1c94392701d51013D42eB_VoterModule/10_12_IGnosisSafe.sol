// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IGnosisSafe {
    event DisabledModule(address module);
    event EnabledModule(address module);

    enum Operation {
        Call,
        DelegateCall
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) external returns (bool success);

    function enableModule(address module) external;
    
    function disableModule(address prevModule, address module) external;

    function getModules() external view returns (address[] memory);

    function isModuleEnabled(address module) external view returns (bool);
}