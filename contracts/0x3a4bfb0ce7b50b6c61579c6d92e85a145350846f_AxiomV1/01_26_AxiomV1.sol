// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {AxiomV1Core} from "./AxiomV1Core.sol";
import {AxiomV1Access} from "./AxiomV1Access.sol";
import {IAxiomV1} from "./interfaces/IAxiomV1.sol";

/// @title  Axiom V1
/// @author Axiom
/// @notice Core Axiom smart contract that verifies the validity of historical block hashes using SNARKs.
contract AxiomV1 is AxiomV1Core, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    /// @notice Prevents the implementation contract from being initialized outside of the upgradeable proxy.
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract and the parent contracts once.
    function initialize(
        address _verifierAddress,
        address _historicalVerifierAddress,
        address timelock,
        address guardian
    ) public initializer {
        require(timelock != address(0)); // AxiomV1: timelock cannot be the zero address
        __UUPSUpgradeable_init();
        // prover is initialized to the contract deployer
        __AxiomV1Core_init(_verifierAddress, _historicalVerifierAddress, guardian, msg.sender);

        _grantRole(DEFAULT_ADMIN_ROLE, timelock);
        _grantRole(TIMELOCK_ROLE, timelock);
    }

    function _authorizeUpgrade(address) internal override onlyRole(TIMELOCK_ROLE) {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IAxiomV1).interfaceId || super.supportsInterface(interfaceId);
    }
}