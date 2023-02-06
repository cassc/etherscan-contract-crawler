// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CHECKS EGG - C43 Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    These eggs are not ordinary eggs!                               //
//    It is not possible to predict what will come out of the egg!    //
//    Maybe it's real! Maybe it's not!                                //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract EGG is ERC1155Creator {
    constructor() ERC1155Creator("CHECKS EGG - C43 Editions", "EGG") {}
}