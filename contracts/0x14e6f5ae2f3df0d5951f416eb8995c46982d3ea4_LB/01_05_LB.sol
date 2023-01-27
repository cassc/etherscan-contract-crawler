// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lady Bitcoin
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                //
//                                                                                                                                                                //
//    Hi there, I am madcrypto24, I am an artist, I enjoy creating and minting! Lady Bitcoin represent all the ladies out there like myself who loves Bitcoin!    //
//                                                                                                                                                                //
//                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LB is ERC1155Creator {
    constructor() ERC1155Creator("Lady Bitcoin", "LB") {}
}