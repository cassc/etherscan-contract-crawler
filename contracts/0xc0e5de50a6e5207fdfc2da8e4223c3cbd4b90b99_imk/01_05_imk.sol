// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: imkate editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//      _           _         _             _   _                          //
//     (_)_ __ ___ | | ____ _| |_ ___   ___| |_| |__                       //
//     | | '_ ` _ \| |/ / _` | __/ _ \ / _ \ __| '_ \                      //
//     | | | | | | |   < (_| | ||  __/|  __/ |_| | | |                     //
//     |_|_| |_| |_|_|\_\__,_|\__\___(_)___|\__|_| |_|                     //
//                                                                         //
//                                                                         //
//    When buying a token on this contract,                                //
//    I give full permission to copy and use this art for any purpose,     //
//    but on condition that I am mentioned as the author.                  //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract imk is ERC721Creator {
    constructor() ERC721Creator("imkate editions", "imk") {}
}