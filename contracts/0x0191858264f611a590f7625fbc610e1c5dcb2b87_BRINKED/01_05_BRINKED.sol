// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bryan Brinkman Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//       ___      _      __                      ____   ___ __  _                 //
//      / _ )____(_)__  / /__ __ _  ___ ____    / __/__/ (_) /_(_)__  ___  ___    //
//     / _  / __/ / _ \/  '_//  ' \/ _ `/ _ \  / _// _  / / __/ / _ \/ _ \(_-<    //
//    /____/_/ /_/_//_/_/\_\/_/_/_/\_,_/_//_/ /___/\_,_/_/\__/_/\___/_//_/___/    //
//                                                                                //
//                             ----Future Proofed----                             //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract BRINKED is ERC721Creator {
    constructor() ERC721Creator("Bryan Brinkman Editions", "BRINKED") {}
}