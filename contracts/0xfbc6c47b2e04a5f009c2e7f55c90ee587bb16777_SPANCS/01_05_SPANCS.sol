// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spancs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//      _________                                      //
//     /   _____/__________    ____   ____   ______    //
//     \_____  \\____ \__  \  /    \_/ ___\ /  ___/    //
//     /        \  |_> > __ \|   |  \  \___ \___ \     //
//    /_______  /   __(____  /___|  /\___  >____  >    //
//            \/|__|       \/     \/     \/     \/     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract SPANCS is ERC721Creator {
    constructor() ERC721Creator("Spancs", "SPANCS") {}
}