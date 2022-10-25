//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// adapted from https://github.com/w1nt3r-eth/hot-chain-svg

// Core utils used extensively to format CSS and numbers.
library utils {
    // used to simulate empty strings
    string internal constant NULL = "";

    // formats a CSS variable line. includes a semicolon for formatting.
    function setCssVar(string memory _key, string memory _val) internal pure returns (string memory) {
        return string.concat("--", _key, ":", _val, ";");
    }

    // formats getting a css variable
    function getCssVar(string memory _key) internal pure returns (string memory) {
        return string.concat("var(--", _key, ")");
    }

    // formats getting a def URL
    function getDefURL(string memory _id) internal pure returns (string memory) {
        return string.concat("url(#", _id, ")");
    }

    // formats rgba white with a specified opacity / alpha
    function white_a(uint256 _a) internal pure returns (string memory) {
        return rgba(255, 255, 255, _a);
    }

    // formats rgba black with a specified opacity / alpha
    function black_a(uint256 _a) internal pure returns (string memory) {
        return rgba(0, 0, 0, _a);
    }

    // formats generic rgba color in css
    function rgba(uint256 _r, uint256 _g, uint256 _b, uint256 _a) internal pure returns (string memory) {
        string memory formattedA = _a < 100 ? string.concat("0.", utils.uint2str(_a)) : "1";
        return string.concat(
            "rgba(", utils.uint2str(_r), ",", utils.uint2str(_g), ",", utils.uint2str(_b), ",", formattedA, ")"
        );
    }

    // checks if two strings are equal
    function stringsEqual(string memory _a, string memory _b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    // returns the length of a string in characters
    function utfStringLength(string memory _str) internal pure returns (uint256 length) {
        uint256 i = 0;
        bytes memory string_rep = bytes(_str);

        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) {
                i += 1;
            } else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) {
                i += 2;
            } else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) {
                i += 3;
            } else if (string_rep[i] >> 3 == bytes1(uint8(0x1E))) {
                i += 4;
            }
            //For safety
            else {
                i += 1;
            }

            length++;
        }
    }

    // converts an unsigned integer to a string
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
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

    // generate hsla color from seed
    function getHslColor(uint256 seed) internal pure returns (string memory _hsla) {
        uint256 hue = seed % 360;
        _hsla = string.concat("hsla(", utils.uint2str(hue), ", 88%, 56%, 1)");
    }

    function bound(uint256 value, uint256 max, uint256 min) internal pure returns (uint256 _value) {
        /* require(max >= min, "INVALID_BOUND"); */
        _value = value % (max - min) + min;
    }

    function addressToString(address _address) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    function shortAddressToString(address _address) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(6);
        _string[0] = "0";
        _string[1] = "x";
        for (uint256 i = 0; i < 2; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }
}