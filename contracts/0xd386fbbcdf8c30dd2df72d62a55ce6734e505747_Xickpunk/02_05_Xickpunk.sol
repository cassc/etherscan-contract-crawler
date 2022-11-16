// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Xickpunk
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    XICK!!!!!!!!    //
//                    //
//                    //
////////////////////////


contract Xickpunk is ERC721Creator {
    constructor() ERC721Creator("Xickpunk", "Xickpunk") {}
}