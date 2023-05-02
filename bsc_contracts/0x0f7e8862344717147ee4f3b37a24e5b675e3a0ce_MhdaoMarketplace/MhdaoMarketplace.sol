/**
 *Submitted for verification at BscScan.com on 2023-05-01
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
   *
   * [IMPORTANT]
   * ====
   * You shouldn't rely on `isContract` to protect against flash loan attacks!
   *
   * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
   * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
   * constructor.
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize/address.code.length, which returns 0
    // for contracts in construction, since the code is only stored at the end
    // of the constructor execution.

    return account.code.length > 0;
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
    require(address(this).balance >= amount, "no funds");

    (bool success, ) = recipient.call{value: amount}("");
    require(success);
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain `call` is an unsafe replacement for a function call: use this
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
    return functionCallWithValue(target, data, 0);
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
    return functionCallWithValue(target, data, value);
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value);
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
   * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
   *
   * _Available since v4.8._
   */
  function verifyCallResultFromTarget(
    address target,
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    if (success) {
      if (returndata.length == 0) {
        // only check isContract if the call was successful and the return data is empty
        // otherwise we already know that it was a contract
        require(isContract(target));
      }
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  /**
   * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason or using the provided one.
   *
   * _Available since v4.3._
   */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function _revert(bytes memory returndata, string memory errorMessage) private pure {
    // Look for revert reason and bubble it up if present
    if (returndata.length > 0) {
      // The easiest way to bubble the revert reason is using memory via assembly
      /// @solidity memory-safe-assembly
      assembly {
        let returndata_size := mload(returndata)
        revert(add(32, returndata), returndata_size)
      }
    } else {
      revert(errorMessage);
    }
  }
}

// File @openzeppelin/contracts-upgradeable/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   * @custom:oz-retyped-from bool
   */
  uint8 private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private _initializing;

  /**
   * @dev Triggered when the contract has been initialized or reinitialized.
   */
  event Initialized(uint8 version);

  /**
   * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
   * `onlyInitializing` functions can be used to initialize parent contracts.
   *
   * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
   * constructor.
   *
   * Emits an {Initialized} event.
   */
  modifier initializer() {
    bool isTopLevelCall = !_initializing;
    require(
      (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
      "n"
    );
    _initialized = 1;
    if (isTopLevelCall) {
      _initializing = true;
    }
    _;
    if (isTopLevelCall) {
      _initializing = false;
      emit Initialized(1);
    }
  }

  /**
   * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
   * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
   * used to initialize parent contracts.
   *
   * A reinitializer may be used after the original initialization step. This is essential to configure modules that
   * are added through upgrades and that require initialization.
   *
   * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
   * cannot be nested. If one is invoked in the context of another, execution will revert.
   *
   * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
   * a contract, executing them in the right order is up to the developer or operator.
   *
   * WARNING: setting the version to 255 will prevent any future reinitialization.
   *
   * Emits an {Initialized} event.
   */
  modifier reinitializer(uint8 version) {
    require(!_initializing && _initialized < version);
    _initialized = version;
    _initializing = true;
    _;
    _initializing = false;
    emit Initialized(version);
  }

  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
   * {initializer} and {reinitializer} modifiers, directly or indirectly.
   */
  modifier onlyInitializing() {
    require(_initializing);
    _;
  }

  /**
   * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
   * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
   * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
   * through proxies.
   *
   * Emits an {Initialized} event the first time it is successfully executed.
   */
  function _disableInitializers() internal virtual {
    require(!_initializing);
    if (_initialized < type(uint8).max) {
      _initialized = type(uint8).max;
      emit Initialized(type(uint8).max);
    }
  }

  /**
   * @dev Internal function that returns the initialized version. Returns `_initialized`
   */
  function _getInitializedVersion() internal view returns (uint8) {
    return _initialized;
  }

  /**
   * @dev Internal function that returns the initialized version. Returns `_initializing`
   */
  function _isInitializing() internal view returns (bool) {
    return _initializing;
  }
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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
abstract contract ContextUpgradeable is Initializable {
  function __Context_init() internal onlyInitializing {}

  function __Context_init_unchained() internal onlyInitializing {}

  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
  enum Rounding {
    Down, // Toward negative infinity
    Up, // Toward infinity
    Zero // Toward zero
  }

  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev Returns the average of two numbers. The result is rounded towards
   * zero.
   */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow.
    return (a & b) + (a ^ b) / 2;
  }

  /**
   * @dev Returns the ceiling of the division of two numbers.
   *
   * This differs from standard division with `/` in that it rounds up instead
   * of rounding down.
   */
  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a == 0 ? 0 : (a - 1) / b + 1;
  }

  /**
   * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
   * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
   * with further edits by Uniswap Labs also under MIT license.
   */
  function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
    unchecked {
      // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
      // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
      // variables such that product = prod1 * 2^256 + prod0.
      uint256 prod0; // Least significant 256 bits of the product
      uint256 prod1; // Most significant 256 bits of the product
      assembly {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
      }

      // Handle non-overflow cases, 256 by 256 division.
      if (prod1 == 0) {
        return prod0 / denominator;
      }

      // Make sure the result is less than 2^256. Also prevents denominator == 0.
      require(denominator > prod1);

      ///////////////////////////////////////////////
      // 512 by 256 division.
      ///////////////////////////////////////////////

      // Make division exact by subtracting the remainder from [prod1 prod0].
      uint256 remainder;
      assembly {
        // Compute remainder using mulmod.
        remainder := mulmod(x, y, denominator)

        // Subtract 256 bit number from 512 bit number.
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
      }

      // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
      // See https://cs.stackexchange.com/q/138556/92363.

      // Does not overflow because the denominator cannot be zero at this stage in the function.
      uint256 twos = denominator & (~denominator + 1);
      assembly {
        // Divide denominator by twos.
        denominator := div(denominator, twos)

        // Divide [prod1 prod0] by twos.
        prod0 := div(prod0, twos)

        // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
        twos := add(div(sub(0, twos), twos), 1)
      }

      // Shift in bits from prod1 into prod0.
      prod0 |= prod1 * twos;

      // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
      // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
      // four bits. That is, denominator * inv = 1 mod 2^4.
      uint256 inverse = (3 * denominator) ^ 2;

      // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
      // in modular arithmetic, doubling the correct bits in each step.
      inverse *= 2 - denominator * inverse; // inverse mod 2^8
      inverse *= 2 - denominator * inverse; // inverse mod 2^16
      inverse *= 2 - denominator * inverse; // inverse mod 2^32
      inverse *= 2 - denominator * inverse; // inverse mod 2^64
      inverse *= 2 - denominator * inverse; // inverse mod 2^128
      inverse *= 2 - denominator * inverse; // inverse mod 2^256

      // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
      // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
      // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inverse;
      return result;
    }
  }

  /**
   * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
   */
  function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
    uint256 result = mulDiv(x, y, denominator);
    if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
      result += 1;
    }
    return result;
  }

  /**
   * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
   *
   * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
   */
  function sqrt(uint256 a) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
    //
    // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
    // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
    //
    // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
    // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
    // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
    //
    // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
    uint256 result = 1 << (log2(a) >> 1);

    // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
    // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
    // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
    // into the expected uint128 result.
    unchecked {
      result = (result + a / result) >> 1;
      result = (result + a / result) >> 1;
      result = (result + a / result) >> 1;
      result = (result + a / result) >> 1;
      result = (result + a / result) >> 1;
      result = (result + a / result) >> 1;
      result = (result + a / result) >> 1;
      return min(result, a / result);
    }
  }

  /**
   * @notice Calculates sqrt(a), following the selected rounding direction.
   */
  function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
    unchecked {
      uint256 result = sqrt(a);
      return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
    }
  }

  /**
   * @dev Return the log in base 2, rounded down, of a positive value.
   * Returns 0 if given 0.
   */
  function log2(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
    unchecked {
      if (value >> 128 > 0) {
        value >>= 128;
        result += 128;
      }
      if (value >> 64 > 0) {
        value >>= 64;
        result += 64;
      }
      if (value >> 32 > 0) {
        value >>= 32;
        result += 32;
      }
      if (value >> 16 > 0) {
        value >>= 16;
        result += 16;
      }
      if (value >> 8 > 0) {
        value >>= 8;
        result += 8;
      }
      if (value >> 4 > 0) {
        value >>= 4;
        result += 4;
      }
      if (value >> 2 > 0) {
        value >>= 2;
        result += 2;
      }
      if (value >> 1 > 0) {
        result += 1;
      }
    }
    return result;
  }

  /**
   * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
   * Returns 0 if given 0.
   */
  function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
    unchecked {
      uint256 result = log2(value);
      return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
    }
  }

  /**
   * @dev Return the log in base 10, rounded down, of a positive value.
   * Returns 0 if given 0.
   */
  function log10(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
    unchecked {
      if (value >= 10 ** 64) {
        value /= 10 ** 64;
        result += 64;
      }
      if (value >= 10 ** 32) {
        value /= 10 ** 32;
        result += 32;
      }
      if (value >= 10 ** 16) {
        value /= 10 ** 16;
        result += 16;
      }
      if (value >= 10 ** 8) {
        value /= 10 ** 8;
        result += 8;
      }
      if (value >= 10 ** 4) {
        value /= 10 ** 4;
        result += 4;
      }
      if (value >= 10 ** 2) {
        value /= 10 ** 2;
        result += 2;
      }
      if (value >= 10 ** 1) {
        result += 1;
      }
    }
    return result;
  }

  /**
   * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
   * Returns 0 if given 0.
   */
  function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
    unchecked {
      uint256 result = log10(value);
      return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
    }
  }

  /**
   * @dev Return the log in base 256, rounded down, of a positive value.
   * Returns 0 if given 0.
   *
   * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
   */
  function log256(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
    unchecked {
      if (value >> 128 > 0) {
        value >>= 128;
        result += 16;
      }
      if (value >> 64 > 0) {
        value >>= 64;
        result += 8;
      }
      if (value >> 32 > 0) {
        value >>= 32;
        result += 4;
      }
      if (value >> 16 > 0) {
        value >>= 16;
        result += 2;
      }
      if (value >> 8 > 0) {
        result += 1;
      }
    }
    return result;
  }

  /**
   * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
   * Returns 0 if given 0.
   */
  function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
    unchecked {
      uint256 result = log256(value);
      return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
    }
  }
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
  bytes16 private constant _SYMBOLS = "0123456789abcdef";
  uint8 private constant _ADDRESS_LENGTH = 20;

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    unchecked {
      uint256 length = MathUpgradeable.log10(value) + 1;
      string memory buffer = new string(length);
      uint256 ptr;
      /// @solidity memory-safe-assembly
      assembly {
        ptr := add(buffer, add(32, length))
      }
      while (true) {
        ptr--;
        /// @solidity memory-safe-assembly
        assembly {
          mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
        }
        value /= 10;
        if (value == 0) break;
      }
      return buffer;
    }
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
   */
  function toHexString(uint256 value) internal pure returns (string memory) {
    unchecked {
      return toHexString(value, MathUpgradeable.log256(value) + 1);
    }
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
   */
  function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = "0";
    buffer[1] = "x";
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = _SYMBOLS[value & 0xf];
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

// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

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
interface IERC165Upgradeable {
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

// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
  function __ERC165_init() internal onlyInitializing {}

  function __ERC165_init_unchained() internal onlyInitializing {}

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165Upgradeable).interfaceId;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/access/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
abstract contract AccessControlUpgradeable is
  Initializable,
  ContextUpgradeable,
  IAccessControlUpgradeable,
  ERC165Upgradeable
{
  function __AccessControl_init() internal onlyInitializing {}

  function __AccessControl_init_unchained() internal onlyInitializing {}

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
    return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
            StringsUpgradeable.toHexString(account),
            " is missing role ",
            StringsUpgradeable.toHexString(uint256(role), 32)
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
    require(account == _msgSender());

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

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}

// File @openzeppelin/contracts-upgradeable/security/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  bool private _paused;

  /**
   * @dev Initializes the contract in unpaused state.
   */
  function __Pausable_init() internal onlyInitializing {
    __Pausable_init_unchained();
  }

  function __Pausable_init_unchained() internal onlyInitializing {
    _paused = false;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenNotPaused() {
    _requireNotPaused();
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  modifier whenPaused() {
    _requirePaused();
    _;
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view virtual returns (bool) {
    return _paused;
  }

  /**
   * @dev Throws if the contract is paused.
   */
  function _requireNotPaused() internal view virtual {
    require(!paused());
  }

  /**
   * @dev Throws if the contract is not paused.
   */
  function _requirePaused() internal view virtual {
    require(paused());
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
  struct Counter {
    // This variable should never be directly accessed by users of the library: interactions must be restricted to
    // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
    // this feature: see https://github.com/ethereum/solidity/issues/4637
    uint256 _value; // default: 0
  }

  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }

  function increment(Counter storage counter) internal {
    unchecked {
      counter._value += 1;
    }
  }

  function decrement(Counter storage counter) internal {
    uint256 value = counter._value;
    require(value > 0, "Counter: decrement overflow");
    unchecked {
      counter._value = value - 1;
    }
  }

  function reset(Counter storage counter) internal {
    counter._value = 0;
  }
}

// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File @openzeppelin/contracts-upgradeable/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
  /**
   * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
   * given ``owner``'s signed approval.
   *
   * IMPORTANT: The same issues {IERC20-approve} has related to transaction
   * ordering also apply here.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `deadline` must be a timestamp in the future.
   * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
   * over the EIP712-formatted function arguments.
   * - the signature must use ``owner``'s current nonce (see {nonces}).
   *
   * For more information on the signature format, see the
   * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
   * section].
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Returns the current nonce for `owner`. This value must be
   * included whenever a signature is generated for {permit}.
   *
   * Every successful call to {permit} increases ``owner``'s nonce by one. This
   * prevents a signature from being used multiple times.
   */
  function nonces(address owner) external view returns (uint256);

  /**
   * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
   */
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File @openzeppelin/contracts-upgradeable/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
  using AddressUpgradeable for address;

  function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
    unchecked {
      uint256 oldAllowance = token.allowance(address(this), spender);
      require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
      uint256 newAllowance = oldAllowance - value;
      _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
  }

  function safePermit(
    IERC20PermitUpgradeable token,
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
    uint256 nonceBefore = token.nonces(owner);
    token.permit(owner, spender, value, deadline, v, r, s);
    uint256 nonceAfter = token.nonces(owner);
    require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

// File contracts/interfaces/MHIERC20.sol

pragma solidity ^0.8.0;

interface MHIERC20 {
  function approve(address to, uint256 tokenId) external;

  function transferFrom(address from, address to, uint256 value) external;

  function transfer(address recipient, uint256 amount) external returns (bool);

  function balanceOf(address owner) external view returns (uint256 balance);

  function allowance(address owner, address spender) external view returns (uint256);

  function burn(uint256 amount) external;

  function burn(address from, uint256 amount) external;

  function burnFrom(address account, uint256 amount) external;

  function decimals() external view returns (uint8);

  function mint(address to, uint256 amount) external;

  function totalSupply() external view returns (uint256);
}

// File contracts/interfaces/MHIERC721.sol

pragma solidity ^0.8.9;

interface MHIERC721 {
  function transferFrom(address from, address to, uint256 tokenId) external;

  function safeTransferFrom(address from, address to, uint256 tokenId) external;

  function burn(uint256 tokenId) external;

  function burnFrom(address account, uint256 tokenId) external;

  function mintNftByRarity(address to, address rarity) external;

  function totalSupply() external view returns (uint256);

  function ownerOf(uint256 tokenId) external view returns (address);

  function getApproved(uint256 tokenId) external view returns (address);

  function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File contracts/interfaces/ICommunityPool.sol

pragma solidity ^0.8.9;

interface ICommunityPool {
  function getReserves() external view returns (uint256 _gameTokenReserve, uint256 _stableTokenReserve);

  function getPrice() external view returns (uint256 _price);

  function quoteStableToGameTokens(uint256 stableTokens) external view returns (uint256 gameTokens);

  function quoteGameToStableTokens(uint256 gameTokens) external view returns (uint256 stableTokens);

  function getStableTokensIn(uint256 bctOut) external view returns (uint256 stableTokensIn);

  function quoteBuyGameTokens(uint256 gameTokensToBuy) external view returns (uint256 costInStableTokens);

  function quoteSellGameTokens(
    uint256 gameTokensToSell
  ) external view returns (uint256 stableTokensOut, uint256 feeInWei);

  function quoteSellGameTokensFor(
    uint256 gameTokensToSell,
    address account
  ) external view returns (uint256 stableTokensOut, uint256 feeInWei);

  function buyGameTokens(uint256 gameTokens) external returns (uint256 stableTokensPaid);

  function buyGameTokensAtPrice(
    uint256 gameTokens,
    uint256 atPrice,
    uint256 maxSlippage
  ) external returns (uint256 stableTokensPaid);

  function sellGameTokens(uint256 gameTokens) external returns (uint256 stableTokensOut);

  function sellGameTokensAtPrice(
    uint256 gameTokens,
    uint256 atPrice,
    uint256 maxSlippage
  ) external returns (uint256 stableTokensOut);

  function buyAndBurn(uint256 amountIn) external returns (uint256 amountBurned);
}

// File contracts/interfaces/INftInCollection.sol

pragma solidity ^0.8.9;

interface INftInCollection {
  function collectionOf(uint256 tokenId) external view returns (uint256);
}

// File contracts/interfaces/IMhdaoFarmMerchant.sol

pragma solidity ^0.8.9;

interface IMhdaoFarmMerchant {
  function merchantLevelOf(address playerAddress) external view returns (uint256);

  function payWithBalance(
    address account,
    uint256 bctAmount,
    uint256[] memory _resources
  ) external returns (uint256[] memory);
}

// File hardhat/[email protected]

pragma solidity >=0.4.22 <0.9.0;

library console {
  address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

  function _sendLogPayload(bytes memory payload) private view {
    uint256 payloadLength = payload.length;
    address consoleAddress = CONSOLE_ADDRESS;
    assembly {
      let payloadStart := add(payload, 32)
      let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
    }
  }

  function log() internal view {
    _sendLogPayload(abi.encodeWithSignature("log()"));
  }

  function logInt(int p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
  }

  function logUint(uint p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
  }

  function logString(string memory p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
  }

  function logBool(bool p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
  }

  function logAddress(address p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
  }

  function logBytes(bytes memory p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
  }

  function logBytes1(bytes1 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
  }

  function logBytes2(bytes2 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
  }

  function logBytes3(bytes3 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
  }

  function logBytes4(bytes4 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
  }

  function logBytes5(bytes5 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
  }

  function logBytes6(bytes6 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
  }

  function logBytes7(bytes7 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
  }

  function logBytes8(bytes8 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
  }

  function logBytes9(bytes9 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
  }

  function logBytes10(bytes10 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
  }

  function logBytes11(bytes11 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
  }

  function logBytes12(bytes12 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
  }

  function logBytes13(bytes13 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
  }

  function logBytes14(bytes14 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
  }

  function logBytes15(bytes15 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
  }

  function logBytes16(bytes16 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
  }

  function logBytes17(bytes17 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
  }

  function logBytes18(bytes18 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
  }

  function logBytes19(bytes19 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
  }

  function logBytes20(bytes20 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
  }

  function logBytes21(bytes21 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
  }

  function logBytes22(bytes22 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
  }

  function logBytes23(bytes23 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
  }

  function logBytes24(bytes24 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
  }

  function logBytes25(bytes25 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
  }

  function logBytes26(bytes26 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
  }

  function logBytes27(bytes27 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
  }

  function logBytes28(bytes28 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
  }

  function logBytes29(bytes29 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
  }

  function logBytes30(bytes30 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
  }

  function logBytes31(bytes31 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
  }

  function logBytes32(bytes32 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
  }

  function log(uint p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
  }

  function log(string memory p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
  }

  function log(bool p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
  }

  function log(address p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
  }

  function log(uint p0, uint p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
  }

  function log(uint p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
  }

  function log(uint p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
  }

  function log(uint p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
  }

  function log(string memory p0, uint p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
  }

  function log(string memory p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
  }

  function log(string memory p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
  }

  function log(string memory p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
  }

  function log(bool p0, uint p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
  }

  function log(bool p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
  }

  function log(bool p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
  }

  function log(bool p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
  }

  function log(address p0, uint p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
  }

  function log(address p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
  }

  function log(address p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
  }

  function log(address p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
  }

  function log(uint p0, uint p1, uint p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
  }

  function log(uint p0, uint p1, string memory p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
  }

  function log(uint p0, uint p1, bool p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
  }

  function log(uint p0, uint p1, address p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
  }

  function log(uint p0, string memory p1, uint p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
  }

  function log(uint p0, string memory p1, string memory p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
  }

  function log(uint p0, string memory p1, bool p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
  }

  function log(uint p0, string memory p1, address p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
  }

  function log(uint p0, bool p1, uint p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
  }

  function log(uint p0, bool p1, string memory p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
  }

  function log(uint p0, bool p1, bool p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
  }

  function log(uint p0, bool p1, address p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
  }

  function log(uint p0, address p1, uint p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
  }

  function log(uint p0, address p1, string memory p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
  }

  function log(uint p0, address p1, bool p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
  }

  function log(uint p0, address p1, address p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
  }

  function log(string memory p0, uint p1, uint p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
  }

  function log(string memory p0, uint p1, string memory p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
  }

  function log(string memory p0, uint p1, bool p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
  }

  function log(string memory p0, uint p1, address p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
  }

  function log(string memory p0, string memory p1, uint p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
  }

  function log(string memory p0, string memory p1, string memory p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
  }

  function log(string memory p0, string memory p1, bool p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
  }

  function log(string memory p0, string memory p1, address p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
  }

  function log(string memory p0, bool p1, uint p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
  }

  function log(string memory p0, bool p1, string memory p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
  }

  function log(string memory p0, bool p1, bool p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
  }

  function log(string memory p0, bool p1, address p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
  }

  function log(string memory p0, address p1, uint p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
  }

  function log(string memory p0, address p1, string memory p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
  }

  function log(string memory p0, address p1, bool p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
  }

  function log(string memory p0, address p1, address p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
  }

  function log(bool p0, uint p1, uint p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
  }

  function log(bool p0, uint p1, string memory p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
  }

  function log(bool p0, uint p1, bool p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
  }

  function log(bool p0, uint p1, address p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
  }

  function log(bool p0, string memory p1, uint p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
  }

  function log(bool p0, string memory p1, string memory p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
  }

  function log(bool p0, string memory p1, bool p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
  }

  function log(bool p0, string memory p1, address p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
  }

  function log(bool p0, bool p1, uint p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
  }

  function log(bool p0, bool p1, string memory p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
  }

  function log(bool p0, bool p1, bool p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
  }

  function log(bool p0, bool p1, address p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
  }

  function log(bool p0, address p1, uint p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
  }

  function log(bool p0, address p1, string memory p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
  }

  function log(bool p0, address p1, bool p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
  }

  function log(bool p0, address p1, address p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
  }

  function log(address p0, uint p1, uint p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
  }

  function log(address p0, uint p1, string memory p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
  }

  function log(address p0, uint p1, bool p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
  }

  function log(address p0, uint p1, address p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
  }

  function log(address p0, string memory p1, uint p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
  }

  function log(address p0, string memory p1, string memory p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
  }

  function log(address p0, string memory p1, bool p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
  }

  function log(address p0, string memory p1, address p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
  }

  function log(address p0, bool p1, uint p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
  }

  function log(address p0, bool p1, string memory p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
  }

  function log(address p0, bool p1, bool p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
  }

  function log(address p0, bool p1, address p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
  }

  function log(address p0, address p1, uint p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
  }

  function log(address p0, address p1, string memory p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
  }

  function log(address p0, address p1, bool p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
  }

  function log(address p0, address p1, address p2) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
  }

  function log(uint p0, uint p1, uint p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
  }

  function log(uint p0, uint p1, uint p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
  }

  function log(uint p0, uint p1, uint p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
  }

  function log(uint p0, uint p1, uint p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
  }

  function log(uint p0, uint p1, string memory p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
  }

  function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
  }

  function log(uint p0, uint p1, string memory p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
  }

  function log(uint p0, uint p1, string memory p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
  }

  function log(uint p0, uint p1, bool p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
  }

  function log(uint p0, uint p1, bool p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
  }

  function log(uint p0, uint p1, bool p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
  }

  function log(uint p0, uint p1, bool p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
  }

  function log(uint p0, uint p1, address p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
  }

  function log(uint p0, uint p1, address p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
  }

  function log(uint p0, uint p1, address p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
  }

  function log(uint p0, uint p1, address p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
  }

  function log(uint p0, string memory p1, uint p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
  }

  function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
  }

  function log(uint p0, string memory p1, uint p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
  }

  function log(uint p0, string memory p1, uint p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
  }

  function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
  }

  function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
  }

  function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
  }

  function log(uint p0, string memory p1, string memory p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
  }

  function log(uint p0, string memory p1, bool p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
  }

  function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
  }

  function log(uint p0, string memory p1, bool p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(uint p0, string memory p1, bool p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
  }

  function log(uint p0, string memory p1, address p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
  }

  function log(uint p0, string memory p1, address p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
  }

  function log(uint p0, string memory p1, address p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
  }

  function log(uint p0, string memory p1, address p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
  }

  function log(uint p0, bool p1, uint p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
  }

  function log(uint p0, bool p1, uint p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
  }

  function log(uint p0, bool p1, uint p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
  }

  function log(uint p0, bool p1, uint p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
  }

  function log(uint p0, bool p1, string memory p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
  }

  function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
  }

  function log(uint p0, bool p1, string memory p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(uint p0, bool p1, string memory p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
  }

  function log(uint p0, bool p1, bool p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
  }

  function log(uint p0, bool p1, bool p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(uint p0, bool p1, bool p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(uint p0, bool p1, bool p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(uint p0, bool p1, address p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
  }

  function log(uint p0, bool p1, address p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
  }

  function log(uint p0, bool p1, address p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(uint p0, bool p1, address p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
  }

  function log(uint p0, address p1, uint p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
  }

  function log(uint p0, address p1, uint p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
  }

  function log(uint p0, address p1, uint p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
  }

  function log(uint p0, address p1, uint p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
  }

  function log(uint p0, address p1, string memory p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
  }

  function log(uint p0, address p1, string memory p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
  }

  function log(uint p0, address p1, string memory p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
  }

  function log(uint p0, address p1, string memory p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
  }

  function log(uint p0, address p1, bool p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
  }

  function log(uint p0, address p1, bool p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
  }

  function log(uint p0, address p1, bool p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(uint p0, address p1, bool p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
  }

  function log(uint p0, address p1, address p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
  }

  function log(uint p0, address p1, address p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
  }

  function log(uint p0, address p1, address p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
  }

  function log(uint p0, address p1, address p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
  }

  function log(string memory p0, uint p1, uint p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
  }

  function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
  }

  function log(string memory p0, uint p1, uint p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
  }

  function log(string memory p0, uint p1, uint p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
  }

  function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
  }

  function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
  }

  function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
  }

  function log(string memory p0, uint p1, string memory p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
  }

  function log(string memory p0, uint p1, bool p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
  }

  function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
  }

  function log(string memory p0, uint p1, bool p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
  }

  function log(string memory p0, uint p1, bool p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
  }

  function log(string memory p0, uint p1, address p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
  }

  function log(string memory p0, uint p1, address p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
  }

  function log(string memory p0, uint p1, address p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
  }

  function log(string memory p0, uint p1, address p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
  }

  function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
  }

  function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
  }

  function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
  }

  function log(string memory p0, string memory p1, uint p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
  }

  function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
  }

  function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
  }

  function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
  }

  function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
  }

  function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
  }

  function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
  }

  function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(string memory p0, string memory p1, bool p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
  }

  function log(string memory p0, string memory p1, address p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
  }

  function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
  }

  function log(string memory p0, string memory p1, address p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
  }

  function log(string memory p0, string memory p1, address p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
  }

  function log(string memory p0, bool p1, uint p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
  }

  function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
  }

  function log(string memory p0, bool p1, uint p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
  }

  function log(string memory p0, bool p1, uint p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
  }

  function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
  }

  function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
  }

  function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(string memory p0, bool p1, string memory p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
  }

  function log(string memory p0, bool p1, bool p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
  }

  function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(string memory p0, bool p1, bool p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(string memory p0, bool p1, bool p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(string memory p0, bool p1, address p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
  }

  function log(string memory p0, bool p1, address p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
  }

  function log(string memory p0, bool p1, address p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(string memory p0, bool p1, address p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
  }

  function log(string memory p0, address p1, uint p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
  }

  function log(string memory p0, address p1, uint p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
  }

  function log(string memory p0, address p1, uint p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
  }

  function log(string memory p0, address p1, uint p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
  }

  function log(string memory p0, address p1, string memory p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
  }

  function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
  }

  function log(string memory p0, address p1, string memory p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
  }

  function log(string memory p0, address p1, string memory p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
  }

  function log(string memory p0, address p1, bool p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
  }

  function log(string memory p0, address p1, bool p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
  }

  function log(string memory p0, address p1, bool p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(string memory p0, address p1, bool p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
  }

  function log(string memory p0, address p1, address p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
  }

  function log(string memory p0, address p1, address p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
  }

  function log(string memory p0, address p1, address p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
  }

  function log(string memory p0, address p1, address p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
  }

  function log(bool p0, uint p1, uint p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
  }

  function log(bool p0, uint p1, uint p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
  }

  function log(bool p0, uint p1, uint p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
  }

  function log(bool p0, uint p1, uint p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
  }

  function log(bool p0, uint p1, string memory p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
  }

  function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
  }

  function log(bool p0, uint p1, string memory p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
  }

  function log(bool p0, uint p1, string memory p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
  }

  function log(bool p0, uint p1, bool p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
  }

  function log(bool p0, uint p1, bool p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
  }

  function log(bool p0, uint p1, bool p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
  }

  function log(bool p0, uint p1, bool p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
  }

  function log(bool p0, uint p1, address p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
  }

  function log(bool p0, uint p1, address p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
  }

  function log(bool p0, uint p1, address p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
  }

  function log(bool p0, uint p1, address p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
  }

  function log(bool p0, string memory p1, uint p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
  }

  function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
  }

  function log(bool p0, string memory p1, uint p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
  }

  function log(bool p0, string memory p1, uint p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
  }

  function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
  }

  function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
  }

  function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
  }

  function log(bool p0, string memory p1, string memory p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
  }

  function log(bool p0, string memory p1, bool p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
  }

  function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
  }

  function log(bool p0, string memory p1, bool p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(bool p0, string memory p1, bool p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
  }

  function log(bool p0, string memory p1, address p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
  }

  function log(bool p0, string memory p1, address p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
  }

  function log(bool p0, string memory p1, address p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
  }

  function log(bool p0, string memory p1, address p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
  }

  function log(bool p0, bool p1, uint p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
  }

  function log(bool p0, bool p1, uint p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
  }

  function log(bool p0, bool p1, uint p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
  }

  function log(bool p0, bool p1, uint p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
  }

  function log(bool p0, bool p1, string memory p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
  }

  function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
  }

  function log(bool p0, bool p1, string memory p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(bool p0, bool p1, string memory p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
  }

  function log(bool p0, bool p1, bool p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
  }

  function log(bool p0, bool p1, bool p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(bool p0, bool p1, bool p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(bool p0, bool p1, bool p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(bool p0, bool p1, address p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
  }

  function log(bool p0, bool p1, address p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
  }

  function log(bool p0, bool p1, address p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(bool p0, bool p1, address p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
  }

  function log(bool p0, address p1, uint p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
  }

  function log(bool p0, address p1, uint p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
  }

  function log(bool p0, address p1, uint p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
  }

  function log(bool p0, address p1, uint p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
  }

  function log(bool p0, address p1, string memory p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
  }

  function log(bool p0, address p1, string memory p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
  }

  function log(bool p0, address p1, string memory p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
  }

  function log(bool p0, address p1, string memory p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
  }

  function log(bool p0, address p1, bool p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
  }

  function log(bool p0, address p1, bool p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
  }

  function log(bool p0, address p1, bool p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(bool p0, address p1, bool p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
  }

  function log(bool p0, address p1, address p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
  }

  function log(bool p0, address p1, address p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
  }

  function log(bool p0, address p1, address p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
  }

  function log(bool p0, address p1, address p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
  }

  function log(address p0, uint p1, uint p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
  }

  function log(address p0, uint p1, uint p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
  }

  function log(address p0, uint p1, uint p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
  }

  function log(address p0, uint p1, uint p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
  }

  function log(address p0, uint p1, string memory p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
  }

  function log(address p0, uint p1, string memory p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
  }

  function log(address p0, uint p1, string memory p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
  }

  function log(address p0, uint p1, string memory p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
  }

  function log(address p0, uint p1, bool p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
  }

  function log(address p0, uint p1, bool p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
  }

  function log(address p0, uint p1, bool p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
  }

  function log(address p0, uint p1, bool p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
  }

  function log(address p0, uint p1, address p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
  }

  function log(address p0, uint p1, address p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
  }

  function log(address p0, uint p1, address p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
  }

  function log(address p0, uint p1, address p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
  }

  function log(address p0, string memory p1, uint p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
  }

  function log(address p0, string memory p1, uint p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
  }

  function log(address p0, string memory p1, uint p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
  }

  function log(address p0, string memory p1, uint p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
  }

  function log(address p0, string memory p1, string memory p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
  }

  function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
  }

  function log(address p0, string memory p1, string memory p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
  }

  function log(address p0, string memory p1, string memory p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
  }

  function log(address p0, string memory p1, bool p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
  }

  function log(address p0, string memory p1, bool p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
  }

  function log(address p0, string memory p1, bool p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(address p0, string memory p1, bool p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
  }

  function log(address p0, string memory p1, address p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
  }

  function log(address p0, string memory p1, address p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
  }

  function log(address p0, string memory p1, address p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
  }

  function log(address p0, string memory p1, address p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
  }

  function log(address p0, bool p1, uint p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
  }

  function log(address p0, bool p1, uint p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
  }

  function log(address p0, bool p1, uint p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
  }

  function log(address p0, bool p1, uint p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
  }

  function log(address p0, bool p1, string memory p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
  }

  function log(address p0, bool p1, string memory p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
  }

  function log(address p0, bool p1, string memory p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(address p0, bool p1, string memory p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
  }

  function log(address p0, bool p1, bool p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
  }

  function log(address p0, bool p1, bool p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(address p0, bool p1, bool p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(address p0, bool p1, bool p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(address p0, bool p1, address p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
  }

  function log(address p0, bool p1, address p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
  }

  function log(address p0, bool p1, address p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(address p0, bool p1, address p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
  }

  function log(address p0, address p1, uint p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
  }

  function log(address p0, address p1, uint p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
  }

  function log(address p0, address p1, uint p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
  }

  function log(address p0, address p1, uint p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
  }

  function log(address p0, address p1, string memory p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
  }

  function log(address p0, address p1, string memory p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
  }

  function log(address p0, address p1, string memory p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
  }

  function log(address p0, address p1, string memory p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
  }

  function log(address p0, address p1, bool p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
  }

  function log(address p0, address p1, bool p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
  }

  function log(address p0, address p1, bool p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(address p0, address p1, bool p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
  }

  function log(address p0, address p1, address p2, uint p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
  }

  function log(address p0, address p1, address p2, string memory p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
  }

  function log(address p0, address p1, address p2, bool p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
  }

  function log(address p0, address p1, address p2, address p3) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
  }
}

// File contracts/features/MhdaoMarketplace.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Marketplace
 * @dev  A marketplace for Mouse Haunt Token holders to buy and sell.
 */
contract MhdaoMarketplace is Initializable, AccessControlUpgradeable, PausableUpgradeable {
  using SafeERC20Upgradeable for MHIERC20;
  using AddressUpgradeable for address;
  using CountersUpgradeable for CountersUpgradeable.Counter;

  bytes32 internal constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
  bytes32 internal constant MERCHANT_ROLE = keccak256("MERCHANT_ROLE");

  CountersUpgradeable.Counter internal _orderIdCounter;
  mapping(uint256 => uint256) internal _orderIdToOrderIndex;

  // TODO add AntiMev module

  uint256 burnFeePct;

  struct Merchant {
    uint256 auctions;
    uint256 privateSales;
    uint256 sales;
  }

  struct PaymentRequest {
    address buyer;
    address seller;
    address thirdParty;
    uint256 price;
    uint256 amountForSeller;
    uint256 amountForThirdParty;
    uint256 burnFee;
    uint256 merchantFee;
    bool payWithBusd;
    bool isBusdOnly;
  }

  mapping(address => Merchant) public merchants;
  mapping(address => AssetType) public acceptedAssets;

  Order[] public orders;

  MHIERC20 public bct;
  MHIERC20 public busd;
  ICommunityPool public pool;
  IMhdaoFarmMerchant public farm;

  enum AssetType {
    NIL,
    ERC20,
    ERC721
  }

  struct Asset {
    address addr; //ERC721 or ERC20 token address
    AssetType assetType; //ERC721 or ERC20
  }

  struct Order {
    uint256 id; // Order ID (starts at 1)
    address seller; // Owner of the asset
    address assetAddress; // address of what's being sold
    uint256 assetId; // asset ID for ERC721
    uint256 amount; // Token amount for ERC20
    uint256 price; // Price (in wei) for the published item
    address privateFor; // if it's a private sale, who is it for (0x0 if it's a public)
    uint256 createdAt; // Block when the order was created; In Dutch Acutions, the price will reach `price` in 7200 blocks
    uint256 sellerShare; // Seller share in percentage
    address thirdParty; // Third party address that gets the bulk of the money when the order is completed
    bool isDutchAuction; // Dutch auction flag
    bool isBusdOnly; // BUSD only flag
  }

  event OrderCreated(
    uint256 id,
    uint256 assetId,
    address assetAddress,
    address seller,
    address privateFor,
    uint256 amount,
    uint256 priceInWei,
    uint256 createdAt,
    bool isDutchAuction,
    bool isBusdOnly
  );
  event OrderExecuted(uint256 id, uint256 price, address seller, address buyer, address product);
  event OrderCancelled(uint256 id);

  uint256 public swapFeePercentage;

  uint256 public gracePeriod;
  mapping(uint256 => uint256) public orderIdToAllowedBlock;

  function initialize(address operator, address _bct, address _busd, address _pool, address _farm) public initializer {
    __AccessControl_init();
    __Pausable_init();

    bct = MHIERC20(_bct);
    busd = MHIERC20(_busd);
    pool = ICommunityPool(_pool);
    farm = IMhdaoFarmMerchant(_farm);
    swapFeePercentage = 2050 * 1E15;

    Order memory dummyOrder = Order({
      id: 0,
      seller: address(0),
      assetAddress: address(0),
      assetId: 0,
      amount: 0,
      price: 0,
      privateFor: address(0),
      createdAt: 0,
      sellerShare: 0,
      thirdParty: address(0),
      isDutchAuction: false,
      isBusdOnly: false
    });

    _addOrder(dummyOrder); // Add a dummy order to the first index of the orders array

    _orderIdCounter.increment(); // order IDs start at 1 so that the null value is considered an invalid order ID

    _setupRole(DEFAULT_ADMIN_ROLE, operator);
    _setupRole(OPERATOR_ROLE, operator);
    _setupRole(MERCHANT_ROLE, operator);

    burnFeePct = 5;

    busd.approve(_pool, type(uint256).max);
  }

  //###############
  // Getters
  function getOrder(uint256 orderId) public view returns (Order memory) {
    uint256 orderIndex = _orderIdToOrderIndex[orderId];
    require(orderIndex < orders.length && orderIndex != 0, "Invalid order index");

    Order memory order = orders[orderIndex];
    require(order.id == orderId, "Invalid order ID");
    return order;
  }

  function getOrders() public view returns (Order[] memory) {
    return orders;
  }

  function getMerchant(address merchant) public view returns (Merchant memory) {
    return merchants[merchant];
  }

  function previewSwapValue(uint256 _bctAmountOut) external view returns (uint256) {
    return pool.getStableTokensIn(_bctAmountOut);
  }

  function getAuctionCurrentPrice(uint256 orderId) public view returns (uint256) {
    Order memory order = getOrder(orderId);
    uint256 startPrice = order.price * 10;
    uint256 endPrice = order.price;
    uint256 startBlock = order.createdAt;
    uint256 endBlock = order.createdAt + 7200; // 6 hours
    uint256 currentBlock = block.number;

    if (currentBlock >= endBlock) {
      return endPrice;
    } else {
      uint256 blocksPassed = currentBlock - startBlock;
      uint256 maxPriceReduction = startPrice - endPrice;
      uint256 pricePerBlock = maxPriceReduction / 7200; // decreases 0,0125% of the original price every block
      return startPrice - (pricePerBlock * blocksPassed);
    }
  }

  //###############
  // Setters
  function createOrder(
    address assetAddress,
    uint256 assetId,
    uint256 amount,
    uint256 priceInWei,
    address privateFor,
    bool isBusdOnly,
    bool isIngameResource
  ) external whenNotPaused {
    AssetType assetType = _checkOrderCreation(assetAddress, assetId, amount, priceInWei, isIngameResource);

    uint256 orderId = _orderIdCounter.current();
    _orderIdCounter.increment();

    bool isMerchant = hasRole(MERCHANT_ROLE, msg.sender);

    if (privateFor != address(0)) {
      require(isMerchant, "Only merchants can create private orders");
    }

    if (isBusdOnly) {
      require(isMerchant, "Only merchants can create busd only orders");
      require(privateFor != address(0), "Busd-only orders must be private");
    }

    if (isIngameResource) {
      // burn the resource from the farm
      uint256[] memory res = new uint256[](assetId + 1);
      res[assetId] = amount;
      uint256[] memory remaining = farm.payWithBalance(msg.sender, 0, res);
      require(remaining[assetId] == 0, "Not enough resources");

      // mint the resource for the marketplace
      MHIERC20(assetAddress).mint(address(this), amount);
    } else {
      // transfer the assets to marketplace
      _fetchAssets(assetAddress, assetType, amount, assetId);
    }

    _addOrder(
      Order({
        id: orderId,
        seller: msg.sender,
        assetAddress: assetAddress,
        assetId: assetId,
        amount: amount,
        price: priceInWei,
        privateFor: privateFor,
        createdAt: block.number,
        sellerShare: 100,
        thirdParty: address(0),
        isDutchAuction: false,
        isBusdOnly: isBusdOnly
      })
    );

    emit OrderCreated(
      orderId,
      assetId,
      assetAddress,
      msg.sender,
      privateFor,
      amount,
      priceInWei,
      block.number,
      false,
      isBusdOnly
    );
  }

  function createDutchAuction(
    address assetAddress,
    uint256 assetId,
    uint256 amount,
    uint256 priceInWei,
    bool isBusdOnly,
    uint256 sellerShare,
    address thirdParty
  ) external whenNotPaused {
    require(hasRole(MERCHANT_ROLE, msg.sender), "Only merchants can create dutch auctions");
    AssetType assetType = _checkOrderCreation(assetAddress, assetId, amount, priceInWei, false);
    require(assetType == AssetType.ERC721, "Dutch auctions can only be created for ERC721 assets");

    // Make sure the NFT belongs to a collection
    uint256 collectionId = INftInCollection(assetAddress).collectionOf(assetId);
    require(collectionId != 0, "NFT must belong to a collection");

    uint256 orderId = _orderIdCounter.current();
    _orderIdCounter.increment();

    _addOrder(
      Order({
        id: orderId,
        seller: msg.sender,
        assetAddress: assetAddress,
        assetId: assetId,
        amount: amount,
        price: priceInWei,
        privateFor: address(0), // Dutch Auctions cannot be private
        createdAt: block.number,
        sellerShare: sellerShare,
        thirdParty: thirdParty,
        isDutchAuction: true,
        isBusdOnly: isBusdOnly
      })
    );

    // transfer the assets to marketplace
    _fetchAssets(assetAddress, assetType, amount, assetId);

    emit OrderCreated(
      orderId,
      assetId,
      assetAddress,
      msg.sender,
      address(0),
      amount,
      priceInWei,
      block.number,
      true,
      isBusdOnly
    );
  }

  function executeOrder(uint256 orderId) external whenNotPaused {
    _executeOrder(orderId, false);
  }

  function executeOrderWithBusd(uint256 orderId) external whenNotPaused {
    _executeOrder(orderId, true);
  }

  function cancelOrder(uint256 orderId) external whenNotPaused {
    Order memory order = getOrder(orderId);

    require(
      order.seller == msg.sender || hasRole(OPERATOR_ROLE, msg.sender) || order.thirdParty == msg.sender,
      "Unauthorized user"
    );

    if (order.isDutchAuction) {
      require(
        block.number >= order.createdAt + 7200,
        "Dutch auctions cannot be cancelled before minimum price is reached"
      );
    }

    uint256 orderAssetId = order.assetId;
    address orderSeller = order.seller;
    address orderassetAddress = order.assetAddress;
    uint256 orderAmount = order.amount;

    _deleteOrder(orderId);

    emit OrderCancelled(orderId);

    AssetType assetType = acceptedAssets[orderassetAddress];

    if (assetType == AssetType.ERC20) {
      MHIERC20(orderassetAddress).transfer(orderSeller, orderAmount);
    } else if (assetType == AssetType.ERC721) {
      MHIERC721(orderassetAddress).safeTransferFrom(address(this), orderSeller, orderAssetId);
    }
  }

  //###############
  // Internals
  function _addOrder(Order memory order) internal {
    orders.push(order);
    _orderIdToOrderIndex[order.id] = orders.length - 1;
    orderIdToAllowedBlock[order.id] = block.number + gracePeriod;
  }

  function _checkOrderCreation(
    address assetAddress,
    uint256 assetId,
    uint256 amount,
    uint256 priceInWei,
    bool isIngameResource
  ) private view returns (AssetType) {
    require(priceInWei > 0, "Price should be greater than 0");
    AssetType assetType = acceptedAssets[assetAddress];
    require(assetType != AssetType.NIL, "Invalid asset address");

    if (assetType == AssetType.ERC20) {
      MHIERC20 asset = MHIERC20(assetAddress);
      uint8 decimals = asset.decimals();
      require(amount / (10 ** decimals) <= 100, ">100");
      require(amount % (10 ** decimals) == 0, "INV_AMOUNT");

      if (!isIngameResource) {
        require(assetId == 0, "Invalid asset ID");
        uint256 balance = asset.balanceOf(msg.sender);
        require(balance >= amount, "Insufficient balance");
        require(asset.allowance(msg.sender, address(this)) >= amount, "Marketplace unauthorized");
      }
    } else {
      // is AssetType.ERC721
      require(amount == 1, "Invalid amount");
      MHIERC721 asset = MHIERC721(assetAddress);
      address assetOwner = asset.ownerOf(assetId);

      require(assetOwner != address(this), "Asset already on the marketplace");
      require(msg.sender == assetOwner, "Only the owner can create orders");
      require(
        asset.getApproved(assetId) == address(this) || asset.isApprovedForAll(assetOwner, address(this)),
        "Marketplace unauthorized"
      );
    }

    return assetType;
  }

  function _fetchAssets(address assetAddress, AssetType assetType, uint256 amount, uint256 assetId) private {
    if (assetType == AssetType.ERC20) {
      MHIERC20(assetAddress).transferFrom(msg.sender, address(this), amount);
    } else {
      MHIERC721(assetAddress).transferFrom(msg.sender, address(this), assetId);
    }
  }

  function _executeOrder(uint256 orderId, bool payWithBusd) internal {
    Order memory order = getOrder(orderId);

    require(order.seller != msg.sender, "Cannot sell to yourself");
    require(order.thirdParty != msg.sender, "Cannot sell to yourself");
    require(orderIdToAllowedBlock[orderId] < block.number, "Transaction failed, please try again");
    require(order.privateFor == msg.sender || order.privateFor == address(0), "This order is private");

    uint256 price = order.isDutchAuction ? getAuctionCurrentPrice(orderId) : order.price;
    AssetType assetType = acceptedAssets[order.assetAddress];

    if (order.isBusdOnly) {
      require(payWithBusd, "This order can only be paid for in BUSD");
    }

    _deleteOrder(orderId);

    // Receive payment and deliver goods
    (
      uint256 finalAmountForSeller,
      uint256 finalAmountForThirdParty,
      uint256 burnFee,
      uint256 merchantFee
    ) = _calculateFeeAndPrincipal(order.seller, price, order.sellerShare);
    _receivePayment(
      PaymentRequest(
        msg.sender,
        order.seller,
        order.thirdParty,
        price,
        finalAmountForSeller,
        finalAmountForThirdParty,
        burnFee,
        merchantFee,
        payWithBusd,
        order.isBusdOnly
      )
    );
    _deliverGoods(assetType, msg.sender, order.assetAddress, order.amount, order.assetId);

    if (order.privateFor != address(0)) {
      merchants[order.seller].privateSales++;
    } else if (order.isDutchAuction) {
      merchants[order.seller].auctions++;
    }

    merchants[order.seller].sales++;

    emit OrderExecuted(orderId, price, order.seller, msg.sender, order.assetAddress);
  }

  function _calculateFeeAndPrincipal(
    address seller,
    uint256 price,
    uint256 sellerShare
  ) internal view returns (uint256, uint256, uint256, uint256) {
    uint256 merchantFeePercentageTwice = farm.merchantLevelOf(seller); // goes from 0 to 10
    uint256 merchantFee = (price * merchantFeePercentageTwice) / 200; // goes from 0 to 5%
    uint256 originalBurnFee = (price * burnFeePct) / 100;
    uint256 burnFee = originalBurnFee - merchantFee;
    uint256 finalAmountLessFees = price - burnFee; // the merchant fee goes to the seller if he's a merchant!
    uint256 finalAmountForSeller = sellerShare < 100 ? (finalAmountLessFees * sellerShare) / 100 : finalAmountLessFees;
    uint256 finalAmountForThirdParty = sellerShare < 100 ? finalAmountLessFees - finalAmountForSeller : 0;

    return (finalAmountForSeller, finalAmountForThirdParty, burnFee, merchantFee);
  }

  function _receivePayment(PaymentRequest memory paymentRequest) internal {
    if (paymentRequest.payWithBusd) {
      if (paymentRequest.isBusdOnly) {
        // It's a private sale in BUSD
        busd.transferFrom(paymentRequest.buyer, paymentRequest.seller, paymentRequest.amountForSeller); // has to be nominal in BUSD! (website is not ready for this)

        // we take the community fee
        if (paymentRequest.burnFee > 0) {
          busd.transferFrom(paymentRequest.buyer, address(this), paymentRequest.burnFee);
        }

        // if there's a third party, we transfer the amount to them
        if (paymentRequest.amountForThirdParty > 0) {
          busd.transferFrom(paymentRequest.buyer, paymentRequest.thirdParty, paymentRequest.amountForThirdParty);
        }
      } else {
        // It's a liquidity sale; there's no fee in BUSD to take, but there is one in BCT
        _buyBCT(paymentRequest.price);

        // Now, the BCT is within this contract, so we can transfer it to the seller or burn it
        // We transfer to the seller
        bct.transfer(paymentRequest.seller, paymentRequest.amountForSeller);

        // if there's a third party, we transfer the amount to them
        if (paymentRequest.amountForThirdParty > 0) {
          bct.transfer(paymentRequest.thirdParty, paymentRequest.amountForThirdParty);
        }

        // we burn the community fee
        if (paymentRequest.burnFee > 0) {
          bct.burn(paymentRequest.burnFee);
        }
      }
    } else {
      // We transfer to the seller
      bct.transferFrom(paymentRequest.buyer, paymentRequest.seller, paymentRequest.amountForSeller);

      // if there's a third party, we transfer the amount to them
      if (paymentRequest.amountForThirdParty > 0) {
        bct.transferFrom(paymentRequest.buyer, paymentRequest.thirdParty, paymentRequest.amountForThirdParty);
      }

      // we burn the community fee
      if (paymentRequest.burnFee > 0) {
        bct.burnFrom(paymentRequest.buyer, paymentRequest.burnFee);
      }
    }
  }

  function _deliverGoods(
    AssetType assetType,
    address to,
    address assetAddress,
    uint256 amount,
    uint256 assetId
  ) internal {
    if (assetType == AssetType.ERC20) {
      MHIERC20(assetAddress).transfer(to, amount);
    } else {
      MHIERC721(assetAddress).safeTransferFrom(address(this), to, assetId);
    }
  }

  function _deleteOrder(uint256 orderId) internal {
    uint256 orderIndex = _orderIdToOrderIndex[orderId];
    require(orderIndex < orders.length && orderIndex != 0, "Invalid order index");

    Order memory order = orders[orderIndex];
    require(order.id == orderId, "Invalid order ID");

    Order memory lastOrder = orders[orders.length - 1];

    if (lastOrder.id != orderId) {
      orders[orderIndex] = lastOrder;
      _orderIdToOrderIndex[lastOrder.id] = orderIndex;
    }

    orders.pop();
    delete _orderIdToOrderIndex[orderId];
  }

  function _buyBCT(uint256 _bctAmountOut) internal returns (uint256 amountPaid) {
    require(_bctAmountOut > 0, "0");

    //console.log("_buyBCT:: _bctAmountOut", _bctAmountOut);

    uint256 _amountInCalculated = pool.getStableTokensIn(_bctAmountOut);
    uint256 _price = pool.getPrice();

    //console.log("_buyBCT:: _amountInCalculated", _amountInCalculated);

    busd.transferFrom(msg.sender, address(this), _amountInCalculated);

    amountPaid = pool.buyGameTokensAtPrice(_bctAmountOut, _price, 10); // 1% slippage

    //console.log("_buyBCT:: amountPaid", amountPaid);
  }

  //###############
  // Operator only
  function setPool(address _pool) external onlyRole(OPERATOR_ROLE) {
    pool = ICommunityPool(_pool);
  }

  function setBusd(address _busd) external onlyRole(OPERATOR_ROLE) {
    busd = MHIERC20(_busd);
  }

  function pause() external onlyRole(OPERATOR_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(OPERATOR_ROLE) {
    _unpause();
  }

  function recoverERC20(address tokenAddress, address to, uint256 amount) external onlyRole(OPERATOR_ROLE) {
    MHIERC20(tokenAddress).transfer(to, amount);
  }

  function recoverERC721(address tokenAddress, address to, uint256 tokenId) external onlyRole(OPERATOR_ROLE) {
    MHIERC721(tokenAddress).safeTransferFrom(address(this), to, tokenId);
  }

  function setAssets(Asset[] calldata _assets) public onlyRole(OPERATOR_ROLE) {
    for (uint256 i = 0; i < _assets.length; i++) {
      acceptedAssets[_assets[i].addr] = _assets[i].assetType;
    }
  }

  function setFarm(address _farm) external onlyRole(OPERATOR_ROLE) {
    farm = IMhdaoFarmMerchant(_farm);
  }

  //###############
  // Standard
  function onERC721Received() external pure returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }
}