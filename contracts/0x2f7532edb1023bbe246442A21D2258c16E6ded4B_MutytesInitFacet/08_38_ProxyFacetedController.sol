// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ProxyFacetedModel } from "./ProxyFacetedModel.sol";
import { ProxyController } from "../ProxyController.sol";
import { AddressUtils } from "../../utils/AddressUtils.sol";

abstract contract ProxyFacetedController is ProxyFacetedModel, ProxyController {
    using AddressUtils for address;

    function implementation_() internal view virtual override returns (address) {
        return implementation_(msg.sig);
    }

    function implementation_(bytes4 selector)
        internal
        view
        virtual
        returns (address implementation)
    {
        implementation = _implementation(selector);
        implementation.enforceIsNotZeroAddress();
    }

    function addFunctions_(
        bytes4[] memory selectors,
        address implementation,
        bool isUpgradable
    ) internal virtual {
        _enforceCanAddFunctions(implementation);

        unchecked {
            for (uint256 i; i < selectors.length; i++) {
                bytes4 selector = selectors[i];
                _enforceCanAddFunction(selector, implementation);
                _addFunction_(selector, implementation, isUpgradable);
            }
        }
    }

    function addFunction_(
        bytes4 selector,
        address implementation,
        bool isUpgradable
    ) internal virtual {
        _enforceCanAddFunctions(implementation);
        _enforceCanAddFunction(selector, implementation);
        _addFunction_(selector, implementation, isUpgradable);
    }

    function replaceFunctions_(bytes4[] memory selectors, address implementation)
        internal
        virtual
    {
        _enforceCanAddFunctions(implementation);

        unchecked {
            for (uint256 i; i < selectors.length; i++) {
                bytes4 selector = selectors[i];
                _enforceCanReplaceFunction(selector, implementation);
                _replaceFunction_(selector, implementation);
            }
        }
    }

    function replaceFunction_(bytes4 selector, address implementation) internal virtual {
        _enforceCanAddFunctions(implementation);
        _enforceCanReplaceFunction(selector, implementation);
        _replaceFunction_(selector, implementation);
    }

    function removeFunctions_(bytes4[] memory selectors) internal virtual {
        unchecked {
            for (uint256 i; i < selectors.length; i++) {
                removeFunction_(selectors[i]);
            }
        }
    }

    function removeFunction_(bytes4 selector) internal virtual {
        address implementation = _implementation(selector);
        _enforceCanRemoveFunction(selector, implementation);
        _removeFunction_(selector, implementation);
    }

    function setUpgradableFunctions_(bytes4[] memory selectors, bool isUpgradable)
        internal
        virtual
    {
        unchecked {
            for (uint256 i; i < selectors.length; i++) {
                setUpgradableFunction_(selectors[i], isUpgradable);
            }
        }
    }

    function setUpgradableFunction_(bytes4 selector, bool isUpgradable) internal virtual {
        _implementation(selector).enforceIsNotZeroAddress();
        _setUpgradableFunction(selector, isUpgradable);
    }

    function _addFunction_(
        bytes4 selector,
        address implementation,
        bool isUpgradable
    ) internal virtual {
        _addFunction(selector, implementation, isUpgradable);
        _afterAddFunction(implementation);
    }

    function _replaceFunction_(bytes4 selector, address implementation) internal virtual {
        address oldImplementation = _implementation(selector);
        _replaceFunction(selector, implementation);
        _afterRemoveFunction(oldImplementation);
        _afterAddFunction(implementation);
    }

    function _removeFunction_(bytes4 selector, address implementation) internal virtual {
        _removeFunction(selector);
        _afterRemoveFunction(implementation);
    }

    function _enforceCanAddFunctions(address implementation) internal view virtual {
        if (implementation != address(this)) {
            implementation.enforceIsContract();
        }
    }

    function _enforceCanAddFunction(bytes4 selector, address) internal view virtual {
        _implementation(selector).enforceIsZeroAddress();
    }

    function _enforceCanReplaceFunction(bytes4 selector, address implementation)
        internal
        view
        virtual
    {
        address oldImplementation = _implementation(selector);
        oldImplementation.enforceNotEquals(implementation);
        _enforceCanRemoveFunction(selector, oldImplementation);
    }

    function _enforceCanRemoveFunction(bytes4 selector, address implementation)
        internal
        view
        virtual
    {
        implementation.enforceIsNotZeroAddress();

        if (!_isUpgradable(selector)) {
            implementation.enforceNotEquals(address(this));
        }
    }
}