// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../utils/DynamicBuffer.sol';
import "../utils/Random.sol";
import "../utils/Palette.sol";
import {Utils} from "../utils/Utils.sol";

contract Stencils is Random, Palette {

    function generateSVG(uint256 _seed) public view returns (string memory svg, string memory attributes) {
        uint32 tmp;
        uint32 p;
        uint32 n;
        uint32 angle;
        uint256 seed;
        string[8] memory paletteRGB;
        (, bytes memory svgBuffer) = DynamicBuffer.allocate(150 + 105 * 800);
        (, bytes memory attrBuffer) = DynamicBuffer.allocate(300);

        seed = prng(_seed);
        seed = prng(prng(seed));
        (paletteRGB, tmp, seed) = getRandomPalette(seed);

        DynamicBuffer.appendBytes(attrBuffer, bytes(abi.encodePacked(
            '{"trait_type":"Shape","value":"Stencils"},',
            '{"trait_type":"Palette ID","value":',
            Utils.uint32ToString(tmp)
        )));

        seed = prng(seed);
        tmp = randUInt32(seed, 0, 2);
        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            '<svg xmlns=\\"http://www.w3.org/2000/svg\\" viewBox=\\"0 0 800 1200\\"><style>/*<![CDATA[*/svg{background:white;max-width:100vw;max-height:100vh;filter:invert(',
            ['0','100'][tmp],
            '%)}/*]]>*/</style><defs><filter id=\\"noiseFilter\\"><feTurbulence type=\\"fractalNoise\\" baseFrequency=\\"0.65\\" numOctaves=\\"3\\" stitchTiles=\\"stitch\\"/></filter><pattern id=\\"p0\\" width=\\"10\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><rect fill=\\"white\\" width=\\"5\\" height=\\"10\\"/></pattern><pattern id=\\"p1\\" width=\\"20\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><rect fill=\\"white\\" width=\\"10\\" height=\\"10\\"/></pattern><pattern id=\\"p2\\" width=\\"40\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><rect fill=\\"white\\" width=\\"20\\" height=\\"10\\"/></pattern><pattern id=\\"p3\\" width=\\"30\\" height=\\"30\\" patternUnits=\\"userSpaceOnUse\\"><path fill=\\"white\\" d=\\"M0,0 L0,30 L30,15 Z\\"/></pattern>'
        )));

        // gradients
        for (uint8 index = 0; index < 5;) {
            DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
                '<linearGradient id=\\"l',
                ['0', '1', '2', '3', '4', '5', '6', '7'][index],
                '\\"><stop offset=\\"0\\" stop-color=\\"rgb(',
                paletteRGB[index],
                ')\\"/><stop offset=\\".8\\" stop-color=\\"rgba(0,0,0,0)\\"/></linearGradient>'
            )));
            
            unchecked {
                index++;
            }
        }

        seed = prng(seed);
        n = [50, 75, 100][randUInt32(seed, 0, 3)];

        seed = prng(seed);
        p = [250, 500, 750, 1000][randUInt32(seed, 0, 4)];

        seed = prng(seed);
        angle = [30, 330][randUInt32(seed, 0, 2)];

        for (uint8 index = 0; index < n;) {
            seed = prng(seed);
            tmp = randUInt32(seed, 100, 800);
            seed = prng(seed);

            if(randBool(seed, p)) {
                DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked( '<rect id=\\"s',
                    Utils.uint2str(index),
                    '\\" x=\\"-',
                    Utils.uint32ToString(tmp/2),
                    '\\" y=\\"-',
                    Utils.uint32ToString(randUInt32(seed, 100, 1200)/2),
                    '\\" width=\\"',
                    Utils.uint32ToString(tmp),
                    '\\" height=\\"',
                    Utils.uint32ToString(randUInt32(seed, 100, 1200))
                )));
            }
            else {
                DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
                    '<circle id=\\"s',
                    Utils.uint2str(index),
                    '\\" r=\\"',
                    Utils.uint32ToString(tmp)
                )));
            }

            seed = prng(seed);
            DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
                '\\"/><mask id=\\"m',
                Utils.uint2str(index),
                '\\"><use href=\\"#s',
                Utils.uint2str(index),
                '\\" fill=\\"url(#p',
                Utils.uint32ToString(randUInt32(seed, 0, 4)),
                ')\\"/></mask>'
            )));
            
            unchecked {
                index++;
            }
        }

        seed = prng(seed);
        tmp = randUInt32(seed, 0, 6);

        DynamicBuffer.appendBytes(attrBuffer, bytes(abi.encodePacked(
            '},{"trait_type":"Complexity","value":',
            Utils.uint32ToString(n / 25 - 1),
            '},{"trait_type":"Scale","value":',
            ['1', '1', '2', '2', '2', '3'][tmp],
            '},{"trait_type":"Circles","value":',
            Utils.uint32ToString(4 - p / 250),
            '},{"trait_type":"Orientation","value":"',
            ['East', 'West'][angle == 30 ? 0 : 1]
        )));

        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            '</defs><rect width=\\"800\\" height=\\"1200\\" stroke=\\"none\\" fill=\\"white\\"/><g transform=\\"translate(400,600) scale(',
            ['.5', '.5', '.75', '.75', '.75', '1'][tmp],
            ') translate(-400,-600)\\">'
        )));

        seed = prng(seed);
        tmp = [0, 100, 200, 500][randBool(seed, 100)?0:randUInt32(prng(seed), 1, 4)];

        DynamicBuffer.appendBytes(attrBuffer, bytes(abi.encodePacked(
            '"},{"trait_type":"Masks","value":',
            Utils.uint32ToString(tmp/100),
            '}'
        )));

        for (uint8 index = 0; index < n;) {
            seed = prng(seed);
            if(randBool(seed, tmp)) {
                DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
                    '<g style=\\"filter:contrast(150%) brightness(500%); mix-blend-mode: multiply\\" transform=\\"translate(',
                    Utils.uint32ToString(randUInt32(seed, 0, 800)),
                    ',', 
                    Utils.uint32ToString(randUInt32(seed, 0, 1200)),
                    ') rotate(',
                    Utils.uint32ToString(angle + randUInt32(seed, 0, 4) * 90),
                    ')\\"><use href=\\"#s',
                    Utils.uint2str(index),
                    '\\" mask=\\"url(#m',
                    Utils.uint2str(index)
                )));
                DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
                    ')\\" filter=\\"url(#noiseFilter)\\"/><use href=\\"#s',
                    Utils.uint2str(index),
                    '\\" mask=\\"url(#m',
                    Utils.uint2str(index),
                    ')\\" style=\\"mix-blend-mode:multiply\\" fill=\\"url(#l',
                    ['0', '1', '2', '3', '4', '5', '6', '7'][randUInt32(prng(seed), 0, 8)],
                    ')\\"/>',
                    '</g>'
                )));
            }
            else {
                DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
                    '<g style=\\"filter:contrast(150%) brightness(500%); mix-blend-mode: multiply\\" transform=\\"translate(',
                    Utils.uint32ToString(randUInt32(seed, 0, 800)),
                    ',', 
                    Utils.uint32ToString(randUInt32(seed, 0, 1200)),
                    ') rotate(',
                    Utils.uint32ToString(angle + randUInt32(seed, 0, 4) * 90),
                    ')\\"><use href=\\"#s',
                    Utils.uint2str(index)
                )));
                DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
                    '\\" filter=\\"url(#noiseFilter)\\"/><use href=\\"#s',
                    Utils.uint2str(index),
                    '\\" style=\\"mix-blend-mode:multiply\\" fill=\\"url(#l',
                    ['0', '1', '2', '3', '4', '5', '6', '7'][randUInt32(prng(seed), 0, 8)],
                    ')\\"/>',
                    '</g>'
                )));
            }
            
            unchecked {
                index++;
            }
        }

        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            '</g></svg>'
        )));

        svg = string(svgBuffer);

        attributes = string(attrBuffer);
    }
}