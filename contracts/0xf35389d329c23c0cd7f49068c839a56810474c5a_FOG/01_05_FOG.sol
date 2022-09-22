// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ETERNAL
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//      █████▒    ▒█████       ▄████     //
//    ▓██   ▒    ▒██▒  ██▒    ██▒ ▀█▒    //
//    ▒████ ░    ▒██░  ██▒   ▒██░▄▄▄░    //
//    ░▓█▒  ░    ▒██   ██░   ░▓█  ██▓    //
//    ░▒█░       ░ ████▓▒░   ░▒▓███▀▒    //
//     ▒ ░       ░ ▒░▒░▒░     ░▒   ▒     //
//     ░           ░ ▒ ▒░      ░   ░     //
//     ░ ░       ░ ░ ░ ▒     ░ ░   ░     //
//                   ░ ░           ░     //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract FOG is ERC721Creator {
    constructor() ERC721Creator("ETERNAL", "FOG") {}
}