/**
 *Submitted for verification at Etherscan.io on 2023-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex;
                // Replace lastvalue's index to valueIndex
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

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
    internal
    returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
    internal
    returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
    internal
    view
    returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
    internal
    view
    returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set)
    internal
    view
    returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

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

        assembly {
            result := store
        }

        return result;
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IERC20Permit {
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
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface INFTToken {
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

interface IPriceTool {
    function getPrice(address _token) external returns(uint256);
}

contract DigiMintMiningPool is Ownable, ReentrancyGuard {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address[] public nftTokens;
    mapping (address => bool) tokens;

    uint256 public constant ACC_NFT_PRECISION = 1e18;
    uint256 public constant SHARE_PRECISION = 1e6;
    uint256 public constant BASE_FEE_RATE = 1e5;
    // (nftAddress ,userAddress) => user deposited NFTs
    // @notice user -> nft token -> user nfts
    mapping(address => mapping(address => EnumerableSet.UintSet)) private userNfts;
    /// @notice user -> reward token -> user debt
	mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
	/// @notice user -> user share 
	mapping(address => uint256) public userShare;
    //
    mapping(address => uint256) public maxTokenId;

    struct UserReward {
        uint256 claimedReward;
        uint256 claimableReward;
    }

    struct RewardData {
		address token;
		uint256 reward;
        uint256 totalReward;
	}

    struct Reward {
        uint256 periodFinish;
        uint256 rewardPerSecond;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 balance;
        uint256 totalProfit;
    }

    struct Fee {
        uint256 feePerSecond;
        uint256 feeRate;
        uint256 reward;
    }
    /// @notice user -> reward token -> amount; used to store reward amount
	mapping(address => mapping(address => UserReward)) public userRewards;
    // 
    address[] public rewardTokens;
    /// @notice Reward data per token
	mapping(address => Reward) public rewardData;
    //
    mapping(address => Fee) public feeData;

    uint256 public totalShare;
    address public daoTreasury;
    mapping (address => bool) public caller;
    address public priceTool;
    
    event Deposit(address indexed user,address[] _nfts,uint256[] _tokenIds);
    event Withdraw(address indexed user,address[] _nfts,uint256[] _tokenIds);
    event EmergencyWithdraw(address indexed user, uint256[] amounts);
    event RewardPaid(address indexed user, address indexed rewardToken, uint256 reward);
    event UpdatePool(address indexed token, uint256 lastUpdateTime, uint256 reward, uint256 fee);
    event AddReward(address indexed token, uint256 remainingBalance,uint256 amount,uint duration);

    constructor(address _treasury){
        daoTreasury = _treasury;
    }

    function onERC721Received(
        address operator,
        address, //from
        uint256, //tokenId
        bytes calldata //data
    ) public nonReentrant returns (bytes4) {
        require(
            operator == address(this),
            "received Nft from unauthenticated contract"
        );

        return
        bytes4(
            keccak256("onERC721Received(address,address,uint256,bytes)")
        );
    }

    function deposit(address[] memory _nfts,uint256[] memory _tokenIds) public {
        require(_nfts.length == _tokenIds.length,"Invalid value!");
        require(_nfts.length <= 50,"Invalid count!");

        uint len = _nfts.length;
        for (uint256 i = 0; i < len; i++) {
            require(tokens[_nfts[i]],"Invalid nft address!");
            require(_tokenIds[i]<=maxTokenId[_nfts[i]],"Invalid token id");
        }

        for (uint256 i = 0; i < len; i++) {
            IERC721(_nfts[i]).safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            EnumerableSet.add(userNfts[msg.sender][_nfts[i]], _tokenIds[i]);
        }

        _updateReward(msg.sender);
        uint256 share = len.mul(SHARE_PRECISION);
        userShare[msg.sender] = userShare[msg.sender].add(share);

        totalShare = totalShare.add(share);
        emit Deposit(msg.sender,_nfts,_tokenIds);
    }

    function withdraw(address[] memory _nfts,uint256[] memory _tokenIds) public {
        require(_nfts.length <= 50,"Invalid count!");
        uint256 count = _withdrawNftTokenIds(_nfts,_tokenIds);
        _updateReward(msg.sender);
        uint256 share = count.mul(SHARE_PRECISION);
        userShare[msg.sender] = userShare[msg.sender].sub(share);
        totalShare = totalShare.sub(share);
        emit Withdraw(msg.sender,_nfts,_tokenIds);
    }

    function _withdrawNftTokenIds(address[] memory _nfts,uint256[] memory _tokenIds) internal returns(uint256 _totalCounts){
        require(_nfts.length == _tokenIds.length,"Invalid value!");
        _totalCounts = _nfts.length;
        for (uint256 i = 0; i < _totalCounts; i++) {
            require(EnumerableSet.contains(userNfts[msg.sender][_nfts[i]], _tokenIds[i]),"Invalid tokenId"); 
        }

        for(uint256 i=0;i<_totalCounts;i++){
            IERC721(_nfts[i]).transferFrom(address(this), address(msg.sender), _tokenIds[i]);
            EnumerableSet.remove(userNfts[msg.sender][_nfts[i]], _tokenIds[i]);
        }        
    }

    function emergencyWithdraw() external {
        
        _updateReward(msg.sender);
        uint256 length = rewardTokens.length;
		for (uint256 i; i < length; i++) {
			address token = rewardTokens[i];
			uint256 reward = userRewards[msg.sender][token].claimableReward;
			if (reward > 0) {
				userRewards[msg.sender][token].claimableReward = 0;
                feeData[token].reward = reward < rewardData[token].balance?feeData[token].reward.add(reward):feeData[token].reward.add(rewardData[token].balance);
				rewardData[token].balance = reward < rewardData[token].balance? rewardData[token].balance.sub(reward):0;
			}
		}
        uint len = nftTokens.length;
        uint256[] memory amounts = new uint256[](len); 
        for (uint256 i = 0; i < len; i++) {
            uint256 amount = EnumerableSet.length(userNfts[msg.sender][nftTokens[i]]);
            if(amount > 50){
                amount = 50;
            }
            amounts[i] = amount;
        }
        
        uint256 count = _withdrawNftTokens(nftTokens,amounts);
        uint256 share = count.mul(SHARE_PRECISION);
        userShare[msg.sender] = userShare[msg.sender].sub(share);
        totalShare = totalShare.sub(share);
        emit EmergencyWithdraw(msg.sender,amounts);
    }

    function _withdrawNftTokens(address[] memory _nfts,uint256[] memory _amounts) internal returns(uint256 _totalCounts){
        require(_nfts.length == _amounts.length,"Invalid value!");
        uint len = _nfts.length;
        for (uint256 i = 0; i < len; i++) {
            require(tokens[_nfts[i]],"Invalid nft address!");
            require(_amounts[i]<=EnumerableSet.length(userNfts[msg.sender][_nfts[i]]),"Invalid amount!");
        }
        for(uint256 i=0;i<len;i++){
            uint256 count = _amounts[i];
            uint256[] memory tokenIds = new uint256[](count);

            // check
            for(uint256 j =0;j<count;j++){
                uint256 tokenId = EnumerableSet.at(userNfts[msg.sender][_nfts[i]],j);
                tokenIds[j] = tokenId;
            }
            // remove
            for(uint256 k=0;k<count;k++){
                uint256 tokenId = tokenIds[k];
                IERC721(_nfts[i]).transferFrom(address(this), address(msg.sender), tokenId);
                EnumerableSet.remove(userNfts[msg.sender][_nfts[i]], tokenId);
            }
            _totalCounts += count;
        }
    }

    function harvest() public nonReentrant {
        _updateReward(msg.sender);
		_getReward(msg.sender, rewardTokens);
    }

    function _updatePool(address token) internal returns(uint256) {

        (uint256 rpt,uint256 reward,uint256 fee) = rewardPerToken(token);
        
	    Reward storage r = rewardData[token];
		r.rewardPerTokenStored = rpt;
        emit UpdatePool(token,r.lastUpdateTime,reward,fee);
		r.lastUpdateTime = lastTimeRewardApplicable(token);
        r.balance = r.balance.add(reward).add(fee);
        r.totalProfit = r.totalProfit.add(reward);
        feeData[token].reward = feeData[token].reward.add(fee);
        
        return rpt;
    }

	/**
	 * @notice Returns reward applicable timestamp.
	 */
	function lastTimeRewardApplicable(address _rewardToken) public view returns (uint256) {
		uint256 periodFinish = rewardData[_rewardToken].periodFinish;
		return block.timestamp < periodFinish ? block.timestamp : periodFinish;
	}

	/**
	 * @notice Reward amount per token
	 * @dev Reward is distributed only for locks.
	 * @param _rewardToken for reward
	 */
	function rewardPerToken(address _rewardToken) public returns (uint256 rptStored,uint256 reward,uint256 fee) {
		rptStored = rewardData[_rewardToken].rewardPerTokenStored;
		if (totalShare > 0) {
			reward = newReward(_rewardToken);
            uint256 feePerSecond = feeData[_rewardToken].feePerSecond;
            if(feePerSecond > 0){
                uint256 stableFee = lastTimeRewardApplicable(_rewardToken).sub(rewardData[_rewardToken].lastUpdateTime).mul(feePerSecond);
                fee = convertFee(_rewardToken,stableFee);
                if(fee > reward){
                    fee = reward;
                }
            }
            if(feeData[_rewardToken].feeRate > 0){
                uint256 tmpReward = reward;
                tmpReward = tmpReward.sub(fee);
                fee = tmpReward.mul(feeData[_rewardToken].feeRate).div(BASE_FEE_RATE).add(fee);
                reward = reward.sub(fee);
            }

			rptStored = rptStored.add(reward.mul(ACC_NFT_PRECISION).div(totalShare));
		}
	}

    function newReward(address _rewardToken) internal view returns (uint256 reward) {
        reward = lastTimeRewardApplicable(_rewardToken).sub(rewardData[_rewardToken].lastUpdateTime).mul(
				rewardData[_rewardToken].rewardPerSecond
			).div(ACC_NFT_PRECISION);
    }

	/**
	 * @notice Address and claimable amount of all reward tokens for the given account.
	 * @param account for rewards
	 */
	function claimableRewards(
		address account
	) public returns (RewardData[] memory rewardsData) {
        uint256 length = rewardTokens.length;
		rewardsData = new RewardData[](length);
		for (uint256 i = 0; i < length; i++) {
			rewardsData[i].token = rewardTokens[i];
            (uint256 rpt,,) = rewardPerToken(rewardsData[i].token);
            uint256 reward = _earned(
				account,
				rewardsData[i].token,
				userShare[account],
				rpt
			);
            rewardsData[i].reward = reward;
            rewardsData[i].totalReward = reward.add(userRewards[account][rewardTokens[i]].claimedReward);
		}
		return rewardsData;
	}

    function getUserNFTs(address _user,address _nft) public view returns(uint256[] memory){

        uint256 amount = EnumerableSet.length(userNfts[_user][_nft]);
        uint256[] memory tokenIds = new uint256[](amount); 
        // check
        for(uint256 j =0;j<amount;j++){
            uint256 tokenId = EnumerableSet.at(userNfts[_user][_nft],j);
            tokenIds[j] = tokenId;
        }
        return tokenIds;
    }

    /*
     * @notice User gets reward
	 */
	function _getReward(address _user, address[] memory _rewardTokens) internal  {

		uint256 length = _rewardTokens.length;
		for (uint256 i; i < length; i++) {
			address token = _rewardTokens[i];
			uint256 reward = userRewards[_user][token].claimableReward;
			if (reward > 0) {
				// rewards[_user][token] = 0;
                userRewards[_user][token] = UserReward({
                    claimedReward: userRewards[_user][token].claimedReward.add(reward),
                    claimableReward:0
                });
				rewardData[token].balance = reward < rewardData[token].balance? rewardData[token].balance.sub(reward):0;
                IERC20(token).safeTransfer(_user, reward);
				emit RewardPaid(_user, token, reward);
			}
		}
	}

	/**
	 * @notice Calculate earnings.
	 */
	function _earned(
		address _user,
		address _rewardToken,
		uint256 _share,
		uint256 _currentRewardPerToken
	) internal view returns (uint256 earnings) {
		earnings = userRewards[_user][_rewardToken].claimableReward;
		uint256 realRPT = _currentRewardPerToken.sub(userRewardPerTokenPaid[_user][_rewardToken]);
		earnings = earnings.add(_share.mul(realRPT).div(ACC_NFT_PRECISION));
	}

	/**
	 * @notice Update user reward info.
	 */
	function _updateReward(address account) internal {
		uint256 share = userShare[msg.sender];
		uint256 length = rewardTokens.length;
		for (uint256 i = 0; i < length; i++) {
			address token = rewardTokens[i];
			uint256 rpt = _updatePool(token);

			if (account != address(this)) {
				userRewards[account][token].claimableReward = _earned(account, token, share, rpt);
				userRewardPerTokenPaid[account][token] = rpt;
			}
		}
	}

    function convertFee(address _token, uint256 _stableAmount) public returns(uint256) {
        uint256 price = IPriceTool(priceTool).getPrice(_token);
        uint256 multiple = 10 ** IERC20(_token).decimals();
        return _stableAmount.mul(multiple).div(price);
    }

    function recieve(address _rewardToken,uint256 _amount, uint256 _minutes) external returns ( bool ) {
        require(caller[msg.sender],"Invalid address!");
        require(rewardData[_rewardToken].lastUpdateTime > 0, "Not ready!");
        require(_amount > 0,"Invalid amount!");

        _updatePool(_rewardToken);
        uint256 oldBal = IERC20(_rewardToken).balanceOf(address(this));
        IERC20(_rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 allocRewardAmount = rewardData[_rewardToken].balance;
        if(allocRewardAmount > oldBal) {
            allocRewardAmount = oldBal;
        }
        uint256 remainingBal = oldBal.sub(allocRewardAmount);
        uint256 tmpBal = remainingBal;
        remainingBal = remainingBal.add(_amount);
        uint256 unit = 1 minutes;
        rewardData[_rewardToken].rewardPerSecond = remainingBal.mul(ACC_NFT_PRECISION).div(_minutes).div(unit);
        rewardData[_rewardToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardToken].periodFinish = _minutes.mul(unit).add(block.timestamp);

        emit AddReward(_rewardToken,tmpBal,_amount,_minutes);
        return true;
    }

    function getTokenIdsForUser(address _nft,address _user, uint _count) internal view returns(uint256[] memory) {
        uint256 balance = INFTToken(_nft).balanceOf(_user);
        require(balance >= _count,"Invalid count!");
        uint256[] memory re = new uint256[](_count);
        for (uint256 i = 0;i<_count;i++){
            uint256 tokenId = INFTToken(_nft).tokenOfOwnerByIndex(_user, i);
            re[i] = tokenId;            
        }
        return re;
    }

    function safeTokenTransfer(address _rewardToken , address _to, uint256 _amount) internal {
        uint256 tokenBal = IERC20(_rewardToken).balanceOf(address(this));
        if (_amount > tokenBal) {
            if (tokenBal > 0) {
                _amount = tokenBal;
            }
        }
        if(_amount>0) {
            IERC20(_rewardToken).safeTransfer(_to, _amount);
        }
    }

    function setMaxTokenId(address _nftToken,uint256 _tokenId) public {
        require(caller[msg.sender], "Not caller!");
        require(tokens[_nftToken],"Ivalid token");
        maxTokenId[_nftToken] = _tokenId;
    }

    /**
	 * @notice Add a new reward token to be distributed to stakers.
	 */
	function addRewardToken(address _rewardToken) external {
		require(caller[msg.sender], "Not caller!");
		require(rewardData[_rewardToken].lastUpdateTime == 0, "Already added");
        require(_rewardToken != address(0),"Invalid token!");
		rewardTokens.push(_rewardToken);
		rewardData[_rewardToken].lastUpdateTime = block.timestamp;
		rewardData[_rewardToken].periodFinish = block.timestamp;
	}

    function setRewardFee(address _rewardToken, uint256 _feePerSecond, uint256 _feeRate) public {
        require(caller[msg.sender], "not caller");
        require(rewardData[_rewardToken].lastUpdateTime > 0, "Invalid token");
       
        _updatePool(_rewardToken);
        
        Fee memory feeInfo = feeData[_rewardToken];
        feeData[_rewardToken] = Fee({
            feePerSecond: _feePerSecond,
            feeRate: _feeRate,
            reward: feeInfo.reward
        });
    }

    function removeRewardFee(address _rewardToken) public {
        rechargeDaoTreasury(_rewardToken);
        delete feeData[_rewardToken];
    }

    function rechargeDaoTreasury(address _rewardToken) public {
        require(caller[msg.sender], "not caller");
        require(rewardData[_rewardToken].lastUpdateTime > 0, "Invalid token!");
        _updatePool(_rewardToken);
        Fee memory feeInfo = feeData[_rewardToken];
        uint256 reward = feeInfo.reward;
        if(reward > 0){
            rewardData[_rewardToken].balance = reward < rewardData[_rewardToken].balance? rewardData[_rewardToken].balance.sub(reward):0;
            feeData[_rewardToken].reward = 0;
            safeTokenTransfer(_rewardToken,daoTreasury,reward);
        }
    }

    /**
	 * @notice Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders.
	 */
	function recoverERC20(address tokenAddress) external onlyOwner {
		require(rewardData[tokenAddress].lastUpdateTime == 0, "active reward");
        uint256 tokenAmount = IERC20(tokenAddress).balanceOf(address(this));
		IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
	}

    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0),"Invalid address!");
        daoTreasury = _treasury;
    }

    function setPriceTool(address _tool) public onlyOwner {
        require(_tool != address(0),"Invalid address");
        priceTool = _tool;
    }

    function addNFTToken(address _token) public onlyOwner {
        require(_token != address(0),"Invalid address!");
        require(nftTokens.length < 20,"Maximum count exceeded!");
        require(tokens[_token] == false,"Ivalid token");
        nftTokens.push(_token);
        tokens[_token] = true;
    }

    function addCaller(address _caller) public onlyOwner {
        require(_caller != address(0),"Invalid address!");
        caller[_caller] = true;
    }

    function delCaller(address _caller) public onlyOwner {
        require(_caller != address(0),"Invalid address!");
        caller[_caller] = false;
    }
}