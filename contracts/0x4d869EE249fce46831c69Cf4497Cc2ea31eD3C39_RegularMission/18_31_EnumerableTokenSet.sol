// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./NFT.sol";

library EnumerableTokenSet {
    using NFT for NFT.TokenStruct;

    struct Set {
        NFT.TokenStruct[] _values;
        mapping(string => uint256) _indexes;
    }

    function add(Set storage set, NFT.TokenStruct memory token) internal returns (bool) {
        if (!contains(set, token)) {
            set._values.push(token);
            set._indexes[token.createKey()] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function update(Set storage set, NFT.TokenStruct memory token)
        internal
        returns (bool)
    {
        if (contains(set, token)) {
            uint256 idx = set._indexes[token.createKey()];
            set._values[idx - 1] = token;
            return true;
        } else {
            return false;
        }
    }

    function remove(Set storage set, NFT.TokenStruct memory token)
        internal
        returns (bool)
    {
        string memory deleteKey = token.createKey();
        uint256 valueIndex = set._indexes[deleteKey];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                NFT.TokenStruct storage lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue.createKey()] = valueIndex;
            }

            set._values.pop();
            delete set._indexes[deleteKey];

            return true;
        } else {
            return false;
        }
    }

    function contains(Set storage set, NFT.TokenStruct memory token)
        internal
        view
        returns (bool)
    {
        return set._indexes[token.createKey()] != 0;
    }

    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function at(Set storage set, uint256 index)
        internal
        view
        returns (NFT.TokenStruct memory)
    {
        return set._values[index];
    }

    function values(Set storage set) internal view returns (NFT.TokenStruct[] memory) {
        return set._values;
    }
}