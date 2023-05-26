// SPDX-License-Identifier: MIT

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.7.0;

/// @notice Key sets for addresses with enumeration and delete. Uses mappings for random
/// and existence checks and dynamic arrays for enumeration. Key uniqueness is enforced.
/// @dev IterableAddressSets are unordered. Delete operations reorder keys. All operations have a
/// fixed gas cost at any scale, O(1).
/// Code inspired by https://github.com/rob-Hitchens/SetTypes/blob/master/contracts/AddressSet.sol
/// and updated to solidity 0.7.x
library IterableAddressSetUtils {
    /// @dev struct stores array of addresses and mapping of addresses to indices to allow O(1) CRUD operations
    struct IterableAddressSet {
        mapping(address => uint256) indices;
        address[] addresses;
    }

    /// @notice insert a key.
    /// @dev duplicate keys are not permitted but fails silently to avoid wasting gas on exist + insert calls
    /// @param self storage pointer to IterableAddressSet
    /// @param key value to insert.
    function insert(IterableAddressSet storage self, address key) internal {
        if (!exists(self, key)) {
            self.addresses.push(key);
            self.indices[key] = self.addresses.length - 1;
        }
    }

    /// @notice remove a key.
    /// @dev key to remove should exist but fails silently to avoid wasting gas on exist + remove calls
    /// @param self storage pointer to IterableAddressSet
    /// @param key value to remove.
    function remove(IterableAddressSet storage self, address key) internal {
        if (!exists(self, key)) {
            return;
        }

        uint256 last = self.addresses.length - 1;
        uint256 indexToReplace = self.indices[key];
        if (indexToReplace != last) {
            address keyToMove = self.addresses[last];
            self.indices[keyToMove] = indexToReplace;
            self.addresses[indexToReplace] = keyToMove;
        }

        delete self.indices[key];
        self.addresses.pop();
    }

    /// @notice check if a key is in IterableAddressSet
    /// @param self storage pointer to IterableAddressSet
    /// @param key value to check.
    /// @return bool true: is a member, false: not a member.
    function exists(IterableAddressSet storage self, address key) internal view returns (bool) {
        if (self.addresses.length == 0) return false;

        return self.addresses[self.indices[key]] == key;
    }
}