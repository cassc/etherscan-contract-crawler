// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: lordampersand
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                    ..oooo&&oooo..                    //
//                .oooooo........oooooo.                //
//             .o&o..    ........    ..oooo.            //
//          .o&o.     .o&&&&&&&&&&&      .o&o.          //
//         o&o       o&&&&o.....oo&         o&o         //
//       .&o.       .&&&&                     o&.       //
//      .&o         .&&&o                      o&o      //
//     .&o           &&&&.                      .&.     //
//     &o            .&&&&.                      o&     //
//    .&.            .o&&&&o.                     &o    //
//    o&           .&&&o.&&&&.         ...        o&    //
//    &&          o&&&.   o&&&o.      .&&&.       o&    //
//    o&         o&&&.     .&&&&.     .&&&.       o&    //
//    .&.       .&&&o        o&&&o.   .&&&        &o    //
//     &o       .&&&o         .o&&&o  &&&.       o&     //
//     .&o      .&&&&.          o&&&&&&&.       o&.     //
//      .&o      .&&&&.          .&&&&&.       o&.      //
//       .o&.     .o&&&&oo.....oo&&&&&&&.    .oo.       //
//         .&o.     .o&&&&&&&&&&&oo. o&&&o..o&o         //
//           o&o.      .........      ...oo&o.          //
//             .oooo.                ..o&o.             //
//                ..ooooooo....ooooooo..                //
//                     ..oooooooo..                     //
//                                                      //
//                    lordampersand.eth                 //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract amp is ERC1155Creator {
    constructor() ERC1155Creator("lordampersand", "amp") {}
}