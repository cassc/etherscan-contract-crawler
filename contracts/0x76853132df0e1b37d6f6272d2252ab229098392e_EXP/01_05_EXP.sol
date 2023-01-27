// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Exposures
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//      _____  _____  ___  ___ _   _ ___ ___ ___     //
//     | __\ \/ / _ \/ _ \/ __| | | | _ \ __/ __|    //
//     | _| >  <|  _/ (_) \__ \ |_| |   / _|\__ \    //
//     |___/_/\_\_|  \___/|___/\___/|_|_\___|___/    //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract EXP is ERC721Creator {
    constructor() ERC721Creator("Exposures", "EXP") {}
}