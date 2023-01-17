// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beans
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    kkOOOOOOOOOOOOOOOOOOOOOOO00000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXKXKKXXKKKKKKKXKKKKXKKKKKKKKKKKKKKKKKKKKKK    //
//                 .         .................................................................................................    //
//            ...............................................................................................................     //
//      ......,:clllc:,............';:cclc:;,'..........,clllllllllll:'...':llllllllll:,'.''':ooooooooooo:.....,cloooooollll,.    //
//     ....:oxkxdddddxxxo,.....':oxxxxxdddxxxxoc'.....',dK0kxxxxxxxxxc'...:OKkxxxxkxxko,..''c0Kxxddddddddc....'c00ddddddoooo;.    //
//    ...:xOxc,.......,:c'...':xOxc;''.....';cdOx:'...',xKo,'''..''''.....c0O:'.'''''......'c0k;'''............lKx'...........    //
//    ..l0k:.................lOk:'............';xOo'...,xKo'..............c0O:.............'c0k,...............c0x'...........    //
//    .l0x,.................;OO;................,dOc...'dKo...............:OO;..............:0k,...............:0x'...........    //
//    'xk;.......... .......l0o..................:ko...'o0o'..............;kk;..............:0O;.''...'........c0k,...........    //
//    .,,...................:o;..................';,..'':xxooooooddol;...',okdoodddddo:'.'.';kKkxxxxxxxxd:.....;k0kxxxxxxddo,.    //
//    ,ol...................,:,..................;dl'.',oK0xddddddddl;....:OXkdddddddo:...'',cooooolllllc;...'',colcccccc::;'.    //
//    ,kO;..................c0o.................'l0d'.',dKd,'............':O0c'..''''.....'';xk;.'''..''''...'';kx,...........    //
//    .l0x,.................,kO:................:OO;...'oKd'..............;k0c..............,k0:...............;kO;...........    //
//    ..l0k:.................;kOc'............'cOk:....'oKd'..............;k0c..............,k0c...............;k0:...........    //
//    ...;xOx:,.......';c,....,dOxl,'......';lxOd,.....'oKx,..............;k0c......'...''',;kKl,,,,'',,,,'...';k0c',,,,'''''.    //
//     ....;oxkxdoooddxxo,......;lxxxxdooddxkxo;........lKd'..............,x0:.............',o0Okkkkkkkkkxl'..',oOOxxkkxxxxxxc    //
//       .....,:cloll:,'...........';cllllc;,...........,:;................;:'................,:::c::::::;,.....',;;;;;,,,,,'.    //
//                ...            ..     ..  ..         ..           ....  .....  .............................................    //
//    ......''''',,,,,,,,,,,,;;;;;;;;::::::::::::::cccccccllllooooooooooooooooooooooddddddddddddddddddddxddxxxxxxxxxxxxxxxxkxx    //
//    000KKKXXXXXNNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract bns is ERC721Creator {
    constructor() ERC721Creator("Beans", "bns") {}
}