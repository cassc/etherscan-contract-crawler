// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: It's About Time
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//    .-.   .-..----. .----..-.  .-.    //
//    | |   | || {}  }| {}  }\ \/ /     //
//    | `--.| || {}  }| {}  } }  {      //
//    `----'`-'`----' `----'  `--'      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract IAT is ERC721Creator {
    constructor() ERC721Creator("It's About Time", "IAT") {}
}