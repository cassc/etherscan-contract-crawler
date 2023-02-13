// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NTDYC
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    ╔╗╔┌┬┐┌┬┐┬ ┬┌─┐    //
//    ║║║ │  ││└┬┘│      //
//    ╝╚╝ ┴ ─┴┘ ┴ └─┘    //
//                       //
//                       //
///////////////////////////


contract ntdyc is ERC1155Creator {
    constructor() ERC1155Creator("NTDYC", "ntdyc") {}
}