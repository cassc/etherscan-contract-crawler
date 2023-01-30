// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Freedom to Exploit
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//     /\      /\     //
//    /  \    /  \    //
//    \  /    \  /    //
//     \/      \/     //
//     O   T    U     //
//                    //
//                    //
////////////////////////


contract OTU is ERC1155Creator {
    constructor() ERC1155Creator("Freedom to Exploit", "OTU") {}
}