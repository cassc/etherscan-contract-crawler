// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ABSTRCT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    ----ABSTRCT----    //
//      --HA14ASA--      //
//                       //
//                       //
///////////////////////////


contract ABT is ERC721Creator {
    constructor() ERC721Creator("ABSTRCT", "ABT") {}
}