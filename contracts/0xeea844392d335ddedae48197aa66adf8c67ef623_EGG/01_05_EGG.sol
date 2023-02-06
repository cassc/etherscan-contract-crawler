// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CHECK EGG - C43 Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    These eggs are not ordinary eggs!                               //
//    It is not possible to predict what will come out of the egg!    //
//    Just wait for the time.                                         //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract EGG is ERC721Creator {
    constructor() ERC721Creator("CHECK EGG - C43 Edition", "EGG") {}
}