// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "./interfaces/IOperatorResolver.sol";
import "./abstracts/MixinOperatorResolver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Operator Resolver implementation
/// @notice Resolve the operators address
contract OperatorResolver is IOperatorResolver, Ownable {
    /// @dev Operators map of the name and address
    mapping(bytes32 => Operator) public operators;

    /// @inheritdoc IOperatorResolver
    function getOperator(bytes32 name) external view override returns (Operator memory) {
        return operators[name];
    }

    /// @inheritdoc IOperatorResolver
    function requireAndGetOperator(bytes32 name, string calldata reason)
        external
        view
        override
        returns (Operator memory)
    {
        Operator memory _foundOperator = operators[name];
        require(_foundOperator.implementation != address(0), reason);
        return _foundOperator;
    }

    /// @inheritdoc IOperatorResolver
    function areOperatorsImported(bytes32[] calldata names, Operator[] calldata destinations)
        external
        view
        override
        returns (bool)
    {
        uint256 namesLength = names.length;
        require(namesLength == destinations.length, "OR: INPUTS_LENGTH_MUST_MATCH");
        for (uint256 i = 0; i < namesLength; i++) {
            if (
                operators[names[i]].implementation != destinations[i].implementation ||
                operators[names[i]].selector != destinations[i].selector
            ) {
                return false;
            }
        }
        return true;
    }

    /// @inheritdoc IOperatorResolver
    function importOperators(
        bytes32[] calldata names,
        Operator[] calldata operatorsToImport,
        MixinOperatorResolver[] calldata destinations
    ) external override onlyOwner {
        require(names.length == operatorsToImport.length, "OR: INPUTS_LENGTH_MUST_MATCH");
        bytes32 name;
        Operator calldata destination;
        for (uint256 i = 0; i < names.length; i++) {
            name = names[i];
            destination = operatorsToImport[i];
            operators[name] = destination;
            emit OperatorImported(name, destination);
        }

        // rebuild caches atomically
        // see. https://github.com/code-423n4/2021-11-nested-findings/issues/217
        rebuildCaches(destinations);
    }

    /// @notice rebuild the caches of mixin smart contracts
    /// @param destinations The list of mixinOperatorResolver to rebuild
    function rebuildCaches(MixinOperatorResolver[] calldata destinations) public onlyOwner {
        for (uint256 i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }
}