// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GHOST CLUB Collabs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//                                        Ghost Club        //
//                                                          //
//                                    ( collaborations )    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract GCC is ERC721Creator {
    constructor() ERC721Creator("GHOST CLUB Collabs", "GCC") {}
}