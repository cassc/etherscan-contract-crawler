// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "../libraries/ExceptionsLibrary.sol";
import "../interfaces/IService.sol";
/**
* @title Registry Base Contract
* @notice The core contract for the Registry contracts.
* @dev This abstract contract is inherited by the Registry contract and contains functions and modifiers that could be applied to all contracts in this section.
*/
abstract contract RegistryBase is AccessControlEnumerableUpgradeable {
    // STORAGE

    /// @dev The address of the Service contract.
    address public service;

    // MODIFIERS
    /// @notice Modifier that allows calling the method only from the Service contract.
    modifier onlyService() {
        require(msg.sender == service, ExceptionsLibrary.NOT_SERVICE);
        _;
    }
    /// @notice Modifier that allows calling the method only from the Service, TGEFactory, and TokenFactory contracts.
    modifier onlyServiceOrFactory() {
        bool isService = msg.sender == service;
        bool isFactory = msg.sender ==
            address(IService(service).tokenFactory()) ||
            msg.sender == address(IService(service).tgeFactory());

        require(isService || isFactory, ExceptionsLibrary.NOT_SERVICE);
        _;
    }

    // INITIALIZER
    /// @dev This method is executed during deployment or upgrade of the contract to set the contract initiator as the contract administrator. Without binding from the Service contract, this method cannot provide unauthorized access in any way.
    function __RegistryBase_init() internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // PUBLIC FUNCTIONS
    /// @dev This method is executed during deployment and upgrade of the contract to link the main protocol contract with the Registry data storage by storing the address of the Service contract.
    function setService(
        address service_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        service = service_;
    }
}