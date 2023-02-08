// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: prooof1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//           .-""""-.        .-""""-.       //
//          /        \      /        \      //
//         /_        _\    /_        _\     //
//        // \      / \\  // \      / \\    //
//        |\__\    /__/|  |\__\    /__/|    //
//         \    ||    /    \    ||    /     //
//          \        /      \        /      //
//           \  __  /        \  __  /       //
//            '.__.'          '.__.'        //
//             |  |            |  |         //
//             |  |            |  |         //
//                                          //
//                                          //
//////////////////////////////////////////////


contract prf1 is ERC721Creator {
    constructor() ERC721Creator("prooof1", "prf1") {}
}