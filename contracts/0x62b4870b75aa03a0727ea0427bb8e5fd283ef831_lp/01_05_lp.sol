// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Let's Play
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    {{{{{Let's Play}}}}}    //
//                            //
//                            //
////////////////////////////////


contract lp is ERC721Creator {
    constructor() ERC721Creator("Let's Play", "lp") {}
}