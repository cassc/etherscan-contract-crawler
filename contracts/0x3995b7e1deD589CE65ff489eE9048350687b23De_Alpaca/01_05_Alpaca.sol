// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Colorful Message
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//      ___  _                           //
//     / _ \| |                          //
//    / /_\ \ |_ __   __ _  ___ __ _     //
//    |  _  | | '_ \ / _` |/ __/ _` |    //
//    | | | | | |_) | (_| | (_| (_| |    //
//    \_| |_/_| .__/ \__,_|\___\__,_|    //
//            | |                        //
//            |_|                        //
//                                       //
//                                       //
///////////////////////////////////////////


contract Alpaca is ERC721Creator {
    constructor() ERC721Creator("Colorful Message", "Alpaca") {}
}