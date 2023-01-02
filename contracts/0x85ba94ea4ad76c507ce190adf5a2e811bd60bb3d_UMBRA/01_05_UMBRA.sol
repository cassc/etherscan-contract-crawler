// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Witchcraft of Umbra by Dy Mokomi
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Witchcraft of Umbra     //
//    by Dy Mokomi            //
//                            //
//                            //
////////////////////////////////


contract UMBRA is ERC721Creator {
    constructor() ERC721Creator("Witchcraft of Umbra by Dy Mokomi", "UMBRA") {}
}