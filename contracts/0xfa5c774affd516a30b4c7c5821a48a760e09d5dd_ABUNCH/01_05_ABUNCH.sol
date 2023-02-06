// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MINT A BUNCH
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//        _     ___ _   _ _  _  ___ _  _     //
//       /_\   | _ ) | | | \| |/ __| || |    //
//      / _ \  | _ \ |_| | .` | (__| __ |    //
//     /_/ \_\ |___/\___/|_|\_|\___|_||_|    //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract ABUNCH is ERC1155Creator {
    constructor() ERC1155Creator("MINT A BUNCH", "ABUNCH") {}
}