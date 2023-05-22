// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Community Quilt
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//                                                                       //
//       __                                            __        _       //
//      /  )                              _/_         /  )      //_/_    //
//     /   __ ______  ______  . . ____  o /  __  ,   /  /. . o // /      //
//    (__/(_)/ / / <_/ / / <_(_/_/ / <_<_<__/ (_/_  (_\/(_/_<_</_<__     //
//                                             /       `                 //
//                                            '                          //
//    by Sunrise Art Club                                                //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract CQ is ERC1155Creator {
    constructor() ERC1155Creator("Community Quilt", "CQ") {}
}