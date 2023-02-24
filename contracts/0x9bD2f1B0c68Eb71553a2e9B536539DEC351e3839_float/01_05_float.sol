// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: this may or may not be floatable.
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//            /|___                  //
//                 ///|   ))         //
//               /////|   )))        //
//             ///////|    )))       //
//           /////////|     )))      //
//         ///////////|     ))))     //
//       /////////////|     )))      //
//      //////////////|    )))       //
//    ////////////////|___)))        //
//      ______________|________      //
//      \                    /       //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//                                   //
//                                   //
///////////////////////////////////////


contract float is ERC1155Creator {
    constructor() ERC1155Creator("this may or may not be floatable.", "float") {}
}