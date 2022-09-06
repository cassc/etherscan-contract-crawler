// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Digital Peacock
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                    _   _              //
//                 __/o'V'o\__           //
//              __/o \  :  / o\__        //
//             /o `.  \ : /  .' o\       //
//            _\    '. /"\ .'    /_      //
//           /o `-._  '\v/'  _.-` o\     //
//           \_     `-./ \.-`     _/     //
//          /o ``---._/   \_.---'' o\    //
//          \_________\   /_________/    //
//                    '\_/'              //
//                    _|_|_              //
//                                       //
//                                       //
///////////////////////////////////////////


contract Peacock is ERC721Creator {
    constructor() ERC721Creator("The Digital Peacock", "Peacock") {}
}