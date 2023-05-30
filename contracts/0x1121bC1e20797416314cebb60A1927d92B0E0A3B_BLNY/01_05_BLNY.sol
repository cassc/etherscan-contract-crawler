// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Memes by Blouny
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//    ███████████████████████████    //
//    █▄─▄─▀█▄─▄███▄─▀█▄─▄█▄─█─▄█    //
//    ██─▄─▀██─██▀██─█▄▀─███▄─▄██    //
//    ▀▄▄▄▄▀▀▄▄▄▄▄▀▄▄▄▀▀▄▄▀▀▄▄▄▀▀    //
//                                   //
//                                   //
///////////////////////////////////////


contract BLNY is ERC1155Creator {
    constructor() ERC1155Creator("The Memes by Blouny", "BLNY") {}
}