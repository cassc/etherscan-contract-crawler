//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Core utils used extensively to format CSS and numbers.

// modified from original to take away functions that I'm not using
// also includes the random number parser 
library utils {
    // converts an unsigned integer to a string
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return '0';
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // helper function for generation
    // from: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol 
    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint; 

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }
        return tempUint;
    }

    // from: https://ethereum.stackexchange.com/questions/31457/substring-in-solidity/31470
    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function generateDecimalString(uint nr, uint decimals) internal pure returns (string memory) {
        if(decimals == 1) { return string(abi.encodePacked('0.', uint2str(nr))); }
        if(decimals == 2) { return string(abi.encodePacked('0.0', uint2str(nr))); }
        if(decimals == 3) { return string(abi.encodePacked('0.00', uint2str(nr))); }
        if(decimals == 4) { return string(abi.encodePacked('0.000', uint2str(nr))); }
    }

    // entropy carving
    // extrapolated into utils file in order to re-use between drawing + trait generation
    // 19 random variables
    function getAmount(bytes memory hash) internal pure returns (uint256) { return 2+uint256(toUint8(hash, 0))/16;  }  // 2 - 18
    function getRange(bytes memory hash) internal pure returns (uint256) { return 220 + uint256(toUint8(hash, 1))/4;  } // 180 - 240
    function getColour(bytes memory hash) internal pure returns (uint256) { return uint256(toUint8(hash, 2))*360/256;  } // 0 - 360
    function getColourShift(bytes memory hash) internal pure returns (uint256) { return uint256(toUint8(hash, 3));  } // 0 - 255
    function getSandSeed(bytes memory hash) internal pure returns (uint256) { return uint256(toUint8(hash, 4));  } 
    function getSandScale(bytes memory hash) internal pure returns (uint256) { return 1 + uint256(toUint8(hash, 5))/8;  } 
    function getSandOctaves(bytes memory hash) internal pure returns (uint256) {return 1 + uint256(toUint8(hash, 6))/64;  } 
    function getFineSandSeed(bytes memory hash) internal pure returns (uint256) {return uint256(toUint8(hash, 7)); } 
    function getFineSandOctaves(bytes memory hash) internal pure returns (uint256) {return 1 + uint256(toUint8(hash, 8))/64; } 
    function getColourOffsetShift(bytes memory hash, uint256 offsetIndex) internal pure returns (uint256) {
        
        if(offsetIndex == 0 ) { return uint256(toUint8(hash, 9))/128; } // red
        if(offsetIndex == 1 ) { return uint256(toUint8(hash, 10))/128; } // green
        if(offsetIndex == 2 ) { return uint256(toUint8(hash, 11))/128; } // blue
    } 
    function getColourOffsetChange(bytes memory hash, uint256 offsetIndex) internal pure returns (uint256) {

        if(offsetIndex == 0 ) { return uint256(toUint8(hash, 12))*100/256; } // red
        if(offsetIndex == 1 ) { return uint256(toUint8(hash, 13))*100/256; } // green
        if(offsetIndex == 2 ) { return uint256(toUint8(hash, 14))*100/256; } // blue
    } 
    function getLeftY(bytes memory hash) internal pure returns (uint256) {return 100+uint256(toUint8(hash, 15))/16; } 
    function getRightY(bytes memory hash) internal pure returns (uint256) {return 100+uint256(toUint8(hash, 16))/16; } 
    function getDiffLeft(bytes memory hash) internal pure returns (uint256) {return 10+uint256(toUint8(hash, 17))/16; } 
    function getDiffRight(bytes memory hash) internal pure returns (uint256) {return 10+uint256(toUint8(hash, 18))/16; } 

    function getIndices(bytes memory hash, bool randomMint) internal pure returns (uint256 _rareCount, uint256 _allCount, uint256[3][10] memory) {
        uint256[3][10] memory indices; // solidity's array assignents are reversed.
        // 0 -> assigned slot or not (0 or 1)
        // 1 -> rare word or not (0 or 1)
        // 2 -> index in word list (default list (0-52) or rare list (0-31))
        uint256 allCount;
        uint256 rareCount;

        uint leftY = getLeftY(hash);
        uint rightY = getRightY(hash);
        uint diffLeft = getDiffLeft(hash);
        uint diffRight = getDiffRight(hash);

        for(uint i = 0; i < 10; i+=1) {
            uint y;
            if(i % 2 == 0) {
                y = leftY;
                leftY += diffLeft;
            } else {
                y = rightY;
                rightY += diffRight;
            }
            if((y+i) % 4 == 0) { // 1 in 4 chance for an experience to be shown
                uint256 entropy = uint256(toUint8(hash, 19+i));
                uint256[3] memory IS;
                IS[0] = 1; // assigned slot (0 or 1)
                // default for IS[0] is 0, so don't have to assign it
                if(randomMint && (y+i+entropy) % 3 == 0) { // if its a random mint, the action has 1/3 chance of being rare
                    IS[1] = 1; // it's a rare word/action
                    IS[2] = entropy*33/256; // index in rare actions list
                    rareCount+=1;
                } else {
                    // don't have to assign IS[1] because it's 0 on default
                    IS[2] = entropy*62/256; // index in actions list
                }
                indices[i] = IS;
                allCount+=1; 
            } 
        }

        return (rareCount, allCount, indices);
    }
}