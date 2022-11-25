// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Glorious Three
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//                                                                       //
//    /=\ |         /=\ |                         /=\ |                  //
//     |  |=\ /=\   | _ |  /=\ /= = /=\ | | /==    |  |=\ /= /=\ /=\     //
//     |  | | \=    \=/ \= \=/ |  | \=/ \=/ ==/    |  | | |  \=  \=      //
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract TG3 is ERC721Creator {
    constructor() ERC721Creator("The Glorious Three", "TG3") {}
}