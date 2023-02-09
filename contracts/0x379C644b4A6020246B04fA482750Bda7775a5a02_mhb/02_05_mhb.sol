// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mhbxyz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                _     _                         //
//               | |   | |                        //
//      _ __ ___ | |__ | |__  __  ___   _ ____    //
//     | '_ ` _ \| '_ \| '_ \ \ \/ / | | |_  /    //
//     | | | | | | | | | |_) | >  <| |_| |/ /     //
//     |_| |_| |_|_| |_|_.__(_)_/\_\\__, /___|    //
//                                   __/ |        //
//                                  |___/         //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract mhb is ERC721Creator {
    constructor() ERC721Creator("mhbxyz", "mhb") {}
}