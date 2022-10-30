// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {QurableRegistryV2} from "./QurableRegistryV2.sol";

abstract contract QurableRegistryManagedV2 is OwnableUpgradeable {
    QurableRegistryV2 internal _qurableRegistry;

    event QurableRegistryChanged(address indexed qurableRegistry);

    function _setRegistry(address qurableRegistry) internal {
        require(qurableRegistry != address(0), "InvalidQurableRegistry");

        _qurableRegistry = QurableRegistryV2(
            qurableRegistry
        );

        require(_qurableRegistry.vault() != address(0), "InvalidSafeVault");

        transferOwnership(_qurableRegistry.owner());

        emit QurableRegistryChanged(qurableRegistry);
    }

    function getQurableRegistry() external view returns (address) {
        return address(_qurableRegistry);
    }

    function setQurableRegistry(address qurableRegistry)
        external
        onlyOwner
    {
        _setRegistry(qurableRegistry);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}