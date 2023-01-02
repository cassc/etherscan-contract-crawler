// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mozzu arts collection(manifold)
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//                                      //
//                                      //
//     ____   ___ _____ _____ _   _     //
//    |    \ / _ (___  |___  ) | | |    //
//    | | | | |_| / __/ / __/| |_| |    //
//    |_|_|_|\___(_____|_____)\____|    //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract mozzu is ERC721Creator {
    constructor() ERC721Creator("Mozzu arts collection(manifold)", "mozzu") {}
}