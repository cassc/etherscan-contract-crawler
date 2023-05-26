// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Typical Friends Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    Typical Friends Edition        //
//                                   //
//    twitter.com/_typicalfriends    //
//    typicalfriends.com             //
//                                   //
//                                   //
///////////////////////////////////////


contract TFE is ERC1155Creator {
    constructor() ERC1155Creator("Typical Friends Edition", "TFE") {}
}