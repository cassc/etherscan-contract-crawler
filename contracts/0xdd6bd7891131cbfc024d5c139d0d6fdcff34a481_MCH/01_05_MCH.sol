// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MY COLOURED HUSTLE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//      __  __   _____  _    _     //
//     |  \/  | / ____|| |  | |    //
//     | \  / || |     | |__| |    //
//     | |\/| || |     |  __  |    //
//     | |  | || |____ | |  | |    //
//     |_|  |_| \_____||_|  |_|    //
//                                 //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract MCH is ERC721Creator {
    constructor() ERC721Creator("MY COLOURED HUSTLE", "MCH") {}
}