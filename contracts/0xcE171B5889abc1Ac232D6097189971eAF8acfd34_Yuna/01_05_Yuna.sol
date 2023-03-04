// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Getting through
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    . . .-. .-. .-. .-. . . .-. .-. .-. .-.     //
//     |  |-' | | |-' | | | | |-| |-| |(   |      //
//     `  '   `-' '   `-' `.' ` ' ` ' ' '  '      //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract Yuna is ERC721Creator {
    constructor() ERC721Creator("Getting through", "Yuna") {}
}