// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IN THE MOOD FOR LOVE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//                 .d8b.  d88888b .d8888. db      db    db db    db              //
//                d8' `8b 88'     88'  YP 88      88    88 88    88              //
//                88ooo88 88ooooo `8bo.   88      88    88 Y8    8P              //
//                88~~~88 88~~~~~   `Y8b. 88      88    88 `8b  d8'              //
//                88   88 88.     db   8D 88booo. 88b  d88  `8bd8'               //
//                YP   YP Y88888P `8888Y' Y88888P ~Y8888P'    YP                 //
//                                                                               //
//    .. -.    - .... .    -- --- --- -..    ..-. --- .-.    .-.. --- ...- .     //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////


contract ITMFL is ERC721Creator {
    constructor() ERC721Creator("IN THE MOOD FOR LOVE", "ITMFL") {}
}