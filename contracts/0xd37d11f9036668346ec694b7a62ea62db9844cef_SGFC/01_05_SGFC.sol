// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sustainoplis
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//     ___  __  __  ___   __  __     //
//    / __||  \/  ||   \ |  \/  |    //
//    \__ \| |\/| || |) || |\/| |    //
//    |___/|_|  |_||___/ |_|  |_|    //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract SGFC is ERC721Creator {
    constructor() ERC721Creator("Sustainoplis", "SGFC") {}
}