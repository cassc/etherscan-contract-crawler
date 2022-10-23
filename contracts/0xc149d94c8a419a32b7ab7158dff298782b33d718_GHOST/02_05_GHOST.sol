// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ghost in the Machine
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//              __               __     //
//       ____ _/ /_  ____  _____/ /_    //
//      / __ `/ __ \/ __ \/ ___/ __/    //
//     / /_/ / / / / /_/ (__  ) /_      //
//     \__, /_/ /_/\____/____/\__/      //
//    /____/                            //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract GHOST is ERC721Creator {
    constructor() ERC721Creator("Ghost in the Machine", "GHOST") {}
}