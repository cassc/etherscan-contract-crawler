// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: yagamiii.eth
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    /////////////////////////////////////////    //
//    //                                     //    //
//    //                                     //    //
//    //    This is my ASCII Mark. - Yaga    //    //
//    //                                     //    //
//    //                                     //    //
//    /////////////////////////////////////////    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract Sol2Ed is ERC1155Creator {
    constructor() ERC1155Creator("yagamiii.eth", "Sol2Ed") {}
}