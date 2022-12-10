// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Peeping
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//                                      //
//       __   __  ______   _________    //
//      / /  /  |/  / _ | / __/ ___/    //
//     / _ \/ /|_/ / __ |_\ \/ /__      //
//    /_.__/_/  /_/_/ |_/___/\___/      //
//                                      //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract Peep is ERC721Creator {
    constructor() ERC721Creator("Peeping", "Peep") {}
}