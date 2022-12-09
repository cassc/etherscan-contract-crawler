// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TOADZ STUFF
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                //
//                                                                                                                                                //
//    Cartoonist, Free figuration, outsider art.                                                                                                  //
//    I grew up drawing cartoons, I sold my arts on the streets, and I've always doodled on my notes, art is my escape and it always has been.    //
//                                                                                                                                                //
//                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TOADZ is ERC1155Creator {
    constructor() ERC1155Creator("TOADZ STUFF", "TOADZ") {}
}