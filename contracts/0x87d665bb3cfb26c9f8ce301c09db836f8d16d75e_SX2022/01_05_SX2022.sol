// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sylphy's X'mas 2022
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    Sylphy    //
//              //
//              //
//////////////////


contract SX2022 is ERC721Creator {
    constructor() ERC721Creator("Sylphy's X'mas 2022", "SX2022") {}
}