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

    // entropy carving
    // extrapolated into utils file in order to re-use between drawing + trait generation
    function getPetalCount(bytes memory hash) internal pure returns (uint256) {
        uint8[5] memory petalCounters = [8, 12, 20, 24, 36];
        uint pI = utils.toUint8(hash,0)/52; //0 - 4.9
        uint petalCount = petalCounters[pI]; // 360 + 2
        return petalCount;
    }

    function getHeight(bytes memory hash) internal pure returns (uint256) { return 180-utils.toUint8(hash,1)/2;} // 180 - 52
    function getSeed(bytes memory hash) internal pure returns (uint256) { return uint256(utils.toUint8(hash,2))*uint256(utils.toUint8(hash,3))*uint256(utils.toUint8(hash,4));} // 0 - 16581375

    function getBaseFrequencyOne(bytes memory hash) internal pure returns (uint256) { return 1 + uint256(utils.toUint8(hash,5))*1000/256; }
    function getBaseFrequencyTwo(bytes memory hash) internal pure returns (uint256) { return 1 + uint256(utils.toUint8(hash,6))*1000/256; }
    function getDecimalsOne(bytes memory hash) internal pure returns (uint256) { return uint256(utils.toUint8(hash, 7))*3/256; }
    function getDecimalsTwo(bytes memory hash) internal pure returns (uint256) { return uint256(utils.toUint8(hash, 8))*3/256; }
    function getMatrixOffset(bytes memory hash, uint offset) internal pure returns (uint256) { return uint256(utils.toUint8(hash, offset))/4; } // re-uses entropy 0 - 19
    function getNegOrPos(bytes memory hash, uint offset) internal pure returns (uint256) { return utils.toUint8(hash, offset); } // re-uses entropy 1 - 20
    function getMidPointReduction(bytes memory hash) internal pure returns (uint256) { return 5 + utils.toUint8(hash,9)/13;  } // 0 - 18-ish
    function getFrontPetalColour(bytes memory hash) internal pure returns (uint256) { return uint256(utils.toUint8(hash,10))*360/256;  } // 0 - 360
}