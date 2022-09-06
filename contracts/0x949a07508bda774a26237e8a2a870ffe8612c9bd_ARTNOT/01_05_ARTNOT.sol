// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Not Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    ┌П┐(▀̿Ĺ̯▀̿)             //
//                            //
//    Not Art by David Loh    //
//                            //
//                            //
////////////////////////////////


contract ARTNOT is ERC721Creator {
    constructor() ERC721Creator("Not Art", "ARTNOT") {}
}