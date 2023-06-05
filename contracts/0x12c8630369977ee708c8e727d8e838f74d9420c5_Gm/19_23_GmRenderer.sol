// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {InflateLib} from "./InflateLib.sol";
import {GmDataInterface} from "./GmDataInterface.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

interface ICourierFont {
    function font() external view returns (string memory);
}

contract GmRenderer {
    ICourierFont private immutable font;
    GmDataInterface private immutable gmData1;
    GmDataInterface private immutable gmData2;

    struct Color {
        bytes hexNum;
        bytes name;
    }

    constructor(
        ICourierFont fontAddress,
        GmDataInterface gmData1Address,
        GmDataInterface gmData2Address
    ) {
        font = fontAddress;
        gmData1 = gmData1Address;
        gmData2 = gmData2Address;
    }

    /// @notice decompresses the GmDataSet
    /// @param gmData, compressed ascii svg data
    function decompress(GmDataInterface.GmDataSet memory gmData)
        public
        pure
        returns (bytes memory, bytes memory)
    {
        (, bytes memory inflated) = InflateLib.puff(
            gmData.compressedImage,
            gmData.compressedSize
        );
        return (gmData.imageName, inflated);
    }

    /// @notice returns an svg filter
    /// @param index, a random number derived from the seed
    function _getFilter(uint256 index) internal pure returns (bytes memory) {

        // 1 || 2 || 3 || 4 || 5 -> noise 5%
        if (
            (index == 1) ||
            (index == 2) ||
            (index == 3) ||
            (index == 4) ||
            (index == 5)
        ) {
            return "noise";
        }

        // 7 || 8 || 98 -> scribble 3%
        if ((index == 7) || (index == 8) || (index == 9)) {
            return "scribble";
        }

        // 10 - 29 -> morph 20%
        if (((100 - index) > 70) && ((100 - index) <= 90)) {
            return "morph";
        }

        // 30 - 39 -> glow 10%
        if (((100 - index) > 60) && ((100 - index) <= 70)) {
            return "glow";
        }

        // 69 -> fractal 1%
        if (index == 69) {
            return "fractal";
        }

        return "none";
    }

    /// @notice returns a background color and font color
    /// @param seed, pseudo random seed
    function _getColors(bytes32 seed)
        internal
        pure
        returns (Color memory bgColor, Color memory fontColor)
    {
        uint32 bgRand = uint32(bytes4(seed)) % 111;
        uint32 fontJitter = uint32(bytes4(seed << 32)) % 5;
        uint32 fontOperation = uint8(bytes1(seed << 64)) % 2;
        uint32 fontRand;
        if (fontOperation == 0) {
            fontRand = (bgRand + (55 + fontJitter)) % 111;
        } else {
            fontRand = (bgRand + (55 - fontJitter)) % 111;
        }

        return (_getColor(bgRand), _getColor(fontRand));
    }

    /// @notice executes string comparison against two strings
    /// @param a, first string
    /// @param b, second string
    function strCompare(string memory a, string memory b) internal pure returns (bool) {
        if(bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
        }
    }

    /// @notice returns the raw svg yielded by seed
    /// @param seed, pseudo random seed
    function svgRaw(bytes32 seed)
        external
        view
        returns (
            bytes memory,
            bytes memory,
            bytes memory,
            bytes memory,
            bytes memory
        )
    {
        uint32 style = uint32(bytes4(seed << 65)) % 69;
        uint32 filterRand = uint32(bytes4(seed << 97)) % 100;
        bytes memory filter = _getFilter(filterRand);

        (Color memory bgColor, Color memory fontColor) = _getColors(seed);

        bytes memory inner;
        bytes memory name;
        if (style < 50) {
            (name, inner) = decompress(gmData1.getSvg(style));
        } else {
            (name, inner) = decompress(gmData2.getSvg(style));
        }

        if ((strCompare(string(name), "Hex")) || (strCompare(string(name), "Binary")) || (strCompare(string(name), "Morse")) || (strCompare(string(name), "Mnemonic"))){
            filter = "none";
        }

        return (
            abi.encodePacked(
                svgPreambleString(bgColor.hexNum, fontColor.hexNum, filter),
                inner,
                "</svg>"
            ),
            name,
            bgColor.name,
            fontColor.name,
            filter
        );
    }

    /// @notice returns the svg filters
    function svgFilterDefs() private view returns (bytes memory) {
        return
            abi.encodePacked(
                '<defs><filter id="fractal" filterUnits="objectBoundingBox" x="0%" y="0%" width="100%" height="100%" ><feTurbulence id="turbulence" type="fractalNoise" baseFrequency="0.03" numOctaves="1" ><animate attributeName="baseFrequency" values="0.01;0.4;0.01" dur="100s" repeatCount="indefinite" /></feTurbulence><feDisplacementMap in="SourceGraphic" scale="50"></feDisplacementMap></filter><filter id="morph"><feMorphology operator="dilate" radius="0"><animate attributeName="radius" values="0;5;0" dur="8s" repeatCount="indefinite" /></feMorphology></filter><filter id="glow" filterUnits="objectBoundingBox" x="0%" y="0%" width="100%" height="100%" ><feGaussianBlur stdDeviation="5" result="blur2" in="SourceGraphic" /><feMerge><feMergeNode in="blur2" /><feMergeNode in="SourceGraphic" /></feMerge></filter><filter id="noise"><feTurbulence baseFrequency="0.05"/><feColorMatrix type="hueRotate" values="0"><animate attributeName="values" from="0" to="360" dur="1s" repeatCount="indefinite"/></feColorMatrix><feColorMatrix type="matrix" values="0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0"/><feDisplacementMap in="SourceGraphic" scale="10"/></filter><filter id="none"><feOffset></feOffset></filter><filter id="scribble"><feTurbulence type="turbulence" baseFrequency="0.05" numOctaves="2" result="turbulence"/><feDisplacementMap in2="turbulence" in="SourceGraphic" scale="50" xChannelSelector="R" yChannelSelector="G"/></filter><filter id="tile" x="10" y="10" width="10%" height="10%"><feTile in="SourceGraphic" x="10" y="10" width="10" height="10" /><feTile/></filter></defs>'
            );
    }

    /// @notice returns the svg preamble
    /// @param bgColor, color of the background as hex string
    /// @param fontColor, color of the font as hex string
    /// @param filter, filter for the svg
    function svgPreambleString(
        bytes memory bgColor,
        bytes memory fontColor,
        bytes memory filter
    ) private view returns (bytes memory) {
        return
            abi.encodePacked(
                "<svg viewBox='0 0 640 640' width='100%' height='100%' xmlns='http://www.w3.org/2000/svg'><style> @font-face { font-family: CourierFont; src: url('",
                font.font(),
                "') format('opentype'); }",
                ".base{filter:url(#",
                filter,
                ");fill:",
                fontColor,
                ";font-family:CourierFont;font-size: 16px;}</style>",
                svgFilterDefs(),
                '<rect width="100%" height="100%" fill="',
                bgColor,
                '" /> '
            );
    }

    /// @notice returns the Color yielded by index
    /// @param index, random number determined by seed
    function _getColor(uint32 index)
        internal
        pure
        returns (Color memory color)
    {
        // AUTOGEN:START

        if (index == 0) {
            color.hexNum = "#000000";
            color.name = "Black";
        }

        if (index == 1) {
            color.hexNum = "#004c6a";
            color.name = "Navy Dark Blue";
        }

        if (index == 2) {
            color.hexNum = "#0098d4";
            color.name = "Bayern Blue";
        }

        if (index == 3) {
            color.hexNum = "#00e436";
            color.name = "Lexaloffle Green";
        }

        if (index == 4) {
            color.hexNum = "#1034a6";
            color.name = "Egyptian Blue";
        }

        if (index == 5) {
            color.hexNum = "#008811";
            color.name = "Lush Garden";
        }

        if (index == 6) {
            color.hexNum = "#06d078";
            color.name = "Underwater Fern";
        }

        if (index == 7) {
            color.hexNum = "#1c1cf0";
            color.name = "Bluebonnet";
        }

        if (index == 8) {
            color.hexNum = "#127453";
            color.name = "Green Velvet";
        }

        if (index == 9) {
            color.hexNum = "#14bab4";
            color.name = "Super Rare Jade";
        }

        if (index == 10) {
            color.hexNum = "#111122";
            color.name = "Corbeau";
        }

        if (index == 11) {
            color.hexNum = "#165d95";
            color.name = "Lapis Jewel";
        }

        if (index == 12) {
            color.hexNum = "#16b8f3";
            color.name = "Zima Blue";
        }

        if (index == 13) {
            color.hexNum = "#1ef876";
            color.name = "Synthetic Spearmint";
        }

        if (index == 14) {
            color.hexNum = "#214fc6";
            color.name = "New Car";
        }

        if (index == 15) {
            color.hexNum = "#249148";
            color.name = "Paperboy's Lawn";
        }

        if (index == 16) {
            color.hexNum = "#24da91";
            color.name = "Reptile Green";
        }

        if (index == 17) {
            color.hexNum = "#223311";
            color.name = "Darkest Forest";
        }

        if (index == 18) {
            color.hexNum = "#297f6d";
            color.name = "Mermaid Sea";
        }

        if (index == 19) {
            color.hexNum = "#22cccc";
            color.name = "Mermaid Net";
        }

        if (index == 20) {
            color.hexNum = "#2e2249";
            color.name = "Elderberry";
        }

        if (index == 21) {
            color.hexNum = "#326ab1";
            color.name = "Dover Straits";
        }

        if (index == 22) {
            color.hexNum = "#2bc51b";
            color.name = "Felwood Leaves";
        }

        if (index == 23) {
            color.hexNum = "#391285";
            color.name = "Pixie Powder";
        }

        if (index == 24) {
            color.hexNum = "#2e58e8";
            color.name = "Veteran's Day Blue";
        }

        if (index == 25) {
            color.hexNum = "#419f59";
            color.name = "Chateau Green";
        }

        if (index == 26) {
            color.hexNum = "#45e9c1";
            color.name = "Aphrodite Aqua";
        }

        if (index == 27) {
            color.hexNum = "#424330";
            color.name = "Garden Path";
        }

        if (index == 28) {
            color.hexNum = "#429395";
            color.name = "Catalan";
        }

        if (index == 29) {
            color.hexNum = "#44dd00";
            color.name = "Magic Blade";
        }

        if (index == 30) {
            color.hexNum = "#432e6f";
            color.name = "Her Highness";
        }

        if (index == 31) {
            color.hexNum = "#4477dd";
            color.name = "Andrea Blue";
        }

        if (index == 32) {
            color.hexNum = "#5ad33e";
            color.name = "Verdant Fields";
        }

        if (index == 33) {
            color.hexNum = "#3a18b1";
            color.name = "Indigo Blue";
        }

        if (index == 34) {
            color.hexNum = "#556611";
            color.name = "Forestial Outpost";
        }

        if (index == 35) {
            color.hexNum = "#55bb88";
            color.name = "Bleached Olive";
        }

        if (index == 36) {
            color.hexNum = "#5500ee";
            color.name = "Tezcatlipoca Blue";
        }

        if (index == 37) {
            color.hexNum = "#545554";
            color.name = "Carbon Copy";
        }

        if (index == 38) {
            color.hexNum = "#58a0bc";
            color.name = "Dupain";
        }

        if (index == 39) {
            color.hexNum = "#55ff22";
            color.name = "Traffic Green";
        }

        if (index == 40) {
            color.hexNum = "#5b3e90";
            color.name = "Daisy Bush";
        }

        if (index == 41) {
            color.hexNum = "#6688ff";
            color.name = "Deep Denim";
        }

        if (index == 42) {
            color.hexNum = "#61e160";
            color.name = "Lightish Green";
        }

        if (index == 43) {
            color.hexNum = "#6a31ca";
            color.name = "Sagat Purple";
        }

        if (index == 44) {
            color.hexNum = "#667c3e";
            color.name = "Military Green";
        }

        if (index == 45) {
            color.hexNum = "#68c89d";
            color.name = "Intense Jade";
        }

        if (index == 46) {
            color.hexNum = "#6d1008";
            color.name = "Chestnut Brown";
        }

        if (index == 47) {
            color.hexNum = "#696374";
            color.name = "Purple Punch";
        }

        if (index == 48) {
            color.hexNum = "#6fb7e0";
            color.name = "Life Force";
        }

        if (index == 49) {
            color.hexNum = "#770044";
            color.name = "Dawn of the Fairies";
        }

        if (index == 50) {
            color.hexNum = "#7851a9";
            color.name = "Royal Lavender";
        }

        if (index == 51) {
            color.hexNum = "#769c18";
            color.name = "Luminescent Green";
        }

        if (index == 52) {
            color.hexNum = "#7be892";
            color.name = "Ragweed";
        }

        if (index == 53) {
            color.hexNum = "#703be7";
            color.name = "Bluish Purple";
        }

        if (index == 54) {
            color.hexNum = "#7b8b5d";
            color.name = "Sage Leaves";
        }

        if (index == 55) {
            color.hexNum = "#82d9c5";
            color.name = "Tender Turquoise";
        }

        if (index == 56) {
            color.hexNum = "#7e2530";
            color.name = "Scarlet Shade";
        }

        if (index == 57) {
            color.hexNum = "#83769c";
            color.name = "Voxatron Purple";
        }

        if (index == 58) {
            color.hexNum = "#88cc00";
            color.name = "Fabulous Frog";
        }

        if (index == 59) {
            color.hexNum = "#881166";
            color.name = "Possessed Purple";
        }

        if (index == 60) {
            color.hexNum = "#8756e4";
            color.name = "Gloomy Purple";
        }

        if (index == 61) {
            color.hexNum = "#93b13d";
            color.name = "Green Tea Ice Cream";
        }

        if (index == 62) {
            color.hexNum = "#90fda9";
            color.name = "Foam Green";
        }

        if (index == 63) {
            color.hexNum = "#914b13";
            color.name = "Parasite Brown";
        }

        if (index == 64) {
            color.hexNum = "#919c81";
            color.name = "Whispering Willow";
        }

        if (index == 65) {
            color.hexNum = "#99eeee";
            color.name = "Freezy Breezy";
        }

        if (index == 66) {
            color.hexNum = "#983d53";
            color.name = "Algae Red";
        }

        if (index == 67) {
            color.hexNum = "#9c87c1";
            color.name = "Petrified Purple";
        }

        if (index == 68) {
            color.hexNum = "#98da2c";
            color.name = "Effervescent Lime";
        }

        if (index == 69) {
            color.hexNum = "#942193";
            color.name = "Acai Juice";
        }

        if (index == 70) {
            color.hexNum = "#a675fe";
            color.name = "Purple Illusionist";
        }

        if (index == 71) {
            color.hexNum = "#a4c161";
            color.name = "Jungle Juice";
        }

        if (index == 72) {
            color.hexNum = "#aa00cc";
            color.name = "Ferocious Fuchsia";
        }

        if (index == 73) {
            color.hexNum = "#a85e39";
            color.name = "Earthen Jug";
        }

        if (index == 74) {
            color.hexNum = "#aaa9a4";
            color.name = "Ellie Grey";
        }

        if (index == 75) {
            color.hexNum = "#aaee11";
            color.name = "Glorious Green Glitter";
        }

        if (index == 76) {
            color.hexNum = "#ad4379";
            color.name = "Mystic Maroon";
        }

        if (index == 77) {
            color.hexNum = "#b195e4";
            color.name = "Dreamy Candy Forest";
        }

        if (index == 78) {
            color.hexNum = "#b1dd52";
            color.name = "Conifer";
        }

        if (index == 79) {
            color.hexNum = "#c034af";
            color.name = "Pink Perennial";
        }

        if (index == 80) {
            color.hexNum = "#b78727";
            color.name = "University of California Gold";
        }

        if (index == 81) {
            color.hexNum = "#b9d08b";
            color.name = "Young Leaves";
        }

        if (index == 82) {
            color.hexNum = "#bb11ee";
            color.name = "Promiscuous Pink";
        }

        if (index == 83) {
            color.hexNum = "#c06960";
            color.name = "Tapestry Red";
        }

        if (index == 84) {
            color.hexNum = "#bebbc9";
            color.name = "Silverberry";
        }

        if (index == 85) {
            color.hexNum = "#bf0a30";
            color.name = "Old Glory Red";
        }

        if (index == 86) {
            color.hexNum = "#c35b99";
            color.name = "Llilacquered";
        }

        if (index == 87) {
            color.hexNum = "#caa906";
            color.name = "Christmas Gold";
        }

        if (index == 88) {
            color.hexNum = "#c2f177";
            color.name = "Cucumber Milk";
        }

        if (index == 89) {
            color.hexNum = "#d648d7";
            color.name = "Pinkish Purple";
        }

        if (index == 90) {
            color.hexNum = "#cf9346";
            color.name = "Fleshtone Shade Wash";
        }

        if (index == 91) {
            color.hexNum = "#d3e0b1";
            color.name = "Rockmelon Rind";
        }

        if (index == 92) {
            color.hexNum = "#d22d1d";
            color.name = "Pure Red";
        }

        if (index == 93) {
            color.hexNum = "#d28083";
            color.name = "Galah";
        }

        if (index == 94) {
            color.hexNum = "#d5c7e8";
            color.name = "Foggy Love";
        }

        if (index == 95) {
            color.hexNum = "#db1459";
            color.name = "Rubylicious";
        }

        if (index == 96) {
            color.hexNum = "#dd66bb";
            color.name = "Pink Charge";
        }

        if (index == 97) {
            color.hexNum = "#e2b227";
            color.name = "Gold Tips";
        }

        if (index == 98) {
            color.hexNum = "#ee0099";
            color.name = "Love Vessel";
        }

        if (index == 99) {
            color.hexNum = "#dd55ff";
            color.name = "Flaming Flamingo";
        }

        if (index == 100) {
            color.hexNum = "#eda367";
            color.name = "Adventure Orange";
        }

        if (index == 101) {
            color.hexNum = "#e9f1d0";
            color.name = "Yellowish White";
        }

        if (index == 102) {
            color.hexNum = "#ef3939";
            color.name = "Vivaldi Red";
        }

        if (index == 103) {
            color.hexNum = "#e78ea5";
            color.name = "Underwater Flare";
        }

        if (index == 104) {
            color.hexNum = "#eedd11";
            color.name = "Yellow Buzzing";
        }

        if (index == 105) {
            color.hexNum = "#ee2277";
            color.name = "Furious Fuchsia";
        }

        if (index == 106) {
            color.hexNum = "#f075e6";
            color.name = "Lian Hong Lotus Pink";
        }

        if (index == 107) {
            color.hexNum = "#f7c34c";
            color.name = "Creamy Sweet Corn";
        }

        if (index == 108) {
            color.hexNum = "#fc0fc0";
            color.name = "CGA Pink";
        }

        if (index == 109) {
            color.hexNum = "#ff6622";
            color.name = "Sparrows Fire";
        }

        if (index == 110) {
            color.hexNum = "#fbaf8d";
            color.name = "Orange Grove";
        }

        // AUTOGEN:END
    }
}