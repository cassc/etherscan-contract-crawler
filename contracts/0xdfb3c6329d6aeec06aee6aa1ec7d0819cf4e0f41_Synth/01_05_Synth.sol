// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Synthetic Lives
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    sssssssss sssssssss    ssssssssss sssssssss    //
//    sssssssss                         sssssssss    //
//    ssssss                               ssssss    //
//    sss                                     sss    //
//    ss                                       ss    //
//    s                                         s    //
//                                                   //
//              0                   0                //
//                                                   //
//                                                   //
//                                                   //
//                        0                          //
//                                                   //
//                                                   //
//                  yyyyyyyyyyyyyyy                  //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract Synth is ERC1155Creator {
    constructor() ERC1155Creator("Synthetic Lives", "Synth") {}
}