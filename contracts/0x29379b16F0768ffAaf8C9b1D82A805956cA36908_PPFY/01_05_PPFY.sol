// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepefy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    ______ ___________ _____________   __    //
//    | ___ \  ___| ___ \  ___|  ___\ \ / /    //
//    | |_/ / |__ | |_/ / |__ | |_   \ V /     //
//    |  __/|  __||  __/|  __||  _|   \ /      //
//    | |   | |___| |   | |___| |     | |      //
//    \_|   \____/\_|   \____/\_|     \_/      //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract PPFY is ERC721Creator {
    constructor() ERC721Creator("Pepefy", "PPFY") {}
}