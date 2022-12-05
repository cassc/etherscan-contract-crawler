// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Seamorphus Extra
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Seamorphus Extra    //
//                        //
//                        //
////////////////////////////


contract SME is ERC721Creator {
    constructor() ERC721Creator("Seamorphus Extra", "SME") {}
}