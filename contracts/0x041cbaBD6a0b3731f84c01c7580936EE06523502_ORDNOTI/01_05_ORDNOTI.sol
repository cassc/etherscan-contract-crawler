// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OrdinalNotify
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    <<<<:::)))))))    //
//                      //
//                      //
//////////////////////////


contract ORDNOTI is ERC1155Creator {
    constructor() ERC1155Creator("OrdinalNotify", "ORDNOTI") {}
}