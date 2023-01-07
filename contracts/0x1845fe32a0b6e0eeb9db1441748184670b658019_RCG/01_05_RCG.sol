// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reverse Cowgirl
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//     :::====  :::===== :::=====     //
//     :::  === :::      :::          //
//     =======  ===      === =====    //
//     === ===  ===      ===   ===    //
//     ===  ===  =======  =======     //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract RCG is ERC721Creator {
    constructor() ERC721Creator("Reverse Cowgirl", "RCG") {}
}