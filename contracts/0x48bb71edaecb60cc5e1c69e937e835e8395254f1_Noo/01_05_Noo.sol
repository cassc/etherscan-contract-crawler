// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art By Nooan
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//     _  _  _____  _____     //
//    ( \( )(  _  )(  _  )    //
//     )  (  )(_)(  )(_)(     //
//    (_)\_)(_____)(_____)    //
//                            //
//                            //
//                            //
////////////////////////////////


contract Noo is ERC721Creator {
    constructor() ERC721Creator("Art By Nooan", "Noo") {}
}