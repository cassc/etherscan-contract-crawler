// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EdgeStretching 721
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//       _______  ________________      ______      //
//      / __/ _ \/ ___/ __/_  __/ | /| / / __ \     //
//     / _// // / (_ / _/  / /  | |/ |/ / /_/ /     //
//    /___/____/\___/___/ /_/   |__/|__/\____/      //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract Edge721 is ERC721Creator {
    constructor() ERC721Creator("EdgeStretching 721", "Edge721") {}
}