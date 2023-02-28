// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: cryptopainter yellow list
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    CP TIGER    //
//                //
//                //
////////////////////


contract CPTIGER is ERC721Creator {
    constructor() ERC721Creator("cryptopainter yellow list", "CPTIGER") {}
}