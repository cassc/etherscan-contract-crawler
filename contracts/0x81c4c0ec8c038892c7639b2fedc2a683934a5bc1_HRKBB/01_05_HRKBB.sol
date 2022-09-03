// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hirakubo Beach
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//      ___ _____________ ____  __.____________________     //
//     /   |   \______   \    |/ _|\______   \______   \    //
//    /    ~    \       _/      <   |    |  _/|    |  _/    //
//    \    Y    /    |   \    |  \  |    |   \|    |   \    //
//     \___|_  /|____|_  /____|__ \ |______  /|______  /    //
//           \/        \/        \/        \/        \/     //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract HRKBB is ERC721Creator {
    constructor() ERC721Creator("Hirakubo Beach", "HRKBB") {}
}