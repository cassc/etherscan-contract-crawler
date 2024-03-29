// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tech Turn Up Tech Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//                                                                       //
//      _______        _       _______                 _    _            //
//     |__   __|      | |     |__   __|               | |  | |           //
//        | | ___  ___| |__      | |_   _ _ __ _ __   | |  | |_ __       //
//        | |/ _ \/ __| '_ \     | | | | | '__| '_ \  | |  | | '_ \      //
//        | |  __/ (__| | | |    | | |_| | |  | | | | | |__| | |_) |     //
//      __|_|\___|\___|_| |_|    |_|\__,_|_| _|_| |_|  \____/| .__/      //
//     |__   __|      | |         /\        | |              | |         //
//        | | ___  ___| |__      /  \   _ __| |_             |_|         //
//        | |/ _ \/ __| '_ \    / /\ \ | '__| __|                        //
//        | |  __/ (__| | | |  / ____ \| |  | |_                         //
//        |_|\___|\___|_| |_| /_/    \_\_|   \__|                        //
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract TECHART is ERC721Creator {
    constructor() ERC721Creator("Tech Turn Up Tech Art", "TECHART") {}
}