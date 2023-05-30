// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IVFAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract VFAccessControl is IVFAccessControl, Context, ERC165, ReentrancyGuard {
    //Struct for maintaining role information
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    //Role information
    mapping(bytes32 => RoleData) private _roles;

    //Admin role
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    //Token contract role
    bytes32 public constant TOKEN_CONTRACT_ROLE =
        keccak256("TOKEN_CONTRACT_ROLE");
    //Sales contract role
    bytes32 public constant SALES_CONTRACT_ROLE =
        keccak256("SALES_CONTRACT_ROLE");
    //Burner role
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    //Minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    //Array of addresses that can mint
    address[] public minterAddresses;
    //Index of next minter in minterAddresses
    uint8 private _currentMinterIndex = 0;

    //Array of roles that can mint
    bytes32[] public minterRoles;

    /**
     * @dev Initializes the contract by assigning the msg sender the admin, minter,
     * and burner role. Along with adding the minter role and sales contract role
     * to the minter roles array.
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());
        minterRoles.push(MINTER_ROLE);
        minterRoles.push(SALES_CONTRACT_ROLE);
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IVFAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IVFAccessControl-hasRole}.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /**
     * @dev See {IVFAccessControl-checkRole}.
     */
    function checkRole(bytes32 role, address account) public view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev See {IVFAccessControl-getAdminRole}.
     */
    function getAdminRole() external view virtual returns (bytes32) {
        return DEFAULT_ADMIN_ROLE;
    }

    /**
     * @dev See {IVFAccessControl-getTokenContractRole}.
     */
    function getTokenContractRole() external view virtual returns (bytes32) {
        return TOKEN_CONTRACT_ROLE;
    }

    /**
     * @dev See {IVFAccessControl-getSalesContractRole}.
     */
    function getSalesContractRole() external view virtual returns (bytes32) {
        return SALES_CONTRACT_ROLE;
    }

    /**
     * @dev See {IVFAccessControl-getBurnerRole}.
     */
    function getBurnerRole() external view virtual returns (bytes32) {
        return BURNER_ROLE;
    }

    /**
     * @dev See {IVFAccessControl-getMinterRole}.
     */
    function getMinterRole() external view virtual returns (bytes32) {
        return MINTER_ROLE;
    }

    /**
     * @dev See {IVFAccessControl-getMinterRoles}.
     */
    function getMinterRoles() external view virtual returns (bytes32[] memory) {
        return minterRoles;
    }

    /**
     * @dev See {IVFAccessControl-getRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev See {IVFAccessControl-grantRole}.
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /**
     * @dev See {IVFAccessControl-revokeRole}.
     */
    function revokeRole(bytes32 role, address account)
        external
        virtual
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @dev See {IVFAccessControl-renounceRole}.
     */
    function renounceRole(bytes32 role, address account) external virtual {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev See {IVFAccessControl-selectNextMinter}.
     */
    function selectNextMinter()
        external
        onlyRole(SALES_CONTRACT_ROLE)
        returns (address payable)
    {
        address nextMinter = minterAddresses[_currentMinterIndex];
        if (_currentMinterIndex + 1 < minterAddresses.length) {
            _currentMinterIndex++;
        } else {
            _currentMinterIndex = 0;
        }
        return payable(nextMinter);
    }

    /**
     * @dev See {IVFAccessControl-grantMinterRole}.
     */
    function grantMinterRole(address minter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(MINTER_ROLE, minter);
        minterAddresses.push(minter);
        _currentMinterIndex = 0;
    }

    /**
     * @dev See {IVFAccessControl-revokeMinterRole}.
     */
    function revokeMinterRole(address minter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(MINTER_ROLE, minter);
        uint256 index;
        for (index = 0; index < minterAddresses.length; index++) {
            if (minter == minterAddresses[index]) {
                minterAddresses[index] = minterAddresses[
                    minterAddresses.length - 1
                ];
                break;
            }
        }
        minterAddresses.pop();
        _currentMinterIndex = 0;
    }

    /**
     * @dev See {IVFAccessControl-fundMinters}.
     */
    function fundMinters() external payable nonReentrant {
        uint256 totalMinters = minterAddresses.length;
        uint256 amount = msg.value / totalMinters;
        for (uint256 index = 0; index < totalMinters; index++) {
            payable(minterAddresses[index]).transfer(amount);
        }
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev Widthraw balance on contact to msg sender
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function withdrawMoney() external onlyRole(DEFAULT_ADMIN_ROLE) {
        address payable to = payable(_msgSender());
        to.transfer(address(this).balance);
    }
}