// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jesus Pepe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    MemeGenesis.com    //
//                       //
//                       //
///////////////////////////


contract JP is ERC721Creator {
    constructor() ERC721Creator("Jesus Pepe", "JP") {}
}