// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Starseed
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//      ####    ######     ##     #####     ####    ######   ######   ####        //
//     ##  ##     ##      ####    ##  ##   ##  ##   ##       ##       ## ##       //
//     ##         ##     ##  ##   ##  ##   ##       ##       ##       ##  ##      //
//      ####      ##     ######   #####     ####    ####     ####     ##  ##      //
//         ##     ##     ##  ##   ####         ##   ##       ##       ##  ##      //
//     ##  ##     ##     ##  ##   ## ##    ##  ##   ##       ##       ## ##       //
//      ####      ##     ##  ##   ##  ##    ####    ######   ######   ####        //
//                                                                                //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract STAR is ERC1155Creator {
    constructor() ERC1155Creator() {}
}