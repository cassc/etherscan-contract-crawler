// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MariVstudio
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//      __  __            ___      __  _             _ _           //
//     |  \/  |          (_) \    / / | |           | (_)          //
//     | \  / | __ _ _ __ _ \ \  / /__| |_ _   _  __| |_  ___      //
//     | |\/| |/ _` | '__| | \ \/ / __| __| | | |/ _` | |/ _ \     //
//     | |  | | (_| | |  | |  \  /\__ \ |_| |_| | (_| | | (_) |    //
//     |_|  |_|\__,_|_|  |_|   \/ |___/\__|\__,_|\__,_|_|\___/     //
//                                                                 //
//                                                                 //
//    MariVstudio - ILLUSTRATOR / GRAPHIC DESIGNER                 //
//                                                                 //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract MariV is ERC1155Creator {
    constructor() ERC1155Creator("MariVstudio", "MariV") {}
}