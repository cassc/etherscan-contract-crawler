// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Brushstrokes of Divination
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//    Brushstrokes of Divination                                                      //
//                                                                                    //
//    This collection of paintings delves into the fascinating world                  //
//    of fortune-telling cards, showcasing unique interpretations                     //
//    of the symbols and imagery found on these cards.                                //
//    With a focus on the role they play in providing comfort and                     //
//    guidance during times of uncertainty, the collection conveys                    //
//    the message that many people turn to divination to find clarity and             //
//    inner peace in an unpredictable world. Each painting combines                   //
//    the characters and colors of the cards to offer viewers a chance                //
//    to reflect on their own lives and contemplate the ancient art of divination,    //
//    which can provide insight and a sense of reassurance in today's world.          //
//                                                                                    //
//    -- St. Laurent Jr. --                                                           //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////


contract BoD is ERC721Creator {
    constructor() ERC721Creator("Brushstrokes of Divination", "BoD") {}
}