// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: love
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


contract LV is ERC1155Creator {
    constructor() ERC1155Creator("love", "LV") {}
}