// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pneumaninesix
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//                                                         //
//    ______    ____    ____   __ __   _____  _____        //
//    \____ \  /    \ _/ __ \ |  |  \ /     \ \__  \       //
//    |  |_> >|   |  \\  ___/ |  |  /|  Y Y  \ / __ \_     //
//    |   __/ |___|  / \___  >|____/ |__|_|  /(____  /     //
//    |__|         \/      \/              \/      \/      //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract PN96 is ERC1155Creator {
    constructor() ERC1155Creator("Pneumaninesix", "PN96") {}
}