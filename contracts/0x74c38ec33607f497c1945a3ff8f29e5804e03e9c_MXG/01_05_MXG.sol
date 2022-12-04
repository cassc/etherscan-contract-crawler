// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MXG_AUDIO
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░██████░░░██░░██░██████░░    //
//    ░░██░░████░░░████░██░░░░░░    //
//    ░░██░░░░██░████░░░██░░██░░    //
//    ░░██░░░░██░██░░██░░░████░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//      1/1 L3G0 audio devices      //
//                                  //
//                                  //
//////////////////////////////////////


contract MXG is ERC721Creator {
    constructor() ERC721Creator("MXG_AUDIO", "MXG") {}
}