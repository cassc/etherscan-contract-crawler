// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: fdkcollective
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMo........................................................................oMMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+             mdhhhhhhs          `mdhhhhs.          `ms  `sd/            +MMM    //
//    MMM+             Nm```````          .Mh```-Nd          `Mh :dd-             +MMM    //
//    MMM+             Nm------.          .My    yM-         `Mdomo`              +MMM    //
//    MMM+             NNyyyyyys          .My    hM.         `MmhN+`              +MMM    //
//    MMM+             Nd                 .Mh```:Nd          `Mh`+mh-             +MMM    //
//    MMM+             mh                 `mdyyhds.          `my  .sd/            +MMM    //
//    MMM+             `                   ````               `     ``            +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMM+                                                                        +MMM    //
//    MMMo........................................................................oMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract FDK is ERC721Creator {
    constructor() ERC721Creator("fdkcollective", "FDK") {}
}