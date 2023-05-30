// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "../libraries/CustomErrors.sol";
import "./WithOperatorRegistryState.sol";
import "../libraries/LANFTUtils.sol";
import "../extensions/AccessControl.sol";
import "operator-filter-registry/src/IOperatorFilterRegistry.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "operator-filter-registry/src/lib/Constants.sol";

 contract WithOperatorRegistry is AccessControl  {
    address constant DEFAULT_OPERATOR_REGISTRY_ADDRESS =
        0x000000000000AAeB6D7670E522A718067333cd4E;

    /// @dev The upgradeable initialize function that should be called when the contract is being upgraded.
    function _initOperatorRegsitry(
    ) internal {
        WithOperatorRegistryState.OperatorRegistryState
            storage registryState = WithOperatorRegistryState
                ._getOperatorRegistryState();
        IOperatorFilterRegistry registry = IOperatorFilterRegistry(
            DEFAULT_OPERATOR_REGISTRY_ADDRESS
        );

        registryState.operatorFilterRegistry = registry;

        if (address(registry).code.length > 0) {
                registry.registerAndSubscribe(
                    address(this),
                    CANONICAL_CORI_SUBSCRIPTION
                );
        }
    }


    function initOperatorRegsitry(
    ) public onlyAdmin {
        _initOperatorRegsitry();
    }

    /**
     * @dev A helper modifier to check if the operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper modifier to check if the operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if the operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        WithOperatorRegistryState.OperatorRegistryState
            storage registryState = WithOperatorRegistryState
                ._getOperatorRegistryState();
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registryState.operatorFilterRegistry).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting or
            // upgraded contracts may specify their own OperatorFilterRegistry implementations, which may behave
            // differently
            if (
                !registryState.operatorFilterRegistry.isOperatorAllowed(
                    address(this),
                    operator
                )
            ) {
                revert CustomErrors.NotAllowed();
            }
        }
    }


    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
     *         address, checks will be bypassed. OnlyOwner.
     */
    function updateOperatorFilterRegistryAddress(address newRegistry) public onlyAdmin {
        WithOperatorRegistryState.OperatorRegistryState
            storage registryState = WithOperatorRegistryState
                ._getOperatorRegistryState();
        IOperatorFilterRegistry registry = IOperatorFilterRegistry(
            newRegistry
        );
        registryState.operatorFilterRegistry = registry;
    }
}