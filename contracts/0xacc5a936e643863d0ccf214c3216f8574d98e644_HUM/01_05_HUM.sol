// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hummingbird Christmas
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    :)    //
//          //
//          //
//////////////


contract HUM is ERC721Creator {
    constructor() ERC721Creator("Hummingbird Christmas", "HUM") {}
}