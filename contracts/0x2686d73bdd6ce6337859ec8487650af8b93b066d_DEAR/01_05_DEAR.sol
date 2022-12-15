// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DEAR by CHIARA ALEXA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//       ___  _______   ___       //
//      / _ \/ __/ _ | / _ \      //
//     / // / _// __ |/ , _/      //
//    /____/___/_/ |_/_/|_|       //
//                                //
//                                //
////////////////////////////////////


contract DEAR is ERC721Creator {
    constructor() ERC721Creator("DEAR by CHIARA ALEXA", "DEAR") {}
}