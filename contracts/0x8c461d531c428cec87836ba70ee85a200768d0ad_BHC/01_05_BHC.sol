// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: bluehawk calendar cards
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


contract BHC is ERC721Creator {
    constructor() ERC721Creator("bluehawk calendar cards", "BHC") {}
}