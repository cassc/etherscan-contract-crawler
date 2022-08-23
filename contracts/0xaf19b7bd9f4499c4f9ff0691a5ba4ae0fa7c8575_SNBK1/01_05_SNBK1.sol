// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sun Back
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//     ____  _  _  __ _    ____   __    ___  __ _     //
//    / ___)/ )( \(  ( \  (  _ \ / _\  / __)(  / )    //
//    \___ \) \/ (/    /   ) _ (/    \( (__  )  (     //
//    (____/\____/\_)__)  (____/\_/\_/ \___)(__\_)    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract SNBK1 is ERC721Creator {
    constructor() ERC721Creator("Sun Back", "SNBK1") {}
}