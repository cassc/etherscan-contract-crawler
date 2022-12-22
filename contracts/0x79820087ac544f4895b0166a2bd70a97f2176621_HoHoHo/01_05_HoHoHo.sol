// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Holiday Edition 2022
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//      _    _       _    _       _    _           //
//     | |  | |     | |  | |     | |  | |          //
//     | |__| | ___ | |__| | ___ | |__| | ___      //
//     |  __  |/ _ \|  __  |/ _ \|  __  |/ _ \     //
//     | |  | | (_) | |  | | (_) | |  | | (_) |    //
//     |_|  |_|\___/|_|  |_|\___/|_|  |_|\___/     //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract HoHoHo is ERC1155Creator {
    constructor() ERC1155Creator("Holiday Edition 2022", "HoHoHo") {}
}