// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RELIC
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    RELIC: Heritage                                                                               //
//    Weaving traditional patterns into digital threads                                             //
//                                                                                                  //
//    ‘Relic’ reveals a new visual language of carpet patternry through a collaboration             //
//    between artist and machine. Harnessing the power of AI, Mammadov uses GAN algorithms          //
//    to study the visual similarities of a massive carpet pattern archive collected over           //
//    seven years of intensive research. Then, using a specifically designed coding structure,      //
//    the relationship between the artist and machine produces unique yet familiar patterns.        //
//    Deliberately relinquishing part of his authority over the final product, Mammadov is          //
//    questioning cultural appropriation and the dissolution of deep-rooted cultural traditions     //
//    in a globalized world. Yet he is also reclaiming ownership of them within a contemporary      //
//    context and rewriting their position as relics of the past.                                   //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract RELIC is ERC721Creator {
    constructor() ERC721Creator("RELIC", "RELIC") {}
}