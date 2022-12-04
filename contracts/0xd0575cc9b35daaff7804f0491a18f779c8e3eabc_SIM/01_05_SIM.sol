// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SIMULACRA
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//       _____ ______  ___    //
//      / ___//  _/  |/  /    //
//      \__ \ / // /|_/ /     //
//     ___/ // // /  / /      //
//    /____/___/_/  /_/       //
//                            //
//                            //
////////////////////////////////


contract SIM is ERC1155Creator {
    constructor() ERC1155Creator("SIMULACRA", "SIM") {}
}