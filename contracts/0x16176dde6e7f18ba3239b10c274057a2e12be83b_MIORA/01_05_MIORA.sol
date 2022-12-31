// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Meliora
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//    .   , ,--. ,    ,  ,-.  ,-.   ,.      //
//    |\ /| |    |    | /   \ |  ) /  \     //
//    | V | |-   |    | |   | |-<  |--|     //
//    |   | |    |    | \   / |  \ |  |     //
//    '   ' `--' `--' '  `-'  '  ' '  '     //
//                                          //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract MIORA is ERC721Creator {
    constructor() ERC721Creator("Meliora", "MIORA") {}
}