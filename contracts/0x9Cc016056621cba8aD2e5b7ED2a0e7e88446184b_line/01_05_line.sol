// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: line.io
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//    |------line------|    //
//    |------.------|       //
//    |------io------|      //
//                          //
//     𓆑                   //
//    𓆙                    //
//    𓆗                    //
//                          //
//                          //
//////////////////////////////


contract line is ERC1155Creator {
    constructor() ERC1155Creator("line.io", "line") {}
}