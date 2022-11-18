// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Steppin'
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    STEPPIN.    //
//                //
//                //
////////////////////


contract STPN is ERC721Creator {
    constructor() ERC721Creator("Steppin'", "STPN") {}
}