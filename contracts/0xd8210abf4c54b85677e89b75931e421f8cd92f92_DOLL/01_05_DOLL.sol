// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Marionette
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//      _______  _______  _______  _______          //
//     |       ||   _   ||   _   \|   _   |         //
//     |.|   | ||.  1___||.  l   /|.  |   |         //
//     `-|.  |-'|.  __)_ |.  _   1|.  |   |         //
//       |:  |  |:  1   ||:  |   ||:  1   |         //
//       |::.|  |::.. . ||::.|:. ||::.. . |         //
//       `---'  `-------'`--- ---'`-------'         //
//                Poppy                             //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract DOLL is ERC721Creator {
    constructor() ERC721Creator("Marionette", "DOLL") {}
}