/**
 *Submitted for verification at Etherscan.io on 2022-12-12
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: TMOwnerAdminSettings.sol



pragma solidity >=0.8.0 <0.9.0;


contract TMOwnerAdminSettings is Context {

  address internal _owner;

  struct Admin {
        address WA;
        uint8 roleLevel;
  }
  mapping(address => Admin) internal admins;

  mapping(address => bool) internal isAdminRole;

  event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(_msgSender() == getOwner() ||
            admins[_msgSender()].roleLevel == 1 
            );
    _;
  }

  modifier onlyDev() {
    require(admins[_msgSender()].roleLevel == 1);
    _;
  }

  modifier onlyAntiBot() {
    require(admins[_msgSender()].roleLevel == 1 ||
            admins[_msgSender()].roleLevel == 2
            );
    _;
  }

  modifier onlyAdminRoles() {
    require(_msgSender() == getOwner() ||
            admins[_msgSender()].roleLevel == 1 ||
            admins[_msgSender()].roleLevel == 2 || 
            admins[_msgSender()].roleLevel == 5
            );
    _;
  }

  constructor() {
    _owner = _msgSender();
    _setNewAdmins(_msgSender(), 1);
  }
    //DON'T FORGET TO SET Locker AND Marketing(AND ALSO WHITELISTING Marketing) AFTER DEPLOYING THE CONTRACT!!!
    //DON'T FORGET TO SET ADMINS!!

  //Owner and Admins
  //Set New Owner. Can be done only by the owner.
  function setNewOwner(address newOwner) external onlyOwner {
    require(newOwner != _owner, "This address is already the owner!");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

    //Sets up admin accounts.
    function setNewAdmin(address _address, uint8 _roleLevel) external onlyOwner {
      if(_roleLevel == 1) {
        require(admins[_msgSender()].roleLevel == 1, "You are not authorized to set a dev");
      }
      
      _setNewAdmins(_address, _roleLevel);
    }

    function _setNewAdmins(address _address, uint8 _roleLevel) internal {

            Admin storage newAdmin = admins[_address];
            newAdmin.WA = _address;
            newAdmin.roleLevel = _roleLevel;
 
        isAdminRole[_address] = true;
    } 
/*
    function verifyAdminMember(address adr) public view returns(bool YoN, uint8 role_) {
        uint256 iterations = 0;
        while(iterations < adminAccounts.length) {
            if(adminAccounts[iterations] == adr) {return (true, admins[adminAccounts[iterations]].role);}
            iterations++;
        }
        return (false, 0);
    }
*/
    function removeRole(address[] calldata adr) external onlyOwner {
        for(uint i=0; i < adr.length; i++) {
            _removeRole(adr[i]);
        }
    }

    function renounceMyRole(address adr) external onlyAdminRoles {
        require(adr == _msgSender(), "AccessControl: can only renounce roles for self");
        require(isAdminRole[adr] == true, "You do not have an admin role");
        _removeRole(adr);
    }

    function _removeRole(address adr) internal {

          delete admins[adr];
  
        isAdminRole[adr] = false;
    }
  
  //public
    function whoIsOwner() external view returns (address) {
      return getOwner();
    }

    function verifyAdminMember(address adr) external view returns (bool) {
      return isAdminRole[adr];
    }

    function showAdminRoleLevel(address adr) external view returns (uint8) {
      return admins[adr].roleLevel;
    }

  //internal

    function getOwner() internal view returns (address) {
      return _owner;
    }

}
// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
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
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                require(isContract(target), "Address: call to non-contract");
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

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// File: TokenManager.sol



pragma solidity >=0.8.0 <0.9.0;

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function allPairs(uint) external view returns (address lpPair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface ITokenFunctions {
    function verifyAdminMember(address adr) external view returns (bool);
    function _addNewRouterAndPair(address _routerCA, address _lpPairCA, address _pairedCoinCA) external;
    function _updateRouterAndPair(address _routerCA, address _lpPairCA, bool _switch) external;
    function updateTaxes(uint16 buyFee, uint16 sellFee, uint16 transferFee) external returns (bool);
    function updateRatios(uint32 liquidity, uint32 marketing, uint32 reflection) external returns (bool);
    function updateBuyTaxRatios(uint32 liquidity, uint32 marketing, uint32 reflection) external returns (bool);
    function updateSellTaxRatios(uint32 liquidity, uint32 marketing, uint32 reflection) external returns (bool);
    function updateTransferTaxRatios(uint32 liquidity, uint32 marketing, uint32 reflection) external returns (bool);
    function updateContractSwapEnabled(address pairCA, bool swapEnabled) external returns (bool);
    function updateContractPriceImpactSwapEnabled(address pairCA, bool priceImpactSwapEnabled) external returns (bool);
    function updateContractSwapSettings(address pairCA, uint256 _swapThreshold, uint256 _swapAmount) external returns (bool);
    function updateContractPriceImpactSwapSettings(address pairCA, uint8 priceImpactSwapBps) external returns (bool);
}




contract TokenManager is TMOwnerAdminSettings {
//===============================================================================================================
//Common Variables
    //Library
        using EnumerableSet for EnumerableSet.AddressSet;
        using Address for address;

    IRouter02 private dexRouter;

    mapping (address => EnumerableSet.AddressSet) _lpPairs;

    mapping (address => bool) dexRouters;

    mapping (address => bool) lpPairs;

    //LP Pairs
    struct LPPair {
        address tokenCA;
        address dexCA;
        address pairedCoinCA;
        bool tradingEnabled;
        bool liqAdded;
        bool contractSwapEnabled;
        bool piContractSwapEnabled;
        uint8 piSwapBps;
        uint32 tradingEnabledBlock;
        uint48 tradingEnabledTime;
        uint256 swapThreshold;
        uint256 swapAmount;
        uint256 tokentTotal;        
    }
    mapping(address => LPPair) public lppairs;

//End of Common Variables
//===============================================================================================================

//===============================================================================================================
//Dex Manager Variables
    //Library
        using Address for address;

    ITokenFunctions private managingToken;

    mapping (address => bool) managingTokens;
    mapping (address => bool) confirmedTokens;
    mapping (address => bool) initialTaxSetup;
    mapping (address => bool) lpPairedCoins;

    //Routers
    struct DexRouter {
        address tokenCA;
        IRouter02 dexCA;
        bool enableAggregate;
    }
    mapping(address => DexRouter) public dexrouters;

    event NewDexRouter(address tokenCA, address dexRouterCA);
    event NewLPPair(address tokenCA, address dexRouterCA, address LPPairCA, address pairedCoinCA);
    event DexRouterStatusUpdated(address tokenCA, address dexRouterCA, bool status);
    event LPPairStatusUpdated(address tokenCA, address dexRouterCA, address LPPairCA, address pairedCoinCA, bool status);

//Fee Variables

    struct Fees {
        uint16 buyFee;
        uint16 sellFee;
        uint16 transferFee;
    }

    mapping(address => Fees) public _fees;
/*
        Fees public _taxRates = Fees({
        buyFee: 400,
        sellFee: 400,
        transferFee: 0
        });
*/

    struct Ratios {
        uint32 liquidity;
        uint32 marketing;
        uint32 reflection;
        uint32 totalSwap;
    }
      /*
      Ratios mapping legend:
        1 - _ratios
        2 - _ratiosBuy
        4 - _ratiosSell
        8 - _ratiosTransfer
      */
    mapping(address => mapping (uint8 => Ratios)) public _tokenTaxRatios;


/*
    Ratios public _ratios = Ratios({
        liquidity: 200,
        marketing: 200,
        reflection: 0,
        totalSwap: 400
        });

    Fees private _taxRatesActive = Fees({
        buyFee: 400,
        sellFee: 400,
        transferFee: 0
        });

    Ratios private _ratiosActive = Ratios({
        liquidity: 200,
        marketing: 200,
        reflection: 0,
        totalSwap: 400
        });
*/
/*
    Ratios private _ratiosBuy = Ratios({
        liquidity: 200,
        marketing: 200,
        reflection: 0,
        totalSwap: 400
        });

    Ratios private _ratiosSell = Ratios({
        liquidity: 200,
        marketing: 200,
        reflection: 0,
        totalSwap: 400
        });

    Ratios private _ratiosTransfer = Ratios({
        liquidity: 200,
        marketing: 200,
        reflection: 0,
        totalSwap: 400
        });
*/
/*
    Ratios private _ratiosZero = Ratios({
        liquidity: 0,
        marketing: 0,
        reflection: 0,
        totalSwap: 0
        });

    Ratios private _ratiosProtection = Ratios({
        liquidity: 200,
        marketing: 9799,
        reflection: 0,
        totalSwap: 9999
        });
*/
    uint16 constant public maxBuyTaxes = 2000;
    uint16 constant public maxSellTaxes = 2000;
    uint16 constant public maxTransferTaxes = 2000;
    uint16 constant public maxRoundtripFee = 3000;
    uint16 constant masterTaxDivisor = 10000;

    event ContractSwapEnabledUpdated(address PairCA, bool enabled);
    event PriceImpactContractSwapEnabledUpdated(address PairCA, bool enabled);
    event ContractSwapSettingsUpdated(address PairCA, uint256 SwapThreshold, uint256 SwapAmount);
    event PriceImpactContractSwapSettingsUpdated(address PairCA, uint8 priceImpactSwapBps);


  modifier onlyAuthorized() {
    require(_msgSender() == address(this) ||
            _msgSender() == getOwner() ||
            admins[_msgSender()].roleLevel == 1
            );
    _;
  }

  modifier onlyDMAuthorized() {
    require(_msgSender() == address(this) ||
            _msgSender() == getOwner() ||
            admins[_msgSender()].roleLevel == 1 ||
            managingTokens[_msgSender()]
            );
    _;
  }


//===============================================================================================================
//Token dexManager Authorize
    function authorizeDM(address _tokenAddr) external {
        managingTokens[_tokenAddr] = true;
    }
//===============================================================================================================

//===============================================================================================================
//Dex Router and LPPair Manager Functions

    function setNewRouterAndPair(address _tokenAddr, address _routerAddr, bool _LPwithETH_ToF, address _LPTargetCoinCA, uint256 _tokentTotal) external onlyDMAuthorized returns (bool, address, address) {
        return _setNewRouterAndPair(_tokenAddr, _routerAddr, _LPwithETH_ToF, _LPTargetCoinCA, _tokentTotal);
    }

    function _setNewRouterAndPair(address _tokenAddr, address _routerAddr, bool _LPwithETH_ToF, address _LPTargetCoinCA, uint256 _tokentTotal) internal returns (bool, address, address) {
        if (dexRouters[_routerAddr] == false) {

            DexRouter storage router = dexrouters[_routerAddr];
            router.tokenCA = _tokenAddr;
            router.dexCA = IRouter02(_routerAddr);
            router.enableAggregate = true;

            dexRouters[_routerAddr] = true;

            emit NewDexRouter(_tokenAddr, _routerAddr);

            return _setNewPair(_tokenAddr, _routerAddr, _LPwithETH_ToF, _LPTargetCoinCA, _tokentTotal);
        } else {
            dexRouter = IRouter02(_routerAddr);
            address get_pair;
            if (_LPwithETH_ToF){
                _LPTargetCoinCA = dexRouter.WETH();
                get_pair = IFactoryV2(dexRouter.factory()).getPair(_LPTargetCoinCA, _tokenAddr);
                require(lpPairs[get_pair] == false, "Pair already exists!");

                return _setNewPair(_tokenAddr, _routerAddr, _LPwithETH_ToF, _LPTargetCoinCA, _tokentTotal);
            } else {
                get_pair = IFactoryV2(dexRouter.factory()).getPair(_LPTargetCoinCA, _tokenAddr);
                require(lpPairs[get_pair] == false, "Pair already exists!");

                return _setNewPair(_tokenAddr, _routerAddr, _LPwithETH_ToF, _LPTargetCoinCA, _tokentTotal);
            }
        }
    }

    function _setNewPair(address _tokenAddr, address _routerAddr, bool _LPwithETH_ToF, address _LPTargetCoinCA, uint256 _tokentTotal) internal returns (bool, address, address) {
        dexRouter = IRouter02(_routerAddr);
        address lpPairCA;
        address get_pair;

        if (_LPwithETH_ToF){
            _LPTargetCoinCA = dexRouter.WETH();
            get_pair = IFactoryV2(dexRouter.factory()).getPair(_LPTargetCoinCA, _tokenAddr);
            if (get_pair.isContract()){
                lpPairCA = get_pair;
            } else {
                lpPairCA = IFactoryV2(dexRouter.factory()).createPair(_LPTargetCoinCA, _tokenAddr);
            }
        } else {
            get_pair = IFactoryV2(dexRouter.factory()).getPair(_LPTargetCoinCA, _tokenAddr);
            if (get_pair.isContract()){
                lpPairCA = get_pair;
            } else {
                lpPairCA = IFactoryV2(dexRouter.factory()).createPair(_LPTargetCoinCA, _tokenAddr);
            }            
        }

        LPPair storage lpPair = lppairs[lpPairCA];
        lpPair.tokenCA = _tokenAddr;
        lpPair.dexCA = _routerAddr;
        lpPair.pairedCoinCA = _LPTargetCoinCA;
        lpPair.tradingEnabled = false;
        lpPair.liqAdded = false;
        lpPair.contractSwapEnabled = false;
        lpPair.piContractSwapEnabled = false;
        lpPair.piSwapBps = 0;
        lpPair.tradingEnabledBlock = 0;
        lpPair.tradingEnabledTime = 0;
        lpPair.swapThreshold = 0;
        lpPair.swapAmount = 0;
        lpPair.tokentTotal = _tokentTotal;

        lpPairs[lpPairCA] = true;
        lpPairedCoins[_LPTargetCoinCA] = true;
        
        if(confirmedTokens[_tokenAddr]) {
            managingToken = ITokenFunctions(_tokenAddr);
            managingToken._addNewRouterAndPair(_routerAddr, lpPairCA, _LPTargetCoinCA);
        } else {
            confirmedTokens[_tokenAddr] = true;
        }

        _addLPPair(_routerAddr, lpPairCA);
        _addLPPair(_tokenAddr, lpPairCA);

        emit NewLPPair(_tokenAddr, _routerAddr, lpPairCA, _LPTargetCoinCA);

        return (true, lpPairCA, _LPTargetCoinCA);
    }

    function setLaunch(address _lpPairCA, uint8 _piSwapBps, uint32 _tradingEnabledBlock, uint48 _tradingEnabledTime, uint256 _swapThreshold, uint256 _swapAmount) external onlyDMAuthorized returns (bool) {
        require(lpPairs[_lpPairCA], "This pair is not authorized to use this function.");
        LPPair storage lpPair = lppairs[_lpPairCA];
        lpPair.tradingEnabled = true;
        lpPair.liqAdded = true;
        lpPair.contractSwapEnabled = true;
        lpPair.piContractSwapEnabled = true; 
        lpPair.piSwapBps = _piSwapBps;
        lpPair.tradingEnabledBlock = _tradingEnabledBlock;
        lpPair.tradingEnabledTime = _tradingEnabledTime;
        lpPair.swapThreshold = _swapThreshold;
        lpPair.swapAmount = _swapAmount;

        return true;
    }

    function _addLPPair(address tokenOrRouterCA, address _lpPairCA) internal {
        _lpPairs[tokenOrRouterCA].add(_lpPairCA);
    }

    function _removeLPPair(address tokenOrRouterCA, address _lpPairCA) external onlyAuthorized {
        _lpPairs[tokenOrRouterCA].remove(_lpPairCA);
    }

    /**
     * @dev Returns the number of LPPairs that belongs to `tokenOrRouterCA`. Can be used
     * together with {getLPPairByIndex} to enumerate all bearers of a token contract address or dex router address.
     */
    function getLPPairCountByTokenOrRouterCA(address tokenOrRouterCA) public view onlyAuthorized returns (uint256) {
        return _lpPairs[tokenOrRouterCA].length();
    }

    function getLPPairByIndex(address tokenOrRouterCA, uint256 index) public view onlyAuthorized returns (address) {
        return _lpPairs[tokenOrRouterCA].at(index);
    }

    function getAllLPPairsByTokenOrRouterCA(address tokenOrRouterCA) public view onlyAuthorized returns (address[] memory) {
        return _lpPairs[tokenOrRouterCA].values();
    }


    function setRouterTrading(address _routerAddr, bool _switch) external onlyDMAuthorized returns (address tokenCA_, address routerAddr_, uint numUpdatedPairs, bool status) {
        dexrouters[_routerAddr].enableAggregate = _switch;
        dexRouters[_routerAddr] = _switch;

        emit DexRouterStatusUpdated(dexrouters[_routerAddr].tokenCA, _routerAddr, _switch);
        uint i;
        for(i=0; i < getLPPairCountByTokenOrRouterCA(_routerAddr); i++) {
            setPairTrading(getLPPairByIndex(_routerAddr, i), _switch);
        }
        return (dexrouters[_routerAddr].tokenCA, _routerAddr, i, _switch);
    }

    function setPairTrading(address _lpPairAddr, bool _switch) public onlyDMAuthorized
    returns (address tokenCA_, address routerAddr_, address pairAddr_, address pairedCoinCA_, bool status) {

        lppairs[_lpPairAddr].tradingEnabled = _switch;
        lpPairs[_lpPairAddr] = _switch;

        emit LPPairStatusUpdated(lppairs[_lpPairAddr].tokenCA, lppairs[_lpPairAddr].dexCA, _lpPairAddr, lppairs[_lpPairAddr].pairedCoinCA, _switch);

        managingToken = ITokenFunctions(lppairs[_lpPairAddr].tokenCA);
        managingToken._updateRouterAndPair(lppairs[_lpPairAddr].dexCA, _lpPairAddr, _switch);

        return (lppairs[_lpPairAddr].tokenCA, lppairs[_lpPairAddr].dexCA, _lpPairAddr, lppairs[_lpPairAddr].pairedCoinCA, _switch);
    }

    function updatePairContractSwapSettings(address pairAddr, uint256 swapThreshold, uint256 swapAmount) external onlyDMAuthorized returns (bool) {
        require(lpPairs[pairAddr], "This pair is not authorized to use this function.");
        lppairs[pairAddr].swapThreshold = swapThreshold;
        lppairs[pairAddr].swapAmount = swapAmount;
        return true;
    }

    function loadLPPairInfo(address lpPairCA) external view returns (address, address, bool, bool, uint32, uint48, uint256, uint256) {
        
        LPPair memory lpPair = lppairs[lpPairCA];

        return (lpPair.dexCA, lpPair.pairedCoinCA, lpPair.tradingEnabled, lpPair.liqAdded,
        lpPair.tradingEnabledBlock, lpPair.tradingEnabledTime, lpPair.swapThreshold, lpPair.swapAmount);
    }

//===============================================================================================================
//Fee Settings

    //Set Fees and its Ratios
    function setTaxes(address tokenCA, uint16 buyFee, uint16 sellFee, uint16 transferFee) external onlyDMAuthorized returns (bool) {
        require(managingTokens[tokenCA], "This token is not authorized to use this function.");
        require(buyFee <= maxBuyTaxes
                && sellFee <= maxSellTaxes
                && transferFee <= maxTransferTaxes,
                "Cannot exceed maximums.");
        require(buyFee + sellFee <= maxRoundtripFee, "Cannot exceed roundtrip maximum.");
        bool confirmed = false;

        if(_fees[tokenCA].buyFee != buyFee) {
            _fees[tokenCA].buyFee = buyFee;
            confirmed = updateBuyTaxUsingRatio(tokenCA);
            require(confirmed, "Buy tax update failed");
        }
        
        if(_fees[tokenCA].sellFee != sellFee) {
            _fees[tokenCA].sellFee = sellFee;
            confirmed = updateSellTaxUsingRatio(tokenCA);
            require(confirmed, "Sell tax update failed");
        }
        
        if(_fees[tokenCA].transferFee != transferFee) {
            _fees[tokenCA].transferFee = transferFee;
            confirmed = updateTransferTaxUsingRatio(tokenCA);
            require(confirmed, "Transfer tax update failed");
        }

        return confirmed;
    }
      /*
      Ratios mapping legend (BuyOrSellOrTrnsfr):
        1 - _ratios
        2 - _ratiosBuy
        4 - _ratiosSell
        8 - _ratiosTransfer
      */
    function setRatios(address tokenCA, uint16 liquidity, uint16 marketing, uint16 reflection) external onlyDMAuthorized returns (bool) {
        require(managingTokens[tokenCA], "This token is not authorized to use this function.");
        bool confirmed = false;
        _tokenTaxRatios[tokenCA][1].totalSwap = liquidity + marketing + reflection;

        if(_tokenTaxRatios[tokenCA][1].liquidity != liquidity) {
            _tokenTaxRatios[tokenCA][1].liquidity = liquidity;
            confirmed = updateBuyTaxUsingRatio(tokenCA);
            require(confirmed, "Buy tax update failed");
            confirmed = updateSellTaxUsingRatio(tokenCA);
            require(confirmed, "Sell tax update failed");
            confirmed = updateTransferTaxUsingRatio(tokenCA);
            require(confirmed, "Transfer tax update failed");
        }
        
        if(_tokenTaxRatios[tokenCA][1].marketing != marketing) {
            _tokenTaxRatios[tokenCA][1].marketing = marketing;
            confirmed = updateBuyTaxUsingRatio(tokenCA);
            require(confirmed, "Buy tax update failed");
            confirmed = updateSellTaxUsingRatio(tokenCA);
            require(confirmed, "Sell tax update failed");
            confirmed = updateTransferTaxUsingRatio(tokenCA);
            require(confirmed, "Transfer tax update failed");
        }
        
        if(_tokenTaxRatios[tokenCA][1].reflection != reflection) {
            _tokenTaxRatios[tokenCA][1].reflection = reflection;
            confirmed = updateBuyTaxUsingRatio(tokenCA);
            require(confirmed, "Buy tax update failed");
            confirmed = updateSellTaxUsingRatio(tokenCA);
            require(confirmed, "Sell tax update failed");
            confirmed = updateTransferTaxUsingRatio(tokenCA);
            require(confirmed, "Transfer tax update failed");
        }
        return confirmed;
    }

    function updateBuyTaxUsingRatio(address tokenCA) private returns (bool) {
        managingToken = ITokenFunctions(tokenCA);
        bool updated = false;
        {
        _tokenTaxRatios[tokenCA][2].liquidity = _fees[tokenCA].buyFee * _tokenTaxRatios[tokenCA][1].liquidity / _tokenTaxRatios[tokenCA][1].totalSwap;
        _tokenTaxRatios[tokenCA][2].marketing = _fees[tokenCA].buyFee * _tokenTaxRatios[tokenCA][1].marketing / _tokenTaxRatios[tokenCA][1].totalSwap;
        _tokenTaxRatios[tokenCA][2].reflection = _fees[tokenCA].buyFee * _tokenTaxRatios[tokenCA][1].reflection / _tokenTaxRatios[tokenCA][1].totalSwap;
        _tokenTaxRatios[tokenCA][2].totalSwap = _tokenTaxRatios[tokenCA][2].liquidity + _tokenTaxRatios[tokenCA][2].marketing + _tokenTaxRatios[tokenCA][2].reflection;
        }
        
        if(confirmedTokens[tokenCA]) {
            updated = managingToken.updateBuyTaxRatios(_tokenTaxRatios[tokenCA][2].liquidity, _tokenTaxRatios[tokenCA][2].marketing, _tokenTaxRatios[tokenCA][2].reflection);
            require(updated, "Buy Tax Update failed");
            return updated;
        } else {
            return true;
        }
    }

    function updateSellTaxUsingRatio(address tokenCA) private returns (bool) {
        managingToken = ITokenFunctions(tokenCA);
        bool updated = false;
        {
        _tokenTaxRatios[tokenCA][4].liquidity = _fees[tokenCA].sellFee * _tokenTaxRatios[tokenCA][1].liquidity / _tokenTaxRatios[tokenCA][1].totalSwap;
        _tokenTaxRatios[tokenCA][4].marketing = _fees[tokenCA].sellFee * _tokenTaxRatios[tokenCA][1].marketing / _tokenTaxRatios[tokenCA][1].totalSwap;
        _tokenTaxRatios[tokenCA][4].reflection = _fees[tokenCA].sellFee * _tokenTaxRatios[tokenCA][1].reflection / _tokenTaxRatios[tokenCA][1].totalSwap;
        _tokenTaxRatios[tokenCA][4].totalSwap = _tokenTaxRatios[tokenCA][4].liquidity + _tokenTaxRatios[tokenCA][4].marketing + _tokenTaxRatios[tokenCA][4].reflection;
        }
        
        if(confirmedTokens[tokenCA]) {
            updated = managingToken.updateSellTaxRatios(_tokenTaxRatios[tokenCA][4].liquidity, _tokenTaxRatios[tokenCA][4].marketing, _tokenTaxRatios[tokenCA][4].reflection);
            require(updated, "Sell Tax Update failed");
            return updated;
        } else {
            return true;
        }
    }

    function updateTransferTaxUsingRatio(address tokenCA) private returns (bool) {
        managingToken = ITokenFunctions(tokenCA);
        bool updated = false;
        {
        _tokenTaxRatios[tokenCA][8].liquidity = _fees[tokenCA].transferFee * _tokenTaxRatios[tokenCA][1].liquidity / _tokenTaxRatios[tokenCA][1].totalSwap;
        _tokenTaxRatios[tokenCA][8].marketing = _fees[tokenCA].transferFee * _tokenTaxRatios[tokenCA][1].marketing / _tokenTaxRatios[tokenCA][1].totalSwap;
        _tokenTaxRatios[tokenCA][8].reflection = _fees[tokenCA].transferFee * _tokenTaxRatios[tokenCA][1].reflection / _tokenTaxRatios[tokenCA][1].totalSwap;
        _tokenTaxRatios[tokenCA][8].totalSwap = _tokenTaxRatios[tokenCA][8].liquidity + _tokenTaxRatios[tokenCA][8].marketing + _tokenTaxRatios[tokenCA][8].reflection;
        }
        
        if(confirmedTokens[tokenCA]) {
            updated = managingToken.updateTransferTaxRatios(_tokenTaxRatios[tokenCA][8].liquidity, _tokenTaxRatios[tokenCA][8].marketing, _tokenTaxRatios[tokenCA][8].reflection);
            require(updated, "Transfer Tax Update failed");
            return updated;
        } else {
            return true;
        }
    }

//Contract Swap Settings

    function setContractSwapEnabled(address pairCA, bool swapEnabled) external onlyDMAuthorized {
        require(lppairs[pairCA].contractSwapEnabled != swapEnabled, "Already set at the desired state.");
        lppairs[pairCA].contractSwapEnabled = swapEnabled;

        bool checked;
        managingToken = ITokenFunctions(lppairs[pairCA].tokenCA);
        checked = managingToken.updateContractSwapEnabled(pairCA, swapEnabled);

        if(!checked) {
            revert();
        } else {
            emit ContractSwapEnabledUpdated(pairCA, swapEnabled);
        }
    }

    function setContractPriceImpactSwapEnabled(address pairCA, bool priceImpactSwapEnabled) external onlyDMAuthorized {
        require(lppairs[pairCA].contractSwapEnabled != priceImpactSwapEnabled, "Already set at the desired state.");
        lppairs[pairCA].piContractSwapEnabled = priceImpactSwapEnabled;

        bool checked;
        managingToken = ITokenFunctions(lppairs[pairCA].tokenCA);
        checked = managingToken.updateContractPriceImpactSwapEnabled(pairCA, priceImpactSwapEnabled);

        if(!checked) {
            revert();
        } else {
            emit PriceImpactContractSwapEnabledUpdated(pairCA, priceImpactSwapEnabled);
        }
    }

    function setContractSwapSettings(address lpPairAddr, uint8 swapThresholdBps, uint8 amountBps) external onlyDMAuthorized {
        LPPair memory lpPair = lppairs[lpPairAddr];
        uint256 swapThreshold = (lpPair.tokentTotal * swapThresholdBps) / 10000;
        uint256 swapAmount = (lpPair.tokentTotal * amountBps) / 10000;
        require(swapThreshold <= swapAmount, "Threshold cannot be above amount.");
        require(lpPair.swapThreshold != swapThreshold, "Swap Threshold is already set at the desired state.");
        require(lpPair.swapAmount != swapAmount, "Swap Amount is already set at the desired state.");

        lpPair.swapThreshold = (lpPair.tokentTotal * swapThresholdBps) / 10000;
        lpPair.swapAmount = (lpPair.tokentTotal * amountBps) / 10000;

        bool checked;
        managingToken = ITokenFunctions(lppairs[lpPairAddr].tokenCA);
        checked = managingToken.updateContractSwapSettings(lpPairAddr, lpPair.swapThreshold, lpPair.swapAmount);

        if(!checked) {
            revert();
        } else {
            emit ContractSwapSettingsUpdated(lpPairAddr, lpPair.swapThreshold, lpPair.swapAmount);
        }
    }

    function setContractPriceImpactSwapSettings(address pairCA, uint8 priceImpactSwapBps) external onlyDMAuthorized {
        require(priceImpactSwapBps <= 200, "Cannot set above 2%.");
        require(lppairs[pairCA].piSwapBps != priceImpactSwapBps, "Already set at the desired state.");

        lppairs[pairCA].piSwapBps = priceImpactSwapBps;

        bool checked;
        managingToken = ITokenFunctions(lppairs[pairCA].tokenCA);
        checked = managingToken.updateContractPriceImpactSwapSettings(pairCA, priceImpactSwapBps);

        if(!checked) {
            revert();
        } else {
            emit PriceImpactContractSwapSettingsUpdated(pairCA, priceImpactSwapBps);
        }
    }

}