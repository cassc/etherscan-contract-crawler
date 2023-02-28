// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Exorcist
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//     _            _              ___       _       //
//    | |          | |            / _ \     | |      //
//    | |     ___  | |    _   _  / /_\ \_ __| |_     //
//    | |    / _ \ | |   | | | | |  _  | '__| __|    //
//    | |___|  __/_| |___| |_| |_| | | | |  | |_     //
//    \_____/\___(_)_____/\__,_(_)_| |_/_|   \__|    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract PNE is ERC721Creator {
    constructor() ERC721Creator("Exorcist", "PNE") {}
}