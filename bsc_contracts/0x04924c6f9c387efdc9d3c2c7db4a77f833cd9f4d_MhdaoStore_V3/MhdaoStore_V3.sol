/**
 *Submitted for verification at BscScan.com on 2023-05-04
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

// File contracts/interfaces/IMhdaoFarmMentor.sol

pragma solidity ^0.8.9;

interface IMhdaoFarmMentor {
  function mentorOf(address playerAddress) external view returns (address mentor, uint256 mentorLevel);

  function balanceOf(address playerAddress) external view returns (uint256);

  function balancesOf(
    address playerAddress
  ) external view returns (uint256 bct, uint256 sc, uint256 hc, uint256 ec, uint256 cc, uint256 gn);

  function isSquadOnQuest(uint256 squadIndex) external view returns (bool);

  function payWithBalance(
    address account,
    uint256 amount,
    uint256[] calldata resources
  ) external returns (uint256[] memory remaining);

  function addSquadToPlayer(address playerAddress, uint256 type_) external returns (uint256);

  function increaseSquadSize(uint256 squadId) external;

  function getPlayer(address playerAddress) external view returns (IMhdaoPlayer.Player memory);

  function getSquad(uint256 squadId) external view returns (IMhdaoSquad.Squad memory);

  function setMentorLevel(address playerAddress, uint256 level) external;

  function increaseMerchantLevel(address playerAddress) external;

  function addTo(address playerAddress, uint256 amount, uint256[] memory _resources) external;

  function setSquadTrait(uint256 squadId, uint256 squadTrait) external;

  function setSquadType(uint256 squadId, uint256 type_) external;
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

// File contracts/interfaces/IStasher.sol

pragma solidity ^0.8.9;

interface IStasher {
  function levelOf(address _playerAddress) external view returns (uint8);
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

// File contracts/interfaces/IMhdaoMarketplace.sol

pragma solidity ^0.8.9;

interface IMhdaoMarketplace {
  struct Merchant {
    uint256 auctions;
    uint256 privateSales;
    uint256 sales;
  }

  function merchantLevelOf(address playerAddress) external view returns (uint256);

  function getMerchant(address merchant) external view returns (Merchant memory);
}

// File contracts/features/MhdaoStore_V3.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title MhdaoStore
 * @dev Sells items
 */
contract MhdaoStore_V3 is Initializable, AccessControlUpgradeable, PausableUpgradeable {
  bytes32 internal constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  struct Config {
    uint256 autoReturnRate;
    uint256 cooldownInBlocks;
    uint256 depositBonus;
    uint256 rankUpPrice;
    uint256 agilityUpPrice;
    uint256 extraSquadPrice;
    uint256 mentorPrice;
    uint256 merchantPrice;
    uint256 skillPrice;
    uint256 ritualPrice;
    uint256 maxIntegrationType;
  }
  Config public config;

  // Contracts
  struct Contracts {
    MHIERC20 bct;
    MHIERC20 busd;
    IMhdaoFarmMentor farm;
    IMhdaoNft nft;
    IStasher stasher;
    ICommunityPool pool;
    IMhdaoMarketplace marketplace;
  }
  Contracts public contracts;

  uint256 public totalResources;
  mapping(uint256 => address) public resources;
  mapping(address => bool) public isMintable;

  struct Product {
    uint256 id; // nice to facilitate overwriting products
    uint256 price; // in BCT (when you buy with BUSD, we just convert BCT to BUSD and don't charge resources at all)
    uint256[] priceInResources; // Cheese and the like
    address[] itemsAddresses; // list of NFT/ERC20 addresses
    uint256[] itemsAmounts; // list of NFT/ERC20 amounts
    bool isBusdOnly;
    bool isBctOnly;
  }
  mapping(uint256 => Product) public products;

  event PurchaseDelivered(uint256 productId, address playerAddress);
  event RankUp(uint256 nftId, uint256 ranks, address owner);

  function initialize(
    address operator,
    address _bct,
    address _busd,
    address _farm,
    address _nft,
    address _stasher,
    address _pool,
    address _marketplace
  ) public initializer {
    __AccessControl_init();
    __Pausable_init();

    _setupRole(DEFAULT_ADMIN_ROLE, operator);
    _setupRole(OPERATOR_ROLE, operator);

    contracts = Contracts({
      bct: MHIERC20(_bct),
      busd: MHIERC20(_busd),
      farm: IMhdaoFarmMentor(_farm),
      nft: IMhdaoNft(_nft),
      stasher: IStasher(_stasher),
      pool: ICommunityPool(_pool),
      marketplace: IMhdaoMarketplace(_marketplace)
    });

    config = Config({
      autoReturnRate: 100,
      cooldownInBlocks: 100,
      depositBonus: 3,
      rankUpPrice: 2,
      agilityUpPrice: 5,
      extraSquadPrice: 5000,
      mentorPrice: 550,
      merchantPrice: 100,
      skillPrice: 125,
      ritualPrice: 25,
      maxIntegrationType: 3
    });

    contracts.busd.approve(_pool, type(uint256).max);
  }

  function getProduct(uint256 productId) public view returns (Product memory product) {
    return products[productId];
  }

  function getProductPrice(address account, uint256 productId) public view returns (uint256 bct, uint256 busd) {
    bct = getProductPriceInBct(account, productId);
    busd = bctToBusd(bct);
  }

  function getProductPriceInBct(address account, uint256 productId) public view returns (uint256) {
    uint256 stasherDiscount = contracts.stasher.levelOf(account);
    (, uint256 mentorDiscount) = contracts.farm.mentorOf(account);

    uint256 fullDiscount = products[productId].price -
      (products[productId].price * (stasherDiscount + mentorDiscount)) /
      100;

    return fullDiscount;
  }

  function getRankUpPrices(uint256 type_, uint256 rarity) public view returns (uint256 bct, uint256 resourceCents) {
    uint256 bctPrice = config.rankUpPrice * (2 ** type_ - 1) * (2 ** rarity - 1);
    return (bctPrice * 1E18, bctPrice);
  }

  function getAgilityUpPrices(
    uint256 type_,
    uint256 rarity,
    uint256 currentAgility,
    uint256 levels
  ) public view returns (uint256 bct, uint256 resourceCents) {
    uint256 baseBctPrice = config.agilityUpPrice * (2 ** type_ - 1) * (2 ** rarity - 1);

    uint256 bctPrice;
    for (uint i = currentAgility; i < currentAgility + levels; i++) {
      bctPrice += baseBctPrice * ((i + 1) ** 2);
    }

    return (bctPrice * 1E18, (bctPrice * 10) / 25);
  }

  function getMaxOutRankAgilityPrices(
    uint256 type_,
    uint256 rarity,
    uint256 currentRank,
    uint256 currentAgility
  ) public view returns (uint256 bct, uint256 resourceCents) {
    (uint256 rankUpBct, uint256 rankUpResource) = getRankUpPrices(type_, rarity);
    rankUpBct *= 99 - currentRank;
    rankUpResource *= 99 - currentRank;

    (uint256 agilityUpBct, uint256 agilityUpResource) = getAgilityUpPrices(
      type_,
      rarity,
      currentAgility,
      5 - currentAgility
    );

    return (rankUpBct + agilityUpBct, rankUpResource + agilityUpResource);
  }

  function getExtraSquadPrices(uint256 currentSquads) public view returns (uint256 bct, uint256 resourceCents) {
    uint256 priceInBct = (currentSquads - 3) * config.extraSquadPrice;
    uint256 priceInCheese = currentSquads <= 3 ? 0 : (currentSquads - 4) * 12;

    return (priceInBct * 1E18, priceInCheese * 100);
  }

  function getExtraSlotPrices(
    uint256 currentSize,
    uint256 squadBonus
  ) public pure returns (uint256 bct, uint256 resourceCents) {
    uint256 priceInBct;
    uint256 priceInCheese;

    if (currentSize == 3) {
      priceInBct = 10000;
      priceInCheese = 11;
    } else if (currentSize == 4) {
      priceInBct = 15000;
      priceInCheese = 22;
    } else if (currentSize == 5) {
      priceInBct = 25000;
      priceInCheese = 44;
    }

    priceInBct = (priceInBct * (100 + squadBonus)) / 100;
    priceInCheese = (priceInCheese * (100 + squadBonus)) / 100;

    return (priceInBct * 1E18, priceInCheese * 100);
  }

  function getMentorLevelPrices() public pure returns (uint256 bct, uint256 resourceCents) {
    return (550 * 1E18, 3 * 100);
  }

  function getMerchantLevelPrice(uint256 currentLevel) public pure returns (uint256 nextLevelPriceInBct) {
    return currentLevel * 100 * 1E18;
  }

  function getSkillLevelPrices(
    uint256 rarity,
    uint256 weight,
    uint256 levels
  ) public pure returns (uint256 bct, uint256 resourceCents) {
    uint256 priceInBct = 125 * rarity * weight * levels;

    // resourceCents is exactly 1/100 of the BCT price, so we skip the multiplication by 100; it should be divided by 500 in units, so we just divide it by 5
    return (priceInBct * 1E18, priceInBct / 5);
  }

  function getIntegrationPrices(
    uint256 type_,
    uint256 rarity
  ) public view returns (uint256 bct, uint256 resourceCents) {
    return (config.ritualPrice * type_ * rarity * 1E18, rarity * config.ritualPrice);
  }

  function deposit(uint256 amount) public whenNotPaused {
    require(amount > 10 * 1E18, "<10bct");

    contracts.bct.burnFrom(msg.sender, amount);

    uint256 stasherLevel = contracts.stasher.levelOf(msg.sender);
    (, uint256 mentorLevel) = contracts.farm.mentorOf(msg.sender);

    uint256 bonus = (config.depositBonus + stasherLevel) * 10 + mentorLevel * 5;

    uint256 amountWithBonus = amount + (amount * bonus) / 1000;

    uint256[] memory res = new uint256[](0);
    contracts.farm.addTo(msg.sender, amountWithBonus, res);
  }

  function buyProduct(uint256 productId, bool withBusd) external whenNotPaused {
    Product memory product = products[productId];
    require(product.id != 0, "inv");

    uint256 discountedPriceInBct = getProductPriceInBct(msg.sender, productId);
    _receivePayment(discountedPriceInBct, product.priceInResources, withBusd, product.isBusdOnly, product.isBctOnly);

    for (uint256 i = 0; i < product.itemsAddresses.length; i++) {
      if (isMintable[product.itemsAddresses[i]]) {
        _mintGoods(msg.sender, product.itemsAddresses[i], product.itemsAmounts[i]);
      } else {
        _deliverGoods(msg.sender, product.itemsAddresses[i], product.itemsAmounts[i]);
      }
    }

    emit PurchaseDelivered(productId, msg.sender);
  }

  function buyRankUp(uint256 nftId, uint256 ranks) external whenNotPaused {
    IMhdaoNft.NftCharacter memory nft = contracts.nft.getNft(nftId);
    require(nft.owner == msg.sender, "e5");
    require(nft.rank < 100 - ranks, "e7");

    // get the cost of ranking up according to type and rarity of the NFT
    (uint256 rarity, uint256 type_, ) = contracts.nft.rarityTypeAndSkillsOf(nftId);

    // Multiply rarity and price factors by the basePrice to get the finalPrice
    (uint256 price, uint256 basePriceInResources) = getRankUpPrices(type_, rarity);

    uint256[] memory priceInResources = new uint256[](type_);
    priceInResources[type_ - 1] = basePriceInResources * ranks;

    _receivePayment(price * ranks, priceInResources, false, false, true);

    contracts.nft.setRank(nftId, nft.rank + ranks);

    emit RankUp(nftId, ranks, msg.sender);
  }

  function buyAgilityUp(uint256 nftId, uint256 levels, bool withBusd) external whenNotPaused {
    IMhdaoNft.NftCharacter memory nft = contracts.nft.getNft(nftId);
    require(nft.owner == msg.sender, "e5");
    require(nft.agility + levels < 6, "e7");
    require(levels > 0, "e23");

    // get the cost of agility up according to type and rarity of the NFT
    (uint256 rarity, uint256 type_, ) = contracts.nft.rarityTypeAndSkillsOf(nftId);

    // Multiply rarity and price factors by the basePrice to get the finalPrice
    (uint256 price, uint256 basePriceInResources) = getAgilityUpPrices(type_, rarity, nft.agility, levels);

    uint256[] memory priceInResources = new uint256[](type_);
    priceInResources[type_ - 1] = basePriceInResources;

    _receivePayment(price, priceInResources, withBusd, false, false);

    contracts.nft.setAgility(nftId, nft.agility + levels);
  }

  function buyMaxOutRankAgility(uint256 nftId, bool withBusd) external whenNotPaused {
    IMhdaoNft.NftCharacter memory nft = contracts.nft.getNft(nftId);
    require(nft.owner == msg.sender, "e5");
    require(nft.rank < 99, "e7");
    require(nft.agility < 5, "e7");

    // get the cost of ranking up according to type and rarity of the NFT
    (uint256 rarity, uint256 type_, ) = contracts.nft.rarityTypeAndSkillsOf(nftId);

    // Multiply rarity and price factors by the basePrice to get the finalPrice
    (uint256 price, uint256 basePriceInResources) = getMaxOutRankAgilityPrices(type_, rarity, nft.rank, nft.agility);

    uint256[] memory priceInResources = new uint256[](type_);
    priceInResources[type_ - 1] = basePriceInResources;

    _receivePayment(price, priceInResources, withBusd, false, false);

    contracts.nft.setRank(nftId, 99);
    contracts.nft.setAgility(nftId, 5);
  }

  function buyExtraSquad(bool withBusd) external whenNotPaused {
    IMhdaoPlayer.Player memory player = contracts.farm.getPlayer(msg.sender);
    require(player.squads.length < 20, "e7");

    uint256 stasherLevel = contracts.stasher.levelOf(msg.sender);
    require(player.squads.length - 1 <= stasherLevel || stasherLevel >= 8, "e15");

    (uint256 priceInBct, uint256 priceInCheese) = getExtraSquadPrices(player.squads.length);

    // Always costs Exotic Cheese (index 5)
    uint256[] memory priceInResources = new uint256[](6);
    priceInResources[5] = priceInCheese;

    _receivePayment(priceInBct, priceInResources, withBusd, false, false);

    if ((player.squads.length + 1) % 2 != 0) {
      // it's a mixed squad
      contracts.farm.addSquadToPlayer(msg.sender, 6);
    } else {
      if (player.squads.length == 9 || player.squads.length == 15 || player.squads.length == 19) {
        // it's a Cat squad
        contracts.farm.addSquadToPlayer(msg.sender, 2);
      } else {
        // it's a Mouse squad
        contracts.farm.addSquadToPlayer(msg.sender, 1);
      }
    }
  }

  function buyExtraSlot(uint256 squadId, bool withBusd) external whenNotPaused {
    IMhdaoSquad.Squad memory squad = contracts.farm.getSquad(squadId);
    require(squad.owner == msg.sender, "e5");
    require(squad.size < 6, "e7");

    (uint256 priceInBct, uint256 priceInCheese) = getExtraSlotPrices(squad.size, squad.squadBonus);

    // Always costs Cat Milk (index 6)
    uint256[] memory priceInResources = new uint256[](7);
    priceInResources[6] = priceInCheese;

    _receivePayment(priceInBct, priceInResources, withBusd, false, false);

    contracts.farm.increaseSquadSize(squadId);
  }

  function buyMentorLevel(uint256 levels, bool withBusd) external whenNotPaused {
    IMhdaoPlayer.Player memory player = contracts.farm.getPlayer(msg.sender);
    require(player.mentorLevel + levels <= 10, "e7");

    (uint256 priceInBct, uint256 priceInCheese) = getMentorLevelPrices();

    // Costs only Super Cheese and Glorious Fish (index 0 and 1)
    uint256[] memory priceInResources = new uint256[](2);
    priceInResources[0] = priceInCheese * levels;
    priceInResources[1] = priceInCheese * levels;

    _receivePayment(priceInBct * levels, priceInResources, withBusd, false, false);

    contracts.farm.setMentorLevel(msg.sender, player.mentorLevel + levels);
  }

  function buyMerchantLevel(bool withBusd) external whenNotPaused {
    IMhdaoPlayer.Player memory player = contracts.farm.getPlayer(msg.sender);
    require(player.merchantLevel > 0, "e8");

    IMhdaoMarketplace.Merchant memory merchant = contracts.marketplace.getMerchant(msg.sender);
    require(merchant.privateSales >= (player.merchantLevel - 1) * 3 + 1, "e9");
    if (player.merchantLevel >= 5) {
      require(merchant.auctions >= player.merchantLevel - 4, "e10");
    }

    _receivePayment(getMerchantLevelPrice(player.merchantLevel), new uint256[](0), withBusd, false, false);

    contracts.farm.increaseMerchantLevel(msg.sender);
  }

  function buySkillLevel(uint256 nftId, uint256 skillIndex, uint256 levels, bool withBusd) external whenNotPaused {
    require(contracts.nft.ownerOf(nftId) == msg.sender, "e5");

    (uint256 rarity, uint256 type_, uint256[] memory skills) = contracts.nft.rarityTypeAndSkillsOf(nftId);

    require(skills[skillIndex] + levels <= 5, "e7");

    (uint256 priceInBct, uint256 priceInResource) = getSkillLevelPrices(rarity, skillIndex + 1, levels);
    uint256[] memory priceInResources = new uint256[](11);

    if (skillIndex == 0) {
      // first row of 5 resources (super cheese, shiny fish, groovy grass, happy roots, and sweet bananas)
      priceInResources[type_ - 1] = priceInResource;
    } else if (skillIndex == 1) {
      // second row of 5 resources (exotic cheese, cat milk, magic mushrooms, happy roots, and ape tools)
      priceInResources[type_ + 4] = priceInResource;
    } else if (skillIndex == 2) {
      // The skill is (Extra Farm of Golden Nuts), it costs the same amount in every cheese of that type
      priceInResources[type_ - 1] = priceInResource;
      priceInResources[type_ + 4] = priceInResource;
    } else {
      // The skill is (Extra Farm of Crafting Material), it costs Golden Nuts
      priceInResources[10] = priceInResource;
    }

    _receivePayment(priceInBct, priceInResources, withBusd, false, false);

    skills[skillIndex] = skills[skillIndex] + levels;

    contracts.nft.setSkills(nftId, skills);
  }

  function integrate(uint256[] memory nftIds, bool usePowerMangoes) external whenNotPaused {
    IMhdaoNft.NftCharacter memory target = contracts.nft.getNft(nftIds[0]);
    require(target.owner == msg.sender);
    require(target.rarity <= 4, "e4");

    IMhdaoNft.NftCharacter memory subject1 = contracts.nft.getNft(nftIds[1]);
    require(subject1.owner == msg.sender);
    require(subject1.rarity == target.rarity, "e2");
    require(subject1.type_ == target.type_, "e3");

    uint256 thirdNftId = usePowerMangoes ? 0 : 2;
    IMhdaoNft.NftCharacter memory subject2 = contracts.nft.getNft(nftIds[thirdNftId]);
    require(subject2.owner == msg.sender);
    require(subject2.rarity == target.rarity, "e2");
    require(subject2.type_ == target.type_, "e3");

    uint256 finalRank = (target.rank + subject1.rank + subject2.rank) / 3;
    uint256 finalAgility = (target.agility + subject1.agility + subject2.agility) / 3;
    uint256 finalBaseFarm = (((target.baseFarm + subject1.baseFarm + subject2.baseFarm) / 3) * 17) / 10; // plus 70%
    uint256[] memory finalSkills = new uint256[](4);
    finalSkills[0] = (target.skills[0] + subject1.skills[0] + subject2.skills[0]) / 3;
    finalSkills[1] = (target.skills[1] + subject1.skills[1] + subject2.skills[1]) / 3;
    finalSkills[2] = (target.skills[2] + subject1.skills[2] + subject2.skills[2]) / 3;
    finalSkills[3] = (target.skills[3] + subject1.skills[3] + subject2.skills[3]) / 3;

    contracts.nft.burnFrom(msg.sender, nftIds[1]);

    (uint256 priceInBct, uint256 priceInResource) = getIntegrationPrices(target.type_, target.rarity);
    uint256[] memory priceInResources = new uint256[](19);

    if (usePowerMangoes) {
      // pay and don't burn a second nft
      priceInResources[8] = 300; // 3 Power Mangoes
    } else {
      contracts.nft.burnFrom(msg.sender, nftIds[2]);
    }

    if (target.rarity == 4) {
      require(target.type_ < config.maxIntegrationType, "e7");
      priceInResources[11] = 100; // 1 Gene Therapy
      priceInResources[14 + target.type_] = 100; // 1 DNA above the current type
      _receivePayment(priceInBct, priceInResources, false, false, true);
      contracts.nft.setRarityAndType(target.id, 1, target.type_ + 1, finalBaseFarm);
      contracts.nft.setNameAndImage(target.id, "", "");
    } else {
      priceInResources[target.type_ + 4] = priceInResource; // costs advanced resources of that type
      _receivePayment(priceInBct, priceInResources, false, false, true);
      contracts.nft.setRarityAndType(target.id, target.rarity + 1, target.type_, finalBaseFarm);

      // if the nft had only one trait, give it another random one
      if (target.traits.length == 1) {
        contracts.nft.legendaryRerollTraits(target.id, target.traits[0]);
      } else if (target.traits.length == 0) {
        contracts.nft.rerollTraits(target.id);
      }
    }

    contracts.nft.setRankAgilityAndSkills(target.id, finalRank, finalAgility, finalSkills);
  }

  function extractTrait(uint256 nftId, uint256 traitToExtract, uint256 squadToGetTrait) public whenNotPaused {
    // Get the NFT
    IMhdaoNft.NftCharacter memory target = contracts.nft.getNft(nftId);

    // Check the NFT is owned by the sender
    require(target.owner == msg.sender);

    // Get the squad
    IMhdaoSquad.Squad memory squad = contracts.farm.getSquad(squadToGetTrait);

    // Check the squad is owned by the sender
    require(squad.owner == msg.sender);

    // Cannot be mythic (rarity 5)
    require(target.rarity < 5, "e2");

    // Check the NFT has the traitToExtract
    bool hasTrait;
    for (uint i = 0; i < target.traits.length; i++) {
      if (target.traits[i] == traitToExtract) {
        hasTrait = true;
        break;
      }
    }
    require(hasTrait, "e1");

    // Burn the NFT
    contracts.nft.burnFrom(msg.sender, nftId);

    uint256[] memory priceInResources = new uint256[](9);
    priceInResources[8] = (30 - 5 * target.rarity) * 100; // costs Power Mangoes

    _receivePayment(0, priceInResources, false, false, true);

    contracts.farm.setSquadTrait(squadToGetTrait, traitToExtract);
  }

  function setSquadType(uint256 squadId, uint256 newType) public whenNotPaused {
    IMhdaoSquad.Squad memory squad = contracts.farm.getSquad(squadId);
    require(squad.owner == msg.sender, "e1");

    uint256[] memory priceInResources = new uint256[](10);
    priceInResources[9] = 200; // 2 Ape Tools

    _receivePayment(0, priceInResources, false, false, true);

    contracts.farm.setSquadType(squadId, newType);
  }

  //#############
  // Private functions
  function _receivePayment(
    uint256 priceInBct,
    uint256[] memory priceInResources,
    bool withBusd,
    bool isBusdOnly,
    bool isBctOnly
  ) private {
    if (withBusd) {
      require(!isBctOnly, "e11");
      // We find out how much we should charge in BUSD
      uint256 priceInBusd = bctToBusd(priceInBct);

      // If the payment is in BUSD, we just charge the user
      contracts.busd.transferFrom(msg.sender, address(this), priceInBusd);

      // then we use part of the money to buy BCT at PancakeSwap
      uint256 liquidityShare = (config.autoReturnRate * priceInBusd) / 100;
      contracts.pool.buyAndBurn(liquidityShare);
    } else {
      require(!isBusdOnly, "e12");

      // Try to pay with ingame balances and get the remaining costs
      uint256[] memory remainingResourcesToPay = contracts.farm.payWithBalance(
        msg.sender,
        priceInBct,
        priceInResources
      );

      // If there are still resources to pay, we try to pay with BCT
      if (remainingResourcesToPay[0] > 0) {
        contracts.bct.burnFrom(msg.sender, remainingResourcesToPay[0]);
      }

      for (uint i = 1; i < remainingResourcesToPay.length; i++) {
        if (remainingResourcesToPay[i] > 0) {
          MHIERC20(resources[i - 1]).burnFrom(msg.sender, remainingResourcesToPay[i]);
        }
      }
    }
  }

  // How much busd to charge for a given amount of BCT;
  function bctToBusd(uint256 bctAmount) public view returns (uint256) {
    return contracts.pool.getStableTokensIn(bctAmount);
  }

  function _deliverGoods(address to, address what, uint256 amount) private {
    MHIERC20(what).transfer(to, amount);
  }

  function _mintGoods(address to, address what, uint256 amount) private {
    MHIERC20(what).mint(to, amount);
  }

  //######################
  // OPERATOR functions
  function recoverERC20(address tokenAddress, address to, uint256 amount) external onlyRole(OPERATOR_ROLE) {
    MHIERC20(tokenAddress).transfer(to, amount);
  }

  function recoverERC721(address tokenAddress, address to, uint256 tokenId) external onlyRole(OPERATOR_ROLE) {
    MHIERC721(tokenAddress).safeTransferFrom(address(this), to, tokenId);
  }

  function pause() external onlyRole(OPERATOR_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(OPERATOR_ROLE) {
    _unpause();
  }

  function setMintedProducts(
    address[] calldata mintedProductsAddresses,
    bool[] calldata minted
  ) external onlyRole(OPERATOR_ROLE) {
    for (uint256 i = 0; i < mintedProductsAddresses.length; i++) {
      isMintable[mintedProductsAddresses[i]] = minted[i];
    }
  }

  function setProducts(Product[] memory _products) external onlyRole(OPERATOR_ROLE) {
    for (uint256 i = 0; i < _products.length; i++) {
      products[_products[i].id] = _products[i];
    }
  }

  function setAutoReturnRate(uint256 _autoReturnRate) external onlyRole(OPERATOR_ROLE) {
    config.autoReturnRate = _autoReturnRate;
  }

  function setConfig(Config memory _config) external onlyRole(OPERATOR_ROLE) {
    config = _config;
  }

  function setResources(
    address[] memory resourcesAddresses,
    bool[] memory _isMintable
  ) external onlyRole(OPERATOR_ROLE) {
    for (uint256 i = 0; i < resourcesAddresses.length; i++) {
      resources[i] = resourcesAddresses[i];
      isMintable[resourcesAddresses[i]] = _isMintable[i];
    }

    totalResources = resourcesAddresses.length;
  }
}