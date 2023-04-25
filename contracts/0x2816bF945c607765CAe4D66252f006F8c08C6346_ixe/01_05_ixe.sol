// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: indigo x espinosa
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    (_  _)( \/ )( ___)    //
//     _)(_  )  (  )__)     //
//    (____)(_/\_)(____)    //
//                          //
//                          //
//////////////////////////////


contract ixe is ERC721Creator {
    constructor() ERC721Creator("indigo x espinosa", "ixe") {}
}