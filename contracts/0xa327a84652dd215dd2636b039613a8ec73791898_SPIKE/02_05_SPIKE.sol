// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: spikey monkey foundation
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//              ____              //
//             /---/\             //
//            /---///\            //
//           /---/////\           //
//          /---///////\          //
//         /---/////\///\         //
//        /---/////\\\///\        //
//       /---/////\\\\\///\       //
//      /---/////__\\\\\///\      //
//     /------------\\\\\///\     //
//    /--------------\\\\\///\    //
//    \\\\\\\\\\\\\\\\\\\\\///    //
//     \\\\\\\\\\\\\\\\\\\\\/     //
//                                //
//                                //
////////////////////////////////////


contract SPIKE is ERC721Creator {
    constructor() ERC721Creator("spikey monkey foundation", "SPIKE") {}
}