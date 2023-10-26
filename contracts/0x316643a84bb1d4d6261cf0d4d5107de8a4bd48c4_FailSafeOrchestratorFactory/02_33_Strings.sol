// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StringsF {
    function length(string memory str) internal pure returns (uint256) {
        return bytes(str).length;
    }

    function concatenate(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function compare(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function range(
        string memory _str,
        uint256 b,
        uint256 j
    ) internal pure returns (string memory) {
        uint256 len = j - b;
        bytes memory cstr = new bytes(len);
        bytes memory str = bytes(_str);

        for (uint256 i = 0; i < len; i++) {
            cstr[i] = str[i + b];
        }

        return string(cstr);
    }

    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint256 i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    // note push only works for storage arrays
    // always have to give length
    function split(
        string memory _str,
        string memory _sep,
        uint256 maxTokens
    ) internal pure returns (string[] memory) {
        require(length(_sep) == 1, "requires a single char seperator");
        string[] memory parts = new string[](maxTokens);

        bytes memory str = bytes(_str);
        bytes memory sep = bytes(_sep);

        uint256 b = 0;
        uint256 j = 0;
        uint256 count = 0;
        for (uint256 i = 0; i < str.length; i++) {
            if (i + 1 == str.length) {
                j = i + 1;
            } else {
                j = i;
            }
            if (str[i] == sep[0] || (j != i)) {
                // _str[b:j];
                parts[count] = range(_str, b, j);
                b = i + 1;
                count++;
            }

            require((count <= maxTokens), "Max size exceeded");
        }

        require((count == maxTokens), "token num mismatch");

        return parts;
    }

    function _upper(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    function addressToString(address _addr) public pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));

        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    function toUpper(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    function parseInt(string memory _a) internal pure returns (uint256) {
        bytes memory bresult = bytes(_a);
        uint256 mint = 0;
        for (uint256 i = 0; i < bresult.length; i++) {
            if ((uint8(bresult[i]) >= 48) && (uint8(bresult[i]) <= 57)) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }
}