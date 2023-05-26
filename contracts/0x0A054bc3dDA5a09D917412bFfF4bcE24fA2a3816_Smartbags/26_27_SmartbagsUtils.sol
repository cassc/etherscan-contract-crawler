//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

library SmartbagsUtils {
    using Strings for uint256;

    struct Color {
        string name;
        string color;
    }

    function getColor(address contractAddress)
        internal
        pure
        returns (Color memory)
    {
        uint256 colorSeed = uint256(uint160(contractAddress));

        return
            [
                Color({color: '#fc6f03', name: 'orange'}),
                Color({color: '#ff0000', name: 'red'}),
                Color({color: '#ffb700', name: 'gold'}),
                Color({color: '#ffe600', name: 'yellow'}),
                Color({color: '#fbff00', name: 'light green'}),
                Color({color: '#a6ff00', name: 'green'}),
                Color({color: '#dee060', name: 'pastel green'}),
                Color({color: '#f28b85', name: 'salmon'}),
                Color({color: '#48b007', name: 'forest green'}),
                Color({color: '#00ff55', name: 'turquoise green'}),
                Color({color: '#b4ff05', name: 'flashy Green'}),
                Color({color: '#61c984', name: 'alguae'}),
                Color({color: '#00ff99', name: 'turquoise'}),
                Color({color: '#00ffc3', name: 'flashy blue'}),
                Color({color: '#00fff2', name: 'light blue'}),
                Color({color: '#009c94', name: 'aqua blue'}),
                Color({color: '#0363ff', name: 'deep blue'}),
                Color({color: '#3636c2', name: 'blurple'}),
                Color({color: '#5d00ff', name: 'purple'}),
                Color({color: '#ff4ff9', name: 'pink'}),
                Color({color: '#fc0065', name: 'redPink'}),
                Color({color: '#ffffff', name: 'white'}),
                Color({color: '#c95136', name: 'copper'}),
                Color({color: '#c5c8c9', name: 'silver'})
            ][colorSeed % 24];
    }

    function getName(address contractAddress)
        internal
        view
        returns (string memory)
    {
        // get name from contract if possible
        try IERC721Metadata(contractAddress).name() returns (
            string memory name
        ) {
            // uppercase the name, and remove any non AZ09 characters
            bytes memory strBytes = bytes(name);
            bytes memory sanitized = new bytes(strBytes.length);
            uint8 charCode;
            bytes1 char;
            for (uint256 i; i < strBytes.length; i++) {
                char = strBytes[i];
                charCode = uint8(char);

                if (
                    // ! " # $ %
                    (charCode >= 33 && charCode <= 37) ||
                    // ' ( ) * + - . /
                    (charCode >= 39 && charCode <= 47) ||
                    // 0-9
                    (charCode >= 48 && charCode <= 57) ||
                    // A - Z
                    (charCode >= 65 && charCode <= 90)
                ) {
                    sanitized[i] = char;
                } else if (charCode >= 97 && charCode <= 122) {
                    // if a-z, use uppercase
                    sanitized[i] = bytes1(charCode - 32);
                } else {
                    // for all others, use a space
                    sanitized[i] = 0x32;
                }
            }

            if (sanitized.length > 0) {
                return string(sanitized);
            }
        } catch Error(string memory) {} catch (bytes memory) {}
        return uint256(uint160(contractAddress)).toHexString(20);
    }

    function tokenNumber(uint256 tokenId)
        internal
        pure
        returns (string memory)
    {
        bytes memory tokenStr = bytes(tokenId.toString());
        bytes memory fixedTokenStr = new bytes(4);
        fixedTokenStr[0] = 0x30;
        fixedTokenStr[1] = 0x30;
        fixedTokenStr[2] = 0x30;
        fixedTokenStr[3] = 0x30;

        uint256 it;
        for (uint256 i = tokenStr.length; i > 0; i--) {
            fixedTokenStr[3 - it] = tokenStr[i - 1];
            it++;
        }

        return string(fixedTokenStr);
    }

    function renderContract(address _addr, uint256 length)
        internal
        view
        returns (bytes memory)
    {
        // get contract full size
        uint256 maxSize;
        assembly {
            maxSize := extcodesize(_addr)
        }

        uint256 offset = maxSize > length
            ? (maxSize - length) % uint256(uint160(_addr))
            : 0;

        bytes memory code = getContractBytecode(
            _addr,
            offset,
            maxSize < length ? maxSize : length
        );

        if (maxSize < length) {
            uint256 toFill = length - maxSize;
            uint256 length = toFill / 2;

            bytes memory filler = new bytes(length);
            for (uint256 i; i < length; i++) {
                filler[i] = 0xff;
            }

            return abi.encodePacked(filler, code, filler);
        }

        return code;
    }

    function getContractBytecode(
        address _addr,
        uint256 start,
        uint256 length
    ) internal view returns (bytes memory o_code) {
        assembly {
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(
                0x40,
                add(o_code, and(add(add(length, 0x20), 0x1f), not(0x1f)))
            )
            // store length in memory
            mstore(o_code, length)
            // actually retrieve the code, this needs assembly
            extcodecopy(_addr, add(o_code, 0x20), start, length)
        }
    }
}