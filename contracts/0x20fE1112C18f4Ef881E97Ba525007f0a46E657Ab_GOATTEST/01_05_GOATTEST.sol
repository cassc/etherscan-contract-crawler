// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GOATTEST
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    GASDKFAJ    //
//                //
//                //
////////////////////


contract GOATTEST is ERC721Creator {
    constructor() ERC721Creator("GOATTEST", "GOATTEST") {}
}