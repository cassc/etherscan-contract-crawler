// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Documentist
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//         _         //
//     _n_|_|_,_     //
//    |===.-.===|    //
//    |  ((_))  |    //
//    '==='-'==='    //
//                   //
//                   //
///////////////////////


contract DCMNT is ERC721Creator {
    constructor() ERC721Creator("The Documentist", "DCMNT") {}
}