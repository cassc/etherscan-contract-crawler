// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Reminder by J&K
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                     //
//                                                                                                                     //
//    Some people are always doomed to lose. That is why they called "Some people". Don't be ''some'', be reminder.    //
//                                                                                                                     //
//                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JK is ERC721Creator {
    constructor() ERC721Creator("The Reminder by J&K", "JK") {}
}