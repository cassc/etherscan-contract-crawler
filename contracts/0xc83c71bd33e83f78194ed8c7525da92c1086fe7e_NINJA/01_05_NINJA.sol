// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Merge
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    ***********    //
//    **********     //
//    *********      //
//    ********       //
//    *******        //
//    ******         //
//    *****          //
//    ****           //
//    ***            //
//    **             //
//    *              //
//                   //
//                   //
///////////////////////


contract NINJA is ERC721Creator {
    constructor() ERC721Creator("The Merge", "NINJA") {}
}