// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ponygirl
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//                        //
//                        //
//    Ponygirl            //
//        **              //
//    ***   **            //
//       *                //
//                        //
//                        //
//           *            //
//                        //
//      *                 //
//     *                  //
//    *   *               //
//       *                //
//         **             //
//                .''     //
//      ._.-.___.' (`\    //
//     //(        ( `'    //
//    '/ )\ ).__. )       //
//    ' <' `\ ._/'\       //
//       `   \     \      //
//                        //
//                        //
//                        //
////////////////////////////


contract pngrl is ERC721Creator {
    constructor() ERC721Creator("Ponygirl", "pngrl") {}
}