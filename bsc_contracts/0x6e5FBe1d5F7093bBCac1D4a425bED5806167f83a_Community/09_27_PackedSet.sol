// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

//import "hardhat/console.sol";
/**
 * 
 */
library PackedSet {
    // pow                                                                                                      
    // 6 - means 2**6 = 64. 64 times in uint256 fill completely by max value 0xf                ((2**4)-1)  and MAX SLOTS AND mapping index key = ((2**4)-1)/64 = 0+1 = 1
    // 5 - means 2**5 = 32. 32 times in uint256 fill completely by max value 0xff               ((2**8)-1)  and MAX SLOTS AND mapping index key = ((2**8)-1)/32 = 7+1 = 8
    // 4 - means 2**4 = 16. 16 times in uint256 fill completely by max value 0xffff             ((2**16)-1) and MAX SLOTS AND mapping index key = ((2**16)-1)/16 = 0+1 = 4095
    // 3 - 2**3=8.           8 times in uint256 fill completely by max value 0xffffffff         ((2**32)-1) and MAX SLOTS AND mapping index key = ((2**32)-1)/4 = 0+1 = 1073741823
    // 2 - 2**2=4.           4 times in uint256 fill completely by max value 0xffffffffffffffff ((2**64)-1) and MAX SLOTS AND mapping index key = ((2**64)-1)/2 = 0+1 = 9223372036854775807
    // 1 - 2**1=2.           2 times in uint256 fill completely by max value                    ((2**128)-1)
    // summary 
    // best to use 6.5.4  because have a low iteration in indexes to find already exist item

    uint256 private constant pow = 5;
    uint256 private constant powMaxVal = 256/(2**pow);
    struct Set {
        // mapKey - key in mapping
        // key - position in mapping value 
        // value value at position key in mapping value
        // for example
        // if store [0=>65535 1=>4369 2=>13107]
        // in packed mapping we will store 
        // in mapkey = 0 value "ffff111133330000000000000000000000000000000000000000000000000000"
        // where 0xffff, 0x1111, 0x3333 it's 65535,4369,13107 respectively,  with indexes 0,1,2
        mapping(uint256 => uint256) list;

        uint256 size;

    }
  
    function _push(Set storage _set, uint256 value) private returns (bool ret) {
        (,ret) = _contains(_set, value);
        if (!ret) {
            _update(_set, _set.size, value);
            _set.size += 1;
            ret = !ret;
        }
        return ret;
    }

    function _pop(Set storage _set, uint256 value) private returns (bool) {
        //uint256 key;
        (uint256 key, bool ret) = _contains(_set, value);
        if (ret) {
            uint256 lastKey = _set.size-1;
            uint256 lastVal = _get(_set, lastKey);

            _update(_set, key, lastVal);

            _update(_set, lastKey, 0);
            _set.size -= 1;
            
            return true;
        } else {
            return false;
        }
    }

    function _get(Set storage _set, uint256 key) private view returns (uint256 ret) {

        uint256 mapId = key >> pow;
        uint256 mapVal = _set.list[mapId];
        uint256 mapValueIndex = uint256((key) - ((key>>pow)<<pow)) + 1;
        uint256 bitOffset = (256-mapValueIndex*powMaxVal);

        uint256 maxPowVal = (2**(powMaxVal)-1);

        ret = uint16( (mapVal & (maxPowVal<<bitOffset))>>bitOffset);
    }

     /**
     * @dev Returns true if the value is in the set. O(size + maxSizeInUint256).
     */
    function _contains(Set storage _set, uint256 value) private view returns (uint256, bool) {
        uint256 maxSizeInUint256 = 2**pow;
        uint256 bitOffset;

        for (uint256 i=0; i < _set.size; i++) {
            for (uint256 j=0; j < maxSizeInUint256; j++) {
                bitOffset = (256-(uint256(j)*powMaxVal));
                if (value == uint256( (_set.list[i] & (( ((2**(256/(2**pow)))-1) )<<bitOffset))>>bitOffset)) {
                    return (i*(maxSizeInUint256)+j-1,true);
                }
            }
        }
        return (0,false);
    }


    function _update(Set storage _set, uint256 key, uint256 value) private {
        
        uint256 mapId = key >> pow;
        uint256 mapVal = _set.list[mapId];
        uint256 mapValueIndex = uint256((key) - ((key>>pow)<<pow)) + 1;
        uint256 bitOffset = (256-mapValueIndex*powMaxVal);

        uint256 maxPowVal = (2**(powMaxVal)-1);
        uint256 zeroMask = (type(uint256).max)^( maxPowVal <<(bitOffset));
        uint256 valueMask = uint256(value)<<bitOffset;

        _set.list[mapId] = (mapVal & zeroMask | valueMask);

    }

    function get(Set storage _set, uint256 key) internal view returns (uint8 ret) {
        ret = uint8(_get(_set, key));
    }

    function add(Set storage _set, uint8 value) internal {
        _push(_set, uint256(value));
    }

    function remove(Set storage _set, uint8 value) internal {
        _pop(_set, uint256(value));
    }

    function contains(Set storage _set, uint256 value) internal view returns (bool ret) {
        (, ret) = _contains(_set, value);
    }

    function length(Set storage _set) internal view returns (uint256) {
        return _set.size;
    }
    
    // function getZeroSlot(Set storage _set) internal view returns(uint256) {
    //     return _set.list[0];
    // }
    
/*
    function getBatch(Map storage map, uint256[] memory keys) internal view returns (uint16[] memory values) {
        values = new uint16[](keys.length);
        for(uint256 i = 0; i< keys.length; i++) {
            values[i] = _get(map, keys[i]);
        }
    }

    function setBatch(Map storage map, uint256[] memory keys, uint16[] memory values) internal {
        for(uint256 i = 0; i< keys.length; i++) {
            _set(map, keys[i], values[i]);
        }
        
    }
*/
}