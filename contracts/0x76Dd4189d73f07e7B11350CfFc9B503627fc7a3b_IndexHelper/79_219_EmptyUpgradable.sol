// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "../interfaces/INameRegistry.sol";

abstract contract EmptyUpgradable is AccessControlUpgradeable, UUPSUpgradeable {
    using ERC165CheckerUpgradeable for address;

    /// @notice Role allows configure index related data/components
    bytes32 internal constant INDEX_MANAGER_ROLE = keccak256("INDEX_MANAGER_ROLE");

    /// @notice Initializes empty upgradable
    /// @dev Initialization method used in upgradeable contracts instead of constructor function
    function __EmptyUpgradable_init() internal onlyInitializing {
        __AccessControl_init();
        __UUPSUpgradeable_init();
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}

    uint256[50] private __gap;
}