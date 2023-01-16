// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kaustav Collection
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//     ____  __.                      __                   //
//    |    |/ _|____   __ __  _______/  |______ ___  __    //
//    |      < \__  \ |  |  \/  ___/\   __\__  \\  \/ /    //
//    |    |  \ / __ \|  |  /\___ \  |  |  / __ \\   /     //
//    |____|__ (____  /____//____  > |__| (____  /\_/      //
//            \/    \/           \/            \/          //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract KSC is ERC1155Creator {
    constructor() ERC1155Creator("Kaustav Collection", "KSC") {}
}