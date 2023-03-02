// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 50 Animated Skulls
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//                      //
//       __---__        //
//      (      )        //
//      (o)  (o)        //
//       ( () )         //
//       [[[[[[         //
//    o_        _o      //
//       -XXXX-         //
//    o-        -o      //
//                      //
//                      //
//////////////////////////


contract MPJ is ERC721Creator {
    constructor() ERC721Creator("50 Animated Skulls", "MPJ") {}
}