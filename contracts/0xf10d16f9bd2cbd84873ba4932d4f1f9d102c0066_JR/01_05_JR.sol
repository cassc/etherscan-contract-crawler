// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jackie Rex
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                      _             , __               //
//      /\             | |  o        /|/  \              //
//     |  |  __,   __  | |      _     |___/  _           //
//     |  | /  |  /    |/_) |  |/     | \   |/  /\/      //
//      \_|/\_/|_/\___/| \_/|_/|__/   |  \_/|__/ /\_/    //
//       /|                                              //
//       \|                                              //
//                                                       //
//             By Sarah Zucker / @thesarahshow           //
//                          2022                         //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract JR is ERC721Creator {
    constructor() ERC721Creator("Jackie Rex", "JR") {}
}