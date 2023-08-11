// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DOMVS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    DOMVS    //
//             //
//             //
/////////////////


contract DOMVS is ERC721Creator {
    constructor() ERC721Creator("DOMVS", "DOMVS") {}
}