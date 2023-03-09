// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kawaii Ghost
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//                            //
//    ,--. ,--. ,----.        //
//    |  .'   /'  .-./        //
//    |  .   ' |  | .---.     //
//    |  |\   \'  '--'  |     //
//    `--' '--' `------'      //
//                            //
//                            //
//                            //
//                            //
////////////////////////////////


contract KG is ERC721Creator {
    constructor() ERC721Creator("Kawaii Ghost", "KG") {}
}