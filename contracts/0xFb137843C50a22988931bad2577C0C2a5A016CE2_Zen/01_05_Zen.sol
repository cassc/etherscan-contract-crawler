// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zen Exhibition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//          d888888b          //
//       d888    8888b        //
//     d88    88  898888b     //
//    d8P        88888888b    //
//    88        8888888888    //
//    88       88888888888    //
//    98b     88888888888P    //
//     988     888  8888P     //
//       9888   888888P       //
//          9888888P          //
//             88             //
//             88             //
//            d88b            //
//                            //
//                            //
////////////////////////////////


contract Zen is ERC721Creator {
    constructor() ERC721Creator("Zen Exhibition", "Zen") {}
}