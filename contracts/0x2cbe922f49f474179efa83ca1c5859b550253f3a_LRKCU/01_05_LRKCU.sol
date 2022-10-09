// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lurker customs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//    Lurker customs are where The Lurkers collection originated.                       //
//    Lurker customs are available by commission (DM me on twitter @Empatheticalch1)    //
//    I will also create a seasonal Lurker custom 4 times a year.                       //
//    The Lurkers are on their own ERC-721 contract, the collection is capped at        //
//    100 total supply and is available on secondary thru OS.                           //
//    https://opensea.io/collection/the-lurkers                                         //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract LRKCU is ERC721Creator {
    constructor() ERC721Creator("Lurker customs", "LRKCU") {}
}