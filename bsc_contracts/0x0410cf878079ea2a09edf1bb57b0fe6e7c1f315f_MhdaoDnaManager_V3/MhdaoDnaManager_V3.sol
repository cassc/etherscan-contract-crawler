/**
 *Submitted for verification at BscScan.com on 2023-05-10
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

// File contracts/interfaces/IMhdaoFarmTransact.sol

pragma solidity ^0.8.9;

interface IMhdaoFarmTransact {
  function payWithBalance(
    address account,
    uint256 bctAmount,
    uint256[] memory _resources
  ) external returns (uint256[] memory);

  function spendBctFrom(address account, uint256 amount, bool ethereal) external;

  function balanceOf(address playerAddress) external view returns (uint256);

  function addTo(address playerAddress, uint256 amount, uint256[] memory _resources) external;
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

// File contracts/interfaces/IResult.sol

pragma solidity ^0.8.9;

interface IResult {
  function get(address a, uint256 b, uint256 c, uint256 d, uint256 e) external view returns (uint256);
}

// File contracts/features/MhdaoDnaManager_V3.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title MhdaoStore
 * @dev Sells items
 */
contract MhdaoDnaManager_V3 is Initializable, AccessControlUpgradeable, PausableUpgradeable {
  bytes32 internal constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  IResult private __result;

  // Contracts
  struct Contracts {
    MHIERC20 bct;
    MHIERC20 busd;
    IMhdaoFarmTransact farm;
    IMhdaoNft nft;
    IStasher stasher;
    ICommunityPool pool;
  }
  Contracts public contracts;

  struct Collection {
    uint256 id;
    string name;
    address creator;
    uint256[] nftIds;
  }
  uint256 collectionsCount; // total number of collections
  mapping(uint256 => Collection) public collections; // all the existing collections

  // player => slot index => collection id
  mapping(address => mapping(uint256 => uint256)) public collectionsIdsByOwner;
  // player => collection count
  mapping(address => uint256) public playerCollectionsCount;

  uint256 hybridCollectionthreshold;

  mapping(uint256 => address) public resources; // all the possible resources
  mapping(uint256 => uint256) public evolutions; // how many times each nft has evolved
  mapping(uint256 => uint256) public nutsConsumed; // how many nuts have been applied to this nft

  event TraitReroll(address account, uint256 nftId, uint256 chosenTrait);
  event AddExtraTrait(address account, uint256 nftId, uint256 chosenTrait);
  event Evolve(address account, uint256 nftId, uint256 chosenTrait, uint256 evolutions);
  event NutsToBaseFarm(address account, uint256 nftId, uint256 howManyNuts, uint256 newBaseFarm);
  event NewCollection(address account, uint256 collectionId, string name, uint256 type_);
  event ExpandCollection(address account, uint256 collectionId, uint256 type_);
  event ReplaceTrait(
    address account,
    uint256 targetNftId,
    uint256 traitRemovedFromTarget,
    uint256 sacrificeNftId,
    uint256 traitExtractedFromSacrifice
  );

  function initialize(
    address operator,
    address _bct,
    address _busd,
    address _farm,
    address _nft,
    address _stasher,
    address _pool,
    address _result
  ) public initializer {
    __AccessControl_init();
    __Pausable_init();

    _setupRole(DEFAULT_ADMIN_ROLE, operator);
    _setupRole(OPERATOR_ROLE, operator);

    contracts = Contracts({
      bct: MHIERC20(_bct),
      busd: MHIERC20(_busd),
      farm: IMhdaoFarmTransact(_farm),
      nft: IMhdaoNft(_nft),
      stasher: IStasher(_stasher),
      pool: ICommunityPool(_pool)
    });

    __result = IResult(_result);

    contracts.busd.approve(_pool, type(uint256).max);

    hybridCollectionthreshold = 5;
  }

  function traitReroll(uint256 nftId, uint256 chosenTrait) external whenNotPaused {
    IMhdaoNft.NftCharacter memory nft = contracts.nft.getNft(nftId);
    require(contracts.nft.ownerOf(nftId) == msg.sender, "e5");
    require(!contracts.nft.isOnQuest(nftId), "e6");
    require(nft.rarity < 5, "e7");

    // it costs only 1 Gene Therapy (index 11)
    uint256[] memory priceInResources = new uint256[](12);
    priceInResources[11] = 100; // in cents

    _receivePayment(0, priceInResources, false, false, true);

    _doReroll(nftId, chosenTrait, nft.traits.length == 3);

    emit TraitReroll(msg.sender, nftId, chosenTrait);
  }

  function _doReroll(uint256 nftId, uint256 chosenTrait, bool hasThreeTraits) private {
    if (hasThreeTraits) {
      contracts.nft.rerollTraits(nftId);
      uint256[] memory rolledTraits = contracts.nft.traitsOf(nftId);
      uint256[] memory newTraits = new uint256[](3);
      newTraits[0] = chosenTrait;
      newTraits[1] = rolledTraits[0];
      newTraits[2] = rolledTraits[1];
      contracts.nft.setTraits(nftId, newTraits);
    } else {
      contracts.nft.legendaryRerollTraits(nftId, chosenTrait);
    }
  }

  function evolve(
    uint256 nftId,
    uint256 chosenTrait,
    string memory newName,
    string memory newImageUrl
  ) external whenNotPaused {
    IMhdaoNft.NftCharacter memory nft = contracts.nft.getNft(nftId);
    require(contracts.nft.ownerOf(nftId) == msg.sender, "e5");
    require(!contracts.nft.isOnQuest(nftId), "e6");
    require(nft.rarity > 1, "e7"); // Can't evolve commons

    // it costs 1 Gene Therapy (index 11) + 1 DNA of the type of NFT (indexes 14,15,16,17,18)
    uint256[] memory priceInResources = new uint256[](nft.type_ + 14);
    priceInResources[11] = 100; // Gene Therapy in cents
    priceInResources[nft.type_ + 13] = 100; // DNA in cents

    _receivePayment(0, priceInResources, false, false, true);

    // If this is NOT a mythic, we get to reroll traits, and change the name and the image of it
    if (nft.rarity < 5) {
      if (chosenTrait != 0) {
        _doReroll(nftId, chosenTrait, nft.traits.length == 3);
      }

      contracts.nft.setNameAndImage(nftId, newName, newImageUrl);
    }

    // But everyone gets the base farm improved
    // If the NFT has never evolved before, the bonus is 25%, else is 2%
    uint256 evolutionCount = evolutions[nftId];
    uint256 bonus = evolutionCount == 0 ? 25 : 2;
    evolutions[nftId]++;

    // Apply the bonus to the NFT's basefarm:
    uint256 newBaseFarm = (nft.baseFarm * (100 + bonus)) / 100;

    // Set the new base farm
    contracts.nft.setBaseFarm(nftId, newBaseFarm);

    emit Evolve(msg.sender, nftId, chosenTrait, evolutionCount + 1);
  }

  function improveBaseFarmWithNuts(uint256 nftId, uint256 howManyNuts) external whenNotPaused {
    IMhdaoNft.NftCharacter memory nft = contracts.nft.getNft(nftId);
    require(contracts.nft.ownerOf(nftId) == msg.sender, "e5");
    require(nutsConsumed[nftId] + howManyNuts < 301, "max");

    nutsConsumed[nftId] += howManyNuts;

    // it costs 1 Gold Nut (index 10) per 1% increase in base farm
    uint256[] memory priceInResources = new uint256[](11);
    priceInResources[10] = howManyNuts * 100; // in cents

    _receivePayment(0, priceInResources, false, false, true);

    // Apply the bonus to the NFT's basefarm:
    uint256 newBaseFarm = (nft.baseFarm * (100 + howManyNuts)) / 100;

    // Set the new base farm
    contracts.nft.setBaseFarm(nftId, newBaseFarm);

    emit NutsToBaseFarm(msg.sender, nftId, howManyNuts, newBaseFarm);
  }

  function addExtraTrait(uint256 nftId, uint256 chosenTrait) external whenNotPaused {
    IMhdaoNft.NftCharacter memory nft = contracts.nft.getNft(nftId);
    require(contracts.nft.ownerOf(nftId) == msg.sender, "e5");
    require(nft.traits.length == 2, "e22");

    // it costs 25 Magic Mushrooms (index 7) + 1 DNA of the type of NFT (indexes 14,15,16,17,18)
    uint256[] memory priceInResources = new uint256[](nft.type_ + 14);
    priceInResources[7] = 2500; // Magic Mushrooms in cents
    priceInResources[nft.type_ + 13] = 100; // DNA in cents

    _receivePayment(0, priceInResources, false, false, true);

    // We add the new trait to the NFT
    uint256[] memory newTraitList = new uint256[](3);
    newTraitList[0] = nft.traits[0];
    newTraitList[1] = nft.traits[1];
    newTraitList[2] = chosenTrait;
    contracts.nft.setTraits(nftId, newTraitList);

    emit AddExtraTrait(msg.sender, nftId, chosenTrait);
  }

  // Can only extract from epic to replace in legendary,
  // Or extract from legendary to replace in mythic
  function replaceTrait(
    uint256 targetNftId,
    uint256 traitToRemoveInTarget,
    uint256 sacrificeNftId,
    uint256 traitToExtractFromSacrifice
  ) public whenNotPaused {
    // Get the sacrifice NFT
    IMhdaoNft.NftCharacter memory sacrifice = contracts.nft.getNft(sacrificeNftId);

    // Get the target NFT
    IMhdaoNft.NftCharacter memory target = contracts.nft.getNft(targetNftId);

    // Check that both NFTs are owned by the sender
    require(sacrifice.owner == msg.sender);
    require(target.owner == msg.sender);

    // Must be of the same type_, but not a hybrid
    require(sacrifice.type_ == target.type_, "e81");
    require(sacrifice.type_ < 6, "e82");

    // Can only sacrifice a legendary
    require(sacrifice.rarity == 4, "e83");

    // Check the sacrifice NFT has the traitToExtract
    bool hasTraitToExtract;
    for (uint i = 0; i < sacrifice.traits.length; i++) {
      if (sacrifice.traits[i] == traitToExtractFromSacrifice) {
        hasTraitToExtract = true;
        break;
      }
    }
    require(hasTraitToExtract, "e84");

    // Check the target NFT has the traitToRemove
    bool hasTraitToRemove;
    for (uint i = 0; i < target.traits.length; i++) {
      if (target.traits[i] == traitToRemoveInTarget) {
        hasTraitToRemove = true;
        break;
      }
    }
    require(hasTraitToRemove, "e85");

    // Burn the sacrifice NFT
    contracts.nft.burnFrom(msg.sender, sacrificeNftId);

    uint256[] memory priceInResources = new uint256[](19);
    priceInResources[8] = 300; // 3 Power Mangoes
    priceInResources[9] = 300; // 3 Ape Tools
    priceInResources[11] = 300; // 3 Gene Therapy
    priceInResources[target.type_ + 13] = 300; // 3 DNA of the type

    _receivePayment(0, priceInResources, false, false, true);

    // create the traits array for the new NFT
    uint256[] memory newTraitList = new uint256[](target.traits.length);
    for (uint i = 0; i < target.traits.length; i++) {
      if (target.traits[i] == traitToRemoveInTarget) {
        newTraitList[i] = traitToExtractFromSacrifice;
      } else {
        newTraitList[i] = target.traits[i];
      }
    }

    // Set the new traits
    contracts.nft.setTraits(targetNftId, newTraitList);
  }

  function createCollection(
    string memory collectionName,
    string[] memory names,
    uint256 type_,
    uint256 chosenTrait,
    string[] memory imageUrls,
    bool withBusd
  ) external whenNotPaused {
    uint256 stasherLevel = contracts.stasher.levelOf(msg.sender);

    // This function doesn't create Hybrid Collections
    require(type_ > 0 && type_ < 6, "e8");

    // Lvls 9, 10, and 11 can create type 1; Lvls 10 and 11 can create type 2; Lvl 11 can create types 3, 4 and 5
    require(stasherLevel >= 11 || stasherLevel >= type_ + 8, "e9");

    if (withBusd) {
      // We find out how much we should charge in BUSD
      // In BCT: Mouse: 40k; Cat: 80k; Cow: 160k; Elephant: 320k; Ape: 640k;
      uint256 priceInBct = (2 ** (type_ - 1)) * 40000 * 1e18;
      _receivePayment(priceInBct, new uint256[](0), true, false, false);
    } else {
      // it costs 50 DNA of the type of NFT (indexes 14,15,16,17,18)
      uint256[] memory priceInResources = new uint256[](type_ + 14);
      priceInResources[type_ + 13] = 5000; // DNA in cents

      // and it also costs 1k BCT * (2 ** (type_ - 1))
      uint256 priceInBct = 1000 * (2 ** (type_ - 1)) * 1e18; // Mouse: 1k; Cat: 2k; Cow: 4k; Elephant: 8k; Ape: 16k;

      _receivePayment(priceInBct, priceInResources, false, false, false);
    }

    // create the collection itself:
    uint256 initialTokenIdTracker = contracts.nft.tokenIdTracker();
    collectionsCount++;
    _mintMany(names, type_, chosenTrait, imageUrls, initialTokenIdTracker);

    // mount the nftIds array
    uint256[] memory nftIds = new uint256[](3);
    nftIds[0] = initialTokenIdTracker;
    nftIds[1] = initialTokenIdTracker + 1;
    nftIds[2] = initialTokenIdTracker + 2;

    collections[collectionsCount] = Collection({
      id: collectionsCount,
      name: collectionName,
      creator: msg.sender,
      nftIds: nftIds
    });

    // Index the collection
    collectionsIdsByOwner[msg.sender][playerCollectionsCount[msg.sender]] = collectionsCount;
    playerCollectionsCount[msg.sender]++;

    emit NewCollection(msg.sender, collectionsCount, collectionName, type_);
  }

  // Players who already own a collection may expand it, adding 5 more NFTs to it; it costs the same as creating one
  function expandCollection(
    uint256 collectionId,
    string[] memory names,
    uint256 type_,
    uint256 chosenTrait,
    string[] memory imageUrls,
    bool withBusd
  ) external whenNotPaused {
    Collection memory collection = collections[collectionId];
    require(collection.creator == msg.sender, "e10");
    require(collection.nftIds.length < 14, "e11"); // max is 18 NFTs per collection
    require(names.length == 5, "e12"); // we only allow expanding by 5 NFTs at a time

    // This function doesn't create Hybrid Collections
    require(type_ > 0 && type_ < 6, "e8");

    if (withBusd) {
      // We find out how much we should charge in BUSD
      // In BCT: Mouse: 40k; Cat: 80k; Cow: 160k; Elephant: 320k; Ape: 640k;
      uint256 priceInBct = (2 ** (type_ - 1)) * 40000 * 1e18;
      _receivePayment(priceInBct, new uint256[](0), true, false, false);
    } else {
      // it costs 50 DNA of the type of NFT (indexes 14,15,16,17,18)
      uint256[] memory priceInResources = new uint256[](type_ + 14);
      priceInResources[type_ + 13] = 5000; // DNA in cents

      // and it also costs 1k BCT * type_
      uint256 priceInBct = 1000 * (2 ** (type_ - 1)) * 1e18; // Mouse: 1k; Cat: 2k; Cow: 4k; Elephant: 8k; Ape: 16k;

      _receivePayment(priceInBct, priceInResources, false, false, false);
    }

    // create the collection itself:
    uint256 initialTokenIdTracker = contracts.nft.tokenIdTracker();
    _mintMany(names, type_, chosenTrait, imageUrls, initialTokenIdTracker);

    // mount the nftIds array
    uint256 oldLength = collections[collectionId].nftIds.length;
    uint256[] memory nftIds = new uint256[](oldLength + 5);
    for (uint i = 0; i < oldLength; i++) {
      nftIds[i] = collections[collectionId].nftIds[i];
    }
    for (uint i = oldLength; i < oldLength + 5; i++) {
      nftIds[i] = initialTokenIdTracker + i - oldLength;
    }

    collections[collectionId].nftIds = nftIds;

    emit ExpandCollection(msg.sender, collectionId, type_);
  }

  // Get a collection count by address
  function collectionsCountOfOwner(address player) external view returns (uint256) {
    return playerCollectionsCount[player];
  }

  // Get all collections of a given address
  function collectionsOfOwner(address player) external view returns (Collection[] memory) {
    uint256 currentCollectionsCount = playerCollectionsCount[player];
    Collection[] memory result = new Collection[](currentCollectionsCount);
    uint256 counter = 0;

    for (uint256 i = 0; i < currentCollectionsCount; i++) {
      uint256 collectionId = collectionsIdsByOwner[player][i];
      result[counter] = collections[collectionId];
      counter++;
    }

    return result;
  }

  function getCollection(
    uint256 collectionId
  ) external view returns (Collection memory, IMhdaoNft.NftCharacter[] memory) {
    Collection memory collection = collections[collectionId];
    uint256 length = collection.nftIds.length;
    IMhdaoNft.NftCharacter[] memory nfts = new IMhdaoNft.NftCharacter[](length);

    for (uint256 i = 0; i < length; i++) {
      nfts[i] = contracts.nft.getNft(collection.nftIds[i]);
    }

    return (collection, nfts);
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

      // then we use the money to buy BCT at our Community Pool
      contracts.pool.buyAndBurn(priceInBusd);
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

  function _mintMany(
    string[] memory names,
    uint256 type_,
    uint256 chosenTrait,
    string[] memory imageUrls,
    uint256 initialTokenIdTracker
  ) private {
    for (uint i = 0; i < names.length; i++) {
      // create the traits array:
      uint256[] memory traits = new uint256[](2);
      traits[0] = chosenTrait;
      traits[1] = (__result.get(msg.sender, 1, 50, collectionsCount + i, initialTokenIdTracker + i));

      uint256 nextNftId = initialTokenIdTracker + i;

      contracts.nft.mint({
        _name: names[i],
        _imageUrl: imageUrls[i],
        _owner: msg.sender,
        type_: type_,
        _rarity: 4,
        _rank: 0,
        _traits: traits,
        _collection: collectionsCount
      });

      IMhdaoNft.NftCharacter memory nft = contracts.nft.getNft(nextNftId);
      contracts.nft.setBaseFarm(nextNftId, (nft.baseFarm * 125) / 100);
    }
  }

  // How much busd to charge for a given amount of BCT;
  function bctToBusd(uint256 bctAmount) public view returns (uint256) {
    return contracts.pool.getStableTokensIn(bctAmount);
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

  function setResources(address[] memory resourcesAddresses) external onlyRole(OPERATOR_ROLE) {
    for (uint256 i = 0; i < resourcesAddresses.length; i++) {
      resources[i] = resourcesAddresses[i];
    }
  }

  function setCollections(Collection[] memory _collections) external onlyRole(OPERATOR_ROLE) {
    for (uint256 i = 0; i < _collections.length; i++) {
      collections[_collections[i].id] = _collections[i];
    }

    // set the current id
    collectionsCount = _collections[_collections.length - 1].id > collectionsCount
      ? _collections[_collections.length - 1].id
      : collectionsCount;
  }
}

// TODO: extrair trait de um bicho do mesmo tipo e raridade pra substiuir uma trait num outro!