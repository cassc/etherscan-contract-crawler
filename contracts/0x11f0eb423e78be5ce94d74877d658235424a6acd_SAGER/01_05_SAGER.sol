// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THEsager testBOOP
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//    MMP""MM""YMM `7MMF'  `7MMF`7MM"""YMM          //
//    P'   MM   `7   MM      MM   MM    `7          //
//         MM        MM      MM   MM   d            //
//         MM        MMmmmmmmMM   MMmmMM            //
//         MM        MM      MM   MM   Y  ,         //
//         MM        MM      MM   MM     ,M         //
//       .JMML.    .JMML.  .JMML.JMMmmmmMMM         //
//    ,pP"Ybd  ,6"Yb.  .P"Ybmmm .gP"Ya `7Mb,od8     //
//    8I   `" 8)   MM :MI  I8  ,M'   Yb  MM' "'     //
//    `YMMMa.  ,pm9MM  WmmmP"  8M""""""  MM         //
//    L.   I8 8M   MM 8M       YM.    ,  MM         //
//    M9mmmP' `Moo9^Yo.YMMMMMb  `Mbmmd'.JMML.       //
//                    6'     dP                     //
//                    Ybmmmd'                       //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract SAGER is ERC721Creator {
    constructor() ERC721Creator("THEsager testBOOP", "SAGER") {}
}