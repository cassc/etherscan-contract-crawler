// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Sales {
    struct Sale {
        uint8 id;
        uint16 maxMintAmount;
        uint64 mintCost;
        uint64 maxSupply;
        uint8 hasRestriction;
        uint8 isBurnAndMint;
        bytes32 merkleRoot;
    }

    struct Set {
        Sale[] _values;
        mapping(uint8 => uint256) _indexes;
    }

    function add(Set storage set, Sale memory sale) internal returns (bool) {
        if (!contains(set, sale.id)) {
            set._values.push(sale);
            set._indexes[sale.id] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function update(Set storage set, Sale memory sale) internal returns (bool) {
        if (contains(set, sale.id)) {
            uint256 idx = set._indexes[sale.id];
            set._values[idx - 1] = sale;
            return true;
        } else {
            return false;
        }
    }

    function remove(Set storage set, uint8 id) internal returns (bool) {
        uint256 valueIndex = set._indexes[id];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                Sale storage lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue.id] = valueIndex;
            }

            set._values.pop();
            delete set._indexes[id];

            return true;
        } else {
            return false;
        }
    }

    function contains(Set storage set, uint8 id) internal view returns (bool) {
        return set._indexes[id] != 0;
    }

    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function at(Set storage set, uint256 index) internal view returns (Sale memory) {
        return set._values[index];
    }

    function get(Set storage set, uint8 id) internal view returns (Sale memory) {
        return at(set, set._indexes[id] - 1);
    }

    function values(Set storage set) internal view returns (Sale[] memory) {
        return set._values;
    }
}