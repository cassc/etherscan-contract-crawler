// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mechabaco
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//         ██              ██ _█████████░        //
//         ▒█              ██████     ▓████      //
//         ▒█              ███           ███     //
//         ▒█              ██             ▒█L    //
//         ▒█              ██             ██▌    //
//         ███            ███             ██▌    //
//          ███_        _████             ██▌    //
//           █████████████ª██             ██▌    //
//              ▀█████░    ▒▌             ▀▒     //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract MB is ERC721Creator {
    constructor() ERC721Creator("mechabaco", "MB") {}
}