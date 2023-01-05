// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Official Anonymous Nobody
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                   AAA                                                                                                                                                                       //
//                  A:::A                                                                                                                                                                      //
//                 A:::::A                                                                                                                                                                     //
//                A:::::::A                                                                                                                                                                    //
//               A:::::::::A         nnnn  nnnnnnnn       ooooooooooo   nnnn  nnnnnnnn yyyyyyy           yyyyyyy mmmmmmm    mmmmmmm      ooooooooooo   uuuuuu    uuuuuu      ssssssssss        //
//              A:::::A:::::A        n:::nn::::::::nn   oo:::::::::::oo n:::nn::::::::nny:::::y         y:::::ymm:::::::m  m:::::::mm  oo:::::::::::oo u::::u    u::::u    ss::::::::::s       //
//             A:::::A A:::::A       n::::::::::::::nn o:::::::::::::::on::::::::::::::nny:::::y       y:::::ym::::::::::mm::::::::::mo:::::::::::::::ou::::u    u::::u  ss:::::::::::::s      //
//            A:::::A   A:::::A      nn:::::::::::::::no:::::ooooo:::::onn:::::::::::::::ny:::::y     y:::::y m::::::::::::::::::::::mo:::::ooooo:::::ou::::u    u::::u  s::::::ssss:::::s     //
//           A:::::A     A:::::A       n:::::nnnn:::::no::::o     o::::o  n:::::nnnn:::::n y:::::y   y:::::y  m:::::mmm::::::mmm:::::mo::::o     o::::ou::::u    u::::u   s:::::s  ssssss      //
//          A:::::AAAAAAAAA:::::A      n::::n    n::::no::::o     o::::o  n::::n    n::::n  y:::::y y:::::y   m::::m   m::::m   m::::mo::::o     o::::ou::::u    u::::u     s::::::s           //
//         A:::::::::::::::::::::A     n::::n    n::::no::::o     o::::o  n::::n    n::::n   y:::::y:::::y    m::::m   m::::m   m::::mo::::o     o::::ou::::u    u::::u        s::::::s        //
//        A:::::AAAAAAAAAAAAA:::::A    n::::n    n::::no::::o     o::::o  n::::n    n::::n    y:::::::::y     m::::m   m::::m   m::::mo::::o     o::::ou:::::uuuu:::::u  ssssss   s:::::s      //
//       A:::::A             A:::::A   n::::n    n::::no:::::ooooo:::::o  n::::n    n::::n     y:::::::y      m::::m   m::::m   m::::mo:::::ooooo:::::ou:::::::::::::::uus:::::ssss::::::s     //
//      A:::::A               A:::::A  n::::n    n::::no:::::::::::::::o  n::::n    n::::n      y:::::y       m::::m   m::::m   m::::mo:::::::::::::::o u:::::::::::::::us::::::::::::::s      //
//     A:::::A                 A:::::A n::::n    n::::n oo:::::::::::oo   n::::n    n::::n     y:::::y        m::::m   m::::m   m::::m oo:::::::::::oo   uu::::::::uu:::u s:::::::::::ss       //
//    AAAAAAA                   AAAAAAAnnnnnn    nnnnnn   ooooooooooo     nnnnnn    nnnnnn    y:::::y         mmmmmm   mmmmmm   mmmmmm   ooooooooooo       uuuuuuuu  uuuu  sssssssssss         //
//                                                                               bbbbbbbb    y:::::y                              dddddddd                                                     //
//                                       NNNNNNNN        NNNNNNNN                b::::::b   y:::::y                               d::::::d                                                     //
//                                       N:::::::N       N::::::N                b::::::b  y:::::y                                d::::::d                                                     //
//                                       N::::::::N      N::::::N                b::::::b y:::::y                                 d::::::d                                                     //
//                                       N:::::::::N     N::::::N                 b:::::byyyyyyy                                  d:::::d                                                      //
//                                       N::::::::::N    N::::::N   ooooooooooo   b:::::bbbbbbbbb       ooooooooooo       ddddddddd:::::dyyyyyyy           yyyyyyy                             //
//                                       N:::::::::::N   N::::::N oo:::::::::::oo b::::::::::::::bb   oo:::::::::::oo   dd::::::::::::::d y:::::y         y:::::y                              //
//                                       N:::::::N::::N  N::::::No:::::::::::::::ob::::::::::::::::b o:::::::::::::::o d::::::::::::::::d  y:::::y       y:::::y                               //
//                                       N::::::N N::::N N::::::No:::::ooooo:::::ob:::::bbbbb:::::::bo:::::ooooo:::::od:::::::ddddd:::::d   y:::::y     y:::::y                                //
//                                       N::::::N  N::::N:::::::No::::o     o::::ob:::::b    b::::::bo::::o     o::::od::::::d    d:::::d    y:::::y   y:::::y                                 //
//                                       N::::::N   N:::::::::::No::::o     o::::ob:::::b     b:::::bo::::o     o::::od:::::d     d:::::d     y:::::y y:::::y                                  //
//                                       N::::::N    N::::::::::No::::o     o::::ob:::::b     b:::::bo::::o     o::::od:::::d     d:::::d      y:::::y:::::y                                   //
//                                       N::::::N     N:::::::::No::::o     o::::ob:::::b     b:::::bo::::o     o::::od:::::d     d:::::d       y:::::::::y                                    //
//                                       N::::::N      N::::::::No:::::ooooo:::::ob:::::bbbbbb::::::bo:::::ooooo:::::od::::::ddddd::::::dd       y:::::::y                                     //
//                                       N::::::N       N:::::::No:::::::::::::::ob::::::::::::::::b o:::::::::::::::o d:::::::::::::::::d        y:::::y                                      //
//                                       N::::::N        N::::::N oo:::::::::::oo b:::::::::::::::b   oo:::::::::::oo   d:::::::::ddd::::d       y:::::y                                       //
//                                       NNNNNNNN         NNNNNNN   ooooooooooo   bbbbbbbbbbbbbbbb      ooooooooooo      ddddddddd   ddddd      y:::::y                                        //
//                                                                                                                                             y:::::y                                         //
//                                                                                                                                            y:::::y                                          //
//                                                                                                                                           y:::::y                                           //
//                                                                                                                                          y:::::y                                            //
//                                                                                                                                         yyyyyyy                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ANON is ERC1155Creator {
    constructor() ERC1155Creator("Official Anonymous Nobody", "ANON") {}
}