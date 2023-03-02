// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EVERYDAY ARTIFACTS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    ______ _____ ___________ _      _____     //
//    | ___ \  ___|  ___| ___ \ |    |  ___|    //
//    | |_/ / |__ | |__ | |_/ / |    | |__      //
//    | ___ \  __||  __||  __/| |    |  __|     //
//    | |_/ / |___| |___| |   | |____| |___     //
//    \____/\____/\____/\_|   \_____/\____/     //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract BEEPLE is ERC721Creator {
    constructor() ERC721Creator("EVERYDAY ARTIFACTS", "BEEPLE") {}
}