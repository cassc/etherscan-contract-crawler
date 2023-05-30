// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe Pictures
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//     ___ ___ ___ ___   ___ _    _                        //
//     | _ \ __| _ \ __| | _ (_)__| |_ _  _ _ _ ___ ___    //
//     |  _/ _||  _/ _|  |  _/ / _|  _| || | '_/ -_|_-<    //
//     |_| |___|_| |___| |_| |_\__|\__|\_,_|_| \___/__/    //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract PPPCTRS is ERC1155Creator {
    constructor() ERC1155Creator("Pepe Pictures", "PPPCTRS") {}
}