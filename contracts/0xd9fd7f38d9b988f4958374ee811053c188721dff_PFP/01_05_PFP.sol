// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PFP BY GRAFIK
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    _______________________________     //
//    \______   \_   _____/\______   \    //
//     |     ___/|    __)   |     ___/    //
//     |    |    |     \    |    |        //
//     |____|    \___  /    |____|        //
//                   \/                   //
//                                        //
//                                        //
////////////////////////////////////////////


contract PFP is ERC721Creator {
    constructor() ERC721Creator("PFP BY GRAFIK", "PFP") {}
}