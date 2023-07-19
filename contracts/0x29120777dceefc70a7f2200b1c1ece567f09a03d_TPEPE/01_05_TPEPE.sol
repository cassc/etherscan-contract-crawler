// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THREADPEPE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    TPEPE    //
//             //
//             //
/////////////////


contract TPEPE is ERC721Creator {
    constructor() ERC721Creator("THREADPEPE", "TPEPE") {}
}