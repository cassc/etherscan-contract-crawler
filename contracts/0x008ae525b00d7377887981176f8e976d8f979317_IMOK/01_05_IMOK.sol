// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IM OK
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//           ______  _____    ____  ______  __    //
//          / / __ \/ ___/   / __ )/ __ \ \/ /    //
//     __  / / / / /\__ \   / __  / / / /\  /     //
//    / /_/ / /_/ /___/ /  / /_/ / /_/ / / /      //
//    \____/\____//____/  /_____/\____/ /_/       //
//                                                //
//    https://foundation.app/@J.O                 //
//    https://www.behance.net/Jeanni              //
//    https://www.instagram.com/janmax.eth        //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract IMOK is ERC721Creator {
    constructor() ERC721Creator("IM OK", "IMOK") {}
}