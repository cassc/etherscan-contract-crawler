// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0N1 FORCE CROMAGNUS 1 of 1 canvases
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//       ___  _   _ _   _____ ___  ____   ____ _____     //
//      / _ \| \ | / | |  ___/ _ \|  _ \ / ___| ____|    //
//     | | | |  \| | | | |_ | | | | |_) | |   |  _|      //
//     | |_| | |\  | | |  _|| |_| |  _ <| |___| |___     //
//      \___/|_| \_|_| |_|   \___/|_| \_\\____|_____|    //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract ONICRO is ERC721Creator {
    constructor() ERC721Creator("0N1 FORCE CROMAGNUS 1 of 1 canvases", "ONICRO") {}
}