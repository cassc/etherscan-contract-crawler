// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: COTTONTAIL AND COMPANY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//                                         //
//                                         //
//       .-----.     ,-.      .-----.      //
//      '  .--./     | |     '  .--./      //
//      |  |('-. ,---| |---. |  |('-.      //
//     /_) |OO  )'---| |---'/_) |OO  )     //
//     ||  |`-'|     | |    ||  |`-'|      //
//    (_'  '--'\     `-'   (_'  '--'\      //
//       `-----'              `-----'      //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract CNC is ERC721Creator {
    constructor() ERC721Creator("COTTONTAIL AND COMPANY", "CNC") {}
}