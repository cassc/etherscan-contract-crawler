// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IOperatorFilterRegistry} from "operator-filter-registry/src/IOperatorFilterRegistry.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract OperatorFilterer is Initializable {
    error AlreadyRegistered();
    error OnlyOperatorFilterAdmin();
    error OperatorNotAllowed(address operator);
    error RegistryInvalid();

    event OperatorFilterDisabled(bool disabled);

    bool public operatorFilterDisabled;

    IOperatorFilterRegistry operatorFilterRegistry;

    function __OperatorFilterer_init() internal onlyInitializing {
        IOperatorFilterRegistry registry = IOperatorFilterRegistry(
            0x000000000000AAeB6D7670E522A718067333cd4E
        );
        operatorFilterRegistry = registry;

        if (address(registry).code.length > 0) {
            registry.registerAndSubscribe(
                address(this),
                0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6
            );
        }
    }

    // * MODIFIERS * //

    modifier onlyAllowedOperator(address from) virtual {
        if (
            !operatorFilterDisabled &&
            address(operatorFilterRegistry).code.length > 0
        ) {
            if (from == msg.sender) {
                _;
                return;
            }
            if (
                !operatorFilterRegistry.isOperatorAllowed(
                    address(this),
                    msg.sender
                )
            ) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        if (
            !operatorFilterDisabled &&
            address(operatorFilterRegistry).code.length > 0
        ) {
            if (
                !operatorFilterRegistry.isOperatorAllowed(
                    address(this),
                    operator
                )
            ) {
                revert OperatorNotAllowed(operator);
            }
        }
        _;
    }

    modifier onlyOperatorFilterAdmin() {
        if (!_isOperatorFilterAdmin(msg.sender)) {
            revert OnlyOperatorFilterAdmin();
        }
        _;
    }

    // * ADMIN * //

    function toggleOperatorFilterDisabled()
        public
        virtual
        onlyOperatorFilterAdmin
        returns (bool)
    {
        bool disabled = !operatorFilterDisabled;
        operatorFilterDisabled = disabled;
        emit OperatorFilterDisabled(disabled);
        return disabled;
    }

    function updateOperatorFilterRegistryAddress(
        address newRegistry
    ) public virtual onlyOperatorFilterAdmin {
        operatorFilterRegistry = IOperatorFilterRegistry(newRegistry);
    }

    // * INTERNAL * //

    function _isOperatorFilterAdmin(
        address operator
    ) internal view virtual returns (bool);
}