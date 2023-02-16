// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HeatherPsyD
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//      ___ ___   ___ ___ ___   ___ ___   ___ ___ ___     //
//     |_ _|_ _| |_ _|_ _|_ _| |_ _|_ _| |_ _|_ _|_ _|    //
//      | | | |   | | | | | |   | | | |   | | | | | |     //
//      | | | | _ | | | | | | _ | | | | _ | | | | | |     //
//     |___|___(_)___|___|___(_)___|___(_)___|___|___|    //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract HPSYD is ERC1155Creator {
    constructor() ERC1155Creator("HeatherPsyD", "HPSYD") {}
}