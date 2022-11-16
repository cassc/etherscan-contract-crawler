// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dave Frog Origin Story
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//      ___                 ___                  //
//     |   \ __ ___ _____  | __| _ ___  __ _     //
//     | |) / _` \ V / -_) | _| '_/ _ \/ _` |    //
//     |___/\__,_|\_/\___| |_||_| \___/\__, |    //
//                                     |___/     //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract DFOS is ERC721Creator {
    constructor() ERC721Creator("Dave Frog Origin Story", "DFOS") {}
}