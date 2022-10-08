// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mystics by DEALIOPATRA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    santa lucia    //
//                   //
//                   //
///////////////////////


contract MYST is ERC721Creator {
    constructor() ERC721Creator("Mystics by DEALIOPATRA", "MYST") {}
}