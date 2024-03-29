// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gwagon
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//      ________                                          //
//     /  _____/_  _  _______     ____   ____   ____      //
//    /   \  __\ \/ \/ /\__  \   / ___\ /  _ \ /    \     //
//    \    \_\  \     /  / __ \_/ /_/  >  <_> )   |  \    //
//     \______  /\/\_/  (____  /\___  / \____/|___|  /    //
//            \/             \//_____/             \/     //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract GW is ERC1155Creator {
    constructor() ERC1155Creator("Gwagon", "GW") {}
}