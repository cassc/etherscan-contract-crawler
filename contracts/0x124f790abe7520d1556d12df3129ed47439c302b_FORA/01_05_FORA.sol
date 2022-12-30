// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FRAME OF RAW ART
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//      ______ ____  _____                //
//     |  ____/ __ \|  __ \     /\        //
//     | |__ | |  | | |__) |   /  \       //
//     |  __|| |  | |  _  /   / /\ \      //
//     | |   | |__| | | \ \  / ____ \     //
//     |_|    \____/|_|  \_\/_/    \_\    //
//                                        //
//                                        //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract FORA is ERC721Creator {
    constructor() ERC721Creator("FRAME OF RAW ART", "FORA") {}
}