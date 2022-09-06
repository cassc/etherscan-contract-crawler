// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: oracle
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//                         //
//                         //
//                /)       //
//     ____ _  _ //  _     //
//    (_/ ((_((_(/__(/_    //
//                         //
//                         //
//                         //
//                         //
//                         //
/////////////////////////////


contract orcl is ERC721Creator {
    constructor() ERC721Creator("oracle", "orcl") {}
}