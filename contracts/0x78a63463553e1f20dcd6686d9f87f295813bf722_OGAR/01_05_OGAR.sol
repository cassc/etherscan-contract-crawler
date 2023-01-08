// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ogar
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//      _____   ______ _______  ______    //
//     |     | |  ____ |_____| |_____/    //
//     |_____| |_____| |     | |    \_    //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract OGAR is ERC721Creator {
    constructor() ERC721Creator("Ogar", "OGAR") {}
}