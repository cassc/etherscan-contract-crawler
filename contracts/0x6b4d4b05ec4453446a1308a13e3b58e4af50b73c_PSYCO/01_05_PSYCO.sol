// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PSYCHO KIDS EDITIONS
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


contract PSYCO is ERC1155Creator {
    constructor() ERC1155Creator("PSYCHO KIDS EDITIONS", "PSYCO") {}
}