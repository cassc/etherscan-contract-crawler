// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

import "./CopyrightConstant.sol";

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
 * and `uint256` (`CopyrightHolderSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library CopyrightInfo {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.
    struct CopyrightHolder {
        address account;
        uint24 manageFlag;
        uint24 grantFlag;
        uint24 excuteFlag;
        uint16 customFlag;
        uint8 reservedFlag;
    }

    struct CopyrightRegistry {
        uint40 lockup;
        uint40 appliedAt;
        uint16 policy;
    }

    struct CopyrightHolderSet {
        // Storage of set values
        CopyrightHolder[] _values;
        // left 8bits of reservedFlag represents royalty splits
        // keep track of sum to prevent splits bug
        address _rootAccount;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(address => uint256) _indexes;
    }

    function resolveCopyrightRegistry(CopyrightRegistry memory registry)
        internal
        pure
        returns (
            uint40 lockup,
            uint40 appliedAt,
            uint16 policy
        )
    {
        lockup = registry.lockup;
        appliedAt = registry.appliedAt;
        policy = registry.policy;
    }

    function resolveCopyrightHolder(CopyrightHolder memory copyrightHolder)
        internal
        pure
        returns (
            address account,
            uint24 manageFlag,
            uint24 grantFlag,
            uint24 excuteFlag,
            uint16 customFlag,
            uint8 reservedFlag
        )
    {
        account = copyrightHolder.account;
        manageFlag = copyrightHolder.manageFlag;
        grantFlag = copyrightHolder.grantFlag;
        excuteFlag = copyrightHolder.excuteFlag;
        reservedFlag = copyrightHolder.reservedFlag;
        customFlag = copyrightHolder.customFlag;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(CopyrightHolderSet storage set, CopyrightHolder memory value)
        internal
        returns (bool)
    {
        if (!contains(set, value.account)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value.account] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @return If it doesn't exist, it returns false
     * If it exist, it updates
     */
    function update(
        CopyrightHolderSet storage set,
        CopyrightHolder memory value
    ) internal returns (bool) {
        if (contains(set, value.account)) {
            //if exist, update
            uint256 index = set._indexes[value.account];
            set._values[index - 1] = value;
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Add or Update a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function addOrUpdate(
        CopyrightHolderSet storage set,
        CopyrightHolder memory value
    ) internal returns (bool) {
        if (!contains(set, value.account)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value.account] = set._values.length;
            return true;
        } else {
            //if exist, update
            uint256 index = set._indexes[value.account];
            set._values[index - 1] = value;
            return true;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */

    function remove(CopyrightHolderSet storage set, address addr)
        internal
        returns (bool)
    {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[addr];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                CopyrightHolder memory lastValue = set._values[lastIndex];
                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue.account] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[addr];
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(CopyrightHolderSet storage set, address addr)
        internal
        view
        returns (bool)
    {
        return set._indexes[addr] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(CopyrightHolderSet storage set)
        internal
        view
        returns (uint256)
    {
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
    function valueAtIndex(CopyrightHolderSet storage set, uint256 index)
        internal
        view
        returns (CopyrightHolder memory)
    {
        return set._values[index];
    }

    function valueAtAddress(CopyrightHolderSet storage set, address addr)
        internal
        view
        returns (CopyrightHolder memory copyrightHolder)
    {
        uint256 index = set._indexes[addr];
        if (index != 0) {
            //since we add all index 1, need to minus 1
            copyrightHolder = set._values[index - 1];
        } else {
            //if not exist, it will return CopyrightHolder(0,0,0,0)
            copyrightHolder = CopyrightHolder({
                account: addr,
                manageFlag: 0,
                grantFlag: 0,
                excuteFlag: 0,
                customFlag: 0,
                reservedFlag: 0
            });
        }
    }

    function values(CopyrightHolderSet storage set)
        internal
        view
        returns (CopyrightHolder[] memory)
    {
        return set._values;
    }
}