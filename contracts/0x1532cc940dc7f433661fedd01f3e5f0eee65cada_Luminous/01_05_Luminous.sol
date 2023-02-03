// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Luminous
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//     _                     _                           //
//    | |                   (_)                          //
//    | |    _   _ _ __ ___  _ _ __   ___  _   _ ___     //
//    | |   | | | | '_ ` _ \| | '_ \ / _ \| | | / __|    //
//    | |___| |_| | | | | | | | | | | (_) | |_| \__ \    //
//    \_____/\__,_|_| |_| |_|_|_| |_|\___/ \__,_|___/    //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract Luminous is ERC721Creator {
    constructor() ERC721Creator("Luminous", "Luminous") {}
}