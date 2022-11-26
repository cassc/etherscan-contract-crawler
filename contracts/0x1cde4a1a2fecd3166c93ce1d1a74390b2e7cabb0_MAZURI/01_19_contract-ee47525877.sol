// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/[email protected]/access/AccessControlUpgradeable.sol";
import "@openzeppelin/[email protected]/proxy/utils/Initializable.sol";
import "@openzeppelin/[email protected]/proxy/utils/UUPSUpgradeable.sol";

/// @custom:security-contact [email protected]
contract MAZURI is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("MAZURI", "MZR");
        __ERC20Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _mint(msg.sender, 100000000 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}