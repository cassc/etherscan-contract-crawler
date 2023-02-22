// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ForsArt
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//      ForsArt       //
//    Art === Life    //
//                    //
//                    //
////////////////////////


contract FORS is ERC1155Creator {
    constructor() ERC1155Creator("ForsArt", "FORS") {}
}