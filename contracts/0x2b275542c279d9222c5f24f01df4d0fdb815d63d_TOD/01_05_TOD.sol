// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tales of Daughters
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    ooooooooooooo   .oooooo.   oooooooooo.       //
//    8'   888   `8  d8P'  `Y8b  `888'   `Y8b      //
//         888      888      888  888      888     //
//         888      888      888  888      888     //
//         888      888      888  888      888     //
//         888      `88b    d88'  888     d88'     //
//        o888o      `Y8bood8P'  o888bood8P'       //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract TOD is ERC721Creator {
    constructor() ERC721Creator("Tales of Daughters", "TOD") {}
}