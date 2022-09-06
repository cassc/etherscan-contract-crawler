// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Birds In Flight
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//      // ## \\     //
//     //  ##  \\    //
//         ##        //
//                   //
//                   //
//                   //
///////////////////////


contract BIF is ERC721Creator {
    constructor() ERC721Creator("Birds In Flight", "BIF") {}
}