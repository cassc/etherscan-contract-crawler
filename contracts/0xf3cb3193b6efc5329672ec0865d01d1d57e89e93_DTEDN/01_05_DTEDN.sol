// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: D & T Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//     ______       __     _________    //
//    (  __  \     /__\    \__   __/    //
//    | (  \  )   ( \/ )      ) (       //
//    | |   ) |    \  /       | |       //
//    | |   | |    /  \/\     | |       //
//    | |   ) |   / /\  /     | |       //
//    | (__/  )  (  \/  \     | |       //
//    (______/    \___/\/     )_(       //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract DTEDN is ERC1155Creator {
    constructor() ERC1155Creator("D & T Editions", "DTEDN") {}
}