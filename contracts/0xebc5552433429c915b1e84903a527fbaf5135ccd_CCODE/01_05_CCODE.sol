// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chroma_Code
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                  \  /                   //
//                   \/                    //
//         .===============.               //
//         | .-----------. |               //
//         | |           | |               //
//         | |           | |               //
//         | |           | |   __          //
//         | '-----------'o|  |o.|         //
//         |===============|  |::|         //
//         |  CHROMA CODE  |  |::|         //
//         '==============='  '--'         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract CCODE is ERC721Creator {
    constructor() ERC721Creator("Chroma_Code", "CCODE") {}
}