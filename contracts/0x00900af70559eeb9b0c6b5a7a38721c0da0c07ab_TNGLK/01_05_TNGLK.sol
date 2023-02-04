// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Key
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//     ad8888888888ba                                        //
//     dP'         `"8b,                                     //
//     8  ,aaa,       "Y888a     ,aaaa,     ,aaa,  ,aa,      //
//     8  8' `8           "88baadP""""YbaaadP"""YbdP""Yb     //
//     8  8   8              """        """      ""    8b    //
//     8  8, ,8         ,aaaaaaaaaaaaaaaaaaaaaaaaddddd88P    //
//     8  `"""'       ,d8""                                  //
//     Yb,         ,ad8"                                     //
//      "Y8888888888P"                                       //
//                                                           //
//    “A very little key will open a very heavy door.”       //
//    ― Charles Dickens, Hunted Down                         //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract TNGLK is ERC1155Creator {
    constructor() ERC1155Creator("The Key", "TNGLK") {}
}