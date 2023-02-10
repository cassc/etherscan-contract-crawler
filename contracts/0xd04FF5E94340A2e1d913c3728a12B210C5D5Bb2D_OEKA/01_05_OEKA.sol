// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OPEN EDITION BY KEVIN ABOSCH
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    ////////    //
//    ////////    //
//    ////OPEN    //
//    /EDITION    //
//                //
//                //
//                //
//                //
////////////////////


contract OEKA is ERC721Creator {
    constructor() ERC721Creator("OPEN EDITION BY KEVIN ABOSCH", "OEKA") {}
}