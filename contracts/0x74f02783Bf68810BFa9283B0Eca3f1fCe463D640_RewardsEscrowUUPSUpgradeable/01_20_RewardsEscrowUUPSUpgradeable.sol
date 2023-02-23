// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./RewardsEscrow.sol";
import "./interfaces/IRewardsEscrowV1UUPSUpgradeable.sol";

contract RewardsEscrowUUPSUpgradeable is IRewardsEscrowV1UUPSUpgradeable, RewardsEscrow, UUPSUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    function initializeUUPS(address roleAdmin, address upgrader) public initializer {
        __RewardsEscrow_init(roleAdmin);

        _grantRole(UPGRADER_ROLE, upgrader);
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    function _authorizeUpgrade(address) internal view override {
        require(hasRole(UPGRADER_ROLE, msg.sender), "RewardsEscrow: caller does not have upgrader role");
    }
}