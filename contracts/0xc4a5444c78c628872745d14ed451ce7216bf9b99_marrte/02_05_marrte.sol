// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: marrte
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//                                  __              //
//      _____ _____ _______________/  |_  ____      //
//     /     \\__  \\_  __ \_  __ \   __\/ __ \     //
//    |  Y Y  \/ __ \|  | \/|  | \/|  | \  ___/     //
//    |__|_|  (____  /__|   |__|   |__|  \___  >    //
//          \/     \/                        \/     //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract marrte is ERC1155Creator {
    constructor() ERC1155Creator("marrte", "marrte") {}
}