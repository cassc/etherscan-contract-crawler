// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: a!vibes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//          ._.     ._____.                      //
//    _____ | |__  _|__\_ |__   ____   ______    //
//    \__  \| \  \/ /  || __ \_/ __ \ /  ___/    //
//     / __ \\|\   /|  || \_\ \  ___/ \___ \     //
//    (____  /_ \_/ |__||___  /\___  >____  >    //
//         \/\/             \/     \/     \/     //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract vbs is ERC1155Creator {
    constructor() ERC1155Creator("a!vibes", "vbs") {}
}