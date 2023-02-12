// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: chExcelPunk
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
//     __    _____ _____ _____ _____ _____ _____ _____     //
//    |  |  |     |   __|     |   | |  _  |  |  |_   _|    //
//    |  |__|  |  |  |  |  |  | | | |     |  |  | | |      //
//    |_____|_____|_____|_____|_|___|__|__|_____| |_|      //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract CHXLP is ERC721Creator {
    constructor() ERC721Creator("chExcelPunk", "CHXLP") {}
}