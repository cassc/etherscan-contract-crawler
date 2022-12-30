// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RVig
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//      _______      ___            //
//     |  __ \ \    / (_)           //
//     | |__) \ \  / / _  __ _      //
//     |  _  / \ \/ / | |/ _` |     //
//     | | \ \  \  /  | | (_| |     //
//     |_|  \_\  \/   |_|\__, |     //
//     _____________________/ |     //
//    |_______________________/     //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract RVIG is ERC721Creator {
    constructor() ERC721Creator("RVig", "RVIG") {}
}