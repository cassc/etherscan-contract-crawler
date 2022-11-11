// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "../OperatorResolver.sol";
import "../interfaces/IOperatorResolver.sol";
import "../interfaces/INestedFactory.sol";

/// @title Mixin operator resolver
/// @notice Store in cache operators name and address/selector
abstract contract MixinOperatorResolver {
    /// @notice Emitted when cache is updated
    /// @param name The operator name
    /// @param destination The operator address
    event CacheUpdated(bytes32 name, IOperatorResolver.Operator destination);

    /// @dev The OperatorResolver used to build the cache
    OperatorResolver public immutable resolver;

    /// @dev Cache operators map of the name and Operator struct (address/selector)
    mapping(bytes32 => IOperatorResolver.Operator) internal operatorCache;

    constructor(address _resolver) {
        require(_resolver != address(0), "MOR: INVALID_ADDRESS");
        resolver = OperatorResolver(_resolver);
    }

    /// @dev This function is public not external in order for it to be overridden and
    ///      invoked via super in subclasses
    function resolverOperatorsRequired() public view virtual returns (bytes32[] memory) {}

    /// @notice Rebuild the operatorCache
    function rebuildCache() public {
        bytes32[] memory requiredOperators = resolverOperatorsRequired();
        bytes32 name;
        IOperatorResolver.Operator memory destination;
        // The resolver must call this function whenever it updates its state
        for (uint256 i = 0; i < requiredOperators.length; i++) {
            name = requiredOperators[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            destination = resolver.getOperator(name);
            if (destination.implementation != address(0)) {
                operatorCache[name] = destination;
            } else {
                delete operatorCache[name];
            }
            emit CacheUpdated(name, destination);
        }
    }

    /// @notice Check the state of operatorCache
    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredOperators = resolverOperatorsRequired();
        bytes32 name;
        IOperatorResolver.Operator memory cacheTmp;
        IOperatorResolver.Operator memory actualValue;
        for (uint256 i = 0; i < requiredOperators.length; i++) {
            name = requiredOperators[i];
            cacheTmp = operatorCache[name];
            actualValue = resolver.getOperator(name);
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (
                actualValue.implementation != cacheTmp.implementation ||
                actualValue.selector != cacheTmp.selector ||
                cacheTmp.implementation == address(0)
            ) {
                return false;
            }
        }
        return true;
    }

    /// @dev Get operator address in cache and require (if exists)
    /// @param name The operator name
    /// @return The operator address
    function requireAndGetAddress(bytes32 name) internal view returns (IOperatorResolver.Operator memory) {
        IOperatorResolver.Operator memory _foundAddress = operatorCache[name];
        require(_foundAddress.implementation != address(0), string(abi.encodePacked("MOR: MISSING_OPERATOR: ", name)));
        return _foundAddress;
    }

    /// @dev Build the calldata (with safe datas) and call the Operator
    /// @param _order The order to execute
    /// @param _inputToken The input token address
    /// @param _outputToken The output token address
    /// @return success If the operator call is successful
    /// @return amounts The amounts from the execution (used and received)
    ///         - amounts[0] : The amount of output token
    ///         - amounts[1] : The amount of input token USED by the operator (can be different than expected)
    function callOperator(
        INestedFactory.Order calldata _order,
        address _inputToken,
        address _outputToken
    ) internal returns (bool success, uint256[] memory amounts) {
        IOperatorResolver.Operator memory _operator = requireAndGetAddress(_order.operator);
        // Parameters are concatenated and padded to 32 bytes.
        // We are concatenating the selector + given params
        bytes memory data;
        (success, data) = _operator.implementation.delegatecall(bytes.concat(_operator.selector, _order.callData));

        if (success) {
            address[] memory tokens;
            (amounts, tokens) = abi.decode(data, (uint256[], address[]));
            require(tokens[0] == _outputToken, "MOR: INVALID_OUTPUT_TOKEN");
            require(tokens[1] == _inputToken, "MOR: INVALID_INPUT_TOKEN");
        }
    }
}