// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./AnonymiceLibrary.sol";

contract ChainWavesGenerator {
    using AnonymiceLibrary for uint8;

    string[][9] private PALETTES;
    uint256[] private NOISE;
    uint256[] private SPEED;
    string[] private CHARS;
    uint256[] private TIGHTNESS;

    struct Traits {
        string[] palette;
        uint256 noise;
        uint256 speed;
        string charSet;
        uint256 tightness;
        uint256 numCols;
    }

    constructor() {
        //lava
        PALETTES[0] = ["d00000", "370617", "faa307", "e85d04", "03071e"];
        //flamingo
        PALETTES[1] = ["3a0ca3", "f72585", "4cc9f0", "7209b7", "4cc9f0"];
        //rioja
        PALETTES[2] = ["250902", "38040e", "640d14", "800e13", "ad2831"];
        //forest
        PALETTES[3] = ["013026", "a1ce3f", "107e57", "014760", "cbe58e"];
        //samba
        PALETTES[4] = ["009638", "F6D800", "002672", "fff", "f8961e"];
        //pepewaves
        PALETTES[5] = ["23B024", "F02423", "294AF6", "fff", "000"];
        //cow
        PALETTES[6] = ["aabf98", "1f1f1f", "f2f2f2", "b5caa3", "20251e"];
        //pastelize
        PALETTES[7] = ["7067cf", "b7c0ee", "cbf3d2", "f87575", "ef626c"];
        //dank
        PALETTES[8] = ["414Cb3", "06061a", "e80663", "fff", "ff0066"];

        NOISE = [20, 35, 55, 85];

        SPEED = [95, 75, 50, 25];

        CHARS = ["#83!:", "@94?;", "W72a+", "N$50c", "0101/", "gm;)'"];

        TIGHTNESS = [2, 3, 5];
    }

    struct Palette {
        bytes3 bg;
        bytes3 colOne;
        bytes3 colTwo;
    }

    function buildLine(
        string memory _chars,
        uint256 _modJump,
        uint8 _x,
        uint8 _y
    ) public pure returns (string memory lineOut) {
        bytes memory byteChars = bytes(_chars);

        uint256 randomModulo = 1;
        lineOut = string(
            abi.encodePacked(
                "<text x ='-",
                _x.toString(),
                "' y='",
                _y.toString(),
                "'>"
            )
        );
        for (uint256 i; i < 12; ++i) {
            string memory charChoice = string(
                abi.encodePacked(byteChars[randomModulo % 4])
            );
            lineOut = string(abi.encodePacked(lineOut, charChoice));
            randomModulo += _modJump;
        }
        lineOut = string(abi.encodePacked(lineOut, "</text>"));
    }

    function buildXLines(
        string memory _chars,
        uint256 _modStart,
        uint256 numLines
    ) public pure returns (string memory lineOut) {
        uint8 x = 1;
        uint8 y;
        for (uint256 i; i < numLines; ++i) {
            lineOut = string(
                abi.encodePacked(lineOut, buildLine(_chars, _modStart, x, y))
            );
            _modStart += 7;
            y += 4;
            if (x == 1) {
                x = 3;
            } else {
                x = 1;
            }
        }
    }

    function buildSVG(uint256 _tokenId, string memory _hash)
        public
        view
        returns (string memory _svg)
    {
        // get traits from id
        Traits memory tokenTraits = buildTraits(_hash);

        uint256 modStart = tokenTraits.noise + tokenTraits.tightness;
        _svg = string(
            abi.encodePacked(
                tokenTraits.palette[0],
                "'/><defs><g id='chars' font-family='monospace'>",
                buildXLines(
                    tokenTraits.charSet,
                    modStart,
                    10 - tokenTraits.numCols
                ),
                "<animate attributeName='font-size' attributeType='XML' values='100%;",
                AnonymiceLibrary.toString(tokenTraits.speed),
                "%;100%' begin='0s' dur='15s' repeatCount='indefinite'/></g><filter id='turbulence'><feTurbulence type='turbulence' baseFrequency='0.",
                AnonymiceLibrary.toString(tokenTraits.noise),
                "' numOctaves='",
                AnonymiceLibrary.toString(tokenTraits.tightness),
                "' result='noise' seed='",
                AnonymiceLibrary.toString(_tokenId),
                buildUseLines(tokenTraits.palette, tokenTraits.numCols)
            )
        );
    }

    function buildTraits(string memory _hash)
        public
        view
        returns (Traits memory tokenTraits)
    {
        uint256[] memory traitArray = new uint256[](6);

        for (uint256 i; i < 6; ++i) {
            traitArray[i] = AnonymiceLibrary.parseInt(
                AnonymiceLibrary.substring(_hash, i, i + 1)
            );
        }
        tokenTraits = Traits(
            PALETTES[traitArray[0]],
            NOISE[traitArray[1]],
            SPEED[traitArray[2]],
            CHARS[traitArray[3]],
            TIGHTNESS[traitArray[4]],
            traitArray[5] + 1
        );
        // Go palettes array and return this palette
    }

    function buildUseLines(string[] memory _pal, uint256 _numCols)
        internal
        pure
        returns (string memory output)
    {
        output = "'/><feDisplacementMap in='SourceGraphic' in2='noise' scale='3' /></filter></defs>";
        uint256 y;

        for (uint256 i; i < _numCols; ++i) {
            output = string(
                abi.encodePacked(
                    output,
                    "<use href='#chars' y='",
                    AnonymiceLibrary.toString(y),
                    "' x='0' filter='url(#turbulence)' width='20' height='20' fill='#",
                    _pal[i + 1],
                    "'/>"
                )
            );

            y += 3;
        }
    }
}