// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../Constants.sol";

library RollingBuckets {
    error BucketValueExceedsLimit();
    error BucketLengthExceedsLimit();

    /// @dev `MAX_BUCKET_SIZE` must be a multiple of `WORD_ELEMENT_SIZE`,
    /// otherwise some words may be incomplete which may lead to incorrect bit positioning.
    uint256 constant MAX_BUCKET_SIZE = Constants.MAX_LOCKING_BUCKET;
    /// @dev each `ELEMENT_BIT_SIZE` bits stores an element
    uint256 constant ELEMENT_BIT_SIZE = 24;
    /// @dev `ELEMENT_BIT_SIZE` bits mask
    uint256 constant MASK = 0xFFFFFF;
    /// @dev one word(256 bits) can store (256 // ELEMENT_BIT_SIZE) elements
    uint256 constant WORD_ELEMENT_SIZE = 10;

    function position(uint256 tick) private pure returns (uint256 wordPos, uint256 bitPos) {
        unchecked {
            wordPos = tick / WORD_ELEMENT_SIZE;
            bitPos = tick % WORD_ELEMENT_SIZE;
        }
    }

    function get(mapping(uint256 => uint256) storage buckets, uint256 bucketStamp) internal view returns (uint256) {
        unchecked {
            (uint256 wordPos, uint256 bitPos) = position(bucketStamp % MAX_BUCKET_SIZE);
            return (buckets[wordPos] >> (bitPos * ELEMENT_BIT_SIZE)) & MASK;
        }
    }

    /// [first, last)
    function batchGet(mapping(uint256 => uint256) storage buckets, uint256 firstStamp, uint256 lastStamp)
        internal
        view
        returns (uint256[] memory)
    {
        if (firstStamp > lastStamp) revert BucketLengthExceedsLimit();

        uint256 len;
        unchecked {
            len = lastStamp - firstStamp;
        }

        if (len > MAX_BUCKET_SIZE) {
            revert BucketLengthExceedsLimit();
        }

        uint256[] memory result = new uint256[](len);
        uint256 resultIndex;

        unchecked {
            (uint256 wordPos, uint256 bitPos) = position(firstStamp % MAX_BUCKET_SIZE);

            uint256 wordVal = buckets[wordPos];
            uint256 mask = MASK << (bitPos * ELEMENT_BIT_SIZE);

            for (uint256 i = firstStamp; i < lastStamp;) {
                assembly {
                    /// increase idx firstly to skip `array length`
                    resultIndex := add(resultIndex, 0x20)
                    /// wordVal store order starts from lowest bit
                    /// result[i] = ((wordVal & mask) >> (bitPos * ELEMENT_BIT_SIZE))
                    mstore(add(result, resultIndex), shr(mul(bitPos, ELEMENT_BIT_SIZE), and(wordVal, mask)))
                    mask := shl(ELEMENT_BIT_SIZE, mask)
                    bitPos := add(bitPos, 1)
                    i := add(i, 1)
                }

                if (bitPos == WORD_ELEMENT_SIZE) {
                    (wordPos, bitPos) = position(i % MAX_BUCKET_SIZE);

                    wordVal = buckets[wordPos];
                    mask = MASK;
                }
            }
        }

        return result;
    }

    function set(mapping(uint256 => uint256) storage buckets, uint256 bucketStamp, uint256 value) internal {
        if (value > MASK) revert BucketValueExceedsLimit();

        unchecked {
            (uint256 wordPos, uint256 bitPos) = position(bucketStamp % MAX_BUCKET_SIZE);

            uint256 wordValue = buckets[wordPos];
            uint256 newValue = value << (bitPos * ELEMENT_BIT_SIZE);

            uint256 newWord = (wordValue & ~(MASK << (bitPos * ELEMENT_BIT_SIZE))) | newValue;
            buckets[wordPos] = newWord;
        }
    }

    function batchSet(mapping(uint256 => uint256) storage buckets, uint256 firstStamp, uint256[] memory values)
        internal
    {
        uint256 valLength = values.length;
        if (valLength > MAX_BUCKET_SIZE) revert BucketLengthExceedsLimit();
        if (firstStamp > (type(uint256).max - valLength)) {
            revert BucketLengthExceedsLimit();
        }

        unchecked {
            (uint256 wordPos, uint256 bitPos) = position(firstStamp % MAX_BUCKET_SIZE);

            uint256 wordValue = buckets[wordPos];
            uint256 mask = ~(MASK << (bitPos * ELEMENT_BIT_SIZE));

            /// reuse val length as End Postion
            valLength = (valLength + 1) * 0x20;
            /// start from first element offset
            for (uint256 i = 0x20; i < valLength; i += 0x20) {
                uint256 val;
                assembly {
                    val := mload(add(values, i))
                }
                if (val > MASK) revert BucketValueExceedsLimit();

                assembly {
                    /// newVal = val << (bitPos * BIT_SIZE)
                    let newVal := shl(mul(bitPos, ELEMENT_BIT_SIZE), val)
                    /// save newVal to wordVal, clear corresponding bits and set them as newVal
                    /// wordValue = (wordVal & mask) | newVal
                    wordValue := or(and(wordValue, mask), newVal)
                    /// goto next number idx in current word
                    bitPos := add(bitPos, 1)
                    /// mask = ~(MASK << (bitPos, BIT_SIZE))
                    mask := not(shl(mul(bitPos, ELEMENT_BIT_SIZE), MASK))
                }

                if (bitPos == WORD_ELEMENT_SIZE) {
                    /// store hole word
                    buckets[wordPos] = wordValue;

                    /// get next word' position
                    (wordPos, bitPos) = position((firstStamp + (i / 0x20)) % MAX_BUCKET_SIZE);
                    wordValue = buckets[wordPos];
                    /// restore mask to make it start from lowest bits
                    mask = ~MASK;
                }
            }
            /// store last word which may incomplete
            buckets[wordPos] = wordValue;
        }
    }
}