// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AIdentity Chess
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                           //
//                                                                                                                           //
//       ###    #### ########  ######## ##    ## ######## #### ######## ##    ##                                             //
//      ## ##    ##  ##     ## ##       ###   ##    ##     ##     ##     ##  ##                                              //
//     ##   ##   ##  ##     ## ##       ####  ##    ##     ##     ##      ####                                               //
//    ##     ##  ##  ##     ## ######   ## ## ##    ##     ##     ##       ##                                                //
//    #########  ##  ##     ## ##       ##  ####    ##     ##     ##       ##                                                //
//    ##     ##  ##  ##     ## ##       ##   ###    ##     ##     ##       ##                                                //
//    ##     ## #### ########  ######## ##    ##    ##    ####    ##       ##                                                //
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
//     ######  ##     ## ########  ######   ######                                                                           //
//    ##    ## ##     ## ##       ##    ## ##    ##                                                                          //
//    ##       ##     ## ##       ##       ##                                                                                //
//    ##       ######### ######    ######   ######                                                                           //
//    ##       ##     ## ##             ##       ##                                                                          //
//    ##    ## ##     ## ##       ##    ## ##    ##                                                                          //
//     ######  ##     ## ########  ######   ######                                                                           //
//                                                                                                                           //
//                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AICHESS is ERC721Creator {
    constructor() ERC721Creator("AIdentity Chess", "AICHESS") {}
}