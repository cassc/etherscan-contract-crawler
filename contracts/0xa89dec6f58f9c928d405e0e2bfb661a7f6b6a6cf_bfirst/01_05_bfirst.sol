// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: bhare meets 1stdibs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    dibs on shotgun!    //
//                        //
//                        //
////////////////////////////


contract bfirst is ERC721Creator {
    constructor() ERC721Creator("bhare meets 1stdibs", "bfirst") {}
}