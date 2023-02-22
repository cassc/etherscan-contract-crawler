// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Marcel Caram
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//      __  __   __  __   _____     //
//     |  \/  | |  \/  | / ____|    //
//     | \  / | | \  / || |         //
//     | |\/| | | |\/| || |         //
//     | |  | |_| |  | || |____     //
//     |_|  |_(_)_|  |_(_)_____|    //
//                                  //
//                                  //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract MMC is ERC721Creator {
    constructor() ERC721Creator("Marcel Caram", "MMC") {}
}