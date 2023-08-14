// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bad Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    <!DOCTYPE html>                                //
//    <html>                                         //
//    <style>                                        //
//    body {                                         //
//      font-size: 20px;                             //
//    }                                              //
//    </style>                                       //
//    <body>                                         //
//                                                   //
//    <span style='font-size:100px;'>&#56;</span>    //
//                                                   //
//    </body>                                        //
//    </html>                                        //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract IP is ERC721Creator {
    constructor() ERC721Creator("Bad Art", "IP") {}
}