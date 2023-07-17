// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alice_Tretyakova_edts
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//    ____ _    _ ____ ____    ___ ____ ____ ___ _   _ ____ _  _ ____ _  _ ____        //
//    |__| |    | |    |___     |  |__/ |___  |   \_/  |__| |_/  |  | |  | |__|        //
//    |  | |___ | |___ |___     |  |  \ |___  |    |   |  | | \_ |__|  \/  |  |        //
//                                                                                     //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract ATE is ERC1155Creator {
    constructor() ERC1155Creator("Alice_Tretyakova_edts", "ATE") {}
}