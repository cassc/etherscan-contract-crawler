// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: b.sides
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//     _____     _____  ___  _____  _____  _____     //
//    /  _  \   /  ___>/___\|  _  \/   __\/  ___>    //
//    |  _  < _ |___  ||   ||  |  ||   __||___  |    //
//    \_____/<_><_____/\___/|_____/\_____/<_____/    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract bside is ERC721Creator {
    constructor() ERC721Creator("b.sides", "bside") {}
}