// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Signature Collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//     _____       //
//     /     \     //
//    | () () |    //
//     \  ^  /     //
//      |||||      //
//      |||||      //
//                 //
//                 //
/////////////////////


contract BRT11 is ERC721Creator {
    constructor() ERC721Creator("Signature Collection", "BRT11") {}
}