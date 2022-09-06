// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BEHOLDINGEYE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                             //
//                                                                                                                             //
//                                                                                                                             //
//     888888ba   88888888b dP     dP   .88888.  dP        888888ba  dP 888888ba   .88888.   88888888b dP    dP  88888888b     //
//     88    `8b  88        88     88  d8'   `8b 88        88    `8b 88 88    `8b d8'   `88  88        Y8.  .8P  88            //
//    a88aaaa8P' a88aaaa    88aaaaa88a 88     88 88        88     88 88 88     88 88        a88aaaa     Y8aa8P  a88aaaa        //
//     88   `8b.  88        88     88  88     88 88        88     88 88 88     88 88   YP88  88           88     88            //
//     88    .88  88        88     88  Y8.   .8P 88        88    .8P 88 88     88 Y8.   .88  88           88     88            //
//     88888888P  88888888P dP     dP   `8888P'  88888888P 8888888P  dP dP     dP  `88888'   88888888P    dP     88888888P     //
//    ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//                                                                                                                             //
//                                                                                                                             //
//                                                                                                                             //
//                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BHOLD is ERC721Creator {
    constructor() ERC721Creator("BEHOLDINGEYE", "BHOLD") {}
}