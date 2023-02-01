// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: logbook by Tschuuuly
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//      Tschuuuly writing logbooks since august 2000     //
//         tokenizing moments starting early 2020        //
//               time is fire  -  mint on                //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract logbk is ERC721Creator {
    constructor() ERC721Creator("logbook by Tschuuuly", "logbk") {}
}