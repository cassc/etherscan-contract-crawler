// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library RestrictedMinters {
    struct Minter {
        address _address;
        uint64 _mintCount;
    }

    struct Set {
        Minter[] _values;
        mapping(address => uint256) _indexes;
    }

    function add(Set storage set, address minter, uint64 amount) internal {
        Minter memory _minter = Minter(minter, amount);
        if (!contains(set, minter)) {
            set._values.push(_minter);
            set._indexes[minter] = set._values.length;
        } else {
            set._values[set._indexes[minter] - 1]._mintCount += amount;
        }
    }

    function deleteAll(Set storage set) internal {
        uint256 length = set._values.length;
        if (length > 0) {
            for (uint256 i = 0; i < length; i++) {
                uint256 idx = length - i - 1;
                address deleteAddress = set._values[idx]._address;
                delete set._indexes[deleteAddress];
                set._values.pop();
            }
        }
    }

    function contains(Set storage set, address minter) internal view returns (bool) {
        return set._indexes[minter] != 0;
    }

    function getMintCount(Set storage set, address minter) internal view returns (uint256) {
        uint256 idx = set._indexes[minter];
        if(idx == 0) {
            return 0;
        }
        return set._values[idx - 1]._mintCount;
    }
}