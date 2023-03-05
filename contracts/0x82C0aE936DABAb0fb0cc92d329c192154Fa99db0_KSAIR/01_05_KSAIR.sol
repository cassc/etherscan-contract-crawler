// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kawaii SKULL GIFT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                         ///////.               //
//                     ////.       ////.          //
//                 ////.               ////.      //
//                //.                    //.      //
//              //.     //.       //.     //.     //
//              //.   //////.   //////.   //.     //
//              //.   //. //.   //. //.   //.     //
//                //.                   //.       //
//                //.       ////.       //.       //
//                ////.               ////.       //
//                  //.               //          //
//                  //.               //          //
//                  //    //.   //.   //.         //
//                    ////. ////. ////            //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract KSAIR is ERC721Creator {
    constructor() ERC721Creator("Kawaii SKULL GIFT", "KSAIR") {}
}