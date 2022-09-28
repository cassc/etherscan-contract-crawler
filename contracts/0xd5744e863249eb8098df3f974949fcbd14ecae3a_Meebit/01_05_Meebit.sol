// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Meebit
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    idid    //
//            //
//            //
////////////////


contract Meebit is ERC721Creator {
    constructor() ERC721Creator("Meebit", "Meebit") {}
}