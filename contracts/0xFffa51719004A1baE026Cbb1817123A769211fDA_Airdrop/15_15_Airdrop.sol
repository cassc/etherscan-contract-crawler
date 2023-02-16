// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// OZ Upgrades imports
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**************************************

    Airdrop proxy

 **************************************/

contract Airdrop is Initializable, AccessControlUpgradeable, UUPSUpgradeable {

    // roles
    bytes32 public constant CAN_UPGRADE = keccak256("CAN_UPGRADE");

    /**************************************

        Constructor

    **************************************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    /**************************************

        Initializer

    **************************************/

    function initialize() public initializer {

        // admin setup
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(CAN_UPGRADE, DEFAULT_ADMIN_ROLE);

        // mint
        _setupRole(CAN_UPGRADE, msg.sender);

    }

    /**************************************

        Internal: Authorize upgrade

    **************************************/

    function _authorizeUpgrade(address newImplementation) internal override
    onlyRole(CAN_UPGRADE) {}

}