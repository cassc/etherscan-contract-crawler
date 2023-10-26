// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IAddressTokenMetadata } from "./interfaces/IAddressTokenMetadata.sol";

contract AddressTokenMetadata is IAddressTokenMetadata {
    function tokenJSON(uint256 tokenId) external pure returns(string memory) {
        bytes memory accountHex = bytes(Strings.toHexString(tokenId, 20));
        // accountMask[i] will store the length of the repetition of accountHex[i] starting at the index i
        bytes memory accountMask = new bytes(42);
        bytes memory attributes = bytes.concat(
            _detectRepetitions(accountHex, accountMask),
            _detectLongestPalindrome(accountHex, accountMask),
            _detectWords(accountHex),
            _detectZeroBytes(accountHex),
            _detectSymbols(accountHex),
            _detectAlphabets(accountHex)
        );

        // Cut out last ',\n':
        // attributes.length -= 2;
        assembly ("memory-safe") {  // solhint-disable-line no-inline-assembly
            mstore(attributes, sub(mload(attributes), 2))
        }

        _checksumAddress(accountHex);

        bytes memory json = bytes.concat('{\n',
            '\t"name": "Deploy to ', accountHex, '",\n',
            '\t"description": "Enables holder to deploy arbitrary smart contract to ', accountHex, '",\n',
            '\t"external_url": "https://etherscan.io/address/', accountHex, '",\n',
            '\t"image": "ipfs://QmZW3TTdtK87ktxmh6PG5UumbtoWXU8rVBApo65oknekmc",\n',
            '\t"animation_url": "ipfs://QmZKp3K7oyDFPkVUXUgDKqZ6RcLZY7QW267JvXRTLW1qaG",\n',
            '\t"attributes": [\n',
                attributes, bytes(attributes.length > 0 ? '\n' : ''),
            '\t]\n',
        '}');

        return string(json);
    }

    function _detectRepetitions(bytes memory accountHex, bytes memory accountMask) private pure returns(bytes memory attributes) {
        uint256 length = 1;
        bytes1 letter = accountHex[2];
        for (uint256 i = 3; i < 42; i++) {
            if (accountHex[i] == letter) {
                length++;
            }

            if (accountHex[i] != letter || i == 41) {
                if (length >= 4) {
                    if (length + 2 == i) {
                        attributes = bytes.concat(attributes, '\t\t{\n\t\t\t"trait_type": "Repeated prefix ', letter, '",\n\t\t\t"value": ', bytes(Strings.toString(length)), '\n\t\t},\n');
                    } else if (i == 41) {
                        attributes = bytes.concat(attributes, '\t\t{\n\t\t\t"trait_type": "Repeated suffix ', letter, '",\n\t\t\t"value": ', bytes(Strings.toString(length)), '\n\t\t},\n');
                    }
                    attributes = bytes.concat(attributes, '\t\t{\n\t\t\t"trait_type": "Repeated symbol ', letter, '",\n\t\t\t"value": ', bytes(Strings.toString(length)), '\n\t\t},\n');

                    for (uint256 t = 0; t < length; t++) {
                        accountMask[i + (accountHex[i] != letter ? 0 : 1) - length + t] = bytes1(uint8(length - t));
                    }
                }
                length = 1;
                letter = accountHex[i];
            }
        }
    }

    function _detectLongestPalindrome(bytes memory accountHex, bytes memory accountMask) private pure returns(bytes memory attributes) {
        for (uint256 length = 40; length >= 5 && attributes.length == 0; length--) {
            attributes = _palindromOfLength(accountHex, accountMask, length);
        }
    }

    function _palindromOfLength(bytes memory accountHex, bytes memory accountMask, uint256 length) private pure returns(bytes memory attributes) {
        for (uint256 i = 2; i <= 42 - length; i++) {
            if (uint8(accountMask[i]) >= length) {
                continue;
            }
            uint256 matched = 0;
            for (uint256 j = 0; j < length >> 1 && accountHex[i + j] == accountHex[i + length - 1 - j]; j++) {
                matched++;
            }

            if (matched == length >> 1) {
                if (i == 2) {
                    attributes = bytes.concat(attributes, '\t\t{\n\t\t\t"trait_type": "Palindrome prefix",\n\t\t\t"value": ', bytes(Strings.toString(length)), '\n\t\t},\n');
                } else if (i + length == 42) {
                    attributes = bytes.concat(attributes, '\t\t{\n\t\t\t"trait_type": "Palindrome suffix",\n\t\t\t"value": ', bytes(Strings.toString(length)), '\n\t\t},\n');
                }
                attributes = bytes.concat(attributes, '\t\t{\n\t\t\t"trait_type": "Palindrome",\n\t\t\t"value": ', bytes(Strings.toString(length)), '\n\t\t},\n');
                break;
            }
        }
    }

    function _detectWords(bytes memory accountHex) private pure returns(bytes memory attributes) {
        string[19] memory words = [
            'dead', 'beef', 'c0ffee', 'def1',
            '1ee7', '1337', 'babe', 'f00d',
            'dec0de', 'facade', 'decade', 'feed',
            'face', 'c0de', 'c0c0a', 'caca0',
            'cafe', '5eed', '5e1f'
        ];
        for (uint256 i = 0; i < words.length; i++) {
            attributes = bytes.concat(attributes, _detectSingleWord(accountHex, bytes(words[i])));
        }
    }

    function _detectSingleWord(bytes memory accountHex, bytes memory word) private pure returns(bytes memory attributes) {
        uint256 count = 0;
        for (uint256 i = 2; i <= 42 - word.length; i++) {
            uint256 matched = 0;
            for (uint256 j = 0; j < word.length && accountHex[i + j] == word[j]; j++) {
                matched++;
            }

            if (matched == word.length) {
                if (i == 2) {
                    attributes = bytes.concat(attributes, '\t\t{\n\t\t\t"trait_type": "Word prefix",\n\t\t\t"value": "', word, '"\n\t\t},\n');
                } else if (i + word.length == 42) {
                    attributes = bytes.concat(attributes, '\t\t{\n\t\t\t"trait_type": "Word suffix",\n\t\t\t"value": "', word, '"\n\t\t},\n');
                }
                count++;
                // -1 beacause of i++ in the loop and extra -1 to account for possible deadead overlap
                i += word.length - 2;
            }
        }

        if (count > 0) {
            attributes = bytes.concat(attributes, '\t\t{\n\t\t\t"trait_type": "Word ', word, '",\n\t\t\t"value": ', bytes(Strings.toString(count)), '\n\t\t},\n');
        }
    }

    function _detectZeroBytes(bytes memory accountHex) private pure returns(bytes memory attributes) {
        uint256 count = 0;
        for (uint256 i = 2; i < 42; i += 2) {
            if (accountHex[i] == '0' && accountHex[i + 1] == '0') {
                count++;
            }
        }
        return bytes.concat('\t\t{\n\t\t\t"trait_type": "Zero bytes",\n\t\t\t"value": ', bytes(Strings.toString(count)), '\n\t\t},\n');
    }

    function _detectSymbols(bytes memory accountHex) private pure returns(bytes memory attributes) {
        bytes memory counters = new bytes(256);
        for (uint256 i = 2; i < 42; i++) {
            counters[uint8(accountHex[i])] = bytes1(uint8(counters[uint8(accountHex[i])]) + 1);
        }
        bytes memory alphabet = "0123456789abcdef";
        for (uint256 i = 0; i < alphabet.length; i++) {
            uint256 count = uint8(counters[uint8(alphabet[i])]);
            attributes = bytes.concat(attributes, '\t\t{\n\t\t\t"trait_type": "Symbol ', alphabet[i], '",\n\t\t\t"value": ', bytes(Strings.toString(count)), '\n\t\t},\n');
        }
    }

    function _detectAlphabets(bytes memory accountHex) private pure returns(bytes memory attributes) {
        bool onlyDigits = true;
        bool onlyLetters = true;
        for (uint256 i = 2; i < 42; i++) {
            if (accountHex[i] < '0' || accountHex[i] > '9') {
                onlyDigits = false;
            }
            if (accountHex[i] < 'a' || accountHex[i] > 'f') {
                onlyLetters = false;
            }
        }

        if (onlyDigits) {
            attributes = '\t\t{\n\t\t\t"trait_type": "Digits only"\n\t\t},\n';
        } else if (onlyLetters) {
            attributes = '\t\t{\n\t\t\t"trait_type": "Letters only"\n\t\t},\n';
        }
    }

    function _checksumAddress(bytes memory hexAddress) private pure {
        bytes32 hash;
        assembly ("memory-safe") {  // solhint-disable-line no-inline-assembly
            hash := keccak256(add(hexAddress, 0x22), sub(mload(hexAddress), 2))
        }
        for (uint256 i = 2; i < 42; i++) {
            uint256 hashByte = uint8(hash[(i - 2) >> 1]);
            if (((i & 1 == 0) ? (hashByte >> 4) : (hashByte & 0x0f)) > 7 && hexAddress[i] > '9') {
                hexAddress[i] = bytes1(uint8(hexAddress[i]) - 0x20);
            }
        }
    }
}