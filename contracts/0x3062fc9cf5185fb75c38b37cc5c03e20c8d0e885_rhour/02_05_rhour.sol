// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rush Hour
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                __                             //
//       _____   / /_   ____   __  __   _____    //
//      / ___/  / __ \ / __ \ / / / /  / ___/    //
//     / /     / / / // /_/ // /_/ /  / /        //
//    /_/     /_/ /_/ \____/ \__,_/  /_/         //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract rhour is ERC1155Creator {
    constructor() ERC1155Creator("Rush Hour", "rhour") {}
}