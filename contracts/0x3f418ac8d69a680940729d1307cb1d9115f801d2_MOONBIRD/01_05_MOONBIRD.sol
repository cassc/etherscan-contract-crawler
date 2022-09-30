// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hooters
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                         _________                //
//                        /_  ___   \               //
//                       /@ \/@  \   \              //
//                       \__/\___/   /              //
//                        \_\/______/               //
//                        /     /\\\\\              //
//                       |     |\\\\\\              //
//                        \      \\\\\\             //
//                         \______/\\\\             //
//                   _______ ||_||_______           //
//                  (______(((_(((______(@)         //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract MOONBIRD is ERC721Creator {
    constructor() ERC721Creator("Hooters", "MOONBIRD") {}
}