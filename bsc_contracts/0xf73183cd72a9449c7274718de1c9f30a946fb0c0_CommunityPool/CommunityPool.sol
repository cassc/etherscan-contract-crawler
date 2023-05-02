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

// File contracts/interfaces/IBlocklist.sol

pragma solidity 0.8.9;

interface IBlocklist {
  function isBlocklisted(address account) external view returns (bool);

  function areBlocklisted(address accountA, address accountB) external view returns (bool); // true if either account is blocklisted
}

// File contracts/utils/BlocklistableFlow.sol

pragma solidity 0.8.9;

contract BlocklistableFlow {
  /**
   * @dev the blocklist contract
   */
  IBlocklist public blocklist;

  /**
   * @notice is the blocklist active?
   */
  bool public hasBlocklist;

  modifier notBlocklisted() {
    require(!_isBlocklisted(msg.sender), "Blocklisted");
    _;
  }

  /**
   * @notice Lets the operator set the blocklist address
   * @param blocklistAddress The address of the blocklist contract
   */
  function _setBlocklist(address blocklistAddress) internal {
    blocklist = IBlocklist(blocklistAddress);
    hasBlocklist = true;
  }

  function _isBlocklisted(address account) internal view returns (bool) {
    if (!hasBlocklist) {
      return false;
    }

    return blocklist.isBlocklisted(account);
  }

  function _resetBlocklist() internal {
    blocklist = IBlocklist(address(0));
    hasBlocklist = false;
  }
}

// File contracts/utils/AntiGasWars.sol

pragma solidity 0.8.9;

contract AntiGasWars {
  uint256 public gasPriceLimit;

  modifier onlyFairGas() {
    require(tx.gasprice <= gasPriceLimit, "gas2high");
    _;
  }

  function _setGasPriceLimit(uint256 _gasPriceLimit) internal {
    gasPriceLimit = _gasPriceLimit;
  }
}

// File contracts/utils/Mutexable.sol

pragma solidity ^0.8.0;

contract Mutexable {
  bool private _locked;

  modifier mutex() {
    require(!_locked, "mutex");
    _locked = true;
    _;
    _locked = false;
  }
}

// File contracts/utils/AntiMevLock.sol

pragma solidity 0.8.9;

contract AntiMevLock {
  uint256 public lockPeriod; // in blocks
  mapping(address => uint256) internal _lockedUntil;

  modifier onlyUnlockedSender() {
    require(!_isMevLocked(msg.sender), "cooldown");
    _mevLock(msg.sender);
    _;
  }

  modifier onlyUnlocked(address account) {
    require(!_isMevLocked(account), "cooldown");
    _mevLock(account);
    _;
  }

  function _setLockPeriod(uint256 _lockPeriod) internal {
    lockPeriod = _lockPeriod;
  }

  function _mevLock(address account) internal {
    _lockedUntil[account] = block.number + lockPeriod;
  }

  function _mevUnlock(address account) internal {
    _lockedUntil[account] = 0;
  }

  function _isMevLocked(address account) internal view returns (bool) {
    return _lockedUntil[account] > block.number;
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

// File contracts/interfaces/IStasher.sol

pragma solidity ^0.8.9;

interface IStasher {
  function levelOf(address _playerAddress) external view returns (uint8);
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

// File contracts/features/CommunityPool.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CommunityPool is
  AntiMevLock,
  Mutexable,
  AntiGasWars,
  BlocklistableFlow,
  Initializable,
  AccessControlUpgradeable,
  PausableUpgradeable
{
  bytes32 internal constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
  bytes32 internal constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

  // The MhdaoStasher contract
  IStasher public stasher;

  // ERC20 token state variables
  MHIERC20 public gameToken;
  MHIERC20 public stableToken;

  // State variables for token reserves
  uint256 public gameTokenReserve;
  uint256 public stableTokenReserve;

  uint256 public startBlock; // we start counting months from this block

  /// @dev a 'month' equals 30 days here
  struct Config {
    uint8 stasherDiscount; // percentual points per stasher level
    uint8 baseCommunityFee; // percentual points in the beginning
    uint8 closedForMonths; // will not allow selling until this many months have passed
    uint8 steepCurveMonths; // will decresase the community fee by 10% every month
    uint8 maxMonths; // will stop decreasing the community fee after this many months
  }
  Config public config;

  event LiquidityAdded(address from, uint256 gameTokensIn, uint256 stableTokensIn, uint256 newPrice);
  event Buy(address account, uint256 stableTokensIn, uint256 gameTokensOut, uint256 newPrice);
  event BuyAndBurn(address account, uint256 stableTokensIn, uint256 gameTokensBurned, uint256 newPrice);
  event Sell(
    address account,
    uint256 gameTokensIn,
    uint256 stableTokensOut,
    uint256 gameTokensBurned,
    uint256 newPrice
  );
  event NewPrice(uint256 price);

  function initialize(
    address _operator,
    address _gameToken,
    address _stableToken,
    address _stasher,
    uint256 _startBlock
  ) public initializer {
    __AccessControl_init();
    __Pausable_init();

    _setupRole(DEFAULT_ADMIN_ROLE, _operator);
    _setupRole(OPERATOR_ROLE, _operator);
    _setupRole(UPDATER_ROLE, _operator);

    gameToken = MHIERC20(_gameToken);
    stableToken = MHIERC20(_stableToken);
    stasher = IStasher(_stasher);

    config = Config({
      stasherDiscount: 4, // percentual points per stasher level, up to 30%
      baseCommunityFee: 70, // percentual points in the beginning
      closedForMonths: 2, // will not allow selling until this many months have passed
      steepCurveMonths: 3, // will decrease the community fee by 10% every month
      maxMonths: 14 // will stop decreasing the community fee after this many months
    });

    startBlock = _startBlock;

    _setLockPeriod(200); // 10 minutes in blocks
    _setGasPriceLimit(5 gwei);
  }

  function getReserves() public view returns (uint256 _gameTokenReserve, uint256 _stableTokenReserve) {
    _gameTokenReserve = gameTokenReserve;
    _stableTokenReserve = stableTokenReserve;
  }

  function getPrice() public view returns (uint256 _price) {
    _price = quoteBuyGameTokens(1e18);
  }

  // Quote BUY: how many game tokens will I get for a given amount of stable tokens?
  function quoteStableToGameTokens(uint256 stableTokens) public view returns (uint256 gameTokens) {
    (uint256 _gameTokenReserve, uint256 _stableTokenReserve) = getReserves();

    gameTokens = (_gameTokenReserve * stableTokens) / (_stableTokenReserve + stableTokens);
    require(gameTokens < _gameTokenReserve, "Insufficient Liquidity");
  }

  // Quote SELL: how many stable tokens will I get for a given amount of game tokens?
  function quoteGameToStableTokens(uint256 gameTokens) public view returns (uint256 stableTokens) {
    (uint256 _gameTokenReserve, uint256 _stableTokenReserve) = getReserves();

    stableTokens = (_stableTokenReserve * gameTokens) / (_gameTokenReserve + gameTokens);
    require(stableTokens < _stableTokenReserve, "Insufficient Liquidity");
  }

  // Calculate how much you need to pay in stableTokens to get `bctOut` bct
  function getStableTokensIn(uint256 bctOut) public view returns (uint256 stableTokensIn) {
    (uint256 _gameTokenReserve, uint256 _stableTokenReserve) = getReserves();
    require(bctOut < _gameTokenReserve, "Insufficient Liquidity");

    stableTokensIn = (_stableTokenReserve * bctOut) / (_gameTokenReserve - bctOut) + 1;
  }

  function quoteBuyGameTokens(uint256 gameTokensToBuy) public view returns (uint256 costInStableTokens) {
    require(gameTokensToBuy >= 1 ether, "Minimum buy is 1 BCT");
    (uint256 _gameTokenReserve, uint256 _stableTokenReserve) = getReserves();
    require(gameTokensToBuy < _gameTokenReserve, "Insufficient Liquidity");

    costInStableTokens = (_stableTokenReserve * gameTokensToBuy) / (_gameTokenReserve - gameTokensToBuy) + 1;
  }

  function quoteSellGameTokens(
    uint256 gameTokensToSell
  ) public view returns (uint256 stableTokensOut, uint256 feeInWei) {
    return _quoteSellGameTokens(gameTokensToSell, msg.sender);
  }

  function quoteSellGameTokensFor(
    uint256 gameTokensToSell,
    address account
  ) public view returns (uint256 stableTokensOut, uint256 feeInWei) {
    return _quoteSellGameTokens(gameTokensToSell, account);
  }

  function _quoteSellGameTokens(
    uint256 gameTokensToSell,
    address account
  ) private view returns (uint256 stableTokensOut, uint256 feeInWei) {
    // get reserves
    (uint256 _gameTokenReserve, uint256 _stableTokenReserve) = getReserves();

    uint256 stableTokensOutBeforeLevel = (_stableTokenReserve * gameTokensToSell) /
      (_gameTokenReserve + gameTokensToSell);

    // get stasher level
    uint8 stasherLevel = stasher.levelOf(account);

    // calculate community fee
    feeInWei = getCommunityFeeInWei(stableTokensOutBeforeLevel, stasherLevel);
    stableTokensOut = stableTokensOutBeforeLevel - feeInWei;
    require(stableTokensOut < _stableTokenReserve, "Insufficient Liquidity");
  }

  function buyGameTokens(
    uint256 gameTokens
  ) external mutex whenNotPaused onlyFairGas notBlocklisted onlyUnlockedSender returns (uint256 stableTokensPaid) {
    return _buyGameTokens(gameTokens);
  }

  function buyGameTokensAtPrice(
    uint256 gameTokens,
    uint256 atPrice,
    uint256 maxSlippage
  ) external mutex whenNotPaused onlyFairGas notBlocklisted onlyUnlockedSender returns (uint256 stableTokensPaid) {
    uint256 currentPrice = getPrice();
    uint256 maxPrice = atPrice + (atPrice * maxSlippage) / 1000;
    require(currentPrice <= maxPrice, "Price changed too much");

    return _buyGameTokens(gameTokens);
  }

  function _buyGameTokens(uint256 gameTokens) private returns (uint256 stableTokensPaid) {
    require(gameTokens >= 1 ether, "Minimum buy is 1 BCT");
    stableTokensPaid = quoteBuyGameTokens(gameTokens);

    // Transfer tokenIn to the liquity pool optimistically
    stableToken.transferFrom(msg.sender, address(this), stableTokensPaid);

    // Transfer tokenOut to the user
    gameToken.transfer(msg.sender, gameTokens);

    // Update the reserves
    _update(gameToken.balanceOf(address(this)), stableToken.balanceOf(address(this)));

    uint256 newPrice = getPrice();
    emit Buy(msg.sender, gameTokens, stableTokensPaid, newPrice);
    emit NewPrice(newPrice);
  }

  function sellGameTokens(
    uint256 gameTokens
  ) external mutex whenNotPaused onlyFairGas notBlocklisted onlyUnlockedSender returns (uint256 stableTokensOut) {
    return _sellGameTokens(gameTokens);
  }

  function sellGameTokensAtPrice(
    uint256 gameTokens,
    uint256 atPrice,
    uint256 maxSlippage
  ) external mutex whenNotPaused onlyFairGas notBlocklisted onlyUnlockedSender returns (uint256 stableTokensOut) {
    uint256 currentPrice = getPrice();
    uint256 minPrice = atPrice - (atPrice * maxSlippage) / 1000;
    require(currentPrice >= minPrice, "Price changed too much");

    return _sellGameTokens(gameTokens);
  }

  function _sellGameTokens(uint256 gameTokens) private returns (uint256 stableTokensOut) {
    require(gameTokens > 0, "Insufficient Amount");
    (uint256 _stableTokensOut, uint256 feeInWei) = quoteSellGameTokens(gameTokens);
    stableTokensOut = _stableTokensOut;

    // Transfer gameTokens to the liquity pool
    gameToken.transferFrom(msg.sender, address(this), gameTokens);

    // Transfer tokenOut to the user
    stableToken.transfer(msg.sender, stableTokensOut);

    // Update the reserves
    _update(gameToken.balanceOf(address(this)), stableToken.balanceOf(address(this)));

    uint256 newPrice = getPrice();
    emit Sell(msg.sender, gameTokens, stableTokensOut, feeInWei, newPrice);
    emit NewPrice(newPrice);
  }

  function isOpenForSelling() public view returns (bool) {
    uint256 monthsPassed = (block.number - startBlock) / 864000;
    return monthsPassed >= config.closedForMonths;
  }

  function getCommunityFeeInWei(uint256 _amountOut, uint8 stasherLevel) public view returns (uint256 feeInWei) {
    uint256 feePct = getCommunityFeePct(stasherLevel);

    return (_amountOut * feePct) / 100;
  }

  function getCommunityFeePct(uint8 stasherLevel) public view returns (uint256 feeInPct) {
    require(isOpenForSelling(), "Closed for selling");

    uint256 _stasherDiscount = stasherLevel * config.stasherDiscount; // has to be divided by 100

    uint256 monthsPassed = (block.number - startBlock) / 864000;

    if (monthsPassed > config.maxMonths) {
      monthsPassed = config.maxMonths;
    }

    uint256 steepMonths = monthsPassed >= config.steepCurveMonths + config.closedForMonths
      ? config.steepCurveMonths
      : monthsPassed - config.closedForMonths;

    uint256 gradualMonths = monthsPassed >= config.steepCurveMonths + config.closedForMonths
      ? monthsPassed - (config.steepCurveMonths + config.closedForMonths)
      : 0;

    uint256 baseFee = (config.baseCommunityFee - steepMonths * 10) - (gradualMonths * config.stasherDiscount);

    if (_stasherDiscount > baseFee) {
      return 0;
    } else {
      return baseFee - _stasherDiscount;
    }
  }

  function addLiquidity(uint256 amountOfBct, uint256 amountOfStableTokens) external whenNotPaused {
    // get reserves
    (uint256 _gameTokenReserve, uint256 _stableTokenReserve) = getReserves();

    /*
    Check if the ratio of tokens supplied is proportional
    to reserve ratio to satisfy x * y = k for price to not
    change if both reserves are greater than 0
    */
    if (_gameTokenReserve > 0 || _stableTokenReserve > 0) {
      require(
        amountOfBct * _stableTokenReserve == amountOfStableTokens * _gameTokenReserve,
        "Unbalanced Liquidity Provided"
      );
    }

    // Transfer tokens to the liquidity pool
    if (amountOfBct > 0) {
      gameToken.transferFrom(msg.sender, address(this), amountOfBct);
    }
    if (amountOfStableTokens > 0) {
      stableToken.transferFrom(msg.sender, address(this), amountOfStableTokens);
    }

    // Update the reserves
    _update(gameToken.balanceOf(address(this)), stableToken.balanceOf(address(this)));

    uint256 newPrice = getPrice();
    emit LiquidityAdded(msg.sender, amountOfBct, amountOfStableTokens, newPrice);
    emit NewPrice(newPrice);
  }

  // Private function to update liquidity pool reserves
  function _update(uint256 _gameTokenReserve, uint256 _stableTokenReserve) private {
    gameTokenReserve = _gameTokenReserve;
    stableTokenReserve = _stableTokenReserve;
  }

  ////////////////////////////
  // Operator Functions
  function burnBct(uint256 amount) external onlyRole(UPDATER_ROLE) {
    gameToken.burn(amount);
    _update(gameToken.balanceOf(address(this)), stableToken.balanceOf(address(this)));

    emit NewPrice(getPrice());
  }

  function buyAndBurn(uint256 amountIn) external mutex onlyRole(UPDATER_ROLE) returns (uint256 amountBurned) {
    require(amountIn > 0, "Insufficient Amount");
    amountBurned = quoteStableToGameTokens(amountIn);

    stableToken.transferFrom(msg.sender, address(this), amountIn);

    // burn tokenOut
    gameToken.burn(amountBurned);

    // Update the reserves
    _update(gameToken.balanceOf(address(this)), stableToken.balanceOf(address(this)));

    uint256 newPrice = getPrice();
    emit BuyAndBurn(msg.sender, amountIn, amountBurned, newPrice);
    emit NewPrice(newPrice);
  }

  function recoverERC20(address tokenAddress, address to, uint256 amount) external onlyRole(OPERATOR_ROLE) {
    MHIERC20(tokenAddress).transfer(to, amount);
  }

  function recoverERC721(address tokenAddress, address to, uint256 tokenId) external onlyRole(OPERATOR_ROLE) {
    MHIERC721(tokenAddress).safeTransferFrom(address(this), to, tokenId);
  }

  function setGameToken(address _gameToken) external onlyRole(OPERATOR_ROLE) {
    gameToken = MHIERC20(_gameToken);
  }

  function setStableToken(address _stableToken) external onlyRole(OPERATOR_ROLE) {
    stableToken = MHIERC20(_stableToken);
  }

  function setStasher(address _stasherAddress) external onlyRole(OPERATOR_ROLE) {
    stasher = IStasher(_stasherAddress);
  }

  function setStartBlock(uint256 _startBlock) external onlyRole(OPERATOR_ROLE) {
    startBlock = _startBlock;
  }

  function setConfig(Config calldata _config) external onlyRole(OPERATOR_ROLE) {
    config = _config;
  }

  function pause() external onlyRole(OPERATOR_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(OPERATOR_ROLE) {
    _unpause();
  }

  function setBlocklist(address _blocklist) external onlyRole(OPERATOR_ROLE) {
    _setBlocklist(_blocklist);
  }

  function resetBlocklist() external onlyRole(OPERATOR_ROLE) {
    _resetBlocklist();
  }

  function setGasPriceLimit(uint256 _gasLimit) external onlyRole(OPERATOR_ROLE) {
    _setGasPriceLimit(_gasLimit);
  }
}