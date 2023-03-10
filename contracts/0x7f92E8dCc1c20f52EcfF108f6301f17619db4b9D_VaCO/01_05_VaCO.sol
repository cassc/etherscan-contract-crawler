// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Various and Casual Occursions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//       |          //
//     .'|'.        //
//    /.'|\ \       //
//    | /|'.|       //
//     \ |\/        //
//      \|/         //
//       `          //
//                  //
//    Various       //
//    and           //
//    Casual        //
//    Occursions    //
//                  //
//                  //
//////////////////////


contract VaCO is ERC721Creator {
    constructor() ERC721Creator("Various and Casual Occursions", "VaCO") {}
}