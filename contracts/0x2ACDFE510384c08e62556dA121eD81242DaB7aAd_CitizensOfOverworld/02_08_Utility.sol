// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Utility {
    /*                         
                                                                         ▒▒▒▒ 
                                                                       ▒▒░░░░▒▒
    __    __    __      __  __  __    __                             ▒▒░░░░░░░░▒▒                   
    |  \  |  \  |  \    |  \|  \|  \  |  \                         ▒▒░░░░▒▒░░░░░░▒▒                     
    | 00  | 00 _| 00_    \00| 00 \00 _| 00_    __    __              ▒▒░░░░▒▒░░░░░░▒▒                 
    | 00  | 00|   00 \  |  \| 00|  \|   00 \  |  \  |  \               ▒▒░░░░▒▒▒▒░░░░▒▒                 
    | 00  | 00 \000000  | 00| 00| 00 \000000  | 00  | 00                 ▒▒░░▒▒▒▒░░░░░░▒▒               
    | 00  | 00  | 00 __ | 00| 00| 00  | 00 __ | 00  | 00                 ██▒▒░░░░▒▒░░░░░░▒▒            
    | 00__/ 00  | 00|  \| 00| 00| 00  | 00|  \| 00__/ 00               ██▓▓██░░░░░░▒▒░░░░▒▒                 
     \00    00   \00  00| 00| 00| 00   \00  00 \00    00             ██▓▓██  ▒▒░░░░░░▒▒░░▒▒                      
      \000000     \0000  \00 \00 \00    \0000  _\0000000           ██▓▓██      ▒▒░░░░░░▒▒                      
                                              |  \__| 00         ██▓▓██          ▒▒▒▒▒▒                        
                                               \00    00       ██▓▓██                        
                                                \000000      ██▓▓██                                                               
     ________                                 __      __     ██▓██                              
    |        \                               |  \    |  \                             
    | 00000000__    __  _______    _______  _| 00_    \00  ______   _______    _______ 
    | 00__   |  \  |  \|       \  /       \|   00 \  |  \ /      \ |       \  /       \
    | 00  \  | 00  | 00| 0000000\|  0000000 \000000  | 00|  000000\| 0000000\|  0000000
    | 00000  | 00  | 00| 00  | 00| 00        | 00 __ | 00| 00  | 00| 00  | 00 \00    \ 
    | 00     | 00__/ 00| 00  | 00| 00_____   | 00|  \| 00| 00__/ 00| 00  | 00 _\000000\
    | 00      \00    00| 00  | 00 \00     \   \00  00| 00 \00    00| 00  | 00|       00
     \00       \000000  \00   \00  \0000000    \0000  \00  \000000  \00   \00 \0000000 
                                                                                   
    */

    bytes16 private constant HEX_SYMBOLS = "0123456789abcdef";

    /**
     * Converts a bytes object to a 6 character ASCII `string` hexadecimal representation.
     */
    function _toHexString(bytes memory incomingBytes)
        internal
        pure
        returns (string memory)
    {
        uint24 value = uint24(bytes3(incomingBytes));

        bytes memory buffer = new bytes(6);
        buffer[5] = HEX_SYMBOLS[value & 0xf];
        buffer[4] = HEX_SYMBOLS[(value >> 4) & 0xf];
        buffer[3] = HEX_SYMBOLS[(value >> 8) & 0xf];
        buffer[2] = HEX_SYMBOLS[(value >> 12) & 0xf];
        buffer[1] = HEX_SYMBOLS[(value >> 16) & 0xf];
        buffer[0] = HEX_SYMBOLS[(value >> 20) & 0xf];
        return string(buffer);
    }

    /**
     * Converts a bytes20 object into a string.
     */
    function bytes20ToString(bytes20 _bytes20)
        internal
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 20 && _bytes20[i] != 0) {
            ++i;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 20 && _bytes20[i] != 0; ++i) {
            bytesArray[i] = _bytes20[i];
        }
        return string(bytesArray);
    }
}