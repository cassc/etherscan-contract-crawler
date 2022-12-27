// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Babylon Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//     _           _           _                 //
//    | |         | |         | |                //
//    | |__   __ _| |__  _   _| | ___  _ __      //
//    | '_ \ / _` | '_ \| | | | |/ _ \| '_ \     //
//    | |_) | (_| | |_) | |_| | | (_) | | | |    //
//    |_.__/ \__,_|_.__/ \__, |_|\___/|_| |_|    //
//                        __/ |                  //
//                       |___/                   //
//                                               //
//                                               //
///////////////////////////////////////////////////

contract BabylonEditions is ERC721Creator {
    constructor(string memory name) ERC721Creator(name, "BAB") {}
}