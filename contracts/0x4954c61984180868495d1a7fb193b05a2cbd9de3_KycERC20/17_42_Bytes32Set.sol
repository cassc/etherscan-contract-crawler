// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

/**
 * @notice Key sets with enumeration. Uses mappings for random and existence checks
 * and dynamic arrays for enumeration. Key uniqueness is enforced.
 * @dev This implementation has deletion disabled (removed) because doesn't require it. Therefore, keys
 are organized in order of insertion.
 */

library Bytes32Set {

    struct Set {
        mapping(bytes32 => uint256) keyPointers;
        bytes32[] keyList;
    }

    string private constant MODULE = "Bytes32Set";

    error Bytes32SetConsistency(string module, string method, string reason, string context);

    /**
     * @notice Insert a key to store.
     * @dev Duplicate keys are not permitted.
     * @param self A Set struct
     * @param key A value in the Set.
     * @param context A message string about interpretation of the issue. Normally the calling function.
     */
    function insert(
        Set storage self,
        bytes32 key,
        string memory context
    ) internal {
        if (exists(self, key))
            revert Bytes32SetConsistency({
                module: MODULE,
                method: "insert",
                reason: "exists",
                context: context
            });
        self.keyPointers[key] = self.keyList.length;
        self.keyList.push(key);
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
        bytes32 key,
        string memory context
    ) internal {
        if (!exists(self, key))
            revert Bytes32SetConsistency({
                module: MODULE,
                method: "remove",
                reason: "does not exist",
                context: context
            });
        bytes32 keyToMove = self.keyList[count(self) - 1];
        uint256 rowToReplace = self.keyPointers[key];
        self.keyPointers[keyToMove] = rowToReplace;
        self.keyList[rowToReplace] = keyToMove;
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    /**
     * @notice Count the keys.
     * @param self A Set struct
     * @return uint256 Length of the `keyList` which is the count of keys contained in the Set.
     */
    function count(Set storage self) internal view returns (uint256) {
        return (self.keyList.length);
    }

    /**
     * @notice Check if a key exists in the Set.
     * @param self A Set struct
     * @param key A key to look for.
     * @return bool True if the key exists in the Set, otherwise false.
     */
    function exists(Set storage self, bytes32 key) internal view returns (bool) {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice Retrieve an bytes32 by its position in the Set. Use for enumeration.
     * @param self A Set struct
     * @param index The position in the Set to inspect.
     * @return bytes32 The key stored in the Set at the index position.
     */
    function keyAtIndex(Set storage self, uint256 index) internal view returns (bytes32) {
        return self.keyList[index];
    }
}