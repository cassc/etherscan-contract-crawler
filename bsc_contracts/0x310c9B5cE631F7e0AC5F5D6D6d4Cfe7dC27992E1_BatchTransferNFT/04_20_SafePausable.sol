// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";

import "../Errors.sol";
import "./SafeAccessControlEnumerable.sol";
import "../interfaces/ISafePausable.sol";

abstract contract SafePausable is
    SafeAccessControlEnumerable,
    Pausable,
    ISafePausable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");

    bytes32 public constant PAUSER_ADMIN_ROLE = keccak256("PAUSER_ADMIN_ROLE");
    bytes32 public constant UNPAUSER_ADMIN_ROLE =
        keccak256("UNPAUSER_ADMIN_ROLE");

    /**
     * @dev Set the role admins
     */
    constructor() {
        _setRoleAdmin(PAUSER_ROLE, PAUSER_ADMIN_ROLE);
        _setRoleAdmin(UNPAUSER_ROLE, UNPAUSER_ADMIN_ROLE);
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(SafeAccessControlEnumerable)
        returns (bool)
    {
        return
            interfaceId == type(ISafePausable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Pauses the contract.
     * @dev Sensible part of a contract might be pausable for security reasons.
     *
     * Requirements:
     * - the caller must be the `owner` or have the ``role`` role.
     * - the contrat needs to be unpaused.
     */
    function pause() public virtual override onlyOwnerOrRole(PAUSER_ROLE) {
        if (paused()) revert SafePausable__AlreadyPaused();
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     * @dev Sensible part of a contract might be pausable for security reasons.
     *
     * Requirements:
     * - the caller must be the `owner` or have the ``role`` role.
     * - the contrat needs to be unpaused.
     */
    function unpause() public virtual override onlyOwnerOrRole(UNPAUSER_ROLE) {
        if (!paused()) revert SafePausable__AlreadyUnpaused();
        _unpause();
    }
}