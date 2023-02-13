// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE HIGHEST FORM OF HUMAN EXPRESSION
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    ░█▀▀░█▀█░█▀▀    //
//    ░█▀▀░█░█░█▀▀    //
//    ░▀░░░▀▀▀░▀▀▀    //
//                    //
//                    //
////////////////////////


contract FOE is ERC721Creator {
    constructor() ERC721Creator("THE HIGHEST FORM OF HUMAN EXPRESSION", "FOE") {}
}