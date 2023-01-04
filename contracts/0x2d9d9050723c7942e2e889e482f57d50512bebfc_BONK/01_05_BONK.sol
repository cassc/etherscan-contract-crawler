// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BONK on ETH
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    BONK ON ETH     //
//                    //
//                    //
////////////////////////


contract BONK is ERC721Creator {
    constructor() ERC721Creator("BONK on ETH", "BONK") {}
}