// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The struggle is real
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    Complainooooorrr    //
//                        //
//                        //
////////////////////////////


contract NVM is ERC1155Creator {
    constructor() ERC1155Creator("The struggle is real", "NVM") {}
}