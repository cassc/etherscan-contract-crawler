// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Hamily
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//    Hamily. Hamiltons. Ultracured Hamillionaires    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract HAM is ERC1155Creator {
    constructor() ERC1155Creator("The Hamily", "HAM") {}
}