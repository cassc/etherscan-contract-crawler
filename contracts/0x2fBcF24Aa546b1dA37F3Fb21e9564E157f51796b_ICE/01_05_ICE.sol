// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Frozen Heart
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//      _____ _____ ______     //
//     |_   _/ ____|  ____|    //
//       | || |    | |__       //
//       | || |    |  __|      //
//      _| || |____| |____     //
//     |_____\_____|______|    //
//                             //
//                             //
//                             //
//                             //
/////////////////////////////////


contract ICE is ERC721Creator {
    constructor() ERC721Creator("Frozen Heart", "ICE") {}
}