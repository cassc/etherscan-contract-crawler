// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Johnathan Schultz Open Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//                                                                                   //
//         _  ___    ___                     ___     _  _  _    _                    //
//      _ | |/ __|  / _ \  _ __  ___  _ _   | __| __| |(_)| |_ (_) ___  _ _   ___    //
//     | || |\__ \ | (_) || '_ \/ -_)| ' \  | _| / _` || ||  _|| |/ _ \| ' \ (_-<    //
//      \__/ |___/  \___/ | .__/\___||_||_| |___|\__,_||_| \__||_|\___/|_||_|/__/    //
//                        |_|                                                        //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract Schultz is ERC1155Creator {
    constructor() ERC1155Creator("Johnathan Schultz Open Editions", "Schultz") {}
}