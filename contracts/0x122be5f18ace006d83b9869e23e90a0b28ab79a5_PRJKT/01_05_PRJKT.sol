// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Lost Soul PRJKT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                                                                                               //
//    A representation of loneliness that mankind is submerged into, social networks and cell phones are having a huge impact on the way how people socialize... We are more focused in our digital life instead of living.The lost souls, a light graffity rehearsal, hand painted with a tablet and a scan of a human body.    //
//                                                                                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PRJKT is ERC721Creator {
    constructor() ERC721Creator("The Lost Soul PRJKT", "PRJKT") {}
}