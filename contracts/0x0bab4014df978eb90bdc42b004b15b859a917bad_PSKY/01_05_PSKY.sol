// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Phanksy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//     ____     _                _                //
//     / _  | __| |_ __   __ ___ | |___ _   _     //
//    | (_| |/ _` | '_ \ / _` \ \| |__ | | | |    //
//     \__  | | | | |_) | | | |>   / __| |_| |    //
//        |_|_| |_|_.__/|_| |_/_/|_\___| .__/     //
//                                      \___|     //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract PSKY is ERC1155Creator {
    constructor() ERC1155Creator("Phanksy", "PSKY") {}
}