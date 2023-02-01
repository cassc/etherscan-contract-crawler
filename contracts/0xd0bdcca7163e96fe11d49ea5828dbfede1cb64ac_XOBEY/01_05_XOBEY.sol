// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: XOBEY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//     _  _  _____  ____  ____  _  _     //
//    ( \/ )(  _  )(  _ \( ___)( \/ )    //
//     )  (  )(_)(  ) _ < )__)  \  /     //
//    (_/\_)(_____)(____/(____) (__)     //
//                                       //
//                                       //
///////////////////////////////////////////


contract XOBEY is ERC721Creator {
    constructor() ERC721Creator("XOBEY", "XOBEY") {}
}