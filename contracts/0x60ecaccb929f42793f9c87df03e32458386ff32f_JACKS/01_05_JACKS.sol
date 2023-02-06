// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jacks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//           _               _____   _  __   _____     //
//          | |     /\      / ____| | |/ /  / ____|    //
//          | |    /  \    | |      | ' /  | (___      //
//      _   | |   / /\ \   | |      |  <    \___ \     //
//     | |__| |  / ____ \  | |____  | . \   ____) |    //
//      \____/  /_/    \_\  \_____| |_|\_\ |_____/     //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract JACKS is ERC721Creator {
    constructor() ERC721Creator("Jacks", "JACKS") {}
}