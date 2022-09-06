// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Recursa by Perrine
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//    __________                                               //
//    \______   \ ____   ____  __ _________  ___________       //
//     |       _// __ \_/ ___\|  |  \_  __ \/  ___/\__  \      //
//     |    |   \  ___/\  \___|  |  /|  | \/\___ \  / __ \_    //
//     |____|_  /\___  >\___  >____/ |__|  /____  >(____  /    //
//            \/     \/     \/                  \/      \/     //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract Recursa is ERC721Creator {
    constructor() ERC721Creator("Recursa by Perrine", "Recursa") {}
}