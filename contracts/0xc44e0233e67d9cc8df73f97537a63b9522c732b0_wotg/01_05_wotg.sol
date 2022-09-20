// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: way of the gaze
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//                      _                                //
//           _.     _ _|_ _|_ |_   _   _   _. _   _      //
//     \/\/ (_| \/ (_) |   |_ | | (/_ (_| (_| /_ (/_     //
//              /                      _|                //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract wotg is ERC721Creator {
    constructor() ERC721Creator("way of the gaze", "wotg") {}
}