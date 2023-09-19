// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1 of 1, and 1 for All
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    "Nothing is yours.                                    //
//     It is to use.                                        //
//     It is to share.                                      //
//     If you will not share it, you cannot use it."        //
//                                                          //
//     - Ursula K. Le Guin, The Dispossessed                //
//                                                          //
//    As we move from roles of permission--                 //
//    from "owner" to "custodian"--                         //
//    so too do these move[⁶⁵²⁹][ᵒ].                        //
//                                                          //
//    ⁶⁵²⁹ "i have been reliably informed that it moves"    //
//    ᵒ After all: "To move is to live!"                    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract x1x1x is ERC721Creator {
    constructor() ERC721Creator("1 of 1, and 1 for All", "x1x1x") {}
}