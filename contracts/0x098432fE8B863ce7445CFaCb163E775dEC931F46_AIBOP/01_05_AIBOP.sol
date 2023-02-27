// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Portraits
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    SSSSSSSS%%%%%%%%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@[email protected]@@@    //
//    SSSSSSSS%%%%%%%%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@[email protected]@@@    //
//    SSSSSSSS%%%%%%%%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@[email protected]@@@    //
//    SSSSSSSS%%%%%%%%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@[email protected]@@@    //
//    SSSSSSSS%%%%%%%%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@[email protected]@@@    //
//    SSSSSSSS%%%%%%%%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@[email protected]@@@    //
//    SSSSSSSS%%%%%%%%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@[email protected]@@@    //
//    SSSSSSSS%%%%%%%%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@[email protected]@@@    //
//    SSSSSSSS%%%%%%%%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@@@@@@@    //
//    SSSSSSSS%%%%%%%%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@@@@@@@    //
//    SSSSSSSS%%%%%%%%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@@@@@@@    //
//    SSSSSSSS%%%%%%%%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@@@@@@@    //
//    @@@@@@@@@@@@S%%%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@@@@@@@    //
//    @@@@@@@@@@@@S%%%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@@@@@@@    //
//    @@@@@@@@@@@@S%%%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@@@@@@@    //
//    %%%%%%%%%%%%%%%%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@@@@@@@    //
//    %%%%%%%%%%%%%%%%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@@@@@@@    //
//    SSSSSSSSSSSSSS%%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@@@@@@@    //
//    @@@@@@@@@@@@@@S%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@@@@@@@    //
//    @@@@@@@@@@@@@@S%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@S%%%%[email protected]@@@@@@@    //
//    @@@@@@@@@@@@@@S%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@SSSSS%%%%[email protected]@@@@@@@    //
//    @@@@@@@@@@@@@@S%%[email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@@@@@@@[email protected]@    //
//    [email protected]@S%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@@@@@@@S%%%%%%%%[email protected]@    //
//    @@@@@@@@@@@@@@@@SSSS%%%%%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@@@@@@@S%%%%%%%%[email protected]@    //
//    @@@@@@@@@@@@@@@@@@@@SSSS%%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@@@@@@@SSSSSSSSSSSS    //
//    [email protected]@@@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@[email protected]@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@SSSSSS%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@@@@@@@@@@@[email protected]@    //
//    [email protected]@@@@@S%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%[email protected]@@@@@@@@@@@[email protected]@    //
//    @@@@@@@@@@@@@@@@@@@@@@SSSSSSSSSS%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%%[email protected]@@@@@@@@@@@@@    //
//    [email protected]@@@@@@@@@S%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%%%%%%%%%%%[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@SSSSSSSS%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%%%%%%%%%%%[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@SSSSSSSSSS%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%%%%%%%%%%%[email protected]@@@@@@@@@@@@@    //
//    [email protected]@@@@@@@@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%%%%%%%%%%%[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@SSSSSSSSSS%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%%%%%%%%%%%[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@S%%%%%%%%%%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%%%%%%%%%%%[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%%%%%%%%%%%[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%%%%%%%%%%%[email protected]@@@@@@@@@@@@@    //
//    [email protected]@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%%%%%%%%%%%[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%%%%%%%%%%%[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%%%%%%%%%%%[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@[email protected]@S%%%%%%%%%%%%%%%%%%%%[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@S%%%%%%%%%%%%%%%%%%%%[email protected]@@@@@@@@@@@@@    //
//    [email protected]@[email protected]@S%%%%%%%%%%%%%%%%%%%%[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@Portraits%%%%%%%%%%%%[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@Art%is%binary%%%%%%%%[email protected]@@@@@@@@@@@@@    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract AIBOP is ERC721Creator {
    constructor() ERC721Creator("Portraits", "AIBOP") {}
}