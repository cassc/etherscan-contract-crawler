// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IOperatorFilterRegistry} from "./../interfaces/IOperatorFilterRegistry.sol";
import {ProxyInitialization} from "./../../../proxy/libraries/ProxyInitialization.sol";

library OperatorFiltererStorage {
    using OperatorFiltererStorage for OperatorFiltererStorage.Layout;

    struct Layout {
        IOperatorFilterRegistry registry;
    }

    bytes32 internal constant PROXY_INIT_PHASE_SLOT = bytes32(uint256(keccak256("animoca.token.royalty.OperatorFilterer.phase")) - 1);
    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.token.royalty.OperatorFilterer.storage")) - 1);

    error OperatorNotAllowed(address operator);

    /// @notice Sets the address that the contract will make OperatorFilter checks against.
    /// @dev Note: This function should be called ONLY in the constructor of an immutable (non-proxied) contract.
    /// @param registry The operator filter registry address. When set to the zero address, checks will be bypassed.
    function constructorInit(Layout storage s, IOperatorFilterRegistry registry) internal {
        s.registry = registry;
    }

    /// @notice Sets the address that the contract will make OperatorFilter checks against.
    /// @dev Note: This function should be called ONLY in the init function of a proxied contract.
    /// @dev Reverts if the proxy initialization phase is set to `1` or above.
    /// @param registry The operator filter registry address. When set to the zero address, checks will be bypassed.
    function proxyInit(Layout storage s, IOperatorFilterRegistry registry) internal {
        ProxyInitialization.setPhase(PROXY_INIT_PHASE_SLOT, 1);
        s.constructorInit(registry);
    }

    /// @notice Updates the address that the contract will make OperatorFilter checks against.
    /// @param registry The new operator filter registry address. When set to the zero address, checks will be bypassed.
    function updateOperatorFilterRegistry(Layout storage s, IOperatorFilterRegistry registry) internal {
        s.registry = registry;
    }

    /// @dev Reverts with OperatorNotAllowed if `sender` is not `from` and is not allowed by a valid operator registry.
    function requireAllowedOperatorForTransfer(Layout storage s, address sender, address from) internal view {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred from an EOA.
        if (sender != from) {
            _checkFilterOperator(s, sender);
        }
    }

    /// @dev Reverts with OperatorNotAllowed if `sender` is not allowed by a valid operator registry.
    function requireAllowedOperatorForApproval(Layout storage s, address operator) internal view {
        _checkFilterOperator(s, operator);
    }

    function operatorFilterRegistry(Layout storage s) internal view returns (IOperatorFilterRegistry) {
        return s.registry;
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }

    function _checkFilterOperator(Layout storage s, address operator) private view {
        IOperatorFilterRegistry registry = s.registry;
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registry) != address(0) && address(registry).code.length > 0) {
            if (!registry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}