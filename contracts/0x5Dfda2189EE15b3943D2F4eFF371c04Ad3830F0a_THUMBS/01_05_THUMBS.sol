// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Thumbs - VP Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllldddxdoollllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllloxO0000Okxollllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllokOO0000OOkolllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllxkOO0000OOkollllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllldkkO0000Okkdllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllokkOO00OOkkollllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllldkkOO00OOkxollllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllxOOO000OOkdlllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllldkOO0000OOkdlllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllloxOO000000OOOkdllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllldxkO000000000OOOOkxxxddddddddoollllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllodxxddddoddxkOO0000000000OOOOOOO0000000000Okdlllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllok000000OO000000000000000OOOkkOO0000000000000kollllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllx000000000000000K0000000OOOkkkkkOOOOOOOOOOOOkxollllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllldO00000000000000000000000OOOOxxxxkkkkkkkkxxxdollllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllx00000000000000000000000OOOOOkxkOOOOOOOOOOOkkdolllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllk0000000000000000000O000OOOOOkkkOOOO0000000OOkdlllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllxOOOO000OO000000000OOOOOOOOOOkxxkkOOOOOOOOkkxdolllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllxOOOOOOOOOOOOOO0000OOOOOOOOOOkkxxkkkkkkkxxddolllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllldkOOOkkkkkOkkOOOOOOOOOOOOOOOkkkOOOOOOOOOOOkkxollllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllokOOkkkkkkkkkkkkkkOOOOOOOOOkkxxkkOOOOOOOOOOkxollllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllldkkkkkkkkxxxxxxxxxkkkOOOOOOkkxxkkkkkkxxxxxxolllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllloxxxxxxxddoooodddxxkkkkkkOkkkOOOOOkkkxddolllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllloodooolllcccllloddddxxxkxxxkkOOOOOOOxdolllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllloolloddxxxxddolllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllccllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract THUMBS is ERC1155Creator {
    constructor() ERC1155Creator("Thumbs - VP Edition", "THUMBS") {}
}