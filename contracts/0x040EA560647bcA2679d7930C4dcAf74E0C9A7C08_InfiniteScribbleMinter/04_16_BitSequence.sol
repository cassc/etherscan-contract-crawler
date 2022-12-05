// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* @title BitSequence
 * @author minimizer <[email protected]>; https://minimizer.art/
 * 
 * Based on OpenZeppelin's BitMap, this library allows the user to store a series of booleans
 * sequentially indexed at zero, and find the first index at which the boolean is set to true
 * starting at a given index and working backwards.
 * 
 * The use case is to assist in storing and efficiently retrieving the index of data stored
 * in a corresponding sparsely populated dataset. For example if five tokens have the same
 * attributea value it can be stored in just the id of the first token, and all other ones can
 * look back at that token's value, using the BitSequence to find the correct index.
 */
struct BitSequence {
    mapping(uint => uint) bits;
}

using BitSequenceLib for BitSequence global;

library BitSequenceLib {
    //Bits can only be set, not unset. This code is very much borrowed from BitMap
    function set(BitSequence storage sequence, uint index) internal {
        sequence.bits[index >> 8] |= (1 << (index & 0xff));
    }
    
    //Works backwards looking for a given index to be set. Returns -1 if it can't find any bits set
    function firstSet(BitSequence storage sequence, uint startingIndex) internal view returns (int) {
        unchecked {
            int initialBucket = int(startingIndex >> 8);
            for(int bucket = initialBucket; bucket >= 0; bucket--) {
                uint bits = sequence.bits[uint(bucket)];
                if(bits>0) {
                    int slot = findFirstSetBitFromIndex(bits, int(bucket==initialBucket ? startingIndex & 0xff : 255));
                    if(slot >= 0) {
                        return slot + (bucket << 8);
                    }
                }
            }
            return -1;
        }
    }
    
    //Helper function which looks within a 256-bit uint to see which bit is set, working backwards from index
    function findFirstSetBitFromIndex(uint bits, int index) internal pure returns (int) {
        //check the 256 bits in groups of 16 to see if there are any bits set
        //then if a group has bits set, check each bit sequentially
        unchecked {
            while(index >=0) {
                int nextGroupIndex = (index >> 4 << 4) - 1;
                
                if((bits & (0xffff << (uint(index) >> 4 << 4)) == 0)) {
                    index = nextGroupIndex;
                }
                else {
                    while(index > nextGroupIndex) {
                        if(bits & (1 << uint(index)) != 0) {
                            return int(index);
                        }
                        index--;
                    }        
                }
            }
        }
        
        return -1;
    }
}