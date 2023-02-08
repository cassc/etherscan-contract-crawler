// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hearts
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    <3 <3 <3 <3 <3 <3 <3 <3    //
//    <3 <3 <3 <3 <3 <3 <3 <3    //
//    <3 <3 <3 <3 <3 <3 <3 <3    //
//    <3 <3 <3 <3 <3 <3 <3 <3    //
//    <3 <3 <3 <3 <3 <3 <3 <3    //
//    <3 <3 <3 <3 <3 <3 <3 <3    //
//    <3 <3 <3 <3 <3 <3 <3 <3    //
//    <3 <3 <3 <3 <3 <3 <3 <3    //
//    <3 <3 <3 <3 <3 <3 <3 <3    //
//    <3 <3 <3 <3 <3 <3 <3 <3    //
//                               //
//                               //
///////////////////////////////////


contract HEART is ERC1155Creator {
    constructor() ERC1155Creator("Hearts", "HEART") {}
}