// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Minimalist Manipulations
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    -+Minimalist Manipulations+-    //
//                                    //
//                                    //
////////////////////////////////////////


contract MMEmp is ERC721Creator {
    constructor() ERC721Creator("Minimalist Manipulations", "MMEmp") {}
}