// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Book of Drank
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//             ;OO000O000000OOxllc::cc;ck0OO0O,             //
//             cNMMMMMMMMMMMMMNXXXKOolldXMMMMNc             //
//             :NWNNWWNNWNXKKKKKKKK0kxxk0KKKK0;             //
//             cNWWWWWWWWWNNNNNNN0xOXNNNNNNNNX:             //
//             cWMMMMMMMMMMMMMMMMNKXWNOONMMMMNc             //
//             .ckNWNWWWWWWWWWNXXXXXX0xkKXXKdc.             //
//               ;XWWNNNNNNNNNXKKKKKKK0OOO0k'               //
//               :NMMWWNNNNNNNNNNNNNNXK00O0k'               //
//               :NMMMMWWNNNNNNNNNNNNNNXK00k'               //
//               'd0WMMMMMWNNWWWNNNNNNNNNKx:.               //
//                 ,KMMMMMMMMMMMMWNNNNNNN0'                 //
//                 ,KMMMMMMMMMMMMMMWWNNNN0'                 //
//                 ;XMMMMMMMMMMMMMMMMWNXN0'                 //
//                 ;KMMMMMMMMMMMMMMMMWNXNO'                 //
//                 'OXWMMMMMMMMMMMMMMWNXOo.                 //
//                  .:KMMMMMMMMMMMMWNNNO,.                  //
//                   '0MMMMMMMMMMMMWNNNk.                   //
//                   '0MMMMMMMMMMMMWNNNk.                   //
//                   '0MMMMMMMMMMMMWNNNk.                   //
//       .,. .,,,,,,,lXMMMMMMMMMMMMWNXXx.                   //
//       ..  ........':::::::::::::::;;'                    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract PD is ERC721Creator {
    constructor() ERC721Creator("The Book of Drank", "PD") {}
}