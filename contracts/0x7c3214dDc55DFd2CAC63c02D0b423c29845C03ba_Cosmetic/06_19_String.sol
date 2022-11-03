pragma solidity ^0.7.3;

library String {

    /**
     * @dev Converts a `uint256` to a `string`.
     * via OraclizeAPI - MIT licence
     * https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
     */
    function fromUint(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }

    bytes constant alphabet = "0123456789abcdef";

    function fromAddress(address _addr) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0F))];
        }
        return string(str);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(string memory _base, string memory _value, uint _offset)
        internal
        pure
        returns (int) {
            bytes memory _baseBytes = bytes(_base);
            bytes memory _valueBytes = bytes(_value);

            assert(_valueBytes.length == 1);

            for (uint i = _offset; i < _baseBytes.length; i++) {
                if (_baseBytes[i] == _valueBytes[0]) {
                    return int(i);
                }
            }

            return -1;
        }


    /**
     * String Split (Very high gas cost)
     *
     * Splits a string into an array of strings based off the delimiter value.
     * Please note this can be quite a gas expensive function due to the use of
     * storage so only use if really required.
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string value to be split.
     * @param _value The delimiter to split the string on which must be a single
     *               character
     * @return splitArr An array of values split based off the delimiter, but
     *                  do not container the delimiter.
     */
    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr) {
            bytes memory _baseBytes = bytes(_base);

            uint _offset = 0;
            uint _splitsCount = 1;
            while (_offset < _baseBytes.length) {
                int _limit = _indexOf(_base, _value, _offset);
                if (_limit == -1)
                    break;
                else {
                    _splitsCount++;
                    _offset = uint(_limit) + 1;
                }
            }

            splitArr = new string[](_splitsCount);

            _offset = 0;
            _splitsCount = 0;
            while (_offset < _baseBytes.length) {

                int _limit = _indexOf(_base, _value, _offset);
                if (_limit == - 1) {
                    _limit = int(_baseBytes.length);
                }

                string memory _tmp = new string(uint(_limit) - _offset);
                bytes memory _tmpBytes = bytes(_tmp);

                uint j = 0;
                for (uint i = _offset; i < uint(_limit); i++) {
                    _tmpBytes[j++] = _baseBytes[i];
                }
                _offset = uint(_limit) + 1;
                splitArr[_splitsCount++] = string(_tmpBytes);
            }
            return splitArr;
        }

    function substring(string memory str, uint startIndex, uint endIndex)
            internal
            pure
            returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function toUint(string memory s)
        internal
        pure
        returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint i = 0; i < b.length; i++) {
            uint val = uint(uint8(b[i]));
            if (val >= 48 && val <= 57) {
                result = result * 10 + (val - 48);
            }
        }
        return result;
    }

}