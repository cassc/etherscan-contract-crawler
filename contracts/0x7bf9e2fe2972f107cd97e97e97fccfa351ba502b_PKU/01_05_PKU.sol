// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PIKKU
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//    PPPPPPPPPPPPPPPPP     iiii  kkkkkkkk           kkkkkkkk                                 //
//    P::::::::::::::::P   i::::i k::::::k           k::::::k                                 //
//    P::::::PPPPPP:::::P   iiii  k::::::k           k::::::k                                 //
//    PP:::::P     P:::::P        k::::::k           k::::::k                                 //
//      P::::P     P:::::Piiiiiii  k:::::k    kkkkkkk k:::::k    kkkkkkkuuuuuu    uuuuuu      //
//      P::::P     P:::::Pi:::::i  k:::::k   k:::::k  k:::::k   k:::::k u::::u    u::::u      //
//      P::::PPPPPP:::::P  i::::i  k:::::k  k:::::k   k:::::k  k:::::k  u::::u    u::::u      //
//      P:::::::::::::PP   i::::i  k:::::k k:::::k    k:::::k k:::::k   u::::u    u::::u      //
//      P::::PPPPPPPPP     i::::i  k::::::k:::::k     k::::::k:::::k    u::::u    u::::u      //
//      P::::P             i::::i  k:::::::::::k      k:::::::::::k     u::::u    u::::u      //
//      P::::P             i::::i  k:::::::::::k      k:::::::::::k     u::::u    u::::u      //
//      P::::P             i::::i  k::::::k:::::k     k::::::k:::::k    u:::::uuuu:::::u      //
//    PP::::::PP          i::::::ik::::::k k:::::k   k::::::k k:::::k   u:::::::::::::::uu    //
//    P::::::::P          i::::::ik::::::k  k:::::k  k::::::k  k:::::k   u:::::::::::::::u    //
//    P::::::::P          i::::::ik::::::k   k:::::k k::::::k   k:::::k   uu::::::::uu:::u    //
//    PPPPPPPPPP          iiiiiiiikkkkkkkk    kkkkkkkkkkkkkkk    kkkkkkk    uuuuuuuu  uuuu    //
//                                                                                            //
//    DOT MATRIX DISPLAY PICTURES.                                                            //
//    AN EVOLVING COLLECTION.                                                                 //
//    W/ VARIOUS ARTISTS.                                                                     //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract PKU is ERC721Creator {
    constructor() ERC721Creator("PIKKU", "PKU") {}
}