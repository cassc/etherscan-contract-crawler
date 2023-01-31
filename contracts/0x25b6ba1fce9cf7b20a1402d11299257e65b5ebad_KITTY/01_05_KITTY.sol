// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WOUT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//      /\_/\  (     //
//     ( ^.^ ) _)    //
//       \"/  (      //
//     ( | | )       //
//    (__d b__)      //
//                   //
//                   //
///////////////////////


contract KITTY is ERC1155Creator {
    constructor() ERC1155Creator("WOUT", "KITTY") {}
}