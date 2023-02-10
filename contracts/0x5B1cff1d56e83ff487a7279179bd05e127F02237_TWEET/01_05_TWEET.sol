// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FREEDOM TO FOLLOW
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//              ..',,;:cclodxxkkOkxxx;                  .';,.       ....'...............            //
//                    .',;:codkO000KKXXNNNXX0l.                .;dkdl,.   ......'...............    //
//                 ..,::ldkO000000KKXNWWWWNNKo.                ,x00Oxo;. ...............'..,;:cl    //
//                .;:cokO000Okxddolclk0000kkd,                'd0XXK0Od;.............'','',:lood    //
//              .,:cdk000Oxoc:;,....:llllc::,.               .ck0XNNXKkc........''''....',cdOOdl    //
//             .;:lx000Odc;,,'.. ..,;;;;;,,...              .:dO0XNNNKOo'......'''......,cdOKKko    //
//            ':cok00Oxl;,,'...,:cc:;,,,,,,'...            .;okOKXNNNKOd;..',,''''.. ..,cdk0KXOl    //
//           .;cdO00ko:'','...;c:;,;;;,,,'',,'..          .'lxOKKXNNX0kd:...,,''''.. ..;lk000XOc    //
//          .;cok00ko;..'.. .,:;.....',,;:ldxxo:..        .:dk0KXXXXX0kdc'..'''....  .'cx00OOKO:    //
//         .,cok00Od:........,clccloxkkOOOO00KK0xc'..    .;ok0KKK00KXKkdl,'.'''.... ..;oOKkdd0O:    //
//         .:oxOK0ko,.....'''':oxk0XNWMMWWXKKXXXKkc;'....;oO0KXK0xx0XKOxo;'',,,.... .,ckK0o,cO0l    //
//        .'cdx0KKOd:'.......',cd0XNWMMMMMNKKKXNXOoc:,'''cx0KXX0xloOXXKkxc'',;,'....'cx0Kx,.:k0d    //
//       ..';ok0KK0Od:'.''..';cdOKXNWWMMMWXOxkKXNKkdol:,;oOKKKOo,';dKXKOxo;,;;:,....:x0Kk:..,d0k    //
//    ...','.;d0KXK0Oxolc:;coxOKXXXXXNWMWN0xoox0XXK0kxoclkKXK0d;...:OX0dlc'.,:c;'.':x0KOl.. .oOO    //
//    ...;:'..,oOKXXKKKK0OO0KXXXXXK00NWMWX0xllok0XXXKkddk0XK0x:'...,xK0dc:'..:c:,':x000d'   .:kO    //
//    ...;c:'..'cdOKXXXXXXXXXXKKOkdkKNWWNX0dllloxKXXX0kk0XXKkc,,'..,dK0xl:'..:lc;cx0OOx;.    ,xO    //
//    ...,cc;...'';cokO0K0OkxolllokKNNNNXKOdllc:lkKKXXKKXXK0d:::;'';dK0xlc,..:lllx0Okxc.     .ok    //
//    ....',,......',:coolc:;,;lxOXXKKKKK0ko::c::d00KXXXXK0xlcccc::cxK0klc,.'codk0Oxxo;.     .ck    //
//    ..........'''',:lloolclox0KK0OkOkk00ko:;::cok00XNXK0kl;:clllllkK0kol;.'cx0KOxdo:'.     .;x    //
//    ...........',',lxOO00000K0Okxxxocx00kd:;:clcoxOXNXKkl;,,;;:cclxK0kdo:.,oOK0xdoc;'..     ,d    //
//     .............,d0XNNX0kxxxddxdl;:dO0Oxc;:cccccoOXKOl,.',,,;;:cx00xdo:,lkKKOxl:;;,'.... .;d    //
//       .......  ...ckKX0kdooxxddoc;;clxOOxc;:cccc::codc,'',,,;;;;lk0OxooccdO0Kkl,',,,'..   .;d    //
//         .....   ...,ldoodddolc:,',;;:oOkxc:clllcc:,..',;:ccccc::oO0koodddooxx:'..',,'.    .cx    //
//          .....      .',;:;;,'..  ...'ckkxl:clcc;;,...';cllllccclx00kdxkko:;;'.....',''.  .;dx    //
//          ....             .       ...:kOkxddol:;;;;,,,:ccccccclok00Okkxoc:;;'......';col::ldd    //
//                                   ..,lO00Okxdlc:::c::::clooolllox00OOkdl;''.........,okOkxxxo    //
//                                    'lk00kxdool:'''',,',;;;;;;;;:lxO00kdc,.........  .,codxdl:    //
//                                    .coollccccc:'............',,;coddolc;.. ........   ...'',,    //
//                                     .,,;::c:::;'.........   ...',::;,,'.............             //
//                                      ......'','......          ...'''........... ...   ...       //
//                                         .............              . ...''......      ;ddlc:,    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract TWEET is ERC1155Creator {
    constructor() ERC1155Creator("FREEDOM TO FOLLOW", "TWEET") {}
}