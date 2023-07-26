// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title  Axiom V1 Access
/// @notice Abstract contract controlling permissions of AxiomV1
/// @dev    For use in a UUPS upgradeable contract.
abstract contract AxiomV1Access is Initializable, AccessControlUpgradeable {
    bool public frozen;

    /// @notice Storage slot for the address with the permission of a 'timelock'.
    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");

    /// @notice Storage slot for the addresses with the permission of a 'guardian'.
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    /// @notice Storage slot for the addresses with the permission of a 'prover'.
    bytes32 public constant PROVER_ROLE = keccak256("PROVER_ROLE");

    /// @notice Emitted when the `freezeAll` is called
    event FreezeAll();

    /// @notice Emitted when the `unfreezeAll` is called
    event UnfreezeAll();

    /// @notice Error when trying to call contract while it is frozen
    error ContractIsFrozen();

    /// @notice Error when trying to call contract from address without 'prover' role
    error NotProverRole();

    /**
     * @dev Modifier to make a function callable only by the 'prover' role.
     * As an initial safety mechanism, the 'update_' functions are only callable by the 'prover' role.
     * Granting the prover role to `address(0)` will enable this role for everyone.
     */
    modifier onlyProver() {
        if (!hasRole(PROVER_ROLE, address(0)) && !hasRole(PROVER_ROLE, _msgSender())) {
            revert NotProverRole();
        }
        _;
    }

    function __AxiomV1Access_init() internal onlyInitializing {
        __AxiomV1Access_init_unchained();
    }

    function __AxiomV1Access_init_unchained() internal onlyInitializing {
        frozen = false;
    }

    function freezeAll() external onlyRole(GUARDIAN_ROLE) {
        frozen = true;
        emit FreezeAll();
    }

    function unfreezeAll() external onlyRole(GUARDIAN_ROLE) {
        frozen = false;
        emit UnfreezeAll();
    }

    /// @notice Checks that the contract is not frozen.
    function requireNotFrozen() internal view {
        if (frozen) {
            revert ContractIsFrozen();
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[40] private __gap;
}