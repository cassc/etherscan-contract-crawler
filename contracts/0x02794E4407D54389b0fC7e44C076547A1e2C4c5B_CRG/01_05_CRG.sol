// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: COURage
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//       _____ ____  _    _ _____                      //
//      / ____/ __ \| |  | |  __ \                     //
//     | |   | |  | | |  | | |__) |__ _  __ _  ___     //
//     | |   | |  | | |  | |  _  // _` |/ _` |/ _ \    //
//     | |___| |__| | |__| | | \ \ (_| | (_| |  __/    //
//      \_____\____/ \____/|_|  \_\__,_|\__, |\___|    //
//                                       __/ |         //
//                                      |___/          //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract CRG is ERC721Creator {
    constructor() ERC721Creator("COURage", "CRG") {}
}