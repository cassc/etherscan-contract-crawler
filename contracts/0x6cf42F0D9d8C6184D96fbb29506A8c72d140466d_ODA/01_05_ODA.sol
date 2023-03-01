// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: One of Ones by DaevidAdeola
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//        __                       __     __     //
//    .--|  |.---.-..-----..--.--.|__|.--|  |    //
//    |  _  ||  _  ||  -__||  |  ||  ||  _  |    //
//    |_____||___._||_____| \___/ |__||_____|    //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract ODA is ERC721Creator {
    constructor() ERC721Creator("One of Ones by DaevidAdeola", "ODA") {}
}