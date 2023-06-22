/**
 *Submitted for verification at Etherscan.io on 2023-04-24
*/

// File: contracts/IWasabiPoolFactory.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/**
 * @dev Required interface of an WasabiPoolFactory compliant contract.
 */
interface IWasabiPoolFactory {

    /**
     * @dev The States of Pools
     */
    enum PoolState {
        INVALID,
        ACTIVE,
        DISABLED
    }

    /**
     * @dev Emitted when there is a new pool created
     */
    event NewPool(address poolAddress, address indexed nftAddress, address indexed owner);

    /**
     * @dev INVALID/ACTIVE/DISABLE the specified pool.
     */
    function togglePool(address _poolAddress, PoolState _poolState) external;

    /**
     * @dev Checks if the pool for the given address is enabled.
     */
    function isValidPool(address _poolAddress) external view returns(bool);

    /**
     * @dev Returns the PoolState
     */
    function getPoolState(address _poolAddress) external view returns(PoolState);

    /**
     * @dev Returns IWasabiConduit Contract Address.
     */
    function getConduitAddress() external view returns(address);

    /**
     * @dev Returns IWasabiFeeManager Contract Address.
     */
    function getFeeManager() external view returns(address);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)



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

// File: contracts/fees/IWasabiFeeManager.sol



/**
 * @dev Required interface of an Wasabi Fee Manager compliant contract.
 */
interface IWasabiFeeManager {
    /**
     * @dev Returns the fee data for the given pool and amount
     * @param _pool the pool address
     * @param _amount the amount being paid
     * @return receiver the receiver of the fee
     * @return amount the fee amount
     */
    function getFeeData(address _pool, uint256 _amount) external view returns (address receiver, uint256 amount);

    /**
     * @dev Returns the fee data for the given option and amount
     * @param _optionId the option id
     * @param _amount the amount being paid
     * @return receiver the receiver of the fee
     * @return amount the fee amount
     */
    function getFeeDataForOption(uint256 _optionId, uint256 _amount) external view returns (address receiver, uint256 amount);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)



/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)



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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)



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

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)



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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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
        return _values(set._inner);
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)



/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

// File: contracts/lib/WasabiStructs.sol



library WasabiStructs {
    enum OptionType {
        CALL,
        PUT
    }

    struct OptionData {
        bool active;
        OptionType optionType;
        uint256 strikePrice;
        uint256 expiry;
        uint256 tokenId; // Locked token for CALL options
    }

    struct PoolAsk {
        uint256 id;
        address poolAddress;
        OptionType optionType;
        uint256 strikePrice;
        uint256 premium;
        uint256 expiry;
        uint256 tokenId; // Token to lock for CALL options
        uint256 orderExpiry;
    }

    struct PoolBid {
        uint256 id;
        uint256 price;
        address tokenAddress;
        uint256 orderExpiry;
        uint256 optionId;
    }

    struct Bid {
        uint256 id;
        uint256 price;
        address tokenAddress;
        address collection;
        uint256 orderExpiry;
        address buyer;
        OptionType optionType;
        uint256 strikePrice;
        uint256 expiry;
        uint256 expiryAllowance;
        address optionTokenAddress;
    }

    struct Ask {
        uint256 id;
        uint256 price;
        address tokenAddress;
        uint256 orderExpiry;
        address seller;
        uint256 optionId;
    }

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct ExecutionInfo {
        address module;
        bytes data;
        uint256 value;
    }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)



/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)



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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)



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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)









/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)



/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)



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

// File: contracts/IWasabiPool.sol







/**
 * @dev Required interface of an WasabiPool compliant contract.
 */
interface IWasabiPool is IERC165, IERC721Receiver {
    
    /**
     * @dev Emitted when `admin` is changed.
     */
    event AdminChanged(address admin);

    /**
     * @dev Emitted when an order is cancelled.
     */
    event OrderCancelled(uint256 id);

    /**
     * @dev Emitted when a pool bid is taken
     */
    event PoolBidTaken(uint256 id);

    /**
     * @dev Emitted when an ERC721 is received
     */
    event ERC721Received(uint256 tokenId);

    /**
     * @dev Emitted when ETH is received
     */
    event ETHReceived(uint amount);

    /**
     * @dev Emitted when ERC20 is received
     */
    event ERC20Received(uint amount);

    /**
     * @dev Emitted when an ERC721 is withdrawn
     */
    event ERC721Withdrawn(uint256 tokenId);

    /**
     * @dev Emitted when ERC20 is withdrawn
     */
    event ERC20Withdrawn(uint amount);

    /**
     * @dev Emitted when ETH is withdrawn
     */
    event ETHWithdrawn(uint amount);

    /**
     * @dev Emitted when an option is executed.
     */
    event OptionExecuted(uint256 optionId);

    /**
     * @dev Emitted when an option is issued
     */
    event OptionIssued(uint256 optionId, uint256 price);

    /**
     * @dev Emitted when an option is issued
     */
    event OptionIssued(uint256 optionId, uint256 price, uint256 poolAskId);

    /**
     * @dev Emitted when the pool settings are edited
     */
    event PoolSettingsChanged();

    /**
     * @dev Returns the address of the nft
     */
    function getNftAddress() external view returns(address);

    /**
     * @dev Returns the address of the nft
     */
    function getLiquidityAddress() external view returns(address);

    /**
     * @dev Writes an option for the given ask.
     */
    function writeOption(
        WasabiStructs.PoolAsk calldata _request, bytes calldata _signature
    ) external payable returns (uint256);

    /**
     * @dev Writes an option for the given rule and buyer.
     */
    function writeOptionTo(
        WasabiStructs.PoolAsk calldata _request, bytes calldata _signature, address _receiver
    ) external payable returns (uint256);

    /**
     * @dev Executes the option for the given id.
     */
    function executeOption(uint256 _optionId) external payable;

    /**
     * @dev Executes the option for the given id.
     */
    function executeOptionWithSell(uint256 _optionId, uint256 _tokenId) external payable;

    /**
     * @dev Cancels the order for the given _orderId.
     */
    function cancelOrder(uint256 _orderId) external;

    /**
     * @dev Withdraws ERC721 tokens from the pool.
     */
    function withdrawERC721(IERC721 _nft, uint256[] calldata _tokenIds) external;

    /**
     * @dev Deposits ERC721 tokens to the pool.
     */
    function depositERC721(IERC721 _nft, uint256[] calldata _tokenIds) external;

    /**
     * @dev Withdraws ETH from this pool
     */
    function withdrawETH(uint256 _amount) external payable;

    /**
     * @dev Withdraws ERC20 tokens from this pool
     */
    function withdrawERC20(IERC20 _token, uint256 _amount) external;

    /**
     * @dev Sets the admin of this pool.
     */
    function setAdmin(address _admin) external;

    /**
     * @dev Removes the admin from this pool.
     */
    function removeAdmin() external;

    /**
     * @dev Returns the address of the current admin.
     */
    function getAdmin() external view returns (address);

    /**
     * @dev Returns the address of the factory managing this pool
     */
    function getFactory() external view returns (address);

    /**
     * @dev Returns the available balance this pool contains that can be withdrawn or collateralized
     */
    function availableBalance() view external returns(uint256);

    /**
     * @dev Returns an array of ids of all outstanding (issued or expired) options
     */
    function getOptionIds() external view returns(uint256[] memory);

    /**
     * @dev Returns the id of the option that locked the given token id, reverts if there is none
     */
    function getOptionIdForToken(uint256 _tokenId) external view returns(uint256);

    /**
     * @dev Returns the option data for the given option id
     */
    function getOptionData(uint256 _optionId) external view returns(WasabiStructs.OptionData memory);

    /**
     * @dev Returns 'true' if the option for the given id is valid and active, 'false' otherwise
     */
    function isValid(uint256 _optionId) view external returns(bool);

    /**
     * @dev Checks if _tokenId unlocked
     */
    function isAvailableTokenId(uint256 _tokenId) external view returns(bool);

    /**
     * @dev Clears the expired options from the pool
     */
    function clearExpiredOptions(uint256[] memory _optionIds) external;

    /**
     * @dev accepts the bid for LPs with _tokenId. If its a put option, _tokenId can be 0
     */
    function acceptBid(WasabiStructs.Bid calldata _bid, bytes calldata _signature, uint256 _tokenId) external returns(uint256);

    /**
     * @dev accepts the ask for LPs
     */
    function acceptAsk(WasabiStructs.Ask calldata _ask, bytes calldata _signature) external;

    /**
     * @dev accepts a bid created for this pool
     */
    function acceptPoolBid(WasabiStructs.PoolBid calldata _poolBid, bytes calldata _signature) external payable;
}

// File: contracts/WasabiOption.sol








/**
 * @dev An ERC721 which tracks Wasabi Option positions of accounts
 */
contract WasabiOption is ERC721, IERC2981, Ownable {
    
    address private lastFactory;
    mapping(address => bool) private factoryAddresses;
    mapping(uint256 => address) private optionPools;
    uint256 private _currentId = 1;
    string private _baseURIextended;

    /**
     * @dev Constructs WasabiOption
     */
    constructor() ERC721("Wasabi Option NFTs", "WASAB") {}

    /**
     * @dev Toggles the owning factory
     */
    function toggleFactory(address _factory, bool _enabled) external onlyOwner {
        factoryAddresses[_factory] = _enabled;
        if (_enabled) {
            lastFactory = _factory;
        }
    }

    /**
     * @dev Mints a new WasabiOption
     */
    function mint(address _to, address _factory) external returns (uint256 mintedId) {
        require(factoryAddresses[_factory] == true, "Invalid Factory");
        require(IWasabiPoolFactory(_factory).isValidPool(_msgSender()), "Only valid pools can mint");

        _safeMint(_to, _currentId);
        mintedId = _currentId;
        optionPools[mintedId] = _msgSender();
        _currentId++;
    }

    /**
     * @dev Burns the specified option
     */
    function burn(uint256 _optionId) external {
        require(optionPools[_optionId] == _msgSender(), "Caller can't burn option");
        _burn(_optionId);
    }

    /**
     * @dev Sets the base URI
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    /**
     * @dev Returns the address of the pool which created the given option
     */
    function getPool(uint256 _optionId) external view returns (address) {
        return optionPools[_optionId];
    }
    
    /// @inheritdoc ERC721
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256) {
        IWasabiPool pool = IWasabiPool(optionPools[_tokenId]);
        IWasabiPoolFactory factory = IWasabiPoolFactory(pool.getFactory());
        IWasabiFeeManager feeManager = IWasabiFeeManager(factory.getFeeManager());
        return feeManager.getFeeDataForOption(_tokenId, _salePrice);
    }
    
    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: contracts/IWasabiConduit.sol




/**
 * @dev Required interface of an WasabiConduit compliant contract.
 */
interface IWasabiConduit {

    /**
     * @dev Buys multiple options
     */
    function buyOptions(
        WasabiStructs.PoolAsk[] calldata _requests,
        WasabiStructs.Ask[] calldata _asks,
        bytes[] calldata _signatures
    ) external payable returns (uint256[] memory);

    /**
     * @dev Buys an option
     */
    function buyOption(
        WasabiStructs.PoolAsk calldata _request,
        bytes calldata _signature
    ) external payable returns (uint256);

    /**
     * @dev Transfers a NFT to _target
     *
     * @param _nft the address of NFT
     * @param _tokenId the tokenId to transfer
     * @param _target the target to transfer the NFT
     */
    function transferToken(
        address _nft,
        uint256 _tokenId,
        address _target
    ) external;

    /**
     * @dev Sets Option information
     */
    function setOption(WasabiOption _option) external;

    /**
     * @dev Sets maximum number of option to buy
     */
    function setMaxOptionsToBuy(uint256 _maxOptionsToBuy) external;

    /**
     * @dev Sets pool factory address
     */
    function setPoolFactoryAddress(address _factory) external;

    /**
     * @dev Accpets the Ask
     */
    function acceptAsk(
        WasabiStructs.Ask calldata _ask,
        bytes calldata _signature
    ) external payable returns (uint256);

    /**
     * @dev Accpets the Bid
     */
    function acceptBid(
        uint256 _optionId,
        address _poolAddress,
        WasabiStructs.Bid calldata _bid,
        bytes calldata _signature
    ) external payable;

    /**
     * @dev Pool Accepts the _bid
     */
    function poolAcceptBid(WasabiStructs.Bid calldata _bid, bytes calldata _signature, uint256 _optionId) external;

    /**
     * @dev Cancel the _ask
     */
    function cancelAsk(
        WasabiStructs.Ask calldata _ask,
        bytes calldata _signature
    ) external;

    /**
     * @dev Cancel the _bid
     */
    function cancelBid(
        WasabiStructs.Bid calldata _bid,
        bytes calldata _signature
    ) external;
}

// File: contracts/IWasabiErrors.sol



/**
 * @dev Required interface for defining all the errors
 */

interface IWasabiErrors {

    /**
     * @dev Thrown when an order that has been filled or cancelled is being acted upon
     */
    error OrderFilledOrCancelled();

    /**
     * @dev Thrown when someone tries to make an unauthorized request
     */
    error Unauthorized();

    /**
     * @dev Thrown when a signature is invalid
     */
    error InvalidSignature();

    /**
     * @dev Thrown when there is no sufficient available liquidity left in the pool for issuing a PUT option
     */
    error InsufficientAvailableLiquidity();

    /**
     * @dev Thrown when the requested NFT for a CALL is already locked for another option
     */
    error RequestNftIsLocked();

    /**
     * @dev Thrown when the NFT is not in the pool or invalid
     */
    error NftIsInvalid();

    /**
     * @dev Thrown when the expiry of an ask is invalid for the pool
     */
    error InvalidExpiry();

    /**
     * @dev Thrown when the strike price of an ask is invalid for the pool
     */
    error InvalidStrike();

    /**
     * @dev Thrown when an expired order or option is being exercised
     */
    error HasExpired();
    
    /**
     * @dev Thrown when sending ETH failed
     */
    error FailedToSend();
}

// File: contracts/lib/Signing.sol



/**
 * @dev Signature Verification
 */
library Signing {

    /**
     * @dev Returns the message hash for the given request
     */
    function getMessageHash(WasabiStructs.PoolAsk calldata _request) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _request.id,
                _request.poolAddress,
                _request.optionType,
                _request.strikePrice,
                _request.premium,
                _request.expiry,
                _request.tokenId,
                _request.orderExpiry));
    }

    /**
     * @dev Returns the message hash for the given request
     */
    function getAskHash(WasabiStructs.Ask calldata _ask) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _ask.id,
                _ask.price,
                _ask.tokenAddress,
                _ask.orderExpiry,
                _ask.seller,
                _ask.optionId));
    }

    function getBidHash(WasabiStructs.Bid calldata _bid) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _bid.id,
                _bid.price,
                _bid.tokenAddress,
                _bid.collection,
                _bid.orderExpiry,
                _bid.buyer,
                _bid.optionType,
                _bid.strikePrice,
                _bid.expiry,
                _bid.expiryAllowance));
    }

    /**
     * @dev creates an ETH signed message hash
     */
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function getSigner(
        WasabiStructs.PoolAsk calldata _request,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 messageHash = getMessageHash(_request);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature);
    }

    function getAskSigner(
        WasabiStructs.Ask calldata _ask,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 messageHash = getAskHash(_ask);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

// File: contracts/lib/PoolAskVerifier.sol



/**
 * @dev Signature Verification for PoolAsk
 */
library PoolAskVerifier {

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 constant POOLASK_TYPEHASH =
        keccak256(
            "PoolAsk(uint256 id,address poolAddress,uint8 optionType,uint256 strikePrice,uint256 premium,uint256 expiry,uint256 tokenId,uint256 orderExpiry)"
        );

    /**
     * @dev Creates the hash of the EIP712 domain for this validator
     *
     * @param _eip712Domain the domain to hash
     * @return the hashed domain
     */
    function hashDomain(
        WasabiStructs.EIP712Domain memory _eip712Domain
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(_eip712Domain.name)),
                    keccak256(bytes(_eip712Domain.version)),
                    _eip712Domain.chainId,
                    _eip712Domain.verifyingContract
                )
            );
    }

    /**
     * @dev Creates the hash of the PoolAsk for this validator
     *
     * @param _poolAsk to hash
     * @return the poolAsk domain
     */
    function hashForPoolAsk(
        WasabiStructs.PoolAsk memory _poolAsk
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    POOLASK_TYPEHASH,
                    _poolAsk.id,
                    _poolAsk.poolAddress,
                    _poolAsk.optionType,
                    _poolAsk.strikePrice,
                    _poolAsk.premium,
                    _poolAsk.expiry,
                    _poolAsk.tokenId,
                    _poolAsk.orderExpiry
                )
            );
    }

    /**
     * @dev Gets the signer of the given signature for the given _poolAsk
     *
     * @param _poolAsk the ask to validate
     * @param _signature the signature to validate
     * @return address who signed the signature
     */
    function getSignerForPoolAsk(
        WasabiStructs.PoolAsk memory _poolAsk,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 domainSeparator = hashDomain(
            WasabiStructs.EIP712Domain({
                name: "PoolAskSignature",
                version: "1",
                chainId: getChainID(),
                verifyingContract: address(this)
            })
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, hashForPoolAsk(_poolAsk))
        );
        return Signing.recoverSigner(digest, _signature);
    }

    /**
     * @dev Checks the signer of the given signature for the given poolAsk is the given signer
     *
     * @param _poolAsk the _poolAsk to validate
     * @param _signature the signature to validate
     * @param _signer the signer to validate
     * @return true if the signature belongs to the signer, false otherwise
     */
    function verifyPoolAsk(
        WasabiStructs.PoolAsk memory _poolAsk,
        bytes memory _signature,
        address _signer
    ) internal view returns (bool) {
        return getSignerForPoolAsk(_poolAsk, _signature) == _signer;
    }

    /**
     * @return the current chain id
     */
    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}

// File: contracts/lib/PoolBidVerifier.sol



/**
 * @dev Signature Verification for PoolBid
 */
library PoolBidVerifier {

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 constant POOLBID_TYPEHASH =
        keccak256(
            "PoolBid(uint256 id,uint256 price,address tokenAddress,uint256 orderExpiry,uint256 optionId)"
        );

    /**
     * @dev Creates the hash of the EIP712 domain for this validator
     *
     * @param _eip712Domain the domain to hash
     * @return the hashed domain
     */
    function hashDomain(
        WasabiStructs.EIP712Domain memory _eip712Domain
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(_eip712Domain.name)),
                    keccak256(bytes(_eip712Domain.version)),
                    _eip712Domain.chainId,
                    _eip712Domain.verifyingContract
                )
            );
    }

    /**
     * @dev Creates the hash of the PoolBid for this validator
     *
     * @param _poolBid to hash
     * @return the poolBid hash
     */
    function hashForPoolBid(
        WasabiStructs.PoolBid memory _poolBid
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    POOLBID_TYPEHASH,
                    _poolBid.id,
                    _poolBid.price,
                    _poolBid.tokenAddress,
                    _poolBid.orderExpiry,
                    _poolBid.optionId
                )
            );
    }

    /**
     * @dev Gets the signer of the given signature for the given _poolBid
     *
     * @param _poolBid the bid to validate
     * @param _signature the signature to validate
     * @return address who signed the signature
     */
    function getSignerForPoolBid(
        WasabiStructs.PoolBid memory _poolBid,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 domainSeparator = hashDomain(
            WasabiStructs.EIP712Domain({
                name: "PoolBidVerifier",
                version: "1",
                chainId: getChainID(),
                verifyingContract: address(this)
            })
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, hashForPoolBid(_poolBid))
        );
        return Signing.recoverSigner(digest, _signature);
    }

    /**
     * @dev Checks the signer of the given signature for the given _poolBid is the given signer
     *
     * @param _poolBid the bid to validate
     * @param _signature the signature to validate
     * @param _signer the signer to validate
     * @return true if the signature belongs to the signer, false otherwise
     */
    function verifyPoolBid(
        WasabiStructs.PoolBid memory _poolBid,
        bytes memory _signature,
        address _signer
    ) internal view returns (bool) {
        return getSignerForPoolBid(_poolBid, _signature) == _signer;
    }

    /**
     * @return the current chain id
     */
    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}

// File: contracts/AbstractWasabiPool.sol














/**
 * An base abstract implementation of the IWasabiPool which handles issuing and exercising options alond with state management.
 */
abstract contract AbstractWasabiPool is IERC721Receiver, Ownable, IWasabiPool, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    // Pool metadata
    IWasabiPoolFactory public factory;
    WasabiOption private optionNFT;
    IERC721 private nft;
    address private admin;

    // Option state
    EnumerableSet.UintSet private optionIds;
    mapping(uint256 => uint256) private tokenIdToOptionId;
    mapping(uint256 => WasabiStructs.OptionData) private options;
    mapping(uint256 => bool) public idToFilledOrCancelled;

    receive() external payable virtual {}

    fallback() external payable {
        require(false, "No fallback");
    }

    /**
     * @dev Initializes this pool
     */
    function baseInitialize(
        IWasabiPoolFactory _factory,
        IERC721 _nft,
        address _optionNFT,
        address _owner,
        address _admin
    ) internal {
        require(owner() == address(0), "Already initialized");
        factory = _factory;
        _transferOwnership(_owner);

        nft = _nft;
        optionNFT = WasabiOption(_optionNFT);

        if (_admin != address(0)) {
            admin = _admin;
            emit AdminChanged(_admin);
        }
    }

    /// @inheritdoc IWasabiPool
    function getNftAddress() external view returns(address) {
        return address(nft);
    }

    /// @inheritdoc IWasabiPool
    function getLiquidityAddress() public view virtual returns(address) {
        return address(0);
    }

    /// @inheritdoc IWasabiPool
    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
        emit AdminChanged(_admin);
    }

    /// @inheritdoc IWasabiPool
    function removeAdmin() external onlyOwner {
        admin = address(0);
        emit AdminChanged(address(0));
    }

    /// @inheritdoc IWasabiPool
    function getAdmin() public view virtual returns (address) {
        return admin;
    }

    /// @inheritdoc IWasabiPool
    function getFactory() external view returns (address) {
        return address(factory);
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 tokenId,
        bytes memory /* data */)
    public virtual override returns (bytes4) {
        if (_msgSender() == address(optionNFT)) {
            if (!optionIds.contains(tokenId)) {
                revert IWasabiErrors.NftIsInvalid();
            }
            clearOption(tokenId, 0, false);
        } else if (_msgSender() != address(nft)) {
            revert IWasabiErrors.NftIsInvalid();
        }
        return this.onERC721Received.selector;
    }

    /// @inheritdoc IWasabiPool
    function writeOptionTo(
        WasabiStructs.PoolAsk calldata _request, bytes calldata _signature, address _receiver
    ) public payable nonReentrant returns (uint256) {
        if (idToFilledOrCancelled[_request.id]) {
            revert IWasabiErrors.OrderFilledOrCancelled();
        }
        validate(_request, _signature);

        uint256 optionId = optionNFT.mint(_receiver, address(factory));
        WasabiStructs.OptionData memory optionData = WasabiStructs.OptionData(
            true,
            _request.optionType,
            _request.strikePrice,
            _request.expiry,
            _request.tokenId
        );
        options[optionId] = optionData;

        // Lock NFT / Token into a vault
        if (_request.optionType == WasabiStructs.OptionType.CALL) {
            tokenIdToOptionId[_request.tokenId] = optionId;
        }
        optionIds.add(optionId);
        idToFilledOrCancelled[_request.id] = true;

        emit OptionIssued(optionId, _request.premium, _request.id);
        return optionId;
    }

    /// @inheritdoc IWasabiPool
    function writeOption(
        WasabiStructs.PoolAsk calldata _request, bytes calldata _signature
    ) external payable returns (uint256) {
        return writeOptionTo(_request, _signature, _msgSender());
    }

    /**
     * @dev Validates the given PoolAsk in order to issue an option
     */
    function validate(WasabiStructs.PoolAsk calldata _request, bytes calldata _signature) internal {
        // 1. Validate Signature
        address signer = PoolAskVerifier.getSignerForPoolAsk(_request, _signature);
        if (signer == address(0) || (signer != admin && signer != owner())) {
            revert IWasabiErrors.InvalidSignature();
        }

        // 2. Validate Meta
        if (_request.orderExpiry < block.timestamp) {
            revert IWasabiErrors.HasExpired();
        }
        
        require(_request.poolAddress == address(this), "WasabiPool: Signature doesn't belong to this pool");
        validateAndWithdrawPayment(_request.premium, "WasabiPool: Not enough premium is supplied");

        // 3. Request Validation
        if (_request.strikePrice == 0) {
            revert IWasabiErrors.InvalidStrike();
        }
        if (_request.expiry == 0) {
            revert IWasabiErrors.InvalidExpiry();
        }

        // 4. Type specific validation
        if (_request.optionType == WasabiStructs.OptionType.CALL) {
            if (nft.ownerOf(_request.tokenId) != address(this)) {
                revert IWasabiErrors.NftIsInvalid();
            }
            // Check that the token is free
            uint256 optionId = tokenIdToOptionId[_request.tokenId];
            if (isValid(optionId)) {
                revert IWasabiErrors.RequestNftIsLocked();
            }
        } else if (_request.optionType == WasabiStructs.OptionType.PUT) {
            if (availableBalance() < _request.strikePrice) {
                revert IWasabiErrors.InsufficientAvailableLiquidity();
            }
        }
    }

    /// @inheritdoc IWasabiPool
    function executeOption(uint256 _optionId) external payable nonReentrant {
        validateOptionForExecution(_optionId, 0);
        clearOption(_optionId, 0, true);
        emit OptionExecuted(_optionId);
    }

    /// @inheritdoc IWasabiPool
    function executeOptionWithSell(uint256 _optionId, uint256 _tokenId) external payable nonReentrant {
        validateOptionForExecution(_optionId, _tokenId);
        clearOption(_optionId, _tokenId, true);
        emit OptionExecuted(_optionId);
    }

    /**
     * @dev Validates the option if its available for execution
     */
    function validateOptionForExecution(uint256 _optionId, uint256 _tokenId) private {
        require(optionIds.contains(_optionId), "WasabiPool: Option NFT doesn't belong to this pool");
        require(_msgSender() == optionNFT.ownerOf(_optionId), "WasabiPool: Only the token owner can execute the option");

        WasabiStructs.OptionData memory optionData = options[_optionId];
        if (optionData.expiry < block.timestamp) {
            revert IWasabiErrors.HasExpired();
        }

        if (optionData.optionType == WasabiStructs.OptionType.CALL) {
            validateAndWithdrawPayment(optionData.strikePrice, "WasabiPool: Strike price needs to be supplied to execute a CALL option");
        } else if (optionData.optionType == WasabiStructs.OptionType.PUT) {
            require(_msgSender() == nft.ownerOf(_tokenId), "WasabiPool: Need to own the token to sell in order to execute a PUT option");
        }
    }

    /// @inheritdoc IWasabiPool
    function acceptBid(
        WasabiStructs.Bid calldata _bid,
        bytes calldata _signature,
        uint256 _tokenId
    ) public onlyOwner returns(uint256) {
        // Other validations are done in WasabiConduit
        if (_bid.optionType == WasabiStructs.OptionType.CALL) {
            if (!isAvailableTokenId(_tokenId)) {
                revert IWasabiErrors.NftIsInvalid();
            }
        } else {
            if (availableBalance() < _bid.strikePrice) {
                revert IWasabiErrors.InsufficientAvailableLiquidity();
            }
            _tokenId = 0;
        }

        // Lock NFT / Token into a vault
        uint256 _optionId = optionNFT.mint(_bid.buyer, address(factory));
        if (_bid.optionType == WasabiStructs.OptionType.CALL) {
            tokenIdToOptionId[_tokenId] = _optionId;
        }

        WasabiStructs.OptionData memory optionData = WasabiStructs.OptionData(
            true,
            _bid.optionType,
            _bid.strikePrice,
            _bid.expiry,
            _tokenId
        );
        options[_optionId] = optionData;
        optionIds.add(_optionId);

        emit OptionIssued(_optionId, _bid.price);
        IWasabiConduit(factory.getConduitAddress()).poolAcceptBid(_bid, _signature, _optionId);
        return _optionId;
    }

    /// @inheritdoc IWasabiPool
    function acceptAsk (
        WasabiStructs.Ask calldata _ask,
        bytes calldata _signature
    ) external onlyOwner {

        if (_ask.tokenAddress == getLiquidityAddress() && availableBalance() < _ask.price) {
            revert IWasabiErrors.InsufficientAvailableLiquidity();
        }

        if (_ask.tokenAddress == address(0)) {
            IWasabiConduit(factory.getConduitAddress()).acceptAsk{value: _ask.price}(_ask, _signature);
        } else {
            IERC20 erc20 = IERC20(_ask.tokenAddress);
            erc20.approve(factory.getConduitAddress(), _ask.price);
            IWasabiConduit(factory.getConduitAddress()).acceptAsk(_ask, _signature);
        }
    }

    /// @inheritdoc IWasabiPool
    function acceptPoolBid(WasabiStructs.PoolBid calldata _poolBid, bytes calldata _signature) external payable nonReentrant {
        // 1. Validate
        address signer = PoolBidVerifier.getSignerForPoolBid(_poolBid, _signature);
        if (signer != owner()) {
            revert IWasabiErrors.InvalidSignature();
        }
        if (!isValid(_poolBid.optionId)) {
            revert IWasabiErrors.HasExpired();
        }
        if (idToFilledOrCancelled[_poolBid.id]) {
            revert IWasabiErrors.OrderFilledOrCancelled();
        }
        if (_poolBid.orderExpiry < block.timestamp) {
            revert IWasabiErrors.HasExpired();
        }

        // 2. Only owner of option can accept bid
        if (_msgSender() != optionNFT.ownerOf(_poolBid.optionId)) {
            revert IWasabiErrors.Unauthorized();
        }

        if (_poolBid.tokenAddress == getLiquidityAddress()) {
            WasabiStructs.OptionData memory optionData = getOptionData(_poolBid.optionId);
            if (optionData.optionType == WasabiStructs.OptionType.CALL && availableBalance() < _poolBid.price) {
                revert IWasabiErrors.InsufficientAvailableLiquidity();
            } else if (optionData.optionType == WasabiStructs.OptionType.PUT &&
                // The strike price of the option can be used to payout the bid price
                (availableBalance() + optionData.strikePrice) < _poolBid.price
            ) {
                revert IWasabiErrors.InsufficientAvailableLiquidity();
            }
            clearOption(_poolBid.optionId, 0, false);
            payAddress(_msgSender(), _poolBid.price);
        } else {
            IWasabiFeeManager feeManager = IWasabiFeeManager(factory.getFeeManager());
            (address feeReceiver, uint256 feeAmount) = feeManager.getFeeData(address(this), _poolBid.price);
            uint256 maxFee = _maxFee(_poolBid.price);
            if (feeAmount > maxFee) {
                feeAmount = maxFee;
            }

            if (_poolBid.tokenAddress == address(0)) {
                if (address(this).balance < _poolBid.price) {
                    revert IWasabiErrors.InsufficientAvailableLiquidity();
                }
                (bool sent, ) = payable(_msgSender()).call{value: _poolBid.price - feeAmount}("");
                if (!sent) {
                    revert IWasabiErrors.FailedToSend();
                }
                if (feeAmount > 0) {
                    (bool _sent, ) = payable(feeReceiver).call{value: feeAmount}("");
                    if (!_sent) {
                        revert IWasabiErrors.FailedToSend();
                    }
                }
            } else {
                IERC20 erc20 = IERC20(_poolBid.tokenAddress);
                if (erc20.balanceOf(address(this)) < _poolBid.price) {
                    revert IWasabiErrors.InsufficientAvailableLiquidity();
                }
                if (!erc20.transfer(_msgSender(), _poolBid.price - feeAmount)) {
                    revert IWasabiErrors.FailedToSend();
                }
                if (feeAmount > 0) {
                    if (!erc20.transfer(feeReceiver, feeAmount)) {
                        revert IWasabiErrors.FailedToSend();
                    }
                }
            }
            clearOption(_poolBid.optionId, 0, false);
        }
        idToFilledOrCancelled[_poolBid.id] = true;
        emit PoolBidTaken(_poolBid.id);
    }

    /**
     * @dev An abstract function to check available balance in this pool.
     */
    function availableBalance() view public virtual returns(uint256);

    /**
     * @dev An abstract function to send payment for any function
     */
    function payAddress(address _seller, uint256 _amount) internal virtual;

    /**
     * @dev An abstract function to validate and withdraw payment for any function
     */
    function validateAndWithdrawPayment(uint256 _premium, string memory _message) internal virtual;

    /// @inheritdoc IWasabiPool
    function clearExpiredOptions(uint256[] memory _optionIds) public {
        if (_optionIds.length > 0) {
            for (uint256 i = 0; i < _optionIds.length; i++) {
                uint256 _optionId = _optionIds[i];
                if (!isValid(_optionId)) {
                    optionIds.remove(_optionId);
                }
            }
        } else {
            for (uint256 i = 0; i < optionIds.length();) {
                uint256 _optionId = optionIds.at(i);
                if (!isValid(_optionId)) {
                    optionIds.remove(_optionId);
                } else {
                    i ++;
                }
            }
        }
    }

    /**
     * @dev Clears the option from the existing state and optionally exercises it.
     */
    function clearOption(uint256 _optionId, uint256 _tokenId, bool _exercised) internal {
        WasabiStructs.OptionData memory optionData = options[_optionId];
        if (optionData.optionType == WasabiStructs.OptionType.CALL) {
            if (_exercised) {
                // Sell to executor, the validateOptionForExecution already checked if strike is paid
                nft.safeTransferFrom(address(this), _msgSender(), optionData.tokenId);
            }
            if (tokenIdToOptionId[optionData.tokenId] == _optionId) {
                delete tokenIdToOptionId[optionData.tokenId];
            }
        } else if (optionData.optionType == WasabiStructs.OptionType.PUT) {
            if (_exercised) {
                // Buy from executor
                nft.safeTransferFrom(_msgSender(), address(this), _tokenId);
                payAddress(_msgSender(), optionData.strikePrice);
            }
        }
        options[_optionId].active = false;
        optionIds.remove(_optionId);
        optionNFT.burn(_optionId);
    }

    /// @inheritdoc IWasabiPool
    function withdrawERC721(IERC721 _nft, uint256[] calldata _tokenIds) external onlyOwner nonReentrant {
        bool isPoolAsset = _nft == nft;

        uint256 numNFTs = _tokenIds.length;
        for (uint256 i; i < numNFTs; ) {
            if (isPoolAsset) {
                if (nft.ownerOf(_tokenIds[i]) != address(this)) {
                    revert IWasabiErrors.NftIsInvalid();
                }
                uint256 optionId = tokenIdToOptionId[_tokenIds[i]];
                if (isValid(optionId)) {
                    revert IWasabiErrors.RequestNftIsLocked();
                }

                delete tokenIdToOptionId[_tokenIds[i]];
            }
            _nft.safeTransferFrom(address(this), owner(), _tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IWasabiPool
    function depositERC721(IERC721 _nft, uint256[] calldata _tokenIds) external onlyOwner nonReentrant {
        require(_nft == nft, 'Invalid Collection');
        uint256 numNFTs = _tokenIds.length;
        for (uint256 i; i < numNFTs; ) {
            _nft.safeTransferFrom(_msgSender(), address(this), _tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IWasabiPool
    function cancelOrder(uint256 _orderId) external {
        if (_msgSender() != admin && _msgSender() != owner()) {
            revert IWasabiErrors.Unauthorized();
        }
        if (idToFilledOrCancelled[_orderId]) {
            revert IWasabiErrors.OrderFilledOrCancelled();
        }
        idToFilledOrCancelled[_orderId] = true;
        emit OrderCancelled(_orderId);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IWasabiPool).interfaceId
            || interfaceId == type(IERC721Receiver).interfaceId;
    }

    /// @inheritdoc IWasabiPool
    function isValid(uint256 _optionId) view public returns(bool) {
        return options[_optionId].active && options[_optionId].expiry >= block.timestamp;
    }

    /// @inheritdoc IWasabiPool
    function getOptionData(uint256 _optionId) public view returns(WasabiStructs.OptionData memory) {
        return options[_optionId];
    }

    /// @inheritdoc IWasabiPool
    function getOptionIdForToken(uint256 _tokenId) external view returns(uint256) {
        if (nft.ownerOf(_tokenId) != address(this)) {
            revert IWasabiErrors.NftIsInvalid();
        }
        return tokenIdToOptionId[_tokenId];
    }

    /// @inheritdoc IWasabiPool
    function getOptionIds() public view returns(uint256[] memory) {
        return optionIds.values();
    }

    /// @inheritdoc IWasabiPool
    function isAvailableTokenId(uint256 _tokenId) public view returns(bool) {
        if (nft.ownerOf(_tokenId) != address(this)) {
            return false;
        }
        uint256 optionId = tokenIdToOptionId[_tokenId];
        return !isValid(optionId);
    }

    /**
     * @dev returns the maximum fee that the protocol can take for the given amount
     */
    function _maxFee(uint256 _amount) internal pure returns(uint256) {
        return _amount / 10;
    }
}

// File: contracts/pools/ETHWasabiPool.sol






/**
 * An ETH backed implementation of the IWasabiErrors.
 */
contract ETHWasabiPool is AbstractWasabiPool {
    receive() external payable override {
        emit ETHReceived(msg.value);
    }

    /**
     * @dev Initializes this pool with the given parameters.
     */
    function initialize(
        IWasabiPoolFactory _factory,
        IERC721 _nft,
        address _optionNFT,
        address _owner,
        address _admin
    ) external payable {
        baseInitialize(_factory, _nft, _optionNFT, _owner, _admin);
    }

    /// @inheritdoc AbstractWasabiPool
    function validateAndWithdrawPayment(uint256 _premium, string memory _message) internal override {        
        IWasabiFeeManager feeManager = IWasabiFeeManager(factory.getFeeManager());
        (address feeReceiver, uint256 feeAmount) = feeManager.getFeeData(address(this), _premium);

        if (feeAmount > 0) {
            uint256 maxFee = _maxFee(_premium);
            if (feeAmount > maxFee) {
                feeAmount = maxFee;
            }

            (bool _sent, ) = payable(feeReceiver).call{value: feeAmount}("");
            if (!_sent) {
                revert IWasabiErrors.FailedToSend();
            }
        }

        require(msg.value >= (_premium + feeAmount) && _premium > 0, _message);
    }

    /// @inheritdoc AbstractWasabiPool
    function payAddress(address _seller, uint256 _amount) internal override {
        IWasabiFeeManager feeManager = IWasabiFeeManager(factory.getFeeManager());
        (address feeReceiver, uint256 feeAmount) = feeManager.getFeeData(address(this), _amount);

        if (feeAmount > 0) {
            uint256 maxFee = _maxFee(_amount);
            if (feeAmount > maxFee) {
                feeAmount = maxFee;
            }
            (bool _sent, ) = payable(feeReceiver).call{value: feeAmount}("");
            if (!_sent) {
                revert IWasabiErrors.FailedToSend();
            }
        }

        (bool sent, ) = payable(_seller).call{value: _amount - feeAmount}("");
        if (!sent) {
            revert IWasabiErrors.FailedToSend();
        }
    }

    /// @inheritdoc IWasabiPool
    function withdrawETH(uint256 _amount) external payable onlyOwner {
        if (availableBalance() < _amount) {
            revert IWasabiErrors.InsufficientAvailableLiquidity();
        }
        address payable to = payable(_msgSender());
        (bool sent, ) = to.call{value: _amount}("");
        if (!sent) {
            revert IWasabiErrors.FailedToSend();
        }

        emit ETHWithdrawn(_amount);
    }

    /// @inheritdoc IWasabiPool
    function withdrawERC20(IERC20 _token, uint256 _amount) external onlyOwner {
        if (!_token.transfer(msg.sender, _amount)) {
            revert IWasabiErrors.FailedToSend();
        }
    }

    /// @inheritdoc IWasabiPool
    function availableBalance() view public override returns(uint256) {
        uint256 balance = address(this).balance;
        uint256[] memory optionIds = getOptionIds();
        for (uint256 i = 0; i < optionIds.length; i++) {
            WasabiStructs.OptionData memory optionData = getOptionData(optionIds[i]);
            if (optionData.optionType == WasabiStructs.OptionType.PUT && isValid(optionIds[i])) {
                balance -= optionData.strikePrice;
            }
        }
        return balance;
    }
}