// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../utils/DynamicBuffer.sol';
import "../utils/Random.sol";
import "../utils/Palette.sol";
import {Utils} from "../utils/Utils.sol";

contract Grids is Random, Palette {
    function generateLayer(uint256 _seed, uint8 _index) private pure returns (uint256 seed, string memory layer, uint32 noise) {
        seed = _seed;
        (, bytes memory buffer) = DynamicBuffer.allocate(18000);

        seed = prng(seed);
        noise = randBool(seed, 850) ? 0 : randBool(prng(seed), 150) ? 2 : 1;
        DynamicBuffer.appendBytes(buffer, bytes(abi.encodePacked(
          '<g transform-origin=\\"400 600\\" transform=\\"scale(',
          ['1','2','4','.5', '3'][_index],
          ')\\"><g transform=\\"scale(2)\\" ',
          noise == 1 ? 'opacity=\\".7\\" filter=\\"url(#f)\\">' :
          noise == 2 ? 'opacity=\\".7\\" filter=\\"url(#f) url(#f)\\">' : 'opacity=\\".7\\">',
          '<rect width=\\"1600\\" height=\\"2400\\" fill=\\"none\\"/>'
        )));
        
        for (uint32 id = 0; id < 12 * 8;) {
            seed = prng(seed);
            if(randBool(seed, 600)) {
                uint32 scale = randUInt32(seed, 0, 5);
                seed = prng(seed);
                DynamicBuffer.appendBytes(buffer, bytes(abi.encodePacked(
                    '<rect transform=\\"translate(',
                    Utils.uint32ToString((id%8) * 50),
                    ', ',
                    Utils.uint32ToString((id/8) * 50),
                    ') scale(',
                    ['.5', '1', '2.5', '5', '10'][scale],
                    ') translate(',
                    ['50,50', '25,25', '10,10', '5,5', '2.5,2.5'][scale],
                    ') rotate(',
                    ['0', '90', '180', '270'][randUInt32(seed, 0, 4)]
                )));
                DynamicBuffer.appendBytes(buffer, bytes(abi.encodePacked(
                    ') translate(',
                    ['-50,-50', '-25,-25', '-10,-10', '-5,-5', '-2.5,-2.5'][scale],
                    ')\\" width=\\"',
                    ['100', '50', '20', '10', '5'][scale],
                    '\\" height=\\"',
                    ['100', '50', '20', '10', '5'][scale],
                    '\\" fill=\\"url(#p',
                    ['0','1','2','3','4','5','6','7'][randUInt32(prng(seed), 0, 8)],
                    ')\\"/>'
                )));
                seed = prng(seed);
            }

            unchecked {
                id++;
            }
        }

        DynamicBuffer.appendBytes(buffer, bytes(abi.encodePacked(
            '</g></g>'
        )));

        layer = string(buffer);
    }

    function generateSVG(uint256 _seed) public view returns (string memory svg, string memory attributes) {
        uint32 tmp;
        uint32 noise;
        uint256 seed;
        string memory layer;
        string[8] memory paletteRGB;
        (, bytes memory svgBuffer) = DynamicBuffer.allocate(150 + 105 * 800);
        (, bytes memory attrBuffer) = DynamicBuffer.allocate(1000);

        seed = prng(prng(prng(_seed)));
        (paletteRGB, tmp, seed) = getRandomPalette(seed);

        DynamicBuffer.appendBytes(attrBuffer, bytes(abi.encodePacked(
            '{"trait_type":"Shape","value":"Grids"},{"trait_type":"Palette ID","value":',
            Utils.uint2str(tmp)
        )));


        seed = prng(seed);
        tmp = randBool(seed, 700) ? 0 : randUInt32(seed, 1, 3);
        DynamicBuffer.appendBytes(attrBuffer, bytes(abi.encodePacked(
            '},{"trait_type":"Filter","value":"',
            ['None', 'Grayscale', 'Sepia'][tmp],
            '"},{"trait_type":"Noise Type","value":"',
            ['Turbulence', 'Fractal'][randUInt32(prng(seed), 0, 2)]
        )));

        seed = prng(seed);
        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            '<svg xmlns=\\"http://www.w3.org/2000/svg\\" viewBox=\\"0 0 800 1200\\" style=\\"background:rgb(',
            paletteRGB[0],
            ')\\"><style>g>rect{mix-blend-mode:hard-light;stroke:none}#r{filter:contrast(250%) ',
            ['', 'grayscale(100%) contrast(150%)', 'sepia(100%)'][tmp],
            '}</style><defs><clipPath id=\\"clip\\"><rect width=\\"800\\" height=\\"1200\\"/></clipPath><filter id=\\"f\\"  primitiveUnits=\\"userSpaceOnUse\\"><feTurbulence type=\\"',
            ['turbulence', 'fractalNoise'][randUInt32(seed, 0, 2)],
            '\\" seed=\\"',
            Utils.uint32ToString(randUInt32(seed, 0, 1000)),
            '\\" baseFrequency=\\".005\\" numOctaves=\\"10\\" result=\\"t\\"/><feDisplacementMap in2=\\"t\\" in=\\"SourceGraphic\\" scale=\\"400\\" xChannelSelector=\\"R\\" yChannelSelector=\\"G\\"/></filter><pattern id=\\"p0\\" width=\\"10\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><rect width=\\"5\\" height=\\"5\\" fill=\\"rgb(',
            paletteRGB[1],
            ')\\"/><rect x=\\"5\\" y=\\"5\\" width=\\"5\\" height=\\"5\\" fill=\\"rgb(',
            paletteRGB[1],
            ')\\"/></pattern><pattern id=\\"p1\\" width=\\"10\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><rect width=\\"5\\" height=\\"10\\" fill=\\"rgb(',
            paletteRGB[2]
        )));

        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            ')\\"/></pattern><pattern id=\\"p2\\" width=\\"10\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><rect width=\\"10\\" height=\\"5\\" fill=\\"rgb(',
            paletteRGB[3],
            ')\\"/></pattern><pattern id=\\"p3\\" width=\\"10\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><path d=\\"M0,0 L10,10 L0,10 Z\\" fill=\\"rgb(',
            paletteRGB[4],
            ')\\"/></pattern><pattern id=\\"p4\\" width=\\"10\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><rect width=\\"2.5\\" height=\\"2.5\\" fill=\\"rgb(',
            paletteRGB[5],
            ')\\"/><rect x=\\"2.5\\" y=\\"2.5\\" width=\\"2.5\\" height=\\"2.5\\" fill=\\"rgb(',
            paletteRGB[5],
            ')\\"/><rect x=\\"5\\" y=\\"5\\" width=\\"2.5\\" height=\\"2.5\\" fill=\\"rgb(',
            paletteRGB[5]
        )));

        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            '\\"/><rect x=\\"7.5\\" y=\\"7.5\\" width=\\"2.5\\" height=\\"2.5\\" fill=\\"rgb(',
            paletteRGB[5],
            ')\\"/></pattern><pattern id=\\"p5\\" width=\\"10\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><circle cx=\\"5\\" cy=\\"5\\" r=\\"5\\" fill=\\"rgb(',
            paletteRGB[6],
            ')\\" stroke=\\"none\\"/></pattern><pattern id=\\"p6\\" width=\\"10\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><path d=\\"M5,0 L10,5 L5,10 L0,5 Z\\" fill=\\"rgb(',
            paletteRGB[6],
            ')\\"/></pattern><pattern id=\\"p7\\" width=\\"10\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><line x1=\\"-15\\" y1=\\"-5\\" x2=\\"5\\" y2=\\"15\\" stroke=\\"rgb(',
            paletteRGB[7],
            ')\\" stroke-width=\\"5\\"/><line x1=\\"-5\\" y1=\\"-5\\" x2=\\"15\\" y2=\\"15\\" stroke=\\"rgb(',
            paletteRGB[7],
            ')\\" stroke-width=\\"5\\"/><line x1=\\"5\\" y1=\\"-5\\" x2=\\"25\\" y2=\\"15\\" stroke=\\"rgb(',
            paletteRGB[7],
            ')\\" stroke-width=\\"5\\"/></pattern></defs>'
        )));

        seed = prng(seed);
        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            '<g id=\\"r\\" clip-path=\\"url(#clip)\\" >'
        )));

        seed = prng(seed);
        noise = 0;
        for (uint8 index = 0; index < 5;) {
            (seed, layer, tmp) = generateLayer(seed, index);
            noise += tmp;
            DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
                layer
            )));
            
            unchecked {
                index++;
            }
        }
        DynamicBuffer.appendBytes(attrBuffer, bytes(abi.encodePacked(
            '"},{"trait_type":"Noise Level","value":',
            Utils.uint2str(noise),
            '}'
        )));

        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            '</g></svg>'
        )));

        svg = string(svgBuffer);

        attributes = string(attrBuffer);
    }
}