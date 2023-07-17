// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: neural rain
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//          __   _       //
//        _(  )_( )_     //
//       (_ N _  R _)    //
//      / /(_) (__)      //
//     / / / / / /       //
//    / / / / / /        //
//                       //
//                       //
///////////////////////////


contract NR is ERC721Creator {
    constructor() ERC721Creator("neural rain", "NR") {}
}