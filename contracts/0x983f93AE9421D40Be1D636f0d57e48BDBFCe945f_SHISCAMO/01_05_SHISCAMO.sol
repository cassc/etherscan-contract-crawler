// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SHIScamo
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//     ____  _   _ ___ ____                                //
//    / ___|| | | |_ _/ ___|  ___ __ _ _ __ ___   ___      //
//    \___ \| |_| || |\___ \ / __/ _` | '_ ` _ \ / _ \     //
//     ___) |  _  || | ___) | (_| (_| | | | | | | (_) |    //
//    |____/|_| |_|___|____/ \___\__,_|_| |_| |_|\___/     //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract SHISCAMO is ERC1155Creator {
    constructor() ERC1155Creator("SHIScamo", "SHISCAMO") {}
}