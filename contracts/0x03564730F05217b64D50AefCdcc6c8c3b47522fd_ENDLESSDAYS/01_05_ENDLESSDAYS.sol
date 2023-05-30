// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Endless Days
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//       _____  _____  __   ____________  ___  _____  ______    //
//      / __/ |/ / _ \/ /  / __/ __/ __/ / _ \/ _ \ \/ / __/    //
//     / _//    / // / /__/ _/_\ \_\ \  / // / __ |\  /\ \      //
//    /___/_/|_/____/____/___/___/___/ /____/_/ |_|/_/___/      //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract ENDLESSDAYS is ERC1155Creator {
    constructor() ERC1155Creator("Endless Days", "ENDLESSDAYS") {}
}