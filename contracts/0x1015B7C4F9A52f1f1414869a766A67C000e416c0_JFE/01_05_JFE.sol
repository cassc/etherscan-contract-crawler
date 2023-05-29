// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jonathan Foerster Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//    ┌─┐┌┬┐┬  ┌─┐┌─┐┌─┐┌┬┐┬ ┬┌─┐┌┬┐┬─┐┌─┐┌─┐┌┬┐                           //
//    ├─┤ │ │  ├┤ ├─┤└─┐ │ │││├┤  ││├┬┘├┤ ├─┤│││                           //
//    ┴ ┴ ┴ ┴─┘└─┘┴ ┴└─┘ ┴ └┴┘└─┘─┴┘┴└─└─┘┴ ┴┴ ┴                           //
//                                                                         //
//    Jonathan Foerster started his digital art journey in 1998,           //
//    creating abstract & surreal pieces of artwork in early versions      //
//    of Photoshop and Bryce3D.                                            //
//                                                                         //
//    Through the years, he has evolved into a digital art media swiss     //
//    army knife creating art using a garbage bag full of tools to         //
//    accomplish his visions. Most recently wholly diving into             //
//    Cinema4d and 3D, continuing to evolve his vast array of visuals      //
//    of dream-like (and nightmare-like) imagery.                          //
//                                                                         //
//    This contract embodies Open and Limited Editions of digital          //
//    artwork with Manifold.                                               //
//                                                                         //
//    + atleastwedream.com                                                 //
//    + twitter.com/atleastwedream                                         //
//    + instagram.com/atleastwedream                                       //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract JFE is ERC1155Creator {
    constructor() ERC1155Creator("Jonathan Foerster Editions", "JFE") {}
}