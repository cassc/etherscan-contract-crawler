// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SENTIENT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//      .-. .-. .   .-. . .   . . .-. .-. .-. .-. . .       //
//      `-. |-  |   |-|  |    |<  |-| |(  |-| `-. | |       //
//      `-' `-' `-' ` '  `    ' ` ` ' ' ' ` ' `-' `-'       //
//                                                          //
//            .-. .-. . . .-. .-. .-. . . .-.               //
//            `-. |-  |\|  |   |  |-  |\|  |                //
//            `-' `-' ' `  '  `-' `-' ' `  '                //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract SENTIENT is ERC721Creator {
    constructor() ERC721Creator("SENTIENT", "SENTIENT") {}
}