// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gallery Selects 2023
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//     ######      ###    ##       ##       ######## ########  ##    ##     //
//    ##    ##    ## ##   ##       ##       ##       ##     ##  ##  ##      //
//    ##         ##   ##  ##       ##       ##       ##     ##   ####       //
//    ##   #### ##     ## ##       ##       ######   ########     ##        //
//    ##    ##  ######### ##       ##       ##       ##   ##      ##        //
//    ##    ##  ##     ## ##       ##       ##       ##    ##     ##        //
//     ######   ##     ## ######## ######## ######## ##     ##    ##        //
//                                                                          //
//     ######  ######## ##       ########  ######  ########  ######         //
//    ##    ## ##       ##       ##       ##    ##    ##    ##    ##        //
//    ##       ##       ##       ##       ##          ##    ##              //
//     ######  ######   ##       ######   ##          ##     ######         //
//          ## ##       ##       ##       ##          ##          ##        //
//    ##    ## ##       ##       ##       ##    ##    ##    ##    ##        //
//     ######  ######## ######## ########  ######     ##     ######         //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract GS23 is ERC721Creator {
    constructor() ERC721Creator("Gallery Selects 2023", "GS23") {}
}