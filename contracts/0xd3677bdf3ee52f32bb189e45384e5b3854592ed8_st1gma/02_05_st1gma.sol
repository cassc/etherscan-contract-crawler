// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: st1gma - anxiety
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//                                   //
//                 _     _           //
//     ___ ___ _ _|_|___| |_ _ _     //
//    | .'|   |_'_| | -_|  _| | |    //
//    |__,|_|_|_,_|_|___|_| |_  |    //
//                          |___|    //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract st1gma is ERC721Creator {
    constructor() ERC721Creator("st1gma - anxiety", "st1gma") {}
}