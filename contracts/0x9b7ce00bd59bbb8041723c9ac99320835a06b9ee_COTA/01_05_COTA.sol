// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Color and Tales
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    _________  ________ ___________ _____        //
//    \_   ___ \ \_____  \\__    ___//  _  \       //
//    /    \  \/  /   |   \ |    |  /  /_\  \      //
//    \     \____/    |    \|    | /    |    \     //
//     \______  /\_______  /|____| \____|__  /     //
//            \/         \/                \/      //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract COTA is ERC721Creator {
    constructor() ERC721Creator("Color and Tales", "COTA") {}
}