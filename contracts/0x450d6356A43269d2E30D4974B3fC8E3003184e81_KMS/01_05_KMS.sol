// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kiss my Skull
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//    After a life in marketing consulting, as Ezkan, I now create NFTs with great happiness, equal to that which I experience growing olive trees in a beautiful natural environment.         //
//                                                                                                                                                                                             //
//    I put my soul and my humor into my NFTs, I love creating them, I love sharing them, with you, with the world, with the community, my energy is definitely positive.                      //
//                                                                                                                                                                                             //
//    My art is close to life, close to people, between drawing and photography, sometimes animated and often with a note of humor or derision, I see life as beautiful, in all its facets.    //
//                                                                                                                                                                                             //
//    "Kiss my Skull 2023" is part of a series of unique pieces called "Cabinet des curiosités"                                                                                                //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KMS is ERC721Creator {
    constructor() ERC721Creator("Kiss my Skull", "KMS") {}
}