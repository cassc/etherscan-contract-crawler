// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RecometStamp
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                     ............               //
//                 ..MMMMMMMMMMMMMMM..            //
//              ..MMMMMMMMMMMMMMMMMMMMN.          //
//            .MMMMMMMMMMMMMMMMMMMMMMMMMN.        //
//           .MMMMMMMMMMMMMMMMMMMMMMMMMMMM.       //
//          .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.      //
//         .MMMMMMM" "MMMMMMMMMMMMM.   .MMMM.     //
//         MMMMMMMM. .MMMMMMMMMMM.      .MMMM.    //
//        .MMMMMMMMMMMMMMMMMMMMMM.    ..MMMMM.    //
//        .MMMMMMMMMMMMMMMMMMMMM.  .MMMMMMMMM.    //
//       .MMMMMMMMMMMMMMMMMMMM.  .MMMMMMMMMMM.    //
//      .MMMMMMMMMMMMMMMMMMM.  ..MMMMMMMMMMMM.    //
//     MMMMMMMMMMMMMMMMMM.    .MMMMMMMMMMMMM.     //
//    .MMMMMMMMMMMMM.      .MMMMMMMMMMMMMMM.      //
//      """""""         ..MMMMMMMMMMMMMMMM.       //
//                   ..MMMMMMMMMMMMMMMMM.         //
//                .MMMMMMMMMMMMMMMMMM.            //
//                   MMMMMMMMMMMM.                //
//                    """""""                     //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract RECOMET is ERC1155Creator {
    constructor() ERC1155Creator("RecometStamp", "RECOMET") {}
}