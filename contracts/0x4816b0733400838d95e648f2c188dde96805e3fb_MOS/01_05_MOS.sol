// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moment Of Silence
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//    In the journey of finding peace and beauty, here i am in a moment of silence.    //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract MOS is ERC1155Creator {
    constructor() ERC1155Creator("Moment Of Silence", "MOS") {}
}