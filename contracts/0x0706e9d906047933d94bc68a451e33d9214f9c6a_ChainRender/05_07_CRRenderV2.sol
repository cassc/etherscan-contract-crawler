// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import { Strings} from "openzeppelin/utils/Strings.sol";
import {DynamicBuffer} from 'ethier/utils/DynamicBuffer.sol';
import "./interfaces/IIndelible.sol";
import {IGenericRender} from "./interfaces/IGenericRender.sol";
import { Base64 } from "solady/utils/Base64.sol";
import 'ethier/utils/DynamicBuffer.sol';

interface Shared {
    struct Layer {
        string name;
        bytes hexString;
    }
    struct Color {
        string hexString;
        uint alpha;
        uint red;
        uint green;
        uint blue;
    }
}

interface ICR is Shared{
    function tokenSVGBuffer(Layer [13] memory tokenLayers, Color [8][13] memory tokenPalettes, uint8 numTokenLayers) external pure returns (string[4] memory);
    function getLayer(uint8 layerIndex, uint8 itemIndex) external view returns (Layer memory);
    function uintToHexString2(uint a) external pure returns (string memory);
}

contract ChainRender is IGenericRender, Shared {
    using DynamicBuffer for bytes;

    ICR cr = ICR(0xfDac77881ff861fF76a83cc43a1be3C317c6A1cC); 

    uint256 private constant NUM_LAYERS = 13;
    uint256 private constant NUM_COLORS = 8;
   
    function getTraitDetails(uint8 _layerId, uint8 _traitId) external view returns(IIndelible.Trait memory){
        ICR.Layer memory raw = cr.getLayer(_layerId, _traitId);
        bytes memory out = Base64.decode(raw.name); 
        return IIndelible.Trait(string(out), "image/svg+xml");
    }

    function getTraitData(uint8 _layerId, uint8 _traitId) external view returns(bytes memory){
        //get trait
        Layer memory _trait = cr.getLayer(_layerId, _traitId);

        //get Palette
        Color[NUM_COLORS] memory _palette = palette(_trait.hexString);

        return abi.encodePacked(
            "PHN2ZyB2ZXJzaW9uPScxLjEnIHZpZXdCb3g9JzAgMCAzMjAgMzIwJyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHNoYXBlLXJlbmRlcmluZz0nY3Jpc3BFZGdlcyc+",
            tokenSVGBuffer(_trait, _palette),
            "PHN0eWxlPnJlY3R7d2lkdGg6MTBweDtoZWlnaHQ6MTBweDt9PC9zdHlsZT48L3N2Zz4=");
    }

    function getCollectionName() external pure returns(string memory){
        return "ChainRunners";
    }


    //The rendering functions below are modified from the chainrunners contract to better suit the rendering of single traits
    function tokenSVGBuffer(Layer memory tokenLayer, Color [NUM_COLORS] memory tokenPalette) public pure returns (bytes memory) {
        // Base64 encoded lookups into x/y position strings from 010 to 310.
        string[32] memory lookup = ["MDAw", "MDEw", "MDIw", "MDMw", "MDQw", "MDUw", "MDYw", "MDcw", "MDgw", "MDkw", "MTAw", "MTEw", "MTIw", "MTMw", "MTQw", "MTUw", "MTYw", "MTcw", "MTgw", "MTkw", "MjAw", "MjEw", "MjIw", "MjMw", "MjQw", "MjUw", "MjYw", "Mjcw", "Mjgw", "Mjkw", "MzAw", "MzEw"];
        
        bytes memory buffer = DynamicBuffer.allocate(2**18);
        uint8 x;
        uint8 y;
        Color memory fg;
        for (uint k = 32; k < 416;) {
            for(uint i; i < 4; ++i) {
                for(uint j; j < 8; ++j) {
                    fg = tokenPalette[colorIndex(tokenLayer.hexString, k, j)];
                    if(fg.alpha != 0) buffer.appendSafe(bytes(pixel(lookup, fg.hexString, x, y)));
                    ++x;
                }
                k += 3;
            }
            y++;
            x = 0;
        }
        return buffer;
    }

    function palette(bytes memory data) internal pure returns (Color [NUM_COLORS] memory) {
        Color [NUM_COLORS] memory colors;
        for (uint16 i = 0; i < NUM_COLORS; i++) {
            // Even though this can be computed later from the RGBA values below, it saves gas to pre-compute it once upfront.
            colors[i].hexString = Base64.encode(bytes(abi.encodePacked(
                    byteToHexString(data[i * 4]),
                    byteToHexString(data[i * 4 + 1]),
                    byteToHexString(data[i * 4 + 2])
                )));
            colors[i].red = byteToUint(data[i * 4]);
            colors[i].green = byteToUint(data[i * 4 + 1]);
            colors[i].blue = byteToUint(data[i * 4 + 2]);
            colors[i].alpha = byteToUint(data[i * 4 + 3]);
        }
        return colors;
    }

    function colorIndex(bytes memory data, uint k, uint index) internal pure returns (uint8) {
        if (index == 0) {
            return uint8(data[k]) >> 5;
        } else if (index == 1) {
            return (uint8(data[k]) >> 2) % 8;
        } else if (index == 2) {
            return ((uint8(data[k]) % 4) * 2) + (uint8(data[k + 1]) >> 7);
        } else if (index == 3) {
            return (uint8(data[k + 1]) >> 4) % 8;
        } else if (index == 4) {
            return (uint8(data[k + 1]) >> 1) % 8;
        } else if (index == 5) {
            return ((uint8(data[k + 1]) % 2) * 4) + (uint8(data[k + 2]) >> 6);
        } else if (index == 6) {
            return (uint8(data[k + 2]) >> 3) % 8;
        } else {
            return uint8(data[k + 2]) % 8;
        }
    }

    function pixel(string[32] memory lookup, string memory color, uint8 x, uint8 y) internal pure returns (string memory result) {
        return string(abi.encodePacked(
                "PHJlY3QgICBmaWxsPScj", color, "JyAgeD0n", lookup[x], "JyAgeT0n", lookup[y], "JyAgIC8+"));
    }

    function byteToUint(bytes1 b) private pure returns (uint) {
        return uint(uint8(b));
    }

    function byteToHexString(bytes1 b) private pure returns (string memory) {
        return uintToHexString2(byteToUint(b));
    }

    function uintToHexString2(uint a) public pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i = 0; i < count; ++i) {
            b = a % 16;
            res[count - i - 1] = uintToHexDigit(uint8(b));
            a /= 16;
        }

        string memory str = string(res);
        if (bytes(str).length == 0) {
            return "00";
        } else if (bytes(str).length == 1) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }

        function uintToHexDigit(uint8 d) public pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1('0')) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1('a')) + d - 10);
        }
        revert();
    }
}