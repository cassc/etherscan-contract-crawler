// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

library Contributors {
    struct Contributor {
        address payable payee;
        uint16 weight;
    }

    struct Set {
        Contributor[] _values;
        mapping(address => uint256) _indexes;
    }

    function add(Set storage set, Contributor memory contributor)
        internal
        returns (bool)
    {
        if (!contains(set, contributor.payee)) {
            set._values.push(contributor);
            set._indexes[contributor.payee] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function update(Set storage set, Contributor memory contributor)
        internal
        returns (bool)
    {
        if (contains(set, contributor.payee)) {
            uint256 idx = set._indexes[contributor.payee];
            set._values[idx - 1].weight = contributor.weight;
            return true;
        } else {
            return false;
        }
    }

    function remove(Set storage set, address contributorAddress)
        internal
        returns (bool)
    {
        uint256 valueIndex = set._indexes[contributorAddress];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                Contributor storage lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue.payee] = valueIndex;
            }

            set._values.pop();
            delete set._indexes[contributorAddress];

            return true;
        } else {
            return false;
        }
    }

    function contains(Set storage set, address contributorAddress)
        internal
        view
        returns (bool)
    {
        return
            set._indexes[contributorAddress] != 0;
    }

    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function at(Set storage set, uint256 index)
        internal
        view
        returns (Contributor memory)
    {
        return set._values[index];
    }

    function values(Set storage set)
        internal
        view
        returns (Contributor[] memory)
    {
        return set._values;
    }
}