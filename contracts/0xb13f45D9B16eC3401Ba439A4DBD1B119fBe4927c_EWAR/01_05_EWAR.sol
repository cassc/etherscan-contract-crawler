// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Effects of War by Lina Chu
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//      _     _                ____ _               //
//     | |   (_)_ __   __ _   / ___| |__  _   _     //
//     | |   | | '_ \ / _` | | |   | '_ \| | | |    //
//     | |___| | | | | (_| | | |___| | | | |_| |    //
//     |_____|_|_| |_|\__,_|  \____|_| |_|\__,_|    //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract EWAR is ERC721Creator {
    constructor() ERC721Creator("Effects of War by Lina Chu", "EWAR") {}
}