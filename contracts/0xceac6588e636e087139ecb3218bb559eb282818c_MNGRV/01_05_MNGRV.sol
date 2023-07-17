// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sartorialist Is Right  - Paddy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                            //
//                                                                                                                                            //
//    The "Sartorialist Is Right" series is an euphemism for fast fashion. Style is a preference and should not be predicated upon trends.    //
//                                                                                                                                            //
//                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MNGRV is ERC721Creator {
    constructor() ERC721Creator("Sartorialist Is Right  - Paddy", "MNGRV") {}
}