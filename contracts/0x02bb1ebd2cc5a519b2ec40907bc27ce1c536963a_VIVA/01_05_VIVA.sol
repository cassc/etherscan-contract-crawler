// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VIVA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    Y88b      / 888 Y88b      /      e          //
//     Y88b    /  888  Y88b    /      d8b         //
//      Y88b  /   888   Y88b  /      /Y88b        //
//       Y888/    888    Y888/      /  Y88b       //
//        Y8/     888     Y8/      /____Y88b      //
//         Y      888      Y      /      Y88b     //
//                                                //
//                                                //
//                  SensualBody                   //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract VIVA is ERC721Creator {
    constructor() ERC721Creator("VIVA", "VIVA") {}
}