// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Initializable.sol";

abstract contract AccessControl is Initializable {
    error AccessControlNotAllowed();

    bytes32 public constant COLLECTION_ADMIN_ROLE =
        keccak256("COLLECTION_ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    struct RoleState {
        mapping(bytes32 => mapping(address => bool)) _roles;
    }

    function _getAccessControlState()
        internal
        pure
        returns (RoleState storage state)
    {
        bytes32 position = keccak256("liveart.AccessControl");
        assembly {
            state.slot := position
        }
    }

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @notice Must be called by in the initialize function of the implementation contract
     *
     */
    function _initializeAccessControl(address admin) internal notInitialized {
        _grantRole(COLLECTION_ADMIN_ROLE, admin);
    }

    /**
     * @notice Checks that msg.sender has a specific role.
     * Reverts with a AccessControlNotAllowed.
     *
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @notice Checks that msg.sender has COLLECTION_ADMIN_ROLE
     * Reverts with a AccessControlNotAllowed.
     *
     */
    modifier onlyAdmin() {
        _checkRole(COLLECTION_ADMIN_ROLE);
        _;
    }

    /**
     * @notice Checks that msg.sender has MINTER_ROLE
     * Reverts with a AccessControlNotAllowed.
     *
     */
    modifier onlyMinter() {
        _checkRole(MINTER_ROLE);
        _;
    }

    /**
     * @notice Checks if role is assigned to account
     *
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        RoleState storage state = _getAccessControlState();
        return state._roles[role][account];
    }

    /**
     * @notice Revert with a AccessControlNotAllowed message if `msg.sender` is missing `role`.
     *
     */
    function _checkRole(bytes32 role) internal view virtual {
        if (!hasRole(role, msg.sender)) {
            revert AccessControlNotAllowed();
        }
    }

    /**
     * @notice Grants `role` to `account`.
     *
     * @dev If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account)
        public
        onlyRole(COLLECTION_ADMIN_ROLE)
    {
        _grantRole(role, account);
    }

    /**
     * @notice Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have COLLECTION_ADMIN_ROLE role.
     */
    function revokeRole(bytes32 role, address account)
        public
        onlyRole(COLLECTION_ADMIN_ROLE)
    {
        _revokeRole(role, account);
    }

    /**
     * @notice Revokes `role` from the calling account.
     *
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        if (account != msg.sender) {
            revert AccessControlNotAllowed();
        }

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal {
        RoleState storage state = _getAccessControlState();
        if (!hasRole(role, account)) {
            state._roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal {
        RoleState storage state = _getAccessControlState();
        if (hasRole(role, account)) {
            state._roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}