// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringUtils {
    /**
     * @dev Checks if the given strings are equal.
     */
    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    /**
     * @dev Converts a given string to its slug representation. replacing spaces with hyphens and lowercasing the given string.
     */
    function toSlug(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        uint256 removedChars;

        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);

            // replace spaces with hyphens
            if (_baseBytes[i] == 0x20 || _baseBytes[i] == "'") {
                _baseBytes[i] = 0x2D;
            } else if (_baseBytes[i] == 0xC3) {
                // Special Character
                _baseBytes[i] = "";
                removedChars++;
            } else if (_baseBytes[i] == 0xA8) {
                // è to e
                _baseBytes[i] = "e";
            }
        }

        if (removedChars == 0) {
            return string(_baseBytes);
        }

        bytes memory _modifiedBytes = new bytes(
            _baseBytes.length - removedChars
        );
        uint256 index;
        for (uint256 i; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == "") {
                continue;
            }

            _modifiedBytes[index] = _baseBytes[i];
            index++;
        }

        return string(_modifiedBytes);
    }

    /**
     * @dev Converts a given character to lowercase, if it's between the A-Z range.
     */
    function _lower(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

library UintUtils {
    /**
     * @dev converts and uint256 to string
     */
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
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
}

library Bytes32Utils {
    function bytes32ToString(bytes32 _bytes32)
        internal
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}