// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Raccoons In Custody
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//      _____  _____ _____     //
//     |  __ \|_   _/ ____|    //
//     | |__) | | || |         //
//     |  _  /  | || |         //
//     | | \ \ _| || |____     //
//     |_|  \_\_____\_____|    //
//                             //
//                             //
//                             //
//                             //
/////////////////////////////////


contract RIC is ERC721Creator {
    constructor() ERC721Creator("Raccoons In Custody", "RIC") {}
}