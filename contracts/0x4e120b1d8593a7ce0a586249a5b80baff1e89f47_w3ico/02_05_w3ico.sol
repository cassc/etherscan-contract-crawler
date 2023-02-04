// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Web3 Icons
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                    __   _____        //
//     _      _____  / /_ |__  /        //
//    | | /| / / _ \/ __ \ /_ <         //
//    | |/ |/ /  __/ /_/ /__/ /         //
//    |__/|__/\___/_.___/____/          //
//       (_)________  ____  _____       //
//      / / ___/ __ \/ __ \/ ___/       //
//     / / /__/ /_/ / / / (__  )        //
//    /_/\___/\____/_/ /_/____/         //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract w3ico is ERC1155Creator {
    constructor() ERC1155Creator("Web3 Icons", "w3ico") {}
}