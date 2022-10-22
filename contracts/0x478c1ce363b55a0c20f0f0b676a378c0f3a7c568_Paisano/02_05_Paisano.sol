// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PaisanoDao
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNKkxkkKXNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNKxoooxKXl....lK0ollldKNNNNNNNNNNNNNNNN    //
//    XNNXNNNNNNNNNNNNNNNNXx'...,kXc....cKx'...,kNNNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNNNXkllokXx'...,kXc....cKx....,kNNNNNNNNNNXNNXNN    //
//    NNNNNNNNNNNNNN0;...cKx'...,kXc....cKx....,kNNNNNNNNNNNNNNNN    //
//    XNNXNNNNNNNNNN0;...cKx'...,kXc....cKx....,kNNNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNNN0;...c0x'...,kXc....cKx....,kNNNNNNNNNNXNNXNN    //
//    NNNNNNNNNNNNNN0:...lKx'...,kXl....cKx....,kNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNXOxxx0Xk'...,kXkc::ckX0o:::o0NNNNNNNNNNNNNNNN    //
//    XNNXNNNNNNNNKxlllllxKKxdodx0KK0000KKK00000KXNNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNO;.....,dOOOKNNk:''''''''''''',dXNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNO;..........lKXd'..............lXNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNO;..........:KN0xoooooooooo:...lXNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNO;..........;kOOO0KNNK0OO0Ol...lXNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNKo,..............'oXXo'........lXNNNNNNNNXNNXNN    //
//    NNNNNNNNNNNNNXO;..............:kO:.........lXNNNNNNNNNNNNNN    //
//    XNNXNNNNNNNNNN0;...........................lXNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNNN0:...........................oXNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNNNX0kkx;..................:xkkOKNNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNNNNNNNXl..................lXNNNNNNNNNNNNNXNNXNN    //
//    XNNXNNNNNNNNNNNNNNKl..................lXNNNNNNNNNNNNNXNNXNN    //
//    NNNNNNNNNNNNNNNNNNXd,'''''''''''''''',dXNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNXK0000000000000000KXNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract Paisano is ERC721Creator {
    constructor() ERC721Creator("PaisanoDao", "Paisano") {}
}