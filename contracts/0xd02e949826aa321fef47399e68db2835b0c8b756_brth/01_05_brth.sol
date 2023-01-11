// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: brth
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//       __   _             //
//     _(  )_( )_           //
//    (_   _    _)          //
//      (_) (__)  __   _    //
//     _(  )_( )_           //
//    (_   _    _)          //
//      (_) (__)            //
//                          //
//                          //
//////////////////////////////


contract brth is ERC1155Creator {
    constructor() ERC1155Creator("brth", "brth") {}
}