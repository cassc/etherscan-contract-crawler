// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DiDonato x Nifty Gateway
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    [Stuck in a Pattern]    //
//                            //
//                            //
////////////////////////////////


contract BDNG is ERC721Creator {
    constructor() ERC721Creator("DiDonato x Nifty Gateway", "BDNG") {}
}