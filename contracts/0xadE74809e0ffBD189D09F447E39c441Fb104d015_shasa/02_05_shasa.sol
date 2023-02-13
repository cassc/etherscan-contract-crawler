// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: shasaartwork
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//       _____ _    _           _____             //
//      / ____| |  | |   /\    / ____|  /\        //
//     | (___ | |__| |  /  \  | (___   /  \       //
//      \___ \|  __  | / /\ \  \___ \ / /\ \      //
//      ____) | |  | |/ ____ \ ____) / ____ \     //
//     |_____/|_|  |_/_/    \_\_____/_/    \_\    //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract shasa is ERC1155Creator {
    constructor() ERC1155Creator("shasaartwork", "shasa") {}
}