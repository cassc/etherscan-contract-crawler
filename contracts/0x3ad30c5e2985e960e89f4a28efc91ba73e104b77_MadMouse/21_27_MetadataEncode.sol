//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Warning:
// This library is untested and was only written with
// the specific use-case in mind of encoding traits for MadMouse.
// Use at own risk.

library MetadataEncode {
    /* ------------- Traits ------------- */

    function encode(string[] memory strs) internal pure returns (bytes memory) {
        bytes memory a;
        for (uint256 i; i < strs.length; i++) {
            if (i < strs.length - 1) a = abi.encodePacked(a, strs[i], bytes1(0));
            else a = abi.encodePacked(a, strs[i]);
        }
        return a;
    }

    function decode(bytes memory input, uint256 index) internal pure returns (string memory) {
        uint256 counter;
        uint256 start;
        uint256 end;
        for (; end < input.length; end++) {
            if (input[end] == 0x00) {
                if (counter == index) return getSlice(input, start, end);
                start = end + 1;
                counter++;
            }
        }
        return getSlice(input, start, end);
    }

    function getSlice(
        bytes memory input,
        uint256 start,
        uint256 end
    ) internal pure returns (string memory) {
        bytes memory out = new bytes(end - start);
        for (uint256 i = 0; i < end - start; i++) out[i] = input[i + start];
        return string(out);
    }

    /* ------------- Rarities ------------- */

    function selectWeighted(
        bytes memory traits,
        uint256 r,
        uint256 weights
    ) internal pure returns (string memory) {
        uint256 index = selectWeighted(r, weights);
        return decode(traits, index);
    }

    function selectWeighted(uint256 r, uint256 weights) private pure returns (uint256) {
        unchecked {
            for (uint256 i; i < 32; ++i) {
                r -= (weights >> (i << 3)) & 0xFF;
                if (r > 0xFF) return i;
            }
        }
        return 666666;
    }

    function encode(uint256[] memory weights) internal pure returns (bytes32) {
        uint256 r;
        uint256 sum;
        for (uint256 i; i < weights.length; i++) {
            r |= weights[i] << (i << 3);
            sum += weights[i];
        }
        require(sum == 256, 'Should sum to 256');
        return bytes32(r);
    }

    function decode(bytes32 code, uint256 length) internal pure returns (uint256[] memory) {
        uint256[] memory r = new uint256[](length);
        for (uint256 i; i < length; i++) r[i] = uint256(code >> (i << 3)) & 0xFF;
        return r;
    }

    /* ------------- Helpers ------------- */

    function keyValue(string memory key, string memory value) internal pure returns (string memory) {
        return bytes(value).length > 0 ? string.concat('"', key, '": ', value, ', ') : '';
    }

    function keyValueString(string memory key, string memory value) internal pure returns (string memory) {
        return bytes(value).length > 0 ? string.concat('"', key, '": ', '"', value, '", ') : '';
    }

    function attributeString(string memory traitType, string memory value) internal pure returns (string memory) {
        return attributeString(traitType, value, true);
    }

    function attributeString(
        string memory traitType,
        string memory value,
        bool comma
    ) internal pure returns (string memory) {
        return bytes(value).length > 0 ? attribute(traitType, string.concat('"', value, '"'), comma) : '';
    }

    function attribute(string memory traitType, string memory value) internal pure returns (string memory) {
        return attribute(traitType, value, true);
    }

    function attribute(
        string memory traitType,
        string memory value,
        bool comma
    ) internal pure returns (string memory) {
        return
            bytes(value).length > 0
                ? string.concat('{"trait_type": "', traitType, '", "value": ', value, '}', comma ? ', ' : '')
                : '';
    }

    function attributes(string memory attr) internal pure returns (string memory) {
        return string.concat('"attributes": [', attr, ']');
    }
}