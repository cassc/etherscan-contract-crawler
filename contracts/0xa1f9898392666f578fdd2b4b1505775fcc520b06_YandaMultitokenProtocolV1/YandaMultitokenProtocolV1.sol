/**
 *Submitted for verification at Etherscan.io on 2022-10-24
*/

// Sources flattened with hardhat v2.12.0 https://hardhat.org

// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;




/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File contracts/YandaMultitokenProtocolV1.sol

// SPDX-License-Identifier: GNU GPLv3
pragma solidity ^0.8.3;



contract YandaMultitokenProtocolV1 is AccessControl{

    using SafeMath for uint256;

    uint internal TIME_FRAME_SIZE;
    uint internal VALIDATORS_PERC;
    uint internal BROKER_PERC;
    uint internal FEE_NOMINATOR;
    uint internal FEE_DENOMINATOR;
    uint internal _penaltyPerc;
    uint internal _lockingPeriod;
    uint256 internal _totalStaked;
    IERC20 internal _tokenContract;
    address payable internal _beneficiary;

    enum State { AWAITING_COST, AWAITING_TRANSFER, AWAITING_TERMINATION, AWAITING_VALIDATION, COMPLETED }
    struct Process {
        State state;
        uint256 cost;
        uint256 costConf;
        address token;
        address payable deposit;
        address payable depositConf;
        uint256 fee;
        address service;
        bytes32 productId;
        uint256 startBlock;
        address[] validatorsList;
        address firstValidator;
        bool firstResult;
        address secondValidator;
        bool secondResult;
    }
    struct Service {
        address[] validators;
        uint validationPerc;
        uint commissionPerc;
        uint validatorVersion;
    }
    struct Stake {
        uint256 amount;
        uint256 unlockingBlock;
    }
    mapping(address => mapping(bytes32 => Process)) internal _processes;
    mapping(address => bytes32) internal _depositingProducts;
    mapping(address => Service) internal _services;
    mapping(address => uint256) internal _stakesByValidators;
    mapping(address => address[]) internal _validatorStakers;
    mapping(address => mapping(address => Stake)) internal _stakes;

    event Deposit(
        address indexed customer,
        address indexed service,
        bytes32 indexed productId,
        uint256 weiAmount
    );
    event Action(
        address indexed customer,
        address indexed service,
        bytes32 indexed productId,
        string data
    );
    event Terminate(
        address indexed customer,
        address indexed service,
        bytes32 indexed productId,
        address[] validatorsList
    );
    event Complete(
        address indexed customer,
        address indexed service, 
        bytes32 indexed productId,
        bool success
    );
    event CostRequest(
        address indexed customer,
        address indexed service,
        bytes32 indexed productId,
        address[] validatorsList,
        string data
    );
    event CostResponse(
        address indexed customer,
        address indexed service,
        bytes32 indexed productId,
        uint cost
    );
    event Staked(
        address indexed staker,
        address indexed validator,
        uint256 amount,
        uint256 unlockingBlock
    );
    event UnStaked(
        address indexed staker,
        address indexed validator,
        uint256 amount
    );

    modifier onlyService() {
        require(_services[msg.sender].validators.length > 0, "Only service can call this method");
        _;
    }

    constructor(uint penaltyPerc, uint lockingPeriod, address token) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _beneficiary = payable(msg.sender);

        _penaltyPerc = penaltyPerc;
        _lockingPeriod = lockingPeriod;
        _tokenContract = IERC20(token);

        VALIDATORS_PERC = 15;
        BROKER_PERC = 80;
        FEE_NOMINATOR = 2;
        FEE_DENOMINATOR = 1000;
        TIME_FRAME_SIZE = 50;
    }

    function _containsAddress(address[] memory array, address search) internal pure returns(bool) {
        for(uint x=0; x < array.length; x++) {
            if (array[x] == search) {
                return true;
            }
        }
        return false;
    }

    function setBeneficiary(address payable newAddr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _beneficiary = newAddr;
    }

    function setDefaultPerc(uint vPerc, uint bPerc) external onlyRole(DEFAULT_ADMIN_ROLE) {
        VALIDATORS_PERC = vPerc;
        BROKER_PERC = bPerc;
    }

    function setProtocolFee(uint nominator, uint denominator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        FEE_NOMINATOR = nominator;
        FEE_DENOMINATOR = denominator;
    }

    function setValidationTimeFrame(uint blocks) external onlyRole(DEFAULT_ADMIN_ROLE) {
        TIME_FRAME_SIZE = blocks;
    }

    function getValidationTimeFrame() external view returns(uint) {
        return TIME_FRAME_SIZE;
    }

    function getStakingTokenAddr() external view returns(address) {
        return address(_tokenContract);
    }

    receive() external payable {
        address sender = _msgSender();
        Process storage process = _processes[sender][_depositingProducts[sender]];
        require(process.state == State.AWAITING_TRANSFER, "You don't have a deposit awaiting process, please create it first");
        require(process.cost == msg.value, "Deposit amount doesn't match with the requested deposit");
        // Transfer main payment from customer to the broker(subtracting the fee)
        process.deposit.transfer(msg.value.sub(process.fee));

        // Update process state and emit an event
        process.state = State.AWAITING_TERMINATION;
        emit Deposit(sender, process.service, process.productId, msg.value);
    }

    function addService(address service, address[] memory vList) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(vList.length > 2, "Validators minimum quantity is 3");
        _services[service] = Service({validators: vList, validationPerc: VALIDATORS_PERC, commissionPerc: BROKER_PERC, validatorVersion: 1});
    }

    function setServicePerc(address service, uint vPerc, uint bPerc) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Service storage instance = _services[service];
        instance.validationPerc = vPerc;
        instance.commissionPerc = bPerc;
    }

    function setValidators(address[] memory vList) external onlyService {
        _services[msg.sender].validators = vList;
    }

    function getValidatorVer(address service) external view returns(uint) {
        return _services[service].validatorVersion;
    }

    function setValidatorVer(uint vVer) external onlyService {
        _services[msg.sender].validatorVersion = vVer;
    }

    function getPenaltyPerc() external view returns(uint) {
        return _penaltyPerc;
    }

    function setPenaltyPerc(uint newPenaltyPerc) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _penaltyPerc = newPenaltyPerc;
    }

    function getLockingPeriod() external view returns(uint256) {
        return _lockingPeriod;
    }

    function setLockingPeriod(uint256 newLockingPeriod) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _lockingPeriod = newLockingPeriod;
    }

    function inTimeFrame(address[] memory list, address search, uint256 startBlock, uint intSize) internal view returns(bool) {
        for(uint x=0; x < list.length; x++) {
            if(list[x] == search) {
                return (
                    (x * intSize) <= (block.number - startBlock) && 
                    (block.number - startBlock) < (x * intSize + intSize)
                );
            }
        }
        return false;
    }

    function random() internal view returns(uint256) {
        // Temp solution with fake random
        // TODO resolve with real randomness
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }

    function _randValidatorsList(address service, address exclude1, address exclude2) internal view returns(address[] memory) {
        uint256 localTotalStaked = _totalStaked - _stakesByValidators[exclude1] - _stakesByValidators[exclude2];
        uint256 index = 0;
        uint resultLength = _services[service].validators.length;
        if (exclude1 != address(0)) {
            resultLength -= 1;
        }
        if (exclude2 != address(0)) {
            resultLength -= 1;
        }
        address[] memory result = new address[](resultLength);

        for(uint x=0; x < result.length; x++) {
            index = random() % localTotalStaked;
            for(uint y=0; y < _services[service].validators.length; y++) {
                if (_services[service].validators[y] != exclude1 && _services[service].validators[y] != exclude2) {
                    if (_containsAddress(result, _services[service].validators[y]) == false) {
                        if (index <= _stakesByValidators[_services[service].validators[y]]) {
                            result[x] = _services[service].validators[y];
                            localTotalStaked -= _stakesByValidators[_services[service].validators[y]];
                            break;
                        }
                        index -= _stakesByValidators[_services[service].validators[y]];
                    }
                }
            }
        }
        return result;
    }

    function _createProcess(address token, address service, bytes32 productId, string calldata data) internal {
        require(_services[service].validationPerc > 0, 'Requested service address not found');
        require(_processes[msg.sender][productId].service == address(0), 'Process with specified productId already exist');

        _processes[msg.sender][productId] = Process({
            state: State.AWAITING_COST,
            cost: 0,
            costConf: 0,
            token: token,
            deposit: payable(address(0)),
            depositConf: payable(address(0)),
            fee: 0,
            service: service,
            productId: productId,
            startBlock: block.number,
            validatorsList: _randValidatorsList(service, address(0), address(0)),
            firstValidator: address(0),
            firstResult: false,
            secondValidator: address(0),
            secondResult: false
        });
        emit CostRequest(msg.sender, service, productId, _processes[msg.sender][productId].validatorsList, data);

        if(_depositingProducts[msg.sender].length > 0) {
            if(_processes[msg.sender][_depositingProducts[msg.sender]].state == State.AWAITING_TRANSFER) {
                delete _processes[msg.sender][_depositingProducts[msg.sender]];
            }
        }
        _depositingProducts[msg.sender] = productId;
    }

    function createProcess(address service, bytes32 productId, string calldata data) external {
        _createProcess(address(0), service, productId, data);
    }

    function createProcess(address token, address service, bytes32 productId, string calldata data) external {
        _createProcess(token, service, productId, data);
    }

    function _rewardLoop(address validator, uint256 reward, address token) internal returns(uint256) {
        uint256 transfersSum = 0;
        IERC20 tokenContract;
        if(token != address(0)) {
            tokenContract = IERC20(token);
        }

        for (uint256 i = 0; i < _validatorStakers[validator].length; i++) {
            address staker = _validatorStakers[validator][i];
            Stake storage stakeRecord = _stakes[staker][validator];
            // Calc reward share according to the staked amount
            uint256 transferAmount = reward.mul(stakeRecord.amount.mul(100).div(_stakesByValidators[validator])).div(100);
            // Transfer reward to the staker
            if(token == address(0)) {
                payable(staker).transfer(transferAmount);
            } else {
                tokenContract.transfer(staker, transferAmount);
            }
            transfersSum += transferAmount;
        }
        return transfersSum;
    }

    function _bonusLoop(address validator, uint256 bonus) internal returns(uint256) {
        uint256 transfersSum = 0;
        for (uint256 i = 0; i < _validatorStakers[validator].length; i++) {
            address staker = _validatorStakers[validator][i];
            // Calc bonus share according to the staked amount
            uint256 transferAmount = bonus.mul(_stakes[staker][validator].amount.mul(100).div(_stakesByValidators[validator])).div(100);
            // Increase stake with bonus
            _stakes[staker][validator].amount = _stakes[staker][validator].amount.add(transferAmount);
            transfersSum += transferAmount;
        }
        return transfersSum;
    }

    function _rewardStakers(address firstValidator, address secondValidator, uint256 rewardAmount, address token) internal returns(uint256) {
        uint256 firstReward = rewardAmount.mul(_stakesByValidators[firstValidator].mul(100).div(_stakesByValidators[firstValidator].add(_stakesByValidators[secondValidator]))).div(100);
        uint256 secondReward = rewardAmount - firstReward;
        uint256 firstRewardTsSum = _rewardLoop(firstValidator, firstReward, token);
        uint256 secondRewardTsSum = _rewardLoop(secondValidator, secondReward, token);

        return firstRewardTsSum + secondRewardTsSum;
    }

    function _rewardBonus(address firstValidator, address secondValidator, uint256 bonus) internal {
        uint256 firstBonus = bonus.mul(_stakesByValidators[firstValidator].mul(100).div(_stakesByValidators[firstValidator].add(_stakesByValidators[secondValidator]))).div(100);
        uint256 secondBonus = bonus - firstBonus;
        uint256 firstBonusTsSum = _bonusLoop(firstValidator, firstBonus);
        uint256 secondBonusTsSum = _bonusLoop(secondValidator, secondBonus);

        _stakesByValidators[firstValidator] += firstBonusTsSum;
        _stakesByValidators[secondValidator] += secondBonusTsSum;
    }

    function _makePayouts(address customer, bytes32 productId, bool needRefund, uint256 bonus) internal {
        Process storage process = _processes[customer][productId];
        uint256 reward_amount = process.fee.mul(_services[process.service].validationPerc).div(100);
        uint256 transfers_sum = _rewardStakers(process.firstValidator, process.secondValidator, reward_amount, process.token);
        if(bonus > 0) {
            _rewardBonus(process.firstValidator, process.secondValidator, bonus);
        }

        if(needRefund == false) {
            uint256 commission_amount = process.fee.mul(_services[process.service].commissionPerc).div(100);
            if(process.token == address(0)) {
                payable(process.service).transfer(commission_amount);
                _beneficiary.transfer(process.fee - transfers_sum - commission_amount);
            } else {
                IERC20 tokenContract = IERC20(process.token);
                tokenContract.transfer(process.service, commission_amount);
                tokenContract.transfer(address(_beneficiary), process.fee - transfers_sum - commission_amount);
            }
        } else {
            if(process.token == address(0)) {
                payable(customer).transfer(process.fee - transfers_sum);
            } else {
                IERC20 tokenContract = IERC20(process.token);
                tokenContract.transfer(customer, process.fee - transfers_sum);
            }
        }
    }

    function _penalizeLoop(address validator, uint256 penalty) internal returns(uint256) {
        uint256 transfersSum = 0;
        for (uint256 i = 0; i < _validatorStakers[validator].length; i++) {
            address staker = _validatorStakers[validator][i];
            uint256 transferAmount = penalty.mul(_stakes[staker][validator].amount.mul(100).div(_stakesByValidators[validator])).div(100);
            _stakes[staker][validator].amount = _stakes[staker][validator].amount - transferAmount;
            transfersSum += transferAmount;
        }
        // Subtract penalty from the validator total stakes amount
        _stakesByValidators[validator] -= transfersSum;
        
        return transfersSum;
    }

    function setProcessCost(address customer, bytes32 productId, uint256 cost, address payable depositAddr) external {
        require(_stakesByValidators[msg.sender] > 0, "Only validator with stakes can call this method");
        Process storage process = _processes[customer][productId];
        require(_containsAddress(_services[process.service].validators, msg.sender), "Your address is not whitelisted in the product service settings");
        require(process.state == State.AWAITING_COST, "Cost is already set, check the state");
        require(
            inTimeFrame(
                process.validatorsList,
                msg.sender,
                process.startBlock,
                TIME_FRAME_SIZE
            ),
            "Cannot accept validation, you are out of time"
        );

        if(process.firstValidator == address(0)) {
            process.firstValidator = msg.sender;
            process.cost = cost;
            process.deposit = depositAddr;
            process.startBlock = block.number;
            process.validatorsList = _randValidatorsList(process.service, process.firstValidator, address(0));
            emit CostRequest(customer, process.service, productId, process.validatorsList, '');
        } else if(process.secondValidator == address(0)) {
            process.secondValidator = msg.sender;
            process.costConf = cost;
            process.depositConf = depositAddr;
            if(process.cost == process.costConf && process.deposit == process.depositConf) {
                process.fee = cost.mul(FEE_NOMINATOR).div(FEE_DENOMINATOR);
                process.state = State.AWAITING_TRANSFER;
                emit CostResponse(customer, process.service, productId, cost);
            } else {
                process.startBlock = block.number;
                process.validatorsList = _randValidatorsList(process.service, process.firstValidator, process.secondValidator);
                emit CostRequest(customer, process.service, productId, process.validatorsList, '');
            }
        } else {
            if(process.cost == cost && process.deposit == depositAddr) {
                process.secondValidator = msg.sender;
                process.costConf = cost;
                process.depositConf = depositAddr;
            } else {
                process.firstValidator = msg.sender;
                process.cost = cost;
                process.deposit = depositAddr;
            }
            process.cost = cost;
            process.fee = cost.mul(FEE_NOMINATOR).div(FEE_DENOMINATOR);
            process.state = State.AWAITING_TRANSFER;
            emit CostResponse(customer, process.service, productId, cost);
        }
    }

    function declareAction(address customer, bytes32 productId, string calldata data) external onlyService {
        emit Action(customer, msg.sender, productId, data);
    }

    function startTermination(address customer, bytes32 productId) external {
        require((_services[msg.sender].validationPerc > 0) || (msg.sender == customer), "Only service or product customer can call this method");
        Process storage process = _processes[customer][productId];
        require(process.state == State.AWAITING_TERMINATION, "Cannot start termination, check the state");

        process.state = State.AWAITING_VALIDATION;
        process.startBlock = block.number;
        process.validatorsList = _randValidatorsList(process.service, address(0), address(0));
        process.firstValidator = address(0);
        process.firstResult = false;
        process.secondValidator = address(0);
        process.secondResult = false;
        emit Terminate(customer, msg.sender, productId, process.validatorsList);
    }

    function validateTermination(address customer, bytes32 productId, bool result) external {
        require(_stakesByValidators[msg.sender] > 0, "Only validator with stakes can call this method");
        Process storage process = _processes[customer][productId];
        require(_containsAddress(_services[process.service].validators, msg.sender), "Your address is not whitelisted in the product service settings");
        require(process.state == State.AWAITING_VALIDATION, "Cannot accept validation, check the state");
        require(
            inTimeFrame(
                process.validatorsList,
                msg.sender,
                process.startBlock,
                TIME_FRAME_SIZE
            ),
            "Cannot accept validation, you are out of time"
        );

        // If we don't have first validator response yet
        if(process.firstValidator == address(0)) {
            process.firstValidator = msg.sender;
            process.firstResult = result;
            process.startBlock = block.number;
            process.validatorsList = _randValidatorsList(process.service, process.firstValidator, address(0));
            emit Terminate(customer, process.service, productId, process.validatorsList);
        // If we have first validator response but not the second one
        } else if(process.secondValidator == address(0)) {
            process.secondValidator = msg.sender;
            process.secondResult = result;
            // If the first and second validator results match
            if(process.firstResult == process.secondResult) {
                _makePayouts(customer, productId, !process.firstResult, 0);
                process.state = State.COMPLETED;
                emit Complete(customer, process.service, productId, process.firstResult);
            // If the first and second validator results do not match
            } else {
                process.startBlock = block.number;
                process.validatorsList = _randValidatorsList(process.service, process.firstValidator, process.secondValidator);
                emit Terminate(customer, process.service, productId, process.validatorsList);
            }
        // If we have received the third validator response
        } else {
            if(process.firstResult == result) {
                uint256 penalty = _stakesByValidators[process.secondValidator].mul(_penaltyPerc).div(100);
                uint256 appliedPenalty = _penalizeLoop(process.secondValidator, penalty);
                process.secondValidator = msg.sender;
                process.secondResult = result;
                _makePayouts(customer, productId, !process.firstResult, appliedPenalty);
            } else {
                uint256 penalty = _stakesByValidators[process.firstValidator].mul(_penaltyPerc).div(100);
                uint256 appliedPenalty = _penalizeLoop(process.firstValidator, penalty);
                process.firstValidator = msg.sender;
                process.firstResult = result;
                _makePayouts(customer, productId, !process.firstResult, appliedPenalty);
            }
            process.state = State.COMPLETED;
            emit Complete(customer, process.service, productId, process.firstResult);
        }
    }

    function getProcess(address customer, bytes32 productId) external view returns(Process memory) {
        return _processes[customer][productId];
    }

    function stake(address validator, uint256 amount) external {
        require(validator != address(0), "Validator address cannot be 0");
        require(amount > 0, "Cannot stake 0");

        bool success = _tokenContract.transferFrom(msg.sender, address(this), amount);
        if(success) {
            _totalStaked = _totalStaked.add(amount);
            bool alreadyStaked = false;
            if (_stakes[msg.sender][validator].amount > 0) {
                alreadyStaked = true;
            }
            _stakes[msg.sender][validator].amount = _stakes[msg.sender][validator].amount.add(amount);
            _stakes[msg.sender][validator].unlockingBlock = block.number + _lockingPeriod;
            _stakesByValidators[validator] = _stakesByValidators[validator].add(amount);
            if (alreadyStaked == false && _containsAddress(_validatorStakers[validator], msg.sender) == false) {
                _validatorStakers[validator].push(msg.sender);
            }
            emit Staked(msg.sender, validator, amount, _stakes[msg.sender][validator].unlockingBlock);
        } else {
            revert("Wasn't able to transfer your token");
        }
    }

    function unStake(address validator, uint256 amount) external {
        require(amount > 0, "Cannot unstake 0");
        require(_stakes[msg.sender][validator].amount >= amount, "Your balance is lower than the amount of tokens you want to unstake");
        // Check locking period
        require(_stakes[msg.sender][validator].unlockingBlock <= block.number, "The locking period didn't pass, you cannot unstake");
        // This will transfer the amount of token from contract to the sender balance
        bool success = _tokenContract.transfer(msg.sender, amount);
        if(success) {
            _totalStaked -= amount;
            _stakes[msg.sender][validator].amount = _stakes[msg.sender][validator].amount - amount;
            _stakesByValidators[validator] = _stakesByValidators[validator] - amount;
            emit UnStaked(msg.sender, validator, amount);
        } else {
            revert("Wasn't able to execute transfer of your tokens");
        }
    }

    function stakeOf(address staker, address validator) external view returns (Stake memory) {
        return _stakes[staker][validator];
    }

    function totalStakeOf(address validator) external view returns (uint256) {
        return _stakesByValidators[validator];
    }

    function totalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    function deposit(uint256 amount) external {
        Process storage process = _processes[msg.sender][_depositingProducts[msg.sender]];
        require(process.token != address(0), "The current process doesn't wait for an ERC20 token deposit");
        require(process.state == State.AWAITING_TRANSFER, "You don't have a deposit awaiting process, please create it first");
        require(process.cost == amount, "Deposit amount doesn't match with the requested cost");
        // Create ERC20 token interface
        IERC20 tokenContract = IERC20(process.token);
        // Transfer deposit payment from customer to the contract
        bool success = tokenContract.transferFrom(_msgSender(), address(this), amount);
        if(success) {
            // Transfer main payment from contract to the broker(subtracting the fee)
            success = tokenContract.transfer(address(process.deposit), amount.sub(process.fee));
            if(success) {
                // Update process state and emit an event
                process.state = State.AWAITING_TERMINATION;
                emit Deposit(_msgSender(), process.service, process.productId, amount);
            } else {
                revert("Wasn't able to transfer token to the broker");
            }
        } else {
            revert("Wasn't able to transfer your token");
        }
    }

}