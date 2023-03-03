// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PeaceTest
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//                                                                        //
//     l¯¯l)¯¯)   l¯¯(\__\  /¯¯/l¯¯l‘  /¯¯/\__\   l¯¯(\__\  l¯¯¯¯¯l       //
//     l__l¯¯     l__(/¯¯/  \__\l__'\  \__\/¯¯/   l__(/¯¯/   ¯l__l¯‘      //
//                                                                        //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract PeaceT is ERC721Creator {
    constructor() ERC721Creator("PeaceTest", "PeaceT") {}
}