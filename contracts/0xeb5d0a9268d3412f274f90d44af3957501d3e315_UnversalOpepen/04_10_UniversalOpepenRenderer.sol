// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {DynamicBufferLib} from "solady/utils/DynamicBufferLib.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Base64} from "solady/utils/Base64.sol";

contract UniversalOpepenRenderer {
    using LibString for *;
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;

    function render(uint256 tokenId, bytes3[] calldata colors) external pure returns (string memory) {
        string[] memory hexColors = getHexColors(colors);

        DynamicBufferLib.DynamicBuffer memory buffer;

        buffer.append('{"name":"Universal Opepen #', bytes(tokenId.toString()), '",');
        buffer.append('"description":"Customizable on-chain Opepen. One for every address. Soulbounded.",');
        buffer.append('"attributes":', attributes(hexColors), ",");
        buffer.append('"image":"data:image/svg+xml;base64,', image(hexColors), '"}');

        return string.concat("data:application/json;base64,", Base64.encode(buffer.data));
    }

    function getHexColors(bytes3[] calldata colors) internal pure returns (string[] memory) {
        string[] memory hexColors = new string[](21);
        unchecked {
            for (uint256 i; i < 21; ++i) {
                hexColors[i] = string.concat("#", uint256(uint24(colors[i])).toHexStringNoPrefix(3));
            }
        }
        return hexColors;
    }

    function attributes(string[] memory hexColors) internal pure returns (bytes memory) {
        DynamicBufferLib.DynamicBuffer memory buffer;
        buffer.append('[{"trait_type":"c0","value":"', bytes(hexColors[0]), '"}');
        unchecked {
            for (uint256 i = 1; i < 20; ++i) {
                buffer.append(',{"trait_type":"c', bytes(i.toString()), '","value":"', bytes(hexColors[i]), '"}');
            }
        }
        return buffer.append(',{"trait_type":"Background","value":"', bytes(hexColors[20]), '"}]').data;    
    }

    function image(string[] memory hexColors) internal pure returns (bytes memory) {
        DynamicBufferLib.DynamicBuffer memory buffer;
        buffer.append(
            '<svg class="svg" width="512" height="512" viewBox="0 0 512 512" preserveAspectRatio="xMinYMin meet" xmlns="http://www.w3.org/2000/svg">',
            '<defs><rect id="r" width="64" height="64"/><path id="q1" d="M 64 0 a 64 64 0 0 0 -64 64 H 64"/><path id="q2" d="M 0 0 a 64 64 0 0 1 64 64 H 0"/><path id="q3" d="M 0 64 a 64 64 0 0 0 64 -64 H 0"/><path id="q4" d="M 0 0 a 64 64 0 0 0 64 64 V 0"/></defs>',
            '<rect width="512" height="512" class="c20"/><use href="#r" x="128" y="128" class="c0"/><use href="#q2" x="192" y="128" class="c1"/><use href="#q1" x="256" y="128" class="c2"/><use href="#q2" x="320" y="128" class="c3"/><use href="#q4" x="128" y="192" class="c4"/><use href="#q3" x="192" y="192" class="c5"/><use href="#q4" x="256" y="192" class="c6"/><use href="#q3" x="320" y="192" class="c7"/><use href="#r" x="128" y="256" class="c8"/><use href="#r" x="192" y="256" class="c9"/><use href="#r" x="256" y="256" class="c10"/><use href="#r" x="320" y="256" class="c11"/><use href="#q4" x="128" y="320" class="c12"/><use href="#r" x="192" y="320" class="c13"/><use href="#r" x="256" y="320" class="c14"/><use href="#q3" x="320" y="320" class="c15"/><use href="#q1" x="128" y="448" class="c16"/><use href="#r" x="192" y="448" class="c17"/><use href="#r" x="256" y="448" class="c18"/><use href="#q2" x="320" y="448" class="c19"/>',
            '<style>.svg{shape-rendering:geometricPrecision}'
        );
        unchecked {
            for (uint256 i; i < 21; ++i) {
                buffer.append('.c', bytes(i.toString()), '{fill:', bytes(hexColors[i]), '}');
            }
        }
        return bytes(Base64.encode(buffer.append('</style></svg>').data));
    }
}