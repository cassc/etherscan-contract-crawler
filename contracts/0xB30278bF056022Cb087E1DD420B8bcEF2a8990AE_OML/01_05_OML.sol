// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ohmylore
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
//            _                     _                      _   _         //
//           | |                   | |                    | | | |        //
//       ___ | |__  _ __ ___  _   _| | ___  _ __ ___   ___| |_| |__      //
//      / _ \| '_ \| '_ ` _ \| | | | |/ _ \| '__/ _ \ / _ \ __| '_ \     //
//     | (_) | | | | | | | | | |_| | | (_) | | |  __/|  __/ |_| | | |    //
//      \___/|_| |_|_| |_| |_|\__, |_|\___/|_|  \___(_)___|\__|_| |_|    //
//                             __/ |                                     //
//                            |___/                                      //
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract OML is ERC1155Creator {
    constructor() ERC1155Creator("ohmylore", "OML") {}
}