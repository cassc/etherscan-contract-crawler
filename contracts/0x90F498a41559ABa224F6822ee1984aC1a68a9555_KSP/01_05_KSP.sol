// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kaspar Noé
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//    /< /\ _\~ |^ |-| /\ |_| _\~     //
//                                    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract KSP is ERC721Creator {
    constructor() ERC721Creator(unicode"Kaspar Noé", "KSP") {}
}