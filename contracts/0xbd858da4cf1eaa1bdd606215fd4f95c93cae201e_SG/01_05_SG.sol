// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shaky Ghost
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S8S8    //
//    8X8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888    //
//    [email protected]88888888888888888888888888888888888888888888888888888888888888888888888888888888888888    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    888888X8888888X88888X88888X888888888X88888X888888888X88888X888888888X88888X888888888X88888X888888888X88888X888888888X88888X888888888X88888X888888888XX    //
//    [email protected]8888888888888888888888888888888888888888888888888888888888888888888888888888888888888     //
//    [email protected]@[email protected]@[email protected]@[email protected]@8888888    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@@[email protected]@@8888888888888888888888    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@8888888888888    //
//    [email protected]@888888888S8%[email protected] [email protected]@[email protected]@88888888888    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@88888888    //
//    [email protected][email protected]@[email protected]@[email protected]@@[email protected]    //
//    [email protected]@[email protected]@888888888888888888888 [email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@@8888    //
//    [email protected]@[email protected]@[email protected]@[email protected] [email protected]@88 [email protected] 8888888X888888888888    //
//    [email protected]@[email protected]@[email protected]@ [email protected]@[email protected] [email protected]    //
//    88 [email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@888888    //
//    [email protected] [email protected]@[email protected] [email protected]@[email protected]@[email protected]@[email protected]@88888888888    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected] [email protected]@[email protected]@[email protected]@[email protected]@88888888888888888888888888888    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected] [email protected]@[email protected]@[email protected]@[email protected] 88    //
//    [email protected]@[email protected]@[email protected] [email protected]@[email protected]@[email protected]@8888888888888888888    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@88888888X88888888    //
//    [email protected][email protected]@@ @[email protected]@[email protected]@888888888    //
//    88888888888888X88888X8888888888888888 [email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@8888888888888888888    //
//    [email protected][email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@8888888888888888888888 @[email protected];[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@88888888888888888888 [email protected]@88888888 888888    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@%[email protected] [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@8888888888888888888888    //
//    [email protected] [email protected][email protected]@888888888    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]%[email protected]@[email protected]@ [email protected]@[email protected] [email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@@[email protected]@[email protected]@@888888888888888888888888    //
//    88 [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@88    //
//    [email protected]@[email protected]@[email protected]@@[email protected]@[email protected]    //
//    [email protected]@8888888 [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@88888888888888888888888888888    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@88888888888S    //
//    88 X88888888888888888888888888888888888888[email protected][email protected]@[email protected]@8888%    //
//    8X888888888888888888888[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@8888    //
//    [email protected]@[email protected]@[email protected] [email protected]@@[email protected]@[email protected]@88888888888888X    //
//    [email protected]@[email protected]@[email protected]@[email protected] [email protected]     //
//    [email protected]@[email protected]@[email protected]@[email protected]@888888888888888888888 @[email protected]@88888888    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@8888888    //
//    [email protected] [email protected]@[email protected]@[email protected]    //
//    88 [email protected] [email protected]@[email protected]@[email protected]@[email protected]@888888888S8S8    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@88    //
//    [email protected] [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected] 8    //
//    [email protected]@[email protected]@[email protected] [email protected]@[email protected]@[email protected]@888888888    //
//    88888888888888888888 [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@8888888888    //
//    [email protected]@888888%[email protected]@[email protected]@[email protected]%[email protected]    //
//    [email protected]@[email protected] [email protected]@[email protected]@8888888X888888    //
//    [email protected]@8888888 [email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected][email protected]@[email protected]    //
//    [email protected]@88888888888888888888 [email protected]@[email protected]@[email protected]@[email protected]@8888888888    //
//    88 [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    8X88888888%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@@8    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SG is ERC721Creator {
    constructor() ERC721Creator("Shaky Ghost", "SG") {}
}