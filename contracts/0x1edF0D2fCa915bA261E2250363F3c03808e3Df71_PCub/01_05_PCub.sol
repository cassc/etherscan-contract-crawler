// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pop Cubism
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                            //
//    Cubism was one of the most influential visual art styles of the early twentieth century. It was created by Pablo Picasso (Spanish, 1881–1973) and Georges Braque (French, 1882–1963) in Paris between 1907 and 1914.    //
//                                                                                                                                                                                                                            //
//    Badger makes art! He was Capt, he’s now moved on.                                                                                                                                                                       //
//                                                                                                                                                                                                                            //
//    BOFA was an art movement, it’s evoked into. Pirate hits crew.                                                                                                                                                           //
//                                                                                                                                                                                                                            //
//    Make art have fun, be kind.                                                                                                                                                                                             //
//                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PCub is ERC721Creator {
    constructor() ERC721Creator("Pop Cubism", "PCub") {}
}