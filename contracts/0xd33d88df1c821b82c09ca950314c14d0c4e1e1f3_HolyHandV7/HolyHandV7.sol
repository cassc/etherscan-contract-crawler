/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// File: contracts/HolyHandV6.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

///////////////////////////////////////////////////////////////////////////
//     __/|      
//  __////  /|   This smart contract is part of Mover infrastructure
// |// //_///    https://viamover.com
//    |_/ //     [email protected]
//       |/
///////////////////////////////////////////////////////////////////////////


/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual {
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
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// Interface to represent asset pool interactions
interface IHolyPoolV2 {
    function getBaseAsset() external view returns(address);

    // functions callable by HolyHand transfer proxy
    function depositOnBehalf(address beneficiary, uint256 amount) external;
    function depositOnBehalfDirect(address beneficiary, uint256 amount) external;
    function withdraw(address beneficiary, uint256 amount) external;

    // functions callable by HolyValor investment proxies
    // pool would transfer funds to HolyValor (returns actual amount, could be less than asked)
    function borrowToInvest(uint256 amount) external returns(uint256);
    // return invested body portion from HolyValor (pool will claim base assets from caller Valor)
    function returnInvested(uint256 amountCapitalBody) external;

    // functions callable by HolyRedeemer yield distributor
    function harvestYield(uint256 amount) external; // pool would transfer amount tokens from caller as it's profits
}


// Interface to represent middleware contract for swapping tokens
interface IHolyWing {
    // returns amount of 'destination token' that 'source token' was swapped to
    // NOTE: HolyWing grants allowance to arbitrary address (with call to contract that could be forged) and should not hold any funds
    function executeSwap(address tokenFrom, address tokenTo, uint256 amount, bytes calldata data) external returns(uint256);
}


// Interface to represent middleware contract for swapping tokens
interface IHolyWingV2 {
    // returns amount of 'destination token' that 'source token' was swapped to
    // NOTE: HolyWing grants allowance to arbitrary address (with call to contract that could be forged) and should not hold any funds
    function executeSwap(address tokenFrom, address tokenTo, uint256 amount, bytes calldata data) payable external returns(uint256);

    function executeSwapDirect(address beneficiary, address tokenFrom, address tokenTo, uint256 amount, uint256 fee, bytes calldata data) payable external returns(uint256);
}


// Interface to represent middleware contract for distributing profits
interface IHolyRedeemer {
}


// Interface to represent asset pool interactions
interface ISmartTreasury {
    function spendBonus(address _account, uint256 _amount) external;
    function depositOnBehalf(address _account, uint _tokenMoveAmount, uint _tokenMoveEthAmount) external;
    function claimAndBurnOnBehalf(address _beneficiary, uint256 _amount) external;
}


// Interface to represent burnable ERC20 tokens
interface IBurnable {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external; 
}


interface IChainLinkFeed {
  function latestAnswer() external view returns (int256);
}


abstract contract SafeAllowanceReset {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // this function exists due to OpenZeppelin quirks in safe allowance-changing methods
  // we don't want to set allowance by small chunks as it would cost more gas for users
  // and we don't want to set it to zero and then back to value (this makes no sense security-wise in single tx)
  // from the other side, using it through safeIncreaseAllowance could revery due to SafeMath overflow
  // Therefore, we calculate what amount we can increase allowance on to refill it to max uint256 value
  function resetAllowanceIfNeeded(IERC20 _token, address _spender, uint256 _amount) internal {
    uint256 allowance = _token.allowance(address(this), _spender);
    if (allowance < _amount) {
      uint256 newAllowance = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
      IERC20(_token).safeIncreaseAllowance(address(_spender), newAllowance.sub(allowance));
    }
  }
}



/*
    HolyHand is a transfer proxy contract for ERC20 and ETH transfers through Holyheld infrastructure (deposit/withdraw to HolyPool, swaps, etc.)
    - extract fees;
    - call token conversion if needed;
    - deposit/withdraw tokens into HolyPool;
    - non-custodial, not holding any funds;
    - fees are accumulated on this contract's balance (if fees enabled);

    This contract is a single address that user grants allowance to on any ERC20 token for interacting with HH services.
    This contract could be upgraded in the future to provide subsidized transactions using bonuses from treasury.

    TODO: if token supports permit, provide ability to execute without separate approval call

    V2 version additions:
    - direct deposits to pool (if no fees or conversions);
    - when swapping tokens direct return converted asset to sender (if no fees);
    - ETH support (non-wrapped ETH conversion for deposits and swaps);
    - emergencyTransfer can reclaim ETH

    V3 version additions:
    - support for subsidized transaction execution;

    V4 version additions:
    - support for subsidized treasury deposit/withdrawals;
    - bonus spending parameter using USDC/USD price data from chainlink (feature-flagged)

    V5 version additions:
    - cardTopUp method added that converts to USDC if needed, creates event and transfers to partner account on user behalf

    V6 version additions:
    - added bridging tx methods
*/
contract HolyHandV7 is AccessControlUpgradeable, SafeAllowanceReset {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 private constant ALLOWANCE_SIZE =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    // token address for non-wrapped eth
    address private constant ETH_TOKEN_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // if greater than zero, this is a fractional amount (1e18 = 1.0) fee applied to all deposits
    uint256 public depositFee;
    // if greater than zero, this is a fractional amount (1e18 = 1.0) fee applied to exchange operations with HolyWing proxy
    uint256 public exchangeFee;
    // if greater than zero, this is a fractional amount (1e18 = 1.0) fee applied to withdraw operations
    uint256 public withdrawFee;

    // HolyWing exchange proxy/middleware
    IHolyWing private exchangeProxyContract;

    // HolyRedeemer yield distributor
    // NOTE: to keep overhead for users minimal, fees are not transferred
    // immediately, but left on this contract balance, yieldDistributor can reclaim them
    address private yieldDistributorAddress;

    event TokenSwap(
        address indexed tokenFrom,
        address indexed tokenTo,
        address sender,
        uint256 amountFrom,
        uint256 expectedMinimumReceived,
        uint256 amountReceived
    );

    event FeeChanged(string indexed name, uint256 value);

    event EmergencyTransfer(
        address indexed token,
        address indexed destination,
        uint256 amount
    );

    function initialize() public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        depositFee = 0;
        exchangeFee = 0;
        withdrawFee = 0;
    }

    function setExchangeProxy(address _exchangeProxyContract) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        exchangeProxyContract = IHolyWing(_exchangeProxyContract);
    }

    function setYieldDistributor(
        address _tokenAddress,
        address _distributorAddress
    ) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        yieldDistributorAddress = _distributorAddress;
        // only yield to be redistributed should be present on this contract in baseAsset (or other tokens if swap fees)
        // so no access to lp tokens for the funds invested
        resetAllowanceIfNeeded(
            IERC20(_tokenAddress),
            _distributorAddress,
            ALLOWANCE_SIZE
        );
    }

    // if the pool baseToken matches the token deposited, then no conversion is performed
    // and _expectedMininmumReceived/convertData should be zero/empty
    function depositToPool(
        address _poolAddress,
        address _token,
        uint256 _amount,
        uint256 _expectedMinimumReceived,
        bytes memory _convertData
    ) public payable {
        depositToPoolOnBehalf(msg.sender, _poolAddress, _token, _amount, _expectedMinimumReceived, _convertData);
    }

    function depositToPoolOnBehalf(
        address _beneficiary,
        address _poolAddress,
        address _token,
        uint256 _amount,
        uint256 _expectedMinimumReceived,
        bytes memory _convertData
    ) internal {
        IHolyPoolV2 holyPool = IHolyPoolV2(_poolAddress);
        IERC20 poolToken = IERC20(holyPool.getBaseAsset());

        if (address(poolToken) == _token) {
            // no conversion is needed, allowance and balance checks performed in ERC20 token
            // and not here to not waste any gas fees

            if (depositFee == 0) {
                // use depositOnBehalfDirect function only for this flow to save gas as much as possible
                // (we have approval for this contract, so it can transfer funds to pool directly if
                // deposit fees are zero (otherwise we go with standard processing flow)

                // transfer directly to pool
                IERC20(_token).safeTransferFrom(
                    _beneficiary,
                    _poolAddress,
                    _amount
                );

                // call pool function to process deposit (without transfer)
                holyPool.depositOnBehalfDirect(_beneficiary, _amount);
                return;
            }

            IERC20(_token).safeTransferFrom(_beneficiary, address(this), _amount);

            // HolyPool must have sufficient allowance (one-time for pool/token pair)
            resetAllowanceIfNeeded(poolToken, _poolAddress, _amount);

            // process deposit fees and deposit remainder
            uint256 feeAmount = _amount.mul(depositFee).div(1e18);
            holyPool.depositOnBehalf(_beneficiary, _amount.sub(feeAmount));
            return;
        }

        // conversion is required, perform swap through exchangeProxy (HolyWing)
        if (_token != ETH_TOKEN_ADDRESS) {
            IERC20(_token).safeTransferFrom(
                _beneficiary,
                address(exchangeProxyContract),
                _amount
            );
        }

        if (depositFee > 0) {
            // process exchange/deposit fees and route through HolyHand
            uint256 amountReceived =
                IHolyWingV2(address(exchangeProxyContract)).executeSwapDirect{value: msg.value}(
                    address(this),
                    _token,
                    address(poolToken),
                    _amount,
                    exchangeFee,
                    _convertData
                );
            require(
                amountReceived >= _expectedMinimumReceived,
                "minimum swap amount not met"
            );
            uint256 feeAmount = amountReceived.mul(depositFee).div(1e18);
            amountReceived = amountReceived.sub(feeAmount);

            // HolyPool must have sufficient allowance (one-time for pool/token pair)
            resetAllowanceIfNeeded(poolToken, _poolAddress, _amount);

            // perform actual deposit call
            holyPool.depositOnBehalf(_beneficiary, amountReceived);
        } else {
            // swap directly to HolyPool address and execute direct deposit call
            uint256 amountReceived =
                IHolyWingV2(address(exchangeProxyContract)).executeSwapDirect{value: msg.value}(
                    _poolAddress,
                    _token,
                    address(poolToken),
                    _amount,
                    exchangeFee,
                    _convertData
                );
            require(
                amountReceived >= _expectedMinimumReceived,
                "minimum swap amount not met"
            );
            holyPool.depositOnBehalfDirect(_beneficiary, amountReceived);
        }
    }

    function withdrawFromPool(address _poolAddress, uint256 _amount) public {
        withdrawFromPoolOnBehalf(msg.sender, _poolAddress, _amount);
    }

    function withdrawFromPoolOnBehalf(address _beneficiary, address _poolAddress, uint256 _amount) internal {
        IHolyPoolV2 holyPool = IHolyPoolV2(_poolAddress);
        IERC20 poolToken = IERC20(holyPool.getBaseAsset());
        uint256 amountBefore = poolToken.balanceOf(address(this));
        holyPool.withdraw(_beneficiary, _amount);
        uint256 withdrawnAmount =
            poolToken.balanceOf(address(this)).sub(amountBefore);

        // if amount is less than expected, transfer anyway what was actually received
        if (withdrawFee > 0) {
            // process withdraw fees
            uint256 feeAmount = withdrawnAmount.mul(withdrawFee).div(1e18);
            poolToken.safeTransfer(_beneficiary, withdrawnAmount.sub(feeAmount));
        } else {
            poolToken.safeTransfer(_beneficiary, withdrawnAmount);
        }
    }

    function setDepositFee(uint256 _depositFee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        depositFee = _depositFee;
        emit FeeChanged("deposit", _depositFee);
    }

    function setExchangeFee(uint256 _exchangeFee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        exchangeFee = _exchangeFee;
        emit FeeChanged("exchange", _exchangeFee);
    }

    function setWithdrawFee(uint256 _withdrawFee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        withdrawFee = _withdrawFee;
        emit FeeChanged("withdraw", _withdrawFee);
    }

    function setTransferFee(uint256 _transferFee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        transferFee = _transferFee;
        emit FeeChanged("transfer", _transferFee);
    }

    // token swap function (could be with fees but also can be subsidized later)
    // perform conversion through exhcnageProxy (HolyWing)
        function executeSwap(
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountFrom,
        uint256 _expectedMinimumReceived,
        bytes memory _convertData
    ) public payable {
        executeSwapOnBehalf(msg.sender, _tokenFrom, _tokenTo, _amountFrom, _expectedMinimumReceived, _convertData);
    }

    function executeSwapOnBehalf(
        address _beneficiary,
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountFrom,
        uint256 _expectedMinimumReceived,
        bytes memory _convertData
    ) internal {
        require(_tokenFrom != _tokenTo, "same tokens provided");

        // swap with direct transfer to HolyWing and HolyWing would transfer swapped token (or ETH) back to msg.sender
        if (_tokenFrom != ETH_TOKEN_ADDRESS) {
            IERC20(_tokenFrom).safeTransferFrom(
                _beneficiary,
                address(exchangeProxyContract),
                _amountFrom
            );
        }
        uint256 amountReceived =
            IHolyWingV2(address(exchangeProxyContract)).executeSwapDirect{value: msg.value}(
                _beneficiary,
                _tokenFrom,
                _tokenTo,
                _amountFrom,
                exchangeFee,
                _convertData
            );
        require(
            amountReceived >= _expectedMinimumReceived,
            "minimum swap amount not met"
        );
    }

    // payable fallback to receive ETH when swapping to raw ETH
    receive() external payable {}

    // this function is similar to emergencyTransfer, but relates to yield distribution
    // fees are not transferred immediately to save gas costs for user operations
    // so they accumulate on this contract address and can be claimed by HolyRedeemer
    // when appropriate. Anyway, no user funds should appear on this contract, it
    // only performs transfers, so such function has great power, but should be safe
    // It does not include approval, so may be used by HolyRedeemer to get fees from swaps
    // in different small token amounts
    function claimFees(address _token, uint256 _amount) public {
        require(
            msg.sender == yieldDistributorAddress,
            "yield distributor only"
        );
        if (_token != ETH_TOKEN_ADDRESS) {
            IERC20(_token).safeTransfer(msg.sender, _amount);
        } else {
            payable(msg.sender).sendValue(_amount);
        }
    }

    // all contracts that do not hold funds have this emergency function if someone occasionally
    // transfers ERC20 tokens directly to this contract
    // callable only by owner
    function emergencyTransfer(
        address _token,
        address _destination,
        uint256 _amount
    ) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        if (_token != ETH_TOKEN_ADDRESS) {
            IERC20(_token).safeTransfer(_destination, _amount);
        } else {
            payable(_destination).sendValue(_amount);
        }
        emit EmergencyTransfer(_token, _destination, _amount);
    }

    ///////////////////////////////////////////////////////////////////////////
    // V3 SMART TREASURY AND SUBSIDIZED TRANSACTIONS
    ///////////////////////////////////////////////////////////////////////////
    // these should be callable only by trusted backend wallet
    // so that only signed by account and validated actions get executed and proper bonus amount
    // if spending bonus does not revert, account has enough bonus tokens
    // this contract must have EXECUTOR_ROLE set in Smart Treasury contract to call this

    bytes32 public constant TRUSTED_EXECUTION_ROLE = keccak256("TRUSTED_EXECUTION");  // trusted execution wallets

    address smartTreasury;
    address tokenMoveAddress;
    address tokenMoveEthLPAddress;

    // if greater than zero, this is a fractional amount (1e18 = 1.0) fee applied to transfer operations (that could also be subsidized)
    uint256 public transferFee;

    // connect to Smart Treasury contract
    function setSmartTreasury(address _smartTreasury) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        smartTreasury = _smartTreasury;
    }

    function setTreasuryTokens(address _tokenMoveAddress, address _tokenMoveEthLPAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        tokenMoveAddress = _tokenMoveAddress;
        tokenMoveEthLPAddress = _tokenMoveEthLPAddress;
    }

    // depositing to ST not requiring allowance to ST for MOVE or MOVE-ETH LP
    function depositToTreasury(uint _tokenMoveAmount, uint _tokenMoveEthAmount) public {
        if (_tokenMoveAmount > 0) {
            IERC20(tokenMoveAddress).safeTransferFrom(msg.sender, smartTreasury, _tokenMoveAmount);
        }
        if (_tokenMoveEthAmount > 0) {
            IERC20(tokenMoveEthLPAddress).safeTransferFrom(msg.sender, smartTreasury, _tokenMoveEthAmount);
        }
        ISmartTreasury(smartTreasury).depositOnBehalf(msg.sender, _tokenMoveAmount, _tokenMoveEthAmount);
    }

    // burn of MOVE tokens not requiring allowance so ST for MOVE
    function claimAndBurn(uint _amount) public {
        // burn bonus portion and send USDC
        ISmartTreasury(smartTreasury).claimAndBurnOnBehalf(msg.sender, _amount);
        // burn MOVE tokens (after USDC calculation and transfer complete to have proper totalSupply)
        IBurnable(tokenMoveAddress).burnFrom(msg.sender, _amount);
    }

    // subsidized sending of ERC20 token to another address
    function executeSendOnBehalf(address _beneficiary, address _token, address _destination, uint256 _amount, uint256 _bonus) public {
        require(hasRole(TRUSTED_EXECUTION_ROLE, msg.sender), "trusted executor only");

        ISmartTreasury(smartTreasury).spendBonus(_beneficiary, priceCorrection(_bonus));

        // perform transfer, assuming this contract has allowance
        if (transferFee == 0) {
            IERC20(_token).safeTransferFrom(_beneficiary, _destination, _amount);
        } else {
            uint256 feeAmount = _amount.mul(transferFee).div(1e18);
            IERC20(_token).safeTransferFrom(_beneficiary, address(this), _amount);
            IERC20(_token).safeTransfer(_destination, _amount.sub(feeAmount));
        }
    }

    // subsidized deposit of assets to pool
    function executeDepositOnBehalf(address _beneficiary, address _token, address _pool, uint256 _amount, uint256 _expectedMinimumReceived, bytes memory _convertData, uint256 _bonus) public {
        require(hasRole(TRUSTED_EXECUTION_ROLE, msg.sender), "trusted executor only");

        ISmartTreasury(smartTreasury).spendBonus(_beneficiary, priceCorrection(_bonus));

        // perform deposit, assuming this contract has allowance
        // TODO: check deposit on behalf with raw Eth! it's not supported but that it reverts;
        // TODO: check if swap would be executed properly;
        depositToPoolOnBehalf(_beneficiary, _pool, _token, _amount, _expectedMinimumReceived, _convertData);
    }

    // subsidized withdraw of assets from pool
    function executeWithdrawOnBehalf(address _beneficiary, address _pool, uint256 _amount, uint256 _bonus) public {
        require(hasRole(TRUSTED_EXECUTION_ROLE, msg.sender), "trusted executor only");

        ISmartTreasury(smartTreasury).spendBonus(_beneficiary, priceCorrection(_bonus));

        withdrawFromPoolOnBehalf(_beneficiary, _pool, _amount);
    }
    
    // subsidized swap of ERC20 assets (also possible swap to raw Eth)
    function executeSwapOnBehalf(address _beneficiary, address _tokenFrom, address _tokenTo, uint256 _amountFrom, uint256 _expectedMinimumReceived, bytes memory _convertData, uint256 _bonus) public {
        require(hasRole(TRUSTED_EXECUTION_ROLE, msg.sender), "trusted executor only");

        ISmartTreasury(smartTreasury).spendBonus(_beneficiary, priceCorrection(_bonus));

        // TODO: check deposit on behalf with raw Eth! it's not supported but that it reverts;
        executeSwapOnBehalf(_beneficiary, _tokenFrom, _tokenTo, _amountFrom, _expectedMinimumReceived, _convertData);
    }

    ///////////////////////////////////////////////////////////////////////////
    // V4 UPDATES
    ///////////////////////////////////////////////////////////////////////////
    
    // Address of USDC/USD pricefeed from Chainlink
    // (used for burning bonuses, USD amount expected)
    address private USDCUSD_FEED_ADDRESS;

    // if address is set to 0x, recalculation using pricefeed is disabled
    function setUSDCPriceFeed(address _feed) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        USDCUSD_FEED_ADDRESS = _feed;
    }

    // if feed check is active, recalculate amount of bonus spent in USDC
    // (_bonus amount is calculated from Eth price and is in USD)
    function priceCorrection(uint256 _bonus) internal view returns(uint256) {
        if (USDCUSD_FEED_ADDRESS != address(0)) {
            // feed is providing values as 0.998 (1e8) means USDC is 0.998 USD, so USDC amount = USD amount / feed value
            return _bonus.mul(1e8).div(uint256(IChainLinkFeed(USDCUSD_FEED_ADDRESS).latestAnswer()));
        }
        return _bonus;
    }


    ///////////////////////////////////////////////////////////////////////////
    // V5 UPDATES
    ///////////////////////////////////////////////////////////////////////////
    event CardTopup(address indexed account, address token, uint256 valueToken, uint256 valueUSDC);

    address private CARD_PARTNER_ADDRESS;
    address private CARD_TOPUP_TOKEN;

    function setCardPartnerAddress(address _addr) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        CARD_PARTNER_ADDRESS = _addr;
    }

    function setCardTopupToken(address _addr) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        CARD_TOPUP_TOKEN = _addr;
    }

    function cardTopUp(
        address _beneficiary,
        address _token,
        uint256 _amount,
        uint256 _expectedMinimumReceived,
        bytes memory _convertData
    ) public payable {
        require(_beneficiary == msg.sender, "only direct topups allowed");

        if (CARD_TOPUP_TOKEN == _token) {
            // no conversion is needed, allowance and balance checks performed in ERC20 token
            // and not here to not waste any gas fees
            IERC20(_token).safeTransferFrom(
                _beneficiary,
                CARD_PARTNER_ADDRESS,
                _amount
            );

            emit CardTopup(_beneficiary, _token, _amount, _amount);
            return;
        }

        // conversion is required, perform swap through exchangeProxy (HolyWing)
        if (_token != ETH_TOKEN_ADDRESS) {
            IERC20(_token).safeTransferFrom(
                _beneficiary,
                address(exchangeProxyContract),
                _amount
            );
        }

        // swap directly to partner address
        uint256 amountReceived =
            IHolyWingV2(address(exchangeProxyContract)).executeSwapDirect{value: msg.value}(
                CARD_PARTNER_ADDRESS,
                _token,
                CARD_TOPUP_TOKEN,
                _amount,
                exchangeFee,
                _convertData
            );

        require(
            amountReceived >= _expectedMinimumReceived,
            "minimum swap amount not met"
        );

        emit CardTopup(_beneficiary, _token, _amount, amountReceived);
    }

    ///////////////////////////////////////////////////////////////////////////
    // V6 UPDATES
    ///////////////////////////////////////////////////////////////////////////
    event BridgeTx(address indexed beneficiary, address token, uint256 amount, address target, address relayTarget);

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(
                        add(tempBytes, lengthmod),
                        mul(0x20, iszero(lengthmod))
                    )
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(
                            add(
                                add(_bytes, lengthmod),
                                mul(0x20, iszero(lengthmod))
                            ),
                            _start
                        )
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    // 1. transfer asset to this contract (it should have permission as it's transfer proxy to avoid multiple approval points)
    // 2. check allowance from this contract to bridge tx recepient
    // 3. execute bridging transaction
    // 4. produce bridging event
    function bridgeAsset(address _token, uint256 _amount, bytes memory _bridgeTxData, address _relayTarget) public {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        bridgeAssetDirect(_token, _amount, _bridgeTxData, _relayTarget);
    }

    function bridgeAssetDirect(address _token, uint256 _amount, bytes memory _bridgeTxData, address _relayTarget) internal {
        address targetAddress;
        bytes memory callData = slice(_bridgeTxData, 20, _bridgeTxData.length - 20);
        assembly {
            targetAddress := mload(add(_bridgeTxData, add(0x14, 0)))
        }

        // call method is very powerful, as it allows to call anything pretending to be the transfer proxy
        // (this matters for Mover asset pools)
        // security-wise it's whitelisted to bridge contract address only (may be expanded for different bridges)
        require(targetAddress == 0x6571d6be3d8460CF5F7d6711Cd9961860029D85F, "unknown bridge");

        resetAllowanceIfNeeded(
            IERC20(_token),
            targetAddress,
            _amount
        );

        (bool success, ) = targetAddress.call(callData);
        require(success, "BRIDGE_CALL_FAILED");

        emit BridgeTx(msg.sender, _token, _amount, targetAddress, _relayTarget);
    }

    function swapBridgeAsset(address _tokenFrom, address _tokenTo, uint256 _amountFrom, uint256 _expectedMinimumReceived, bytes memory _convertData, bytes memory _bridgeTxData, address _relayTarget, uint256 _minToMint, uint256 _minDy) public payable {
        require(_tokenFrom != _tokenTo, "same tokens provided");

        if (_tokenFrom != ETH_TOKEN_ADDRESS) {
            IERC20(_tokenFrom).safeTransferFrom(
                msg.sender,
                address(exchangeProxyContract),
                _amountFrom
            );
        }
        uint256 amountReceived =
            IHolyWingV2(address(exchangeProxyContract)).executeSwapDirect{value: msg.value}(
                address(this),
                _tokenFrom,
                _tokenTo,
                _amountFrom,
                exchangeFee,
                _convertData
            );
        require(
            amountReceived >= _expectedMinimumReceived,
            "minimum swap amount not met"
        );

        // modify part of bridgeTxData to reflect new amount
        // bridgeTxData
        // bytes   0..19 target contract address
        // bytes  20..23 function signature
        // bytes  24..151 bridge tx params
        // bytes 152..183 min to mint
        // bytes 184..279 bridge tx params
        // bytes 280..311 min dy
        // bytes 312..407 bridge tx params
        // bytes 408..439 source amount
        // bytes 440..471 bridge tx params
        assembly {
            // first 32 bytes of 'bytes' is it's length, and after that it's contents
            // so offsets are 32+152=184, 32+280=312, 32+408=440
            mstore(add(_bridgeTxData, 184), _minToMint)
            mstore(add(_bridgeTxData, 312), _minDy)
            mstore(add(_bridgeTxData, 440), amountReceived)
        }

        bridgeAssetDirect(_tokenTo, amountReceived, _bridgeTxData, _relayTarget);
    }

    // callable only by trusted executor as it performs withdrawal for arbitrary address on this contract balance (only for bridging)
    function withdrawAndBridgeAsset(address _beneficiary, address _poolAddress, uint256 _amount, bytes memory _bridgeTxData) public {
        require(hasRole(TRUSTED_EXECUTION_ROLE, msg.sender), "trusted executor only");

        IHolyPoolV2 assetPool = IHolyPoolV2(_poolAddress);
        address poolToken = assetPool.getBaseAsset();
        uint256 amountBefore = IERC20(poolToken).balanceOf(address(this));
        assetPool.withdraw(_beneficiary, _amount);
        uint256 withdrawnAmount = IERC20(poolToken).balanceOf(address(this)).sub(amountBefore);

        if (withdrawFee > 0) {
            // process withdraw fees
            // bridgetxdata must take this amount into account
            uint256 feeAmount = withdrawnAmount.mul(withdrawFee).div(1e18);
            bridgeAssetDirect(poolToken, withdrawnAmount.sub(feeAmount), _bridgeTxData, address(0));
        } else {
            bridgeAssetDirect(poolToken, withdrawnAmount, _bridgeTxData, address(0));
        }
    }
}