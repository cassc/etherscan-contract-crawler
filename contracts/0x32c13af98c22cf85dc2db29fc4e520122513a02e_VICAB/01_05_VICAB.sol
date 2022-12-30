// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vicab
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//              BBBBBBBBBBBBBBBBB               AAA               BBBBBBBBBBBBBBBBB               AAA                   //
//              B::::::::::::::::B             A:::A              B::::::::::::::::B             A:::A                  //
//              B::::::BBBBBB:::::B           A:::::A             B::::::BBBBBB:::::B           A:::::A                 //
//              BB:::::B     B:::::B         A:::::::A            BB:::::B     B:::::B         A:::::::A                //
//                B::::B     B:::::B        A:::::::::A             B::::B     B:::::B        A:::::::::A               //
//                B::::B     B:::::B       A:::::A:::::A            B::::B     B:::::B       A:::::A:::::A              //
//                B::::BBBBBB:::::B       A:::::A A:::::A           B::::BBBBBB:::::B       A:::::A A:::::A             //
//                B:::::::::::::BB       A:::::A   A:::::A          B:::::::::::::BB       A:::::A   A:::::A            //
//                B::::BBBBBB:::::B     A:::::A     A:::::A         B::::BBBBBB:::::B     A:::::A     A:::::A           //
//                B::::B     B:::::B   A:::::AAAAAAAAA:::::A        B::::B     B:::::B   A:::::AAAAAAAAA:::::A          //
//                B::::B     B:::::B  A:::::::::::::::::::::A       B::::B     B:::::B  A:::::::::::::::::::::A         //
//                B::::B     B:::::B A:::::AAAAAAAAAAAAA:::::A      B::::B     B:::::B A:::::AAAAAAAAAAAAA:::::A        //
//              BB:::::BBBBBB::::::BA:::::A             A:::::A   BB:::::BBBBBB::::::BA:::::A             A:::::A       //
//              B:::::::::::::::::BA:::::A               A:::::A  B:::::::::::::::::BA:::::A               A:::::A      //
//              B::::::::::::::::BA:::::A                 A:::::A B::::::::::::::::BA:::::A                 A:::::A     //
//              BBBBBBBBBBBBBBBBBAAAAAAA                   AAAAAAABBBBBBBBBBBBBBBBBAAAAAAA                   AAAAAAA    //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VICAB is ERC721Creator {
    constructor() ERC721Creator("Vicab", "VICAB") {}
}