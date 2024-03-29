// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ZAM V3 (OS MAIN) 721
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//          ,----,                        ____         //
//           .'   .`|  ,---,               ,'  , `.    //
//        .'   .'   ; '  .' \           ,-+-,.' _ |    //
//      ,---, '    .'/  ;    '.      ,-+-. ;   , ||    //
//      |   :     ./:  :       \    ,--.'|'   |  ;|    //
//      ;   | .'  / :  |   /\   \  |   |  ,', |  ':    //
//      `---' /  ;  |  :  ' ;.   : |   | /  | |  ||    //
//        /  ;  /   |  |  ;/  \   \'   | :  | :  |,    //
//       ;  /  /--, '  :  | \  \ ,';   . |  ; |--'     //
//      /  /  / .`| |  |  '  '--'  |   : |  | ,        //
//    ./__;       : |  :  :        |   : '  |/         //
//    |   :     .'  |  | ,'        ;   | |`-'          //
//    ;   |  .'     `--''          |   ;/              //
//    `---'                        '---'               //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract ZAMV3 is ERC721Creator {
    constructor() ERC721Creator("ZAM V3 (OS MAIN) 721", "ZAMV3") {}
}