// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

/**
 * @notice Key sets with enumeration and delete. Uses mappings for random access and existence checks,
 * and dynamic arrays for enumeration. Key uniqueness is enforced.
 * @dev Sets are unordered. Delete operations reorder keys.
 */

library AddressSet {

    struct Set {
        mapping(address => uint256) keyPointers;
        address[] keyList;
    }

    string private constant MODULE = "AddressSet";

    error AddressSetConsistency(string module, string method, string reason, string context);

    /**
     * @notice Insert a key to store.
     * @dev Duplicate keys are not permitted.
     * @param self A Set struct
     * @param key A key to insert cast as an address.
     * @param context A message string about interpretation of the issue. Normally the calling function.
     */
    function insert(
        Set storage self,
        address key,
        string memory context
    ) internal {
        if (exists(self, key))
            revert AddressSetConsistency({
                module: MODULE,
                method: "insert",
                reason: "exists",
                context: context
            });
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    /**
     * @notice Remove a key from the store.
     * @dev The key to remove must exist.
     * @param self A Set struct
     * @param key An address to remove from the Set.
     * @param context A message string about interpretation of the issue. Normally the calling function.
     */
    function remove(
        Set storage self,
        address key,
        string memory context
    ) internal {
        if (!exists(self, key))
            revert AddressSetConsistency({
                module: MODULE,
                method: "remove",
                reason: "does not exist",
                context: context
            });
        address keyToMove = self.keyList[count(self) - 1];
        uint256 rowToReplace = self.keyPointers[key];
        self.keyPointers[keyToMove] = rowToReplace;
        self.keyList[rowToReplace] = keyToMove;
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    /**
     * @notice Count the keys.
     * @param self A Set struct
     * @return uint256 Length of the `keyList`, which correspond to the number of elements
     * stored in the `keyPointers` mapping.
     */
    function count(Set storage self) internal view returns (uint256) {
        return (self.keyList.length);
    }

    /**
     * @notice Check if a key exists in the Set.
     * @param self A Set struct
     * @param key An address to look for in the Set.
     * @return bool True if the key exists in the Set, otherwise false.
     */
    function exists(Set storage self, address key) internal view returns (bool) {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice Retrieve an address by its position in the set. Use for enumeration.
     * @param self A Set struct
     * @param index The internal index to inspect.
     * @return address Address value stored at the index position in the Set.
     */
    function keyAtIndex(Set storage self, uint256 index) internal view returns (address) {
        return self.keyList[index];
    }
}