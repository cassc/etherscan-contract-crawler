// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE PSYCHO KIDS EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//     ____  ___  _  _   ___  _   _  _____    _  _  ____  ____   ___     //
//    (  _ \/ __)( \/ ) / __)( )_( )(  _  )  ( )/ )(_  _)(  _ \ / __)    //
//     )___/\__ \ \  / ( (__  ) _ (  )(_)(    )  (  _)(_  )(_) )\__ \    //
//    (__)  (___/ (__)  \___)(_) (_)(_____)  (_)\_)(____)(____/ (___/    //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract PSYKS is ERC1155Creator {
    constructor() ERC1155Creator("THE PSYCHO KIDS EDITIONS", "PSYKS") {}
}