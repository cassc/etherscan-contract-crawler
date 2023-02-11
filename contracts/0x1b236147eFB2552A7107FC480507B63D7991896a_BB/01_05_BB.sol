// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 3D Bumble Bee
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                    .' '.            __       //
//           .        .   .           (__\_     //
//            .         .         . -{{_(|8)    //
//    3DBB      ' .  . ' ' .  . '     (__/      //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract BB is ERC1155Creator {
    constructor() ERC1155Creator("3D Bumble Bee", "BB") {}
}