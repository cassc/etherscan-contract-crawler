// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GRINCHMAS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Baaaaaaaaahumbug    //
//                        //
//                        //
////////////////////////////


contract GRCH is ERC721Creator {
    constructor() ERC721Creator("GRINCHMAS", "GRCH") {}
}