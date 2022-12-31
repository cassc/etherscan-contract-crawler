// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Galea
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//     ________     ________     _____________      ______________    //
//        |   |_____||______    |  ____|_____||     |______|_____|    //
//        |   |     ||______    |_____||     ||_____|______|     |    //
//                                                                    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract Galea is ERC1155Creator {
    constructor() ERC1155Creator("The Galea", "Galea") {}
}