// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "../../interfaces/INestedFactory.sol";
import "../../interfaces/IOperatorResolver.sol";
import "../../abstracts/MixinOperatorResolver.sol";
import "../../interfaces/external/ITransparentUpgradeableProxy.sol";

contract OperatorScripts {
    struct tupleOperator {
        bytes32 name;
        bytes4 selector;
    }

    address public immutable nestedFactory;
    address public immutable resolver;

    constructor(address _nestedFactory, address _resolver) {
        require(_nestedFactory != address(0), "AO-SCRIPT: INVALID_FACTORY_ADDR");
        require(_resolver != address(0), "AO-SCRIPT: INVALID_RESOLVER_ADDR");
        nestedFactory = _nestedFactory;
        resolver = _resolver;
    }

    /// @notice Call NestedFactory and OperatorResolver to add an operator.
    /// @param operator The operator to add
    /// @param name The operator bytes32 name
    function addOperator(IOperatorResolver.Operator memory operator, bytes32 name) external {
        require(operator.implementation != address(0), "AO-SCRIPT: INVALID_IMPL_ADDRESS");

        // Init arrays with length 1 (only one operator to import)
        bytes32[] memory names = new bytes32[](1);
        IOperatorResolver.Operator[] memory operatorsToImport = new IOperatorResolver.Operator[](1);
        MixinOperatorResolver[] memory destinations = new MixinOperatorResolver[](1);

        names[0] = name;
        operatorsToImport[0] = operator;
        destinations[0] = MixinOperatorResolver(nestedFactory);

        IOperatorResolver(resolver).importOperators(names, operatorsToImport, destinations);

        ITransparentUpgradeableProxy(nestedFactory).upgradeToAndCall(
            ITransparentUpgradeableProxy(nestedFactory).implementation(),
            abi.encodeWithSelector(INestedFactory.addOperator.selector, name)
        );
    }

    /// @notice Deploy and add operators
    /// @dev One address and multiple selectors/names
    /// @param bytecode Operator implementation bytecode
    /// @param operators Array of tuples => bytes32/bytes4 (name and selector)
    function deployAddOperators(bytes memory bytecode, tupleOperator[] memory operators) external {
        uint256 operatorLength = operators.length;
        require(operatorLength != 0, "DAO-SCRIPT: INVALID_OPERATOR_LEN");
        require(bytecode.length != 0, "DAO-SCRIPT: BYTECODE_ZERO");

        address deployedAddress;
        assembly {
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        require(deployedAddress != address(0), "DAO-SCRIPT: FAILED_DEPLOY");

        // Init arrays
        bytes32[] memory names = new bytes32[](operatorLength);
        IOperatorResolver.Operator[] memory operatorsToImport = new IOperatorResolver.Operator[](operatorLength);

        for (uint256 i; i < operatorLength; i++) {
            names[i] = operators[i].name;
            operatorsToImport[i] = IOperatorResolver.Operator(deployedAddress, operators[i].selector);
        }

        // Only the NestedFactory as destination
        MixinOperatorResolver[] memory destinations = new MixinOperatorResolver[](1);
        destinations[0] = MixinOperatorResolver(nestedFactory);

        // Start importing operators
        IOperatorResolver(resolver).importOperators(names, operatorsToImport, destinations);

        // Add all the operators to the factory
        for (uint256 i; i < operatorLength; i++) {
            ITransparentUpgradeableProxy(nestedFactory).upgradeToAndCall(
                ITransparentUpgradeableProxy(nestedFactory).implementation(),
                abi.encodeWithSelector(INestedFactory.addOperator.selector, operators[i].name)
            );
        }
    }

    /// @notice Call NestedFactory and OperatorResolver to remove an operator.
    /// @param name The operator bytes32 name
    function removeOperator(bytes32 name) external {
        ITransparentUpgradeableProxy(nestedFactory).upgradeToAndCall(
            ITransparentUpgradeableProxy(nestedFactory).implementation(),
            abi.encodeWithSelector(INestedFactory.removeOperator.selector, name)
        );

        // Init arrays with length 1 (only one operator to remove)
        bytes32[] memory names = new bytes32[](1);
        IOperatorResolver.Operator[] memory operatorsToImport = new IOperatorResolver.Operator[](1);
        MixinOperatorResolver[] memory destinations = new MixinOperatorResolver[](1);

        names[0] = name;
        operatorsToImport[0] = IOperatorResolver.Operator({ implementation: address(0), selector: bytes4(0) });
        destinations[0] = MixinOperatorResolver(nestedFactory);

        IOperatorResolver(resolver).importOperators(names, operatorsToImport, destinations);
    }
}