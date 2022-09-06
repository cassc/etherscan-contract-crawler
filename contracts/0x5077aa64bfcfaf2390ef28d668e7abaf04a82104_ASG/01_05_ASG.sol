// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: All Saints Grimoire
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
//         >X<           ___           |||           (((           '*`              )|(           |||           '*`           ooo           ***          //
//        (o o)         (o o)         (o o)         (o o)         (o o)            (o o)         (o o)         (o o)         (o o)         (o o)         //
//    ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo----ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-    //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ASG is ERC721Creator {
    constructor() ERC721Creator("All Saints Grimoire", "ASG") {}
}