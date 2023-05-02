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

// File contracts/interfaces/IPlayerBonus.sol

pragma solidity ^0.8.9;

interface IPlayerBonus {
  function bonusOf(address _playerAddress) external view returns (uint256);

  function detailedBonusOf(address _playerAddress) external view returns (uint256);

  function bonusWithFortuneOf(address account) external view returns (uint256, uint256);

  function resetBonusOf(address _playerAddress) external;

  function setStashOf(address _playerAddress, uint256 _stash) external;

  function setMythicMintsOf(address _playerAddress, uint256 _mythicMints) external;

  function incrementMythicsOf(address _playerAddress) external;

  function setSpecialOf(address _playerAddress, uint256 _special) external;

  function setAllOf(address _playerAddress, uint256 _stash, uint256 _mythicMints, uint256 _special) external;
}

// File contracts/interfaces/IMhdaoNft.sol

pragma solidity ^0.8.9;

interface IMhdaoNft {
  struct NftCharacter {
    uint256 id; // the NFT ID
    string name; // is an empty string up until the owner sets it
    string imageUrl; // is an empty string up until the owner sets it
    address owner; // the current owner
    uint256 type_; // 0 for none, 1 for mouse, 2 for ghost, 3+ for exotic
    uint256 rarity; // 0 for none, 1 for common, 2 for rare, 3 for epic, 4 for legendary, 5 for mythic, 6 for supreme
    uint256[] traits; // from 0 to 2 traits, that are numbers from 1 to 50 (initially)
    uint256[] skills; // multipliers for the farming of [sc/hc, ec/cc, nuts, crafting, advanced crafting] (all have to be acquired, all go up to 3)
    uint256 baseFarm; // how many Weis of BCT this NFT will generate per cycle
    uint256 agility; // improves Ranks
    uint256 rank; // multiplies the base farm by rank/10
    uint256 farmPerBlock; // the final farm per block
    uint256 squadId; // the squad ID this NFT is in
    uint256 collection; // the collection this NFT belongs to
  }

  struct Booster {
    address address_; // the address of the booster
    address boosterData; // the address of the booster data contract (has names, traits, and imageURLs); if 0x0, use the default values
    string name; // the name of the booster
    string tokensDefaultUri; // the base URI for the tokens that can be unboxed
    uint256 type_; // 1 for mouse, 2 for ghost, 3+ for exotic
    uint256 rarity; // each booster has a defined NFT rarity: it will always mint NFTs of that rarity
    uint256 baseFarmBoost; // how many Weis of BONUS BCT this NFT will generate per cycle
    bool accepted; // whether this booster is accepted by the contract
  }

  function tokenURI(uint256 tokenId) external view returns (string memory);

  function tokenIdTracker() external view returns (uint256);

  function getNft(uint256 tokenId) external view returns (NftCharacter memory);

  function nftsOfOwner(address _owner) external view returns (NftCharacter[] memory);

  function ownerOf(uint256 tokenId) external view returns (address);

  function paginatedNftsOfOwner(address _owner, uint256 page, uint256 pageSize) external view;

  function getBooster(address boosterAddress) external view returns (Booster memory);

  function tokensOfOwner(address _owner) external view returns (uint256[] memory);

  function squadOf(uint256 tokenId) external view returns (uint256);

  function isOnQuest(uint256 tokenId) external view returns (bool);

  function farmPerBlockOf(uint256 tokenId) external view returns (uint256);

  function rarityOf(uint256 tokenId) external view returns (uint256);

  function typeOf(uint256 tokenId) external view returns (uint256);

  function rarityTypeAndSkillsOf(uint256 tokenId) external view returns (uint256, uint256, uint256[] memory);

  function rarityTypeRankAndSkillsOf(
    uint256 tokenId
  ) external view returns (uint256, uint256, uint256, uint256[] memory);

  function traitsOf(uint256 tokenId) external view returns (uint256[] memory);

  function collectionOf(uint256 tokenId) external view returns (uint256);

  function burnFrom(address account, uint256 tokenId) external;

  function setSquad(uint256 tokenId, uint256 squadId) external;

  function unboxBooster(address boosterAddress) external;

  function rankUp(uint256 tokenId) external;

  function setBaseFarm(uint256 tokenId, uint256 newBaseFarm) external;

  function setRank(uint256 tokenId, uint256 newRank) external;

  function setRarityAndType(uint256 tokenId, uint256 newRarity, uint256 newType_, uint256 newBaseFarm) external;

  function setTraits(uint256 tokenId, uint256[] memory traits) external;

  function setSkills(uint256 tokenId, uint256[] memory _skills) external;

  function setRankAgilityAndSkills(uint256 tokenId, uint256 _rank, uint256 _agility, uint256[] memory skills) external;

  function setNameAndImage(uint256 tokenId, string memory newName, string memory newImageUrl) external;

  function rerollTraits(uint256 tokenId) external;

  function legendaryRerollTraits(uint256 tokenId, uint256 chosenTrait) external;

  function setAgility(uint256 tokenId, uint256 _agility) external;

  function changeName(uint256 tokenId, string memory newName) external;

  function changeImageUrl(uint256 tokenId, string memory newImageUrl) external;

  function setCollection(uint256 tokenId, uint256 newCollection) external;

  function mint(
    string memory _name,
    string memory _imageUrl,
    address _owner,
    uint256 type_,
    uint256 _rarity,
    uint256 _rank,
    uint256[] memory _traits,
    uint256 _collection
  ) external;
}

// File contracts/interfaces/IMhdaoPlayer.sol

pragma solidity ^0.8.9;

interface IMhdaoPlayer {
  struct Player {
    uint256 bctToClaim; // available to claim
    uint256 etherealBct; // cannot be withdrawn
    uint256 lastWithdrawalBlock; // last withdraw block
    uint256 registeredAt; // when the player registered (block number)
    address mentor; // the player's mentor gets 0.5% of the player's farmed BCT (extra, not taking from the player)
    uint256 mentorLevel; // multiplies the mentor's reward by mentorLevel, starts at 1 and goes up to 10
    uint256 merchantLevel; // identifies merchants, the higher, the more fees they collect
    uint256[] squads; // a dynamic list of Squad Ids
  }
}

// File contracts/interfaces/IMhdaoSquad.sol

pragma solidity ^0.8.9;

interface IMhdaoSquad {
  struct Squad {
    address owner; // squad owner
    uint256 type_; // squad type: 1 for mouse, 2 for ghost, 3 for mixed
    uint256 size; // how many NFTs can be in the squad
    uint256 baseFarmPerBlock; // farm per block without synergy bonus
    uint256 synergyBonus; // synergy bonus
    uint256 squadBonus; // squad bonus
    uint256 squadTrait; // a trait that the squad has and can synergize with all NFTs there
    uint256 farmPerBlock; // farm per block with synergy bonus
    uint256 currentQuest; // current quest this squad is engaged in
    uint256 questStartedAt; // when the squad started farming this quest
    uint256 questEndsAt; // when the squad should finish this quest
    uint256[] nftIds; // a dynamic list of NFT ids in the squad
    uint256[] traits; // a dynamic list of possibly sinergetic traits in the squad
    uint256[] collections; // a dynamic list of possibly sinergetic collections in the squad
  }
}

// File contracts/interfaces/IMhdaoQuest.sol

pragma solidity ^0.8.9;

interface IMhdaoQuest {
  struct Quest {
    uint256 id; // the quest id
    uint256 minSynergyMultiplier; // the minimum synergy multiplier needed to complete the quest
    uint256 bctPercentage; // how much of the BCT farmed is actually collected
    uint256 etherealPercentage; // how much of the BCT farmed is converted to Ethereal and then collected
    uint256[] resourceMultipliers; // [0 - sc/hc, 1 - ec/cc, 2 - nuts, 3 - crafting, 4 - advanced crafting]
    uint256[] traits; // traits that must be present in the squad
    uint256[] collections; // which collections must be present in the squad
    bool anyCollection; // if true, any collection grants access
  }
}

// File contracts/interfaces/IQuestRewardCalculator.sol

pragma solidity ^0.8.9;

interface IQuestRewardCalculator {
  struct MultiplierRequest {
    uint256 squadType;
    uint256 numberOfNtfs;
    uint256 raritySum;
    uint256 synergyBonus;
    uint256 traits;
    uint256 collections;
    uint256 durationInBlocks;
    address account;
  }

  function getBaseMultipliers(MultiplierRequest memory req) external pure returns (uint256[] memory);
}

// File contracts/features/MhdaoFarm.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// @dev: remove require messages from the 3 following contracts to save on bytecode (you must)

contract MhdaoFarm is Initializable, AccessControlUpgradeable, PausableUpgradeable {
  bytes32 internal constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
  bytes32 internal constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

  // Interfaces
  struct Contracts {
    MHIERC20 bct;
    IMhdaoNft mhdaoNFT;
    IPlayerBonus playerBonus;
    IQuestRewardCalculator questRewardCalculator;
  }
  Contracts public contracts;

  mapping(address => IMhdaoPlayer.Player) public players;
  mapping(uint256 => IMhdaoSquad.Squad) public squads;
  mapping(uint256 => IMhdaoQuest.Quest) public quests;
  uint256 public totalSquads; // total squads ever, counting all players
  mapping(uint256 => uint256) public raritySumOfSquad; // sum of all NFTs rarities in a squad
  mapping(uint256 => address) public resources; // list of resources by resource index
  uint256 totalResourcesRegistered; // total resources registered
  mapping(address => mapping(uint256 => uint256)) public resourceBalances; // player => resource => amount
  mapping(address => uint256) public changeMentorBlock; // player => block number

  Config public config;

  struct Config {
    uint256 burnFeePct; // We'll burn this much % in every withdraw
    uint256 scale; // 100 is 1.00, multiplies the farm per block
    uint256 withdrawalInterval; // minimum number of blocks between withdraws
    uint256 maxSquads; // max squads per player
    uint256 mentorDivider; // (1/mentorDivider)*mentorLevel percent of the total farm goes to the mentor
    bool burnInGameBctBalance; // if true, the in-game BCT balance will be burned from the farm when the player paysWithBalance
    bool burnInGameEbctBalance; // if true, the in-game eMM balance will be burned from the farm when the player paysWithBalance
  }

  event PlayerRegistered(address player);
  event QuestStarted(address player, uint256 squadId, uint256 questId, uint256 duration, uint256 farmPerBlock);
  event QuestEnded(address player, uint256 squadId, uint256 questId, uint256 duration);
  event Withdraw(address player, uint256 amount, uint256 burnAmount);
  event InGameResourceTransfer(address from, address to, uint256 amount);

  function initialize(
    address _operator,
    address _bct,
    address _mhdaoNFT,
    address _playerBonus,
    address _questRewardCalculator
  ) public initializer {
    __AccessControl_init();
    __Pausable_init();

    _setupRole(DEFAULT_ADMIN_ROLE, _operator);
    _setupRole(OPERATOR_ROLE, _operator);
    _setupRole(UPDATER_ROLE, _operator);

    contracts = Contracts({
      bct: MHIERC20(_bct),
      mhdaoNFT: IMhdaoNft(_mhdaoNFT),
      playerBonus: IPlayerBonus(_playerBonus),
      questRewardCalculator: IQuestRewardCalculator(_questRewardCalculator)
    });

    config = Config({
      burnFeePct: 20,
      scale: 800,
      withdrawalInterval: 28800 * 15, // 15 days
      maxSquads: 20,
      mentorDivider: 200,
      burnInGameBctBalance: true,
      burnInGameEbctBalance: true
    });
  }

  //################
  // User functions
  function registerPlayer(address mentor) external whenNotPaused {
    require(players[msg.sender].squads.length == 0, "1");
    require(msg.sender != mentor);

    players[msg.sender] = IMhdaoPlayer.Player({
      bctToClaim: 0,
      etherealBct: 0,
      lastWithdrawalBlock: block.number,
      registeredAt: block.number,
      mentor: mentor,
      mentorLevel: 1,
      merchantLevel: 0,
      squads: new uint256[](0) // a dynamic list of squad ids
    });

    _createNewSquad(msg.sender, 6);
    _createNewSquad(msg.sender, 6);
    _createNewSquad(msg.sender, 6);
    _createNewSquad(msg.sender, 6);

    contracts.playerBonus.resetBonusOf(msg.sender);

    emit PlayerRegistered(msg.sender);
  }

  function addToSquad(uint256[] memory nftIds, uint256 squadId) external whenNotPaused {
    _addToSquad(msg.sender, nftIds, squadId);
  }

  function removeFromSquad(uint256[] memory nftIds, uint256 squadId) external whenNotPaused {
    _removeFromSquad(msg.sender, nftIds, squadId);
  }

  function startQuest(uint256 squadId, uint256 questId, uint256 durationInDays) external whenNotPaused {
    IMhdaoSquad.Squad storage squad = squads[squadId];
    require(squad.owner == msg.sender, "2");
    require(squad.currentQuest == 0, "3");
    require(durationInDays >= 1);

    // get the quest's metadata
    IMhdaoQuest.Quest memory quest = quests[questId];
    require(quest.id > 0, "0");

    // check if the squad has the required amount of NFTs
    require(squad.nftIds.length > 0);

    if (quest.minSynergyMultiplier > 0) {
      require(squad.synergyBonus >= quest.minSynergyMultiplier, "21");
    }

    // check if the squad has at least one of each of the required traits
    if (quest.traits.length > 0) {
      for (uint256 i = 0; i < quest.traits.length; i++) {
        bool hasTrait;
        for (uint256 j = 0; j < squad.traits.length; j++) {
          if (squad.traits[j] == quest.traits[i]) {
            hasTrait = true;
            break;
          }
        }

        if (squad.squadTrait != 0) {
          if (squad.squadTrait == quest.traits[i]) {
            hasTrait = true;
          }
        }

        require(hasTrait, "22");
      }
    }

    // check if the squad has at least one of each of the required collections
    if (quest.collections.length > 0 || quest.anyCollection) {
      for (uint256 i = 0; i < quest.collections.length; i++) {
        bool hasCollection;
        for (uint256 j = 0; j < squad.collections.length; j++) {
          if (squad.collections[j] == quest.collections[i] || quest.anyCollection) {
            hasCollection = true;
            break;
          }
        }

        require(hasCollection, "23");
      }
    }

    // update the squad's current quest
    squad.currentQuest = questId;
    squad.questStartedAt = block.number;
    squad.questEndsAt = block.number + durationInDays * 28800;

    // emit event
    emit QuestStarted(msg.sender, squadId, questId, durationInDays * 28800, squad.farmPerBlock);
  }

  function finishQuest(uint256 squadId) external whenNotPaused {
    IMhdaoSquad.Squad storage squad = squads[squadId];
    require(squad.owner == msg.sender, "2");

    uint256 currentQuestId = squad.currentQuest;
    require(currentQuestId > 0, "5");

    // get the quest's metadata
    IMhdaoQuest.Quest memory quest = quests[currentQuestId];

    // check if the quest has ended
    require(block.number >= squad.questEndsAt);

    uint durationInBlocks = squad.questEndsAt - squad.questStartedAt;

    // update the squad's current quest
    squad.currentQuest = 0;
    squad.questStartedAt = 0;
    squad.questEndsAt = 0;

    IMhdaoPlayer.Player storage player = players[msg.sender];

    // Fetch all multipliers:
    uint256[] memory multipliers = contracts.questRewardCalculator.getBaseMultipliers(
      IQuestRewardCalculator.MultiplierRequest({
        squadType: squad.type_,
        numberOfNtfs: squad.nftIds.length,
        raritySum: raritySumOfSquad[squadId],
        synergyBonus: squad.synergyBonus,
        traits: squad.traits.length,
        collections: squad.collections.length,
        durationInBlocks: durationInBlocks,
        account: squad.owner
      })
    );

    if (quest.bctPercentage > 0) {
      uint256 totalBctFarmed = (squad.farmPerBlock * quest.bctPercentage * config.scale) / 10000;
      totalBctFarmed = (totalBctFarmed * multipliers[0]) / 100;

      player.bctToClaim += totalBctFarmed;
      // if this player has a mentor, send the mentor's bonus
      if (player.mentor != address(0)) {
        players[player.mentor].bctToClaim +=
          (players[player.mentor].mentorLevel * totalBctFarmed) /
          config.mentorDivider;
      }
    }

    if (quest.etherealPercentage > 0) {
      uint256 totalEtherealFarmed = (squad.farmPerBlock * quest.etherealPercentage * config.scale) / 10000;
      totalEtherealFarmed = (totalEtherealFarmed * multipliers[1]) / 100;

      player.etherealBct += totalEtherealFarmed;
      // if this player has a mentor, send the mentor's bonus
      if (player.mentor != address(0)) {
        players[player.mentor].etherealBct +=
          (players[player.mentor].mentorLevel * totalEtherealFarmed) /
          config.mentorDivider;
      }
    }

    uint256[] memory resourceCentsFarmed = new uint256[](19);
    for (uint256 i = 0; i < squad.nftIds.length; i++) {
      // get the NFT's rarity and multiply it
      (uint256 rarity, uint256 type_, uint256[] memory skills) = contracts.mhdaoNFT.rarityTypeAndSkillsOf(
        squad.nftIds[i]
      );

      // Skills: 'Loot' 1 and 2
      resourceCentsFarmed[type_ - 1] += (quest.resourceMultipliers[0] * rarity * skills[0] * multipliers[2]) / 100;
      resourceCentsFarmed[type_ + 4] += (quest.resourceMultipliers[1] * rarity * skills[1] * multipliers[2]) / 100;

      // Skill: 'Nuts'
      resourceCentsFarmed[10] += (quest.resourceMultipliers[2] * rarity * skills[2] * multipliers[3]) / 100;

      // Skill: Crafting
      for (uint256 j = 3; j < 11; j++) {
        resourceCentsFarmed[j + 8] += (quest.resourceMultipliers[j] * rarity * skills[3] * multipliers[4]);
      }
    }

    for (uint i = 0; i < resourceCentsFarmed.length; i++) {
      resourceBalances[msg.sender][i] += resourceCentsFarmed[i];
    }

    // emit event
    emit QuestEnded(msg.sender, squadId, currentQuestId, durationInBlocks);
  }

  function withdraw(uint256 amount, uint256[] calldata _resources) public whenNotPaused {
    IMhdaoPlayer.Player storage player = players[msg.sender];
    require(player.bctToClaim >= amount, "6");
    require(player.lastWithdrawalBlock + config.withdrawalInterval <= block.number, "cooldown");

    uint256 burnAmount = ((amount * config.burnFeePct) / 100);
    uint256 remainingAmount = amount - burnAmount;

    player.bctToClaim -= amount;
    player.lastWithdrawalBlock = block.number;

    contracts.bct.burn(burnAmount);
    contracts.bct.transfer(msg.sender, remainingAmount);

    for (uint i = 0; i < _resources.length; i++) {
      if (_resources[i] > 0) {
        resourceBalances[msg.sender][i] -= _resources[i];
        MHIERC20(resources[i]).mint(msg.sender, _resources[i]);
      }
    }

    emit Withdraw(msg.sender, amount, burnAmount);
  }

  function setMentor(address mentorAddress) public whenNotPaused {
    require(changeMentorBlock[msg.sender] + 864000 < block.number, "7");
    require(mentorAddress != msg.sender);

    changeMentorBlock[msg.sender] = block.number;

    players[msg.sender].mentor = mentorAddress;
  }

  function transferInGameBctAndLoot(address to, uint256 bctAmount, uint256[] memory _resources) public whenNotPaused {
    _transferInGameBctAndLoot(msg.sender, to, bctAmount, _resources);
  }

  //################
  // UPDATER functions
  function cancelQuest(uint256 squadId) external onlyRole(UPDATER_ROLE) {
    IMhdaoSquad.Squad storage squad = squads[squadId];

    // update the squad's current quest
    squad.currentQuest = 0;
    squad.questStartedAt = 0;
    squad.questEndsAt = 0;
  }

  function addSquadToPlayer(address playerAddress, uint256 type_) public onlyRole(UPDATER_ROLE) returns (uint256) {
    uint256 squadId = _createNewSquad(playerAddress, type_);
    return squadId;
  }

  function increaseSquadSize(uint256 squadId) public onlyRole(UPDATER_ROLE) {
    squads[squadId].size++;
  }

  function setMentorLevel(address playerAddress, uint256 level) public onlyRole(UPDATER_ROLE) {
    players[playerAddress].mentorLevel = level;
  }

  function increaseMerchantLevel(address playerAddress) public onlyRole(UPDATER_ROLE) {
    players[playerAddress].merchantLevel++;
  }

  function payWithBalance(
    address account,
    uint256 bctAmount,
    uint256[] memory _resources
  ) public onlyRole(UPDATER_ROLE) returns (uint256[] memory) {
    IMhdaoPlayer.Player storage player = players[account];
    uint256 totalBctBalance = player.etherealBct + player.bctToClaim;

    // Pay BCT
    uint256[] memory remaining = new uint256[](_resources.length + 1);
    if (bctAmount <= player.etherealBct) {
      _spendBct(account, bctAmount, true);
      remaining[0] = 0;
    } else if (bctAmount <= totalBctBalance) {
      _spendBct(account, player.etherealBct, true);
      _spendBct(account, bctAmount - player.etherealBct, false);
      remaining[0] = 0;
    } else {
      _spendBct(account, player.etherealBct, true);
      _spendBct(account, player.bctToClaim, false);
      remaining[0] = bctAmount - totalBctBalance;
    }

    // Pay other _Resources
    for (uint i = 0; i < _resources.length; i++) {
      if (_resources[i] <= resourceBalances[account][i]) {
        resourceBalances[account][i] -= _resources[i];
        remaining[i + 1] = 0;
      } else {
        remaining[i + 1] = _resources[i] - resourceBalances[account][i];
        resourceBalances[account][i] = 0;
      }
    }

    return remaining;
  }

  function spendBctFrom(address account, uint256 amount, bool ethereal) public onlyRole(UPDATER_ROLE) {
    _spendBct(account, amount, ethereal);
  }

  function transferInGameBctAndLootFrom(
    address from,
    address to,
    uint256 bctAmount,
    uint256[] memory _resources
  ) public onlyRole(UPDATER_ROLE) {
    _transferInGameBctAndLoot(from, to, bctAmount, _resources);
  }

  function recalculateSquadFarming(uint256 squadId) public onlyRole(UPDATER_ROLE) {
    _recalculateSquadTraits(squadId);
    _updateSquadFarming(squadId);
  }

  function addTo(address playerAddress, uint256 amount, uint256[] memory _resources) external onlyRole(UPDATER_ROLE) {
    players[playerAddress].etherealBct += amount;
    for (uint i = 0; i < _resources.length; i++) {
      resourceBalances[playerAddress][i] += _resources[i];
    }
  }

  function setSquadType(uint256 squadId, uint256 type_) external onlyRole(UPDATER_ROLE) {
    squads[squadId].type_ = type_;
  }

  function setSquadTrait(uint256 squadId, uint256 squadTrait) external onlyRole(UPDATER_ROLE) {
    squads[squadId].squadTrait = squadTrait;
  }

  //################
  // Internal/private functions
  function _createNewSquad(address playerAddress, uint256 type_) internal returns (uint256) {
    uint256[] storage playerSquads = players[playerAddress].squads;
    require(playerSquads.length < config.maxSquads, "8");

    uint256 squadId = totalSquads + 1;
    playerSquads.push(squadId);

    uint256 squadBonus = playerSquads.length < 4 ? 0 : (playerSquads.length - 4) * 5;

    squads[squadId] = IMhdaoSquad.Squad({
      owner: playerAddress,
      type_: type_,
      size: 3,
      baseFarmPerBlock: 0,
      synergyBonus: 0,
      squadBonus: squadBonus,
      squadTrait: 0,
      farmPerBlock: 0,
      currentQuest: 0,
      questStartedAt: 0,
      questEndsAt: 0,
      nftIds: new uint256[](0),
      traits: new uint256[](0),
      collections: new uint256[](0)
    });

    totalSquads++;

    return squadId;
  }

  function _addToSquad(address playerAddress, uint256[] memory nftIds, uint256 squadId) internal {
    IMhdaoSquad.Squad storage squad = squads[squadId];
    require(squad.owner == playerAddress, "2");
    require(squad.currentQuest == 0, "3");
    require(squad.nftIds.length + nftIds.length <= squad.size, "24");

    uint256 raritySum;
    for (uint256 i = 0; i < nftIds.length; i++) {
      uint256 nftId = nftIds[i];
      require(contracts.mhdaoNFT.ownerOf(nftId) == msg.sender, "2");
      require(contracts.mhdaoNFT.squadOf(nftId) == 0, "9");

      // get the NFT's metadata to check whether this is a mouse, cat, or another beast
      IMhdaoNft.NftCharacter memory nft = contracts.mhdaoNFT.getNft(nftId);
      require(_isAllowedToEnter(nft.type_, squadId), "25");

      // add the NFT id to the squad
      squad.nftIds.push(nftId);

      // add the NFT's traits to the squad
      for (uint256 j = 0; j < nft.traits.length; j++) {
        if (nft.traits[j] > 0) {
          squad.traits.push(nft.traits[j]);
        }
      }

      if (nft.collection > 0) {
        squad.collections.push(nft.collection);
      }

      // update the squad's raritySum
      raritySum += nft.rarity;

      // update the NFT's squad
      contracts.mhdaoNFT.setSquad(nftId, squadId);
    }

    raritySumOfSquad[squadId] += raritySum;

    // update the squad's farming
    _updateSquadFarming(squadId);
  }

  function _removeFromSquad(address playerAddress, uint256[] memory nftIds, uint256 squadId) internal {
    IMhdaoSquad.Squad storage squad = squads[squadId];
    require(squad.owner == playerAddress, "2");
    require(squad.currentQuest == 0, "3");
    require(squad.nftIds.length > 0, "11");

    uint256 raritySum;
    for (uint256 i = 0; i < nftIds.length; i++) {
      uint256 nftId = nftIds[i];
      require(contracts.mhdaoNFT.ownerOf(nftId) == msg.sender, "2");
      require(contracts.mhdaoNFT.squadOf(nftId) == squadId, "12");

      // remove the NFT from the squad
      bool removed;
      for (uint256 j = 0; j < squad.nftIds.length; j++) {
        if (squad.nftIds[j] == nftId) {
          squad.nftIds[j] = squad.nftIds[squad.nftIds.length - 1];
          squad.nftIds.pop();
          removed = true;
          break;
        }
      }
      require(removed, "13");

      uint256 nftCollection = contracts.mhdaoNFT.collectionOf(nftId);
      if (nftCollection > 0) {
        for (uint256 j = 0; j < squad.collections.length; j++) {
          if (squad.collections[j] == nftCollection) {
            squad.collections[j] = squad.collections[squad.collections.length - 1];
            squad.collections.pop();
            removed = true;
            break;
          }
        }

        require(removed, "14");
      }

      // update the NFT's squad
      contracts.mhdaoNFT.setSquad(nftId, 0);

      raritySum += contracts.mhdaoNFT.rarityOf(nftId);
    }

    // update the squad's raritySum
    raritySumOfSquad[squadId] -= raritySum;

    // remove the NFT's traits from the squad and update the squad's synergy bonus
    _recalculateSquadTraits(squadId);
    _updateSquadFarming(squadId);
  }

  function _updateSquadFarming(uint256 squadId) internal whenNotPaused {
    IMhdaoSquad.Squad storage squad = squads[squadId];
    require(squad.currentQuest == 0, "3");

    // update the squad's synergy bonus and farm per block
    squad.baseFarmPerBlock = calculateSquadBaseFarmPerBlock(squadId);
    squad.synergyBonus = calculateTraitSynergy(squad.traits, squad.squadTrait);
    squad.synergyBonus += calculateTraitSynergy(squad.collections, 0);
    squad.farmPerBlock = calculateSquadFarmPerBlock(squadId);
  }

  function _recalculateSquadTraits(uint256 squadId) internal whenNotPaused {
    IMhdaoSquad.Squad storage squad = squads[squadId];

    squad.traits = new uint256[](0);
    for (uint256 i = 0; i < squad.nftIds.length; i++) {
      uint256[] memory traits = contracts.mhdaoNFT.traitsOf(squad.nftIds[i]);
      for (uint256 j = 0; j < traits.length; j++) {
        squad.traits.push(traits[j]);
      }
    }
  }

  function _isAllowedToEnter(uint256 type_, uint256 squadId) internal view returns (bool) {
    uint256 squadType = squads[squadId].type_;
    return (type_ == squadType || squadType == 6 || type_ >= 6);
  }

  function _transferInGameBctAndLoot(address from, address to, uint256 amount, uint256[] memory _resources) private {
    players[from].bctToClaim -= amount; // will revert if negative
    players[to].bctToClaim += amount;

    for (uint i = 0; i < _resources.length; i++) {
      if (_resources[i] > 0) {
        resourceBalances[from][i] -= _resources[i];
        resourceBalances[to][i] += _resources[i];
      }
    }

    emit InGameResourceTransfer(from, to, amount);
  }

  function _spendBct(address account, uint256 amount, bool ethereal) private {
    if (ethereal) {
      players[account].etherealBct -= amount;
      if (config.burnInGameEbctBalance) {
        contracts.bct.burn(amount);
      }
    } else {
      players[account].bctToClaim -= amount;
      if (config.burnInGameBctBalance) {
        contracts.bct.burn(amount);
      }
    }
  }

  //################
  // OPERATOR functions
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

  function setQuests(uint256[] memory questIds, IMhdaoQuest.Quest[] memory quests_) public onlyRole(OPERATOR_ROLE) {
    for (uint256 i = 0; i < quests_.length; i++) {
      quests[questIds[i]] = quests_[i];
    }
  }

  function setConfig(Config calldata newConfig) external onlyRole(OPERATOR_ROLE) {
    config = newConfig;
  }

  function setResources(address[] calldata resourcesAddresses) public onlyRole(OPERATOR_ROLE) {
    for (uint256 i = 0; i < resourcesAddresses.length; i++) {
      resources[i] = resourcesAddresses[i];
    }

    totalResourcesRegistered = resourcesAddresses.length;
  }

  function approveBctSpending(address to, uint256 amount) external onlyRole(OPERATOR_ROLE) {
    contracts.bct.approve(to, amount);
  }

  function setQuestRewardsCalculator(address questRewardsCalculator_) external onlyRole(OPERATOR_ROLE) {
    contracts.questRewardCalculator = IQuestRewardCalculator(questRewardsCalculator_);
  }

  //################
  // Public view/pure functions
  function calculateSquadBaseFarmPerBlock(uint256 squadId) public view returns (uint256) {
    IMhdaoSquad.Squad memory squad = squads[squadId];
    uint256 baseFarmPerBlock = 0;

    // sum the base farm of each NFT that is in this squad
    for (uint256 i = 0; i < squad.nftIds.length; i++) {
      baseFarmPerBlock += contracts.mhdaoNFT.farmPerBlockOf(squad.nftIds[i]);
    }

    return baseFarmPerBlock;
  }

  function calculateTraitSynergy(uint256[] memory traits, uint256 extraTrait) public pure returns (uint256) {
    // count how many instances of each trait appear in the squad
    uint256[] memory _tempTraits = new uint256[](51);
    for (uint256 i = 0; i < traits.length; i++) {
      _tempTraits[traits[i]]++;
    }

    // add the extra trait, if not 0:
    if (extraTrait != 0) {
      _tempTraits[extraTrait]++;
    }

    // calculate the synergy bonus
    uint256 synergy = 0;
    for (uint256 i = 0; i < _tempTraits.length; i++) {
      if (_tempTraits[i] > 1) {
        if (_tempTraits[i] > 6) {
          _tempTraits[i] = 6;
        }
        synergy += _tempTraits[i] ** 2;
      }
    }

    return synergy * 10;
  }

  function calculateSquadFarmPerBlock(uint256 squadId) public view returns (uint256) {
    IMhdaoSquad.Squad storage squad = squads[squadId];

    // Multiply the base farm by the synergy bonus and add that to the base farm
    uint256 farming = squad.baseFarmPerBlock + (squad.baseFarmPerBlock * squad.synergyBonus) / 100;

    // Apply the squad bonus
    farming = farming + (farming * squad.squadBonus) / 100;

    return farming;
  }

  function getSquad(uint256 squadId) public view returns (IMhdaoSquad.Squad memory) {
    IMhdaoSquad.Squad memory squad = squads[squadId];

    return squad;
  }

  function squadsOf(address playerAddress) public view returns (IMhdaoSquad.Squad[] memory) {
    uint totalPlayerSquads = players[playerAddress].squads.length;
    IMhdaoSquad.Squad[] memory playerSquads = new IMhdaoSquad.Squad[](totalPlayerSquads);
    for (uint i = 0; i < totalPlayerSquads; i++) {
      playerSquads[i] = getSquad(players[playerAddress].squads[i]);
    }

    return playerSquads;
  }

  function isSquadOnQuest(uint256 squadId) public view returns (bool) {
    return squads[squadId].currentQuest > 0;
  }

  function getPlayer(address playerAddress) public view returns (IMhdaoPlayer.Player memory) {
    IMhdaoPlayer.Player memory player = players[playerAddress];

    return player;
  }

  function getQuest(uint256 questId) public view returns (IMhdaoQuest.Quest memory) {
    IMhdaoQuest.Quest memory quest = quests[questId];

    return quest;
  }

  function mentorOf(address playerAddress) public view returns (address mentor, uint256 mentorLevel) {
    mentor = players[playerAddress].mentor;
    return (mentor, players[mentor].mentorLevel);
  }

  function balancesOf(address playerAddress) public view returns (uint256[] memory) {
    IMhdaoPlayer.Player memory player = players[playerAddress];
    uint256[] memory balances = new uint256[](totalResourcesRegistered + 1);

    balances[0] = player.bctToClaim + player.etherealBct;

    for (uint256 i = 0; i < totalResourcesRegistered; i++) {
      balances[i + 1] = resourceBalances[playerAddress][i];
    }

    return balances;
  }

  function merchantLevelOf(address playerAddress) public view returns (uint256) {
    return players[playerAddress].merchantLevel;
  }
}