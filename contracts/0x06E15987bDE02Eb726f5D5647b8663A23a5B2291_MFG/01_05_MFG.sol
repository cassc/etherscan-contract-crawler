// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WISH YOU WEREN'T HERE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//          __ _.--..--._ _                   //
//         .-' _/   _/\_   \_'-.              //
//        |__ /   _/\__/\_   \__|             //
//           |___/\_\__/  \___|               //
//                  \__/                      //
//                  \__/                      //
//                   \__/                     //
//                    \__/                    //
//                 ____\__/___                //
//           . - '             ' -.           //
//          /                      \          //
//    ~~~~~~~  ~~~~~ ~~~~~  ~~~ ~~~  ~~~~~    //
//           WISH YOU WEREN'T HERE            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract MFG is ERC721Creator {
    constructor() ERC721Creator("WISH YOU WEREN'T HERE", "MFG") {}
}