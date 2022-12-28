// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fork the Fed
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    ................    //
//    ................    //
//    ....;£íýz{.²zÇ,>    //
//    gv.a.È.ÃˆŠQ2:Ÿ¸ª    //
//    K.^J)«_Iÿÿ...¬+|    //
//    ................    //
//    ................    //
//    ......ÿÿÿÿM.ÿÿ..    //
//    ..EThe Times 03/    //
//    Jan/2009 Chancel    //
//    lor on brink of     //
//    second bailout f    //
//    or banksÿÿÿÿ..ò.    //
//    *....CA.gŠý°þUH'    //
//    .gñ¦q0·.\Ö¨(à9.¦    //
//    ybàê.aÞ¶Iö¼?Lï8Ä    //
//    óU.å.Á.Þ\8M÷º..W    //
//    ŠLp+kñ._¬....       //
//                        //
//                        //
////////////////////////////


contract FED is ERC1155Creator {
    constructor() ERC1155Creator("Fork the Fed", "FED") {}
}