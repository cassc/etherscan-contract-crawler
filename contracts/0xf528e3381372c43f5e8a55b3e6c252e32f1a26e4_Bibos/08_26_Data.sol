// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Util} from "src/libraries/Util.sol";

library Data {
    /*//////////////////////////////////////////////////////////////
                                 POINTS
    //////////////////////////////////////////////////////////////*/

    function bodyPoints(uint256 _i) external pure returns (string[2] memory) {
        uint256 pos = (_i % length) * 2;
        string memory x = Util.bytes1ToString(bodyPointsBytes[pos]);
        string memory y = Util.bytes1ToString(bodyPointsBytes[pos + 1]);
        return [x, y];
    }

    function motePoints(uint256 _i) external pure returns (string[2] memory) {
        uint256 pos = (_i % length) * 2;
        string memory x = Util.bytes1ToString(motesPointsBytes[pos]);
        string memory y = Util.bytes1ToString(motesPointsBytes[pos + 1]);
        return [x, y];
    }

    function glintPoints(uint256 _i) external pure returns (string[2][3] memory) {
        uint256 pos = (_i % length) * 6;
        string[2][3] memory result;
        uint256 i;
        for (; i < 3; ) {
            string memory x = Util.bytes1ToString(glintPointsBytes[pos + 2 * i]);
            string memory y = Util.bytes1ToString(glintPointsBytes[pos + 2 * i + 1]);
            result[i] = [x, y];
            ++i;
        }
        return result;
    }

    /*//////////////////////////////////////////////////////////////
                                  TIMES
    //////////////////////////////////////////////////////////////*/

    function shorterTimes(uint256 _i) external pure returns (string memory) {
        uint256 val = uint256(uint8(shorterTimesBytes[_i % length]));
        return string.concat(Util.uint256ToString(val / 10), ".", Util.uint256ToString(val % 10));
    }

    function shortTimes(uint256 _i) external pure returns (string memory) {
        uint256 val = uint256(uint8(shortTimesBytes[_i % length]));
        return string.concat(Util.uint256ToString(val / 10), ".", Util.uint256ToString(val % 10));
    }

    function longTimes(uint256 _i) external pure returns (string memory) {
        uint256 val = uint256(uint8(longTimesBytes[_i % length]));
        return string.concat(Util.uint256ToString(val / 10), ".", Util.uint256ToString(val % 10));
    }

    /*//////////////////////////////////////////////////////////////
                                 PALETTE
    //////////////////////////////////////////////////////////////*/

    function lightestPalette(uint256 _i) external pure returns (string memory) {
        return _getRGBString(lightestPaletteBytes, _i % length);
    }

    function lightPalette(uint256 _i) external pure returns (string memory) {
        return _getRGBString(lightPaletteBytes, _i % length);
    }

    function darkestPalette(uint256 _i) external pure returns (string memory) {
        return _getRGBString(darkestPaletteBytes, _i % length);
    }

    function invertedLightestPalette(uint256 _i) external pure returns (string memory) {
        return _getRGBString(invertedLightestPaletteBytes, _i % length);
    }

    function invertedLightPalette(uint256 _i) external pure returns (string memory) {
        return _getRGBString(invertedLightPaletteBytes, _i % length);
    }

    function invertedDarkestPalette(uint256 _i) external pure returns (string memory) {
        return _getRGBString(invertedDarkestPaletteBytes, _i % length);
    }

    function _getRGBString(bytes memory _palette, uint256 _pos) internal pure returns (string memory result) {
        return
            string.concat(
                "#",
                Util.bytes1ToHex(_palette[3 * _pos]),
                Util.bytes1ToHex(_palette[3 * _pos + 1]),
                Util.bytes1ToHex(_palette[3 * _pos + 2])
            );
    }

    /*//////////////////////////////////////////////////////////////
                                  DEFS
    //////////////////////////////////////////////////////////////*/

    function defs() external pure returns (string memory) {
        return
            string.concat(
                "<defs>",
                '<filter id="bibo-blur" x="-50%" y="-50%" width="200%" height="200%" color-interpolation-filters="sRGB">',
                '<feGaussianBlur stdDeviation="15" result="out" />',
                "</filter>",
                '<filter id="bibo-blur-sm" x="-50%" y="-50%" width="200%" height="200%" color-interpolation-filters="sRGB">',
                '<feGaussianBlur stdDeviation="5" result="out" />',
                "</filter>",
                '<filter id="bibo-blur-lg" x="-50%" y="-50%" width="200%" height="200%" color-interpolation-filters="sRGB">',
                '<feGaussianBlur stdDeviation="32" result="out" />',
                "</filter>",
                '<path id="bibo-jitter-sm" d="M0.9512 0.9818C4.7033 2.4814 10 4.5234 10 0.9818c0 -3.5299 -5.0997 -1.5806 -9.0488 0zM0.9512 0.9818C0.9381 0.987 0.925 0.9923 0.9118 0.9975C-3.0426 2.5808 -8 4.5628 -8 1.0211s5.1991 -1.5389 8.9512 -0.0394z" />',
                '<path id="bibo-jitter-lg" d="M-0.0596 -0.0403C4.5263 3.4116 11 5.4815 11 -0.0404c0 -5.4948 -6.2329 -3.6384 -11.0596 0zM-0.0596 -0.0403c-0.016 0.0121 -0.0321 0.0242 -0.0481 0.0362C-4.941 3.6406 -11 5.5721 -11 0.0503c0 -5.5218 6.3545 -3.5425 10.9404 -0.0906z" />',
                "</defs>"
            );
    }

    function mpathJitterLg() internal pure returns (string memory) {
        return '<mpath xlink:href="#bibo-jitter-lg" />';
    }

    function mpathJitterSm() internal pure returns (string memory) {
        return '<mpath xlink:href="#bibo-jitter-sm"/>';
    }

    /*//////////////////////////////////////////////////////////////
                                  DATA
    //////////////////////////////////////////////////////////////*/

    uint256 constant length = 64;
    bytes constant bodyPointsBytes =
        hex"75727a8f887c748087736b88906c8a8b7ba397906b7f7a79729488a1829766966faa92846da1a578947983849e6c79af8db891a686b48dafae95a09e9099ad8aa7a49e88a28073887a98b670b77abd84b58eae7ca391b484ad6f7e7278b78bc39ac69ebaa5b483ab85bc9da895ad95bec68eaeabb89aadbebbb1a6c19db1b2b6";
    bytes constant motesPointsBytes =
        hex"f183ee6ce186db75f29ae15fdf97d28dc364c680e8add850efc3d4abc69cb54daa67b971aa84b397c753d5c4c5c1b8b2a055957ca19ee4d2cedcbed3b0c0a2b2a3448f469163878e8ea69a90b5e9a1d897c989b97c44786282547e7172967b8287e683d379b46c5069706287579aa3eb71ee73d461b75b5a5a6b507e6ca548a0";
    bytes constant glintPointsBytes =
        hex"ad5e6bc1ce7f6bc196d2c1c1adce5e7f96d25e7fc16b6b6b965ac1c16bc16bc15ead5a96ce7fcead96d2965a5e7fce7fc16b5a9696d2ad5e6b6bc1c17f5e5ead7fcece7f5eadd296d296c1c17f5e6b6b5ead7f5eadcecead5a965a9696d26b6b965aadce5a96ceadadce6b6b965a5a967f5e5e7f7f5ecead7f5ec1c1ce7f7f5e7fce96d25e7f7f5e96d2d2965a96965aad5e6bc1ce7f6bc196d2c1c1adce5e7f96d25e7fc16b6b6b965ac1c16bc16bc15ead5a96ce7fcead96d2965a5e7fce7fc16b5a9696d2ad5e6b6bc1c17f5e5ead7fcece7f5eadd296d296c1c17f5e6b6b5ead7f5eadcecead5a965a9696d26b6b965aadce5a96ceadadce6b6b965a5a967f5e5e7f7f5ecead7f5ec1c1ce7f7f5e7fce96d25e7f7f5e96d2d2965a96965aad5e6bc1ce7f6bc196d2c1c1adce5e7f96d25e7fc16b6b6b965ac1c16bc16bc15ead5a96ce7fcead96d2965a5e7fce7fc16b5a9696d2ad5e6b6bc1c17f5e5ead7fcece7f5eadd296d296c1c17f5e6b6b5ead7f5eadcecead5a965a9696d26b6b";
    bytes public constant shorterTimesBytes =
        hex"13121013120f13110f12130f1212100f13130f0f1111100f100f1308070509070505060708090808090507070709080908050008090700090008000600080900";
    bytes public constant shortTimesBytes =
        hex"59614460553a60493b505f3753543e3a6163343849473e333c325e53483b624d34343e48505c595562364d4f4e5d515d53384457604c5a5b4454534148586063";
    bytes public constant longTimesBytes =
        hex"70927d8856956369837b55785486625886664f4f4d78875460754c7c785c7f4e709074877c6c788e5f63636478597586777a85746c82799271746d698c4f9288";
    bytes public constant lightPaletteBytes =
        hex"ff3333ff4633ff5933ff6c33ff7e33ff9133ffa433ffb733ffca33ffdd33fff033fcff33e9ff33d6ff33c3ff33b0ff339dff338aff3378ff3365ff3352ff333fff3333ff3a33ff4d33ff6033ff7233ff8533ff9833ffab33ffbe33ffd133ffe433fff733f5ff33e2ff33cfff33bcff33a9ff3396ff3383ff3371ff335eff334bff3338ff4133ff5433ff6733ff7933ff8c33ff9f33ffb233ffc533ffd833ffeb33fffd33ffff33eeff33dbff33c8ff33b5ff33a2ff338fff337dff336aff3357";
    bytes public constant lightestPaletteBytes =
        hex"ffb3b3ffbab3ffc1b3ffc8b3ffcfb3ffd6b3ffddb3ffe4b3ffebb3fff2b3fff9b3feffb3f7ffb3f0ffb3e8ffb3e1ffb3daffb3d3ffb3ccffb3c5ffb3beffb3b7ffb3b3ffb5b3ffbcb3ffc3b3ffcab3ffd1b3ffd8b3ffe0b3ffe7b3ffeeb3fff5b3fffcb3fbffb3f4ffb3edffb3e6ffb3dfffb3d8ffb3d1ffb3caffb3c3ffb3bbffb3b4ffb8b3ffbfb3ffc6b3ffcdb3ffd4b3ffdbb3ffe2b3ffe9b3fff0b3fff7b3fffeb3ffffb3f9ffb3f1ffb3eaffb3e3ffb3dcffb3d5ffb3ceffb3c7ffb3c0";
    bytes public constant darkestPaletteBytes =
        hex"060a06060d07061007061407061907051e07042306022805060a08060d0a06100c06140e061910051e1304231502281706090a060d0d061010061414061819051d1e04212302272806080a06090d060b10060d14060f1905111e04122302142806060a06060d06061006061406061905051e04042302022808060a09060d0b06100d06140f061911051e12042314022809060a0d060d1006101406141806191d051e2104232702280a06080d060a10060c14060e1906101e0513230415280217";
    bytes public constant invertedLightPaletteBytes =
        hex"50f0f04ddcf04bc8f04ab5f049a2f0498ef04a7af04b66f04c52f04e41f14f33f1502bf1552cf15d2df16a2ff17831f18933f19b36f0ac39f0bf3cf0d23ff0e642f0f244e9f243d5f242c1f241aff3419bf34087f43f72f43f5ef53e4af53e38f53e28f64123f54924f55625f56528f4772af48a2df39d30f3af33f2c336f2d73af2ea3de4ef3dd0f03dbdf03cabf03c98f03c87f03b76f03b67f03b5cf03b53f13b4ff13b4ef1414ef14b4df15a4cf16b4cf07e4bf0914bf0a34cf0b74df0ca";
    bytes public constant invertedLightestPaletteBytes =
        hex"3e45453c3e3e3838383133342a2e322328321d2233191c34161635141136120b371206371406381707381b09381f0a39230c39280e3a2d103b32123b37143c3c163e3f183d3e18373c18323b182d3a192939192539182139181d3917193a17173b16143b18143b1b153b1f173c23193d281b3f2c1e413220443722473d234a43254d4a264a4a26454a254149243c492238492134492030491f2c491e29481e27481d25481d25482026482427482929482d2b47322d473730463b34463f384542";
    bytes public constant invertedDarkestPaletteBytes =
        hex"f9f5f9f9f2f8f9eff8f9ebf8f9e6f8fae1f8fbdcf9fdd7faf9f5f7f9f2f5f9eff3f9ebf1f9e6effae1ecfbdceafdd7e8f9f6f5f9f2f2f9efeff9ebebf9e7e6fae2e1fbdedcfdd8d7f9f7f5f9f6f2f9f4eff9f2ebf9f0e6faeee1fbeddcfdebd7f9f9f5f9f9f2f9f9eff9f9ebf9f9e6fafae1fbfbdcfdfdd7f7f9f5f6f9f2f4f9eff2f9ebf0f9e6eefae1edfbdcebfdd7f6f9f5f2f9f2eff9efebf9ebe7f9e6e2fae1defbdcd8fdd7f5f9f7f2f9f5eff9f3ebf9f1e6f9efe1faecdcfbead7fde8";
}