// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SATTO
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////
//                               //
//                               //
//                   |           //
//                  /"\          //
//          T~~     |'| T~~      //
//      T~~ |    T~ WWWW|        //
//      |  /"\   |  |  |/\T~~    //
//     /"\ WWW  /"\ |' |WW|      //
//    WWWWW/\| /   \|'/\|/"\     //
//    |   /__\/]WWW[\/__\WWWW    //
//    |"  WWWW'|I_I|'WWWW'  |    //
//    |   |' |/  -  \|' |'  |    //
//    |'  |  |LI=H=LI|' |   |    //
//    |   |' | |[_]| |  |'  |    //
//    |   |  |_|###|_|  |   |    //
//    '---'--'-/___\-'--'---'    //
//                               //
//                               //
///////////////////////////////////


contract ABSRD is ERC1155Creator {
    constructor() ERC1155Creator("SATTO", "ABSRD") {}
}