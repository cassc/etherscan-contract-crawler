// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My baby shot me down (airdrop)
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    My baby          //
//    shot me down     //
//    (airdrop)        //
//                     //
//                     //
/////////////////////////


contract SHOTME is ERC721Creator {
    constructor() ERC721Creator("My baby shot me down (airdrop)", "SHOTME") {}
}