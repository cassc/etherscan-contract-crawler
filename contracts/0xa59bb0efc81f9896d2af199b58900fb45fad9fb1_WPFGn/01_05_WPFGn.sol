// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WPF Genesis Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    WPF GENESIS COLLECTION. JOIN US.    //
//                                        //
//                                        //
////////////////////////////////////////////


contract WPFGn is ERC721Creator {
    constructor() ERC721Creator("WPF Genesis Collection", "WPFGn") {}
}