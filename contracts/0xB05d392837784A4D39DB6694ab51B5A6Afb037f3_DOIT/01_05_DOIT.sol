// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: $DOIT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//       _  _____   ____ _____ _______     //
//      | ||  __ \ / __ \_   _|__   __|    //
//     / __) |  | | |  | || |    | |       //
//     \__ \ |  | | |  | || |    | |       //
//     (   / |__| | |__| || |_   | |       //
//      |_||_____/ \____/_____|  |_|       //
//                                         //
//                                         //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract DOIT is ERC721Creator {
    constructor() ERC721Creator("$DOIT", "DOIT") {}
}