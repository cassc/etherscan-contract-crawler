// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KON PASS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    ,--. ,--.  ,-----.  ,--.  ,--.     //
//    |  .'   / '  .-.  ' |  ,'.|  |     //
//    |  .   '  |  | |  | |  |' '  |     //
//    |  |\   \ '  '-'  ' |  | `   |     //
//    `--' '--'  `-----'  `--'  `--'     //
//                                       //
//                                       //
///////////////////////////////////////////


contract KONPASS is ERC1155Creator {
    constructor() ERC1155Creator("KON PASS", "KONPASS") {}
}