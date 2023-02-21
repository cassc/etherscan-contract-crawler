// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library EnumerableSalesSet {
    
    struct Sales {
        address buyer;
        uint256 amount;
    }
    
    struct Set {
        Sales[] _values;
        mapping(address => uint256) _indexes;
    }

    function add(Set storage set, Sales memory value) internal returns (bool) {
        if (!contains(set, value)) {
            set._values.push(value);
            set._indexes[value.buyer] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function remove(Set storage set, Sales memory value) internal returns (bool) {
        uint256 valueIndex = set._indexes[value.buyer];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                Sales memory lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue.buyer] = valueIndex;
            }

            set._values.pop();
            delete set._indexes[value.buyer];

            return true;
        } else {
            return false;
        }
    }

    function contains(Set storage set, Sales memory value) internal view returns (bool) {
        return set._indexes[value.buyer] != 0;
    }

    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function at(Set storage set, uint256 index) internal view returns (Sales memory) {
        return set._values[index];
    }

    function values(Set storage set) internal view returns (Sales[] memory) {
        return set._values;
    }
}