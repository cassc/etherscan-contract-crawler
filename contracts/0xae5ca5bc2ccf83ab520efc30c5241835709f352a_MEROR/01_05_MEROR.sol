// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MOTIONERROR
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//     __  __  ____ _____  ____ _____     //
//    |  \/  || ===|| () )/ () \| () )    //
//    |_|\/|_||____||_|\_\\____/|_|\_\    //
//                                        //
//                                        //
////////////////////////////////////////////


contract MEROR is ERC1155Creator {
    constructor() ERC1155Creator("MOTIONERROR", "MEROR") {}
}