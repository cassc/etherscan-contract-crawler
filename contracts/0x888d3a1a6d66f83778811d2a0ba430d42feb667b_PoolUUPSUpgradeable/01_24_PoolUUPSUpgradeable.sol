// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./Pool.sol";
import "./interfaces/IYieldFarmingV1PoolUUPSUpgradeable.sol";

contract PoolUUPSUpgradeable is IYieldFarmingV1PoolUUPSUpgradeable, Pool, UUPSUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    function initializeUUPS(
        PoolConfig memory cfg,
        address roleAdmin,
        address upgrader
    ) public initializer {
        __Pool_init(cfg, roleAdmin);

        _grantRole(UPGRADER_ROLE, upgrader);
    }

    function getImplementation() public view returns (address) {
        return _getImplementation();
    }

    function _authorizeUpgrade(address) internal view override {
        require(hasRole(UPGRADER_ROLE, msg.sender), "YieldFarm: caller does not have upgrader role");
    }
}