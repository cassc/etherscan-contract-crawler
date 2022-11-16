// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "../abstracts/MixinOperatorResolver.sol";

/// @title Operator address resolver interface
interface IOperatorResolver {
    /// @dev Represents an operator definition
    /// @param implementation Contract address
    /// @param selector Function selector
    struct Operator {
        address implementation;
        bytes4 selector;
    }

    /// @notice Emitted when an operator is imported
    /// @param name The operator name
    /// @param destination The operator definition
    event OperatorImported(bytes32 name, Operator destination);

    /// @notice Get an operator (address/selector) for a given name
    /// @param name The operator name
    /// @return The operator struct (address/selector)
    function getOperator(bytes32 name) external view returns (Operator memory);

    /// @notice Get an operator (address/selector) for a given name but require the operator to exist.
    /// @param name The operator name
    /// @param reason Require message
    /// @return The operator struct (address/selector)
    function requireAndGetOperator(bytes32 name, string calldata reason) external view returns (Operator memory);

    /// @notice Check if some operators are imported with the right name (and vice versa)
    /// @dev The check is performed on the index, make sure that the two arrays match
    /// @param names The operator names
    /// @param destinations The operator addresses
    /// @return True if all the addresses/names are correctly imported, false otherwise
    function areOperatorsImported(bytes32[] calldata names, Operator[] calldata destinations)
        external
        view
        returns (bool);

    /// @notice Import/replace operators
    /// @dev names and destinations arrays must coincide
    /// @param names Hashes of the operators names to register
    /// @param operatorsToImport Operators to import
    /// @param destinations Destinations to rebuild cache atomically
    function importOperators(
        bytes32[] calldata names,
        Operator[] calldata operatorsToImport,
        MixinOperatorResolver[] calldata destinations
    ) external;
}