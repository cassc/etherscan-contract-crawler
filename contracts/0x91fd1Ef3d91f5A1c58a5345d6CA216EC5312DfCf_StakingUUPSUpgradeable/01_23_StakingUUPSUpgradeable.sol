// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./Staking.sol";
import "./interfaces/IYieldFarmingV1StakingUUPSUpgradeable.sol";

contract StakingUUPSUpgradeable is IYieldFarmingV1StakingUUPSUpgradeable, Staking, UUPSUpgradeable, AccessControlUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    function initializeUUPS(
        StakingConfig memory cfg,
        address roleAdmin,
        address upgrader
    ) public initializer {
        __Staking_init(cfg);
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, roleAdmin);
        _grantRole(UPGRADER_ROLE, upgrader);
    }

    function getImplementation() public view returns (address) {
        return _getImplementation();
    }

    function _authorizeUpgrade(address) internal view override {
        require(hasRole(UPGRADER_ROLE, msg.sender), "Staking: caller does not have upgrader role");
    }
}