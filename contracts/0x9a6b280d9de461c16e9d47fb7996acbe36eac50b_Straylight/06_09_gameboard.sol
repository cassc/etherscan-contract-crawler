//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "solidity-bytes-utils/contracts/BytesLib.sol";
import "base64-sol/base64.sol";

/// @title Gameboard for inchain turmites
/// @notice Implementation of an Gameboard for Straylight Protocoll.
/// @notice we are all standing on the shoulders of giants - this board is inspired by how CryptoGhost is drawing boards
/// @author @brachlandberlin / plsdlr.net
/// @dev bytesLib & base64 are required for formating

contract Gameboard {
    using BytesLib for bytes;
    mapping(uint256 => gameboard) gameboards;

    struct gameboard {
        bytes1[144][144] board;
    }

    /// @dev an explicit function to get a byte with x,y,board
    /// @param x the x position on the board
    /// @param y the y position on the board
    /// @param boardNumber the boardNumber number
    function getByte(
        uint256 x,
        uint256 y,
        uint256 boardNumber
    ) public view returns (bytes1) {
        return gameboards[boardNumber].board[x][y];
    }

    /// @dev an explicit function to set a byte with x,y,value,board
    /// @param x the x position on the board
    /// @param y the y position on the board
    /// @param value the byte1 value to set
    /// @param boardNumber the board number
    function setByte(
        uint256 x,
        uint256 y,
        bytes1 value,
        uint256 boardNumber
    ) internal {
        gameboards[boardNumber].board[x][y] = value;
    }

    /// @dev function to generate the Bitmap Base64 encoded with boardNumber, position x, position y and boolean if turmite should be rendered
    /// @param boardNumber the board number
    /// @param posx the x position of the turmite on the board
    /// @param posy the y position on the turmite on the board
    /// @param renderTurmite boolean to render turmite
    function getBitmapBase64(
        uint8 boardNumber,
        uint8 posx,
        uint8 posy,
        bool renderTurmite
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:image/bmp;base64,",
                    Base64.encode(getBitmap(boardNumber, posx, posy, renderTurmite))
                )
            );
    }

    /// @dev function to generate a SVG String with boardNumber, position x, position y and boolean if turmite should be rendered
    /// @dev same parameters as getBitmapBase64
    function getSvg(
        uint8 boardNumber,
        uint8 posx,
        uint8 posy,
        bool renderTurmite
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '<svg class="svgBGG" xmlns="http://www.w3.org/2000/svg" version="1.1" width="500" height="500"><defs id="someDefs"><style id="style1999"> .svgBGG { width: 500px;height: 500px;background-image: url(',
                            getBitmapBase64(boardNumber, posx, posy, renderTurmite),
                            "); background-repeat: no-repeat; background-size: 100%; image-rendering: -webkit-optimize-contrast; -ms-interpolation-mode: nearest-neighbor; image-rendering: -moz-crisp-edges; image-rendering: pixelated;}</style></defs></svg>"
                        )
                    )
                )
            );
    }

    /// @dev function to generate byte representation of the Board, position x, position y and boolean if turmite should be rendered
    /// @dev BMP Header is generated externaly
    /// @dev same parameters as getBitmapBase64
    function getBitmap(
        uint8 boardNumber,
        uint8 posx,
        uint8 posy,
        bool renderTurmite
    ) public view returns (bytes memory) {
        bytes
            memory headers = hex"424D385500000000000036040000280000009000000090000000010008000000000002510000120B0000120B00000000000000000000000000000101010002020200030303000404040005050500060606000707070008080800090909000A0A0A000B0B0B000C0C0C000D0D0D000E0E0E000F0F0F00101010001111110012121200131313001414140015151500161616001717170018181800191919001A1A1A001B1B1B001C1C1C001D1D1D001E1E1E001F1F1F00202020002121210022222200232323002424240025252500262626002727270028282800292929002A2A2A002B2B2B002C2C2C002D2D2D002E2E2E002F2F2F00303030003131310032323200333333003434340035353500363636003737370038383800393939003A3A3A003B3B3B003C3C3C003D3D3D003E3E3E003F3F3F00404040004141410042424200434343004444440045454500464646004747470048484800494949004A4A4A004B4B4B004C4C4C004D4D4D004E4E4E004F4F4F00505050005151510052525200535353005454540055555500565656005757570058585800595959005A5A5A005B5B5B005C5C5C005D5D5D005E5E5E005F5F5F00606060006161610062626200636363006464640065656500666666006767670068686800696969006A6A6A006B6B6B006C6C6C006D6D6D006E6E6E006F6F6F00707070007171710072727200737373007474740075757500767676007777770078787800797979007A7A7A007B7B7B007C7C7C007D7D7D007E7E7E007F7F7F00808080008181810082828200838383008484840085858500868686008787870088888800898989008A8A8A008B8B8B008C8C8C008D8D8D008E8E8E008F8F8F00909090009191910092929200939393009494940095959500969696009797970098989800999999009A9A9A009B9B9B009C9C9C009D9D9D009E9E9E009F9F9F00A0A0A000A1A1A100A2A2A200A3A3A300A4A4A400A5A5A500A6A6A600A7A7A700A8A8A800A9A9A900AAAAAA00ABABAB00ACACAC00ADADAD00AEAEAE00AFAFAF00B0B0B000B1B1B100B2B2B200B3B3B300B4B4B400B5B5B500B6B6B600B7B7B700B8B8B800B9B9B900BABABA00BBBBBB00BCBCBC00BDBDBD00BEBEBE00BFBFBF00C0C0C000C1C1C100C2C2C200C3C3C300C4C4C400C5C5C500C6C6C600C7C7C700C8C8C800C9C9C900CACACA00CBCBCB00CCCCCC00CDCDCD00CECECE00CFCFCF00D0D0D000D1D1D100D2D2D200D3D3D300D4D4D400D5D5D500D6D6D600D7D7D700D8D8D800D9D9D900DADADA00DBDBDB00DCDCDC00DDDDDD00DEDEDE00DFDFDF00E0E0E000E1E1E100E2E2E200E3E3E300E4E4E400E5E5E500E6E6E600E7E7E700E8E8E800E9E9E900EAEAEA00EBEBEB00ECECEC00EDEDED00EEEEEE00EFEFEF00F0F0F000F1F1F100F2F2F200F3F3F300F4F4F400F5F5F500F6F6F600F7F7F700F8F8F800F9F9F900FAFAFA00FBFBFB00FCFCFC00FDFDFD00FEFEFE00FFFFFF00";
        bytes memory returngameboard = new bytes(20736);
        for (uint256 xFill = 0; xFill < 144; ++xFill) {
            for (uint256 yFill = 0; yFill < 144; ++yFill) {
                uint256 index = xFill + 144 * yFill;
                returngameboard[index] = gameboards[boardNumber].board[xFill][yFill];
            }
        }
        if (renderTurmite == true) {
            uint256 index2 = uint256(posx) + 144 * uint256(posy);
            returngameboard[index2] = bytes1(uint8(165));
        }
        return headers.concat(returngameboard);
    }
}