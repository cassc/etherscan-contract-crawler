// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: dromsjel Artwork 'Glücksgefühle II'
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//          _                         _      _     //
//         | |                       (_)    | |    //
//       __| |_ __ ___  _ __ ___  ___ _  ___| |    //
//      / _` | '__/ _ \| '_ ` _ \/ __| |/ _ \ |    //
//     | (_| | | | (_) | | | | | \__ \ |  __/ |    //
//      \__,_|_|  \___/|_| |_| |_|___/ |\___|_|    //
//                                  _/ |           //
//                                 |__/            //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract DRO is ERC1155Creator {
    constructor() ERC1155Creator(unicode"dromsjel Artwork 'Glücksgefühle II'", "DRO") {}
}