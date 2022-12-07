// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wÿn editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//      (`\ .-') /`                  .-') _      //
//       `.( OO ),'                 ( OO ) )     //
//    ,--./  .--.    ,--.   ,--.,--./ ,--,'      //
//    |      |  |     \  `.'  / |   \ |  |\      //
//    |  |   |  |,  .-')     /  |    \|  | )     //
//    |  |.'.|  |_)(OO  \   /   |  .     |/      //
//    |         |   |   /  /\_  |  |\    |       //
//    |   ,'.   |   `-./  /.__) |  | \   |       //
//    '--'   '--'     `--'      `--'  `--'       //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract WYNEDS is ERC1155Creator {
    constructor() ERC1155Creator(unicode"Wÿn editions", "WYNEDS") {}
}