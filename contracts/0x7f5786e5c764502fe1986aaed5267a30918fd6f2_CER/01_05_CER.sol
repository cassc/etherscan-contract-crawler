// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vasile Cercelariu
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//                                 _            _           //
//                                | |          (_)          //
//     __   _____ ___ _ __ ___ ___| | __ _ _ __ _ _   _     //
//     \ \ / / __/ _ \ '__/ __/ _ \ |/ _` | '__| | | | |    //
//      \ V / (_|  __/ | | (_|  __/ | (_| | |  | | |_| |    //
//       \_/ \___\___|_|  \___\___|_|\__,_|_|  |_|\__,_|    //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract CER is ERC721Creator {
    constructor() ERC721Creator("Vasile Cercelariu", "CER") {}
}