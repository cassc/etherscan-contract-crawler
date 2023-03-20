// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MONOCHROMES & COLOURS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//      __  __    _____   _          __   __     //
//     |  \/  |  / ____| | |        /_ | /_ |    //
//     | \  / | | |      | |         | |  | |    //
//     | |\/| | | |      | |         | |  | |    //
//     | |  | | | |____  | |____     | |  | |    //
//     |_|  |_|  \_____| |______|    |_|  |_|    //
//                                               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract MCLII is ERC1155Creator {
    constructor() ERC1155Creator("MONOCHROMES & COLOURS", "MCLII") {}
}