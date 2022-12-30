// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "IERC20.sol";
import "IERC721.sol";

// inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol
library ListingSetLib {
    struct Listing {
        IERC721 nftContract;
        uint256 tokenId;
        IERC20 payableToken;
        uint256 price;
    }

    struct ListingSet {
        Listing[] _values;
        // it's not possible to use struct Listing as a mapping key so we use embedded mappings
        //   per each attribute
        //   think about the following structure as about
        //   mapping(Listing /*value*/ => uint256 /*index*/)
        mapping(IERC721 /*nftContract*/ =>
            mapping(uint256 /*tokenId*/ =>
                mapping(IERC20 /*payableToken*/ =>
                    mapping(uint256 /*price*/ => uint256 /*index*/)))) _indexes;
    }

    function getIndex(
        ListingSet storage set,
        Listing memory value
    ) private view returns(uint256) {
        return set._indexes[value.nftContract][value.tokenId][value.payableToken][value.price];
    }

    function setIndex(
        ListingSet storage set,
        Listing memory value,
        uint256 index
    ) private {
        set._indexes[value.nftContract][value.tokenId][value.payableToken][value.price] = index;
    }

    function deleteIndex(
        ListingSet storage set,
        Listing memory value
    ) private {
        delete set._indexes[value.nftContract][value.tokenId][value.payableToken][value.price];
    }

    function add(
        ListingSet storage set,
        Listing memory value
    ) internal {
        if (!contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            setIndex(set, value, set._values.length);
        }
    }

    function remove(
        ListingSet storage set,
        Listing memory value
    ) internal returns(bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = getIndex(set, value);

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                Listing memory lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                setIndex(set, lastValue, valueIndex); // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            deleteIndex(set, value);
            return true;
        } else {
            return false;
        }
    }

    function contains(
        ListingSet storage set,
        Listing memory value
    ) internal view returns (bool) {
        return getIndex(set, value) != 0;
    }

    function length(
        ListingSet storage set
    ) internal view returns (uint256) {
        return set._values.length;
    }

    function at(ListingSet storage set, uint256 index) internal view returns (Listing memory) {
        return set._values[index];
    }
}