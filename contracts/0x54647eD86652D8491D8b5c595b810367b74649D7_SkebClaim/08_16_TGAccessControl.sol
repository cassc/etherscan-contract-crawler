// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITGAccessControl.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 *  @dev Access control contract module
 *  inherited {AccessControl} from OpenZeppelin.
 */
abstract contract TGAccessControl is AccessControl, ITGAccessControl {
    // --- modifier ---

    /**
     * @dev Modifier that checks that an account has admin role. Reverts
     * with a standardized message including the required DEFAULT_ADMIN_ROLE role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role 0x00$/
     */
    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _;
    }

    // --- public function ---

    /**
     *  @dev Returns `true` if `_account` has admin role.
     */
    function hasAdmin(address _account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return hasRole(DEFAULT_ADMIN_ROLE, _account);
    }

    /**
     *  @dev Grants admin role to `_account`.
     *
     *  If `account` has not been already granted admin role, emits a {RoleGranted} event.
     *
     * Requirements:
     * - the caller must have admin role.
     */
    function grantAdmin(address _account) public virtual override onlyAdmin {
        require(
            _account != address(0),
            "TGAccessControl: account is the zero address"
        );
        _grantAdmin(_account);
    }

    /**
     *  @dev Revokes admin role from `_account`.
     *
     *  If `account` had been already granted admin role, emits a {RoleRevoked} event.
     *
     * Requirements:
     * - the caller must have admi rolen, not `_account` (cannot revoke from self).
     */
    function revokeAdmin(address _account) public virtual override onlyAdmin {
        require(
            _account != _msgSender(),
            "TGAccessControl: cannot revoke from self"
        );
        _revokeAdmin(_account);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(ITGAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // --- internal function ---

    /**
     *  @dev Grants admin role to `_account`.
     *
     * Internal function without access restriction.
     *
     *  If `account` has not been already granted admin role, emits a {RoleGranted} event.
     */
    function _grantAdmin(address _account) internal virtual {
        _grantRole(DEFAULT_ADMIN_ROLE, _account);
    }

    /**
     *  @dev Revokes admin role from `_account`.
     *
     * Internal function without access restriction.
     *
     *  If `account` had been already granted admin from, emits a {RoleRevoked} event.
     */
    function _revokeAdmin(address _account) internal virtual {
        _revokeRole(DEFAULT_ADMIN_ROLE, _account);
    }
}