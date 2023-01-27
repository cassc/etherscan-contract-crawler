// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Skinny Bitches Open Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    Skinny Bitches Open edition     //
//                                    //
//                                    //
////////////////////////////////////////


contract SBOE is ERC721Creator {
    constructor() ERC721Creator("Skinny Bitches Open Edition", "SBOE") {}
}