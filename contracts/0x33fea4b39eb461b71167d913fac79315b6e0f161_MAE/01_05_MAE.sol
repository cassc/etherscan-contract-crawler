// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: reflections
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//    //                                    //
//    //                                    //
//    //  ,--,--,--. ,--,--. ,---.          //
//    //  |        |' ,-.  || .-. :         //
//    //  |  |  |  |\ '-'  |\   --..--.     //
//    //  `--`--`--' `--`--' `----''--'     //
//    //                                    //
//                                          //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract MAE is ERC721Creator {
    constructor() ERC721Creator("reflections", "MAE") {}
}