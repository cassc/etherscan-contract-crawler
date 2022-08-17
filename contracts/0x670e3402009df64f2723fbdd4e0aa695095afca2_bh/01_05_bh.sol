// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: bluehawk
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//                 /         //
//    \\\' ,      / //       //
//     \\\//    _/ //'       //
//      \_-//' /  //<'       //
//        \ ///  >   \\\`    //
//       /,)-^>>  _\`        //
//       (/   \\ / \\\       //
//             //  //\\\     //
//            ((`            //
//                           //
//                           //
///////////////////////////////


contract bh is ERC721Creator {
    constructor() ERC721Creator("bluehawk", "bh") {}
}