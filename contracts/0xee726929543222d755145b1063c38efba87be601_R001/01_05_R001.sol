// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mad Raffle
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    Lo    //
//          //
//          //
//////////////


contract R001 is ERC721Creator {
    constructor() ERC721Creator("Mad Raffle", "R001") {}
}