// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DROP
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

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


contract DP is ERC1155Creator {
    constructor() ERC1155Creator("DROP", "DP") {}
}