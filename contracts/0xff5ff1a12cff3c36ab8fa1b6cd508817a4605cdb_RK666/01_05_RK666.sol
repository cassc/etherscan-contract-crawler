// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Inner Monsters
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    Love yourself, you amazing monster.                                   ..                                                    //
//                                                                         ,l,.                                                   //
//                                                                        .oo'                                                    //
//                                                                        ;o:.                                                    //
//                                      ...                              .:c,.                       .                            //
//                                      ':.                              ,l:'.                     .,;.                           //
//                                      ;l.                             .ll;..                    .;l;.                           //
//                                     .cd'                     .'..    cxc,..                    ,oc'                            //
//                                     'od'                     :c'.   ,xd;'.                    .:c,.                            //
//                                    .:xo.                    ,ko.   .okl,..                    ;l:'.                            //
//                                    .lkd'           .       .d0c    ;kxc'...                  .:c;.                             //
//                                    ,xko'.  ..     .,.     .o00c   .okd:'...                  'c:,.                             //
//                                   .cOx:'.. 'l'   .;,     .oO0Kl.  ;dxo;..'.       ..        .;c;'.                             //
//                                   .dOxc,'. ,kc  .:c'    .lO00Ko'.,oxxo:..'.      ';.        'oc,.                              //
//                                   ;kOdc,,..o0l..co;'.   ;k0000xlldkxdd:..'.     'd;        .cd:,.                              //
//                                  .cOOxl;,.:O0:.:xo,...,lk00OOOOOOOxxxd:..'.    .dx,'.      'do:,.                              //
//                                  .lOkxoc,:kKOlckk:.'okO000OO00000kkOxl,..'.   'lOxol:.    .cxl:,.                              //
//                                  .oOOdlclk0OxxOko;.cO000OOO0KK0OkkOOxl,.....,oOOOOOd:.    ,dxl;.                               //
//                                  ,dkOkl;cllodkOxc,;okkkxkOKKK0Okk0Kkdo;'..;k00OOO0kl:.   .lkdc,.                               //
//                                 .:xO00Ol;:oxkOOxc;cdxkkO00KKK0OO0K0xdlc;'.ckO00000x:;,';cokkd;..                               //
//                                 .ckO0000x::dkO0OxoldkkO000KKOkO0KX0xollc,;lkOOkk00d;:x00OkOkl,..                               //
//                                 .lk0K0O00klcdkO0OxodkO0O0KKOkk0KKKOxocoo:cldkkk00xc,:k0xdk0kc,..                               //
//                                 ;dkO000O00OxooxOOkxdod0K00OkkO0KK0xxdldxddxxkOO00xlcokkkO0Oo;'..                               //
//                               .:oxOOOOO00000kddkOOOxoodkOOOOO0KK0kdxxxkOO00OO0000OkkkOOKOxl;'...                               //
//                             .;ldxxxkkOOO00K000kxkkOkddxkkO0K0000OkkOO000000K0000OOxxxdol::c:'...                               //
//                           .;loodddddxxxkkOO00000OOkOOkkxkO0000OOOO00000OOkkkkxdollllllcclol;',:.                               //
//                         .;lddooodooodxxxxxdxxkkOOOOOkkOOOkOOOOkkkkkkxxxxxxdxxxxxkkxxxxxdddolcl:'..                             //
//                       .'cddddddddooooddxxxxddddxxxxxxxxxkkOOOOOOOkxxkkkkkOOOkkkkkkxxxxdddolc:;'..'.                            //
//                      .:oddddoddddooooddddodddddxdddddddxxdxxxdddddoooddddddddddddddolc:;''........'.                           //
//                    .,ldddddoodddddolc:colcloddddoddxxxxxddxxxxxxdddxxxxxdxxxdlc::,..      ....  ...'.                          //
//                   .:lddxdddddooccc:'..',,':odxdddddolc:;::ccllooddddddolc::;,...                   .'.                         //
//                  .;loxxddol:;:cc;'.....,;cooddddol:,.......';codddol:;'......                       ...                        //
//                  'lddxxdxdl,.........,clooooddl;'...  ...;cclc:;;,'.......                          ....                       //
//                 .:dxxdxxxoc;'.......,cdxdddoc;..     ..;llc;'...........                  ..         ....                      //
//                 ,oxxxxkxoc;,'......';ldddooc;..   ....:lc'............                   .....        .''.                     //
//                .ldxxkkxdoc:;'...':lccoolllolc,.....,',;,..........                      ...',.''.     ..,,                     //
//                ,oxkkkxddoc::cccldxxddddolc:;,'....,;'.  ...... ....                    ...',,,::.     ..,;'                    //
//               .cxkkxdooolclodxxkxxdodoc;;''...........       ........ ..                 ..',,;,'.     .,:;.                   //
//              .:dxxxdooddolodxkkxxddddl;'''..............    .............                  ..,',;.     .'::.                   //
//              .lkkxdddxkkxooxkkxxxlcclc;'''................................                  .,'''..    ..:l,                   //
//              ;xOkxdddxOOkxxxxxxdl:ccc:;,,,''...'''...''';,...',,,'.... ..             ...........    ...';l;                   //
//             .lkOOxdxxOOOkkxxxxxolloolllllc::;;;:::;,''',lc'.':cc:'...            ..........''....   ..,;,,c;                   //
//             .ckOOOkkkOOxxxkkkkxxxdddoddxxxkkxxddddoool::ll;..;llc;;.     ....',;::::;,'....''........,lo:,;;.                  //
//              ;xO0Okkk0koloxkxxxxddxxO00KXNNWNNNXK0Oxxxxkko,..,;;;,.    .;cloodxxkxxxdoool:;''.......,cldo:cl'                  //
//              .oO0OOOO0Oko::ldxxdold0NNNNNNNNNNNNNWN0xddxo;;;;;;,'.    .:ooddkO00KKK00kxxxxxoc:;;;;;;:;:lo:co'                  //
//               ,x00OOOddk0kc;clolco0NNNNNNNNNNNNNNNNNXOxxkxdol;;:,...,;cook0KXNNNNNNNNNXKOxdddd:,clccddooc:cc.                  //
//                'x00OOkxO0klcccc:l0WNNNNNNNNNNNNNNNNNNN0xxxdxo'.,;;,:clodkXNNNNNNNNNNNNNNNKkdolccc;'lKXKOdlo;                   //
//                 :kOkkxdOOoclc;;;dXWNNNNNNNNNNNNNNNNNNNKxooloc.....,coxxOXNNNNNNNNNNNNNNNWNXKkdlc:,;cx0KKKOl.                   //
//                  ,oocllkOocc:;:,lKWNNNNNNNNNNNNNNNNNNWXkoll:'.   .;oddkXWNNNNNNNNNNNNNNNNNNXKkl;::::cokkl'.                    //
//                   'dOxlxKxc:ccc;;xXNNNNNNNNNNNNNNNNNNN0o::;'..   ..:clONWNNNNNNNNNNNNNNNNNNX0o'.'''':dxc.                      //
//                    ;k0kO0xlcool:';xXNNNNNNNNNNNNNNNNWNx:;,,'..    .':o0WNNNNNNNNNNNNNNNNNNXOl'..'''',:o,                       //
//                    .xX0xdlcccloc;,,lkKNNNNNNNNNNNNNWXkc;;,'...     .,cxXNNNNNNNNNNNNNNNNNKx:...,,,..':c'                       //
//                     oXklllcllclcc:;,,:oxkO00K000OOOxl:;;,.....      .'cONNNNNNNNNNNNNNNX0o,...,;'',.':,.                       //
//                     l0xooolllcccc::;;,,,,,,,,,,,,,,,,;:;'......     ..'cxOKXNNNNNNXKOkdc'...'clc:oko;.                         //
//                    .d0xk0kdxddoolc:ccc::;;,'',,;;;;::;;,....;cc:,.    ...';::;:::;,'..   ..:odlcdOkl.                          //
//                    .xOdk00OOOkkxdllccccccc::;;;;:::c:;'..'cx0XNNKd.    ......           .,okxlcdxl'                            //
//                    .cddOOKX0ddkOOdlccclcc::cc:;;;;::,'..:kNNNNWWWNd.     ............'.':dOkdxO0d'                             //
//                     ,lxOO0XNKxxkxxolcclllcc:cc:;;;,,,:lxKNWNNNNNNNXd'.     .....,cllllloxxkO000kc.                             //
//                     .:dOO0XNNXKOOkxolcccccccc:;,,,':kXNWNNNNNNNNNNWNOl;.   ...,cdxxdooooodOKXKkc.                              //
//                      ,ok0XNNXXXKK0kxdoccc:;;,'',,,c0WNNWNNNNNNNNNNNWNKOc.  ..,cxkkkxddddxOKK0d,                                //
//                      'dx0XWNNXXXXXX0Okdolccclllddd0NNNWWNNNNNNNNNNNWWWXo.. .'cdkxxxxxxxxO0KOc.                                 //
//                      ,xk0XNNNNNXX0OkdddolodddodkxoxKKXNNNNNWWNNNNNNNNXOc.. .;dkOOxddxxkkOOkc.                                  //
//                      'dkO0XXXXNXXK0OkddlcldxxdllllokKK00KKKXXKKKKKKK0kd:'...'lkkxolloddxxxd;                                   //
//                      .dOxO000KXXXKK0OkocllodollllcdOkdxxkkxdxkkxxddooc:;'....;cc:,,,;:ldxxdc.                                  //
//                      .oOkOOO00KXXKK0Okdoolldo:coccxOdcloolcllooool:::,..............,codxkx:                                   //
//                       .:dO000KKXXKKKOkxdooloxoccccokko:;c:;cooddoc::;'..........';cloxxxkOo.                                   //
//                        .ck0KKKKXXXKK0Oxdddddoxdc::ldxdlcolcllcclll:;;;,,,'...'',;lkkkkkkkx,                                    //
//                         .l0XXKKXXXXXK0OkxxkkdxOOOkO000KKXXKK0kxdollllc:;;;,,coc:coxxkkOOk;                                     //
//                          .:OXXKKXXKKKKKXK000KXXXNNXXKXXXXKKKXXK00KXXKOdlcccokOkodxxk00Okc.                                     //
//                            ;ONNXXKKKKXXKK0OxkOkoodolclolc:c:lxl::cxOkxxkOxxOOkOOOOO00Okd'                                      //
//                             ,ONWNXKKKXXKKKOddkxlcll:::::;'',ll;',;ox:..;lxOOOOO0OOOOOOOk;                                      //
//                              ,ONWNXKKKKKKKkxxdxxooooolcllccoxo:;;:dko,';:ok0K0OkxxkOOkd;.                                      //
//                               'xXWNK0OkkO0kkOOO0OO00OOkxxddxkxooodxkxolldkkOOxddxkOxl'.                                        //
//                                .lKNX0Okxk0OO0000KXXXXXXKKKKKKOOkkkOxddodxxxdddxOOkc'                                           //
//                                  ;OXXK0OO0OkkO00KKKXXXXXXXXXKKKK000OkxxxxdoodOOxc.                                             //
//                                   .:xKKKKKKOxxxdxxkO0KKOO0kollooooxOkxxdlcok0x:.                                               //
//                                     .cOXXXKK0OxdoooddkxxOd:'...',:lodlccokko,.                                                 //
//                                       ;0NNNNXXK0Okdddxkxoc,......',;;:dkxc.                                                    //
//                                        cKWWWNNNNXK0O000Okxdlc:;,,,:lx0Oc.                                                      //
//                                        .dNMWWNNNNNNXXXXXXK00000OO0KKOl.                                                        //
//                                         :KWWWWWWNNNNNWWWWWNNNNNNNXkc.                                                          //
//                                         ,OWWWWWWWNNNNNWWWWWWWWWNKl.                                                            //
//                                         ,OWWWWWWWNXXXXXXXXNNWWKOo.                          ..',..                             //
//                                        .cKWWWWWWWNNXKKK000KXNN0x;           .;:c:;..    ':ok0KXXKk:.                           //
//                                        ,0WWWWWWWWNXXKKK0OO0KXNKk:         .l0XNNNXKkl;ckKNNNNNNNNN0;                           //
//                                       .oNMMMMWWWWWXK0000OO0KXNX0c         cXNNNNNNNNNXNNNNNNNNNNNN0:                           //
//                                       .dNWMMMWWWWWKkxxxxxdx0XNOo,         oXNNNNNNNNNNNNNNNNNNNNNXd.                           //
//                                        lXWWMMMWWWNKOxdl:;;lkK0c.          ;0NNNNNNNNNNNNNNNNNNNNXx.                            //
//                                        ;0NWWWWWWWNXKOxddodk0Xk'            cKNNNNNNNNNNNNNNNNNNXx'                             //
//                                        .dXWWWWWWWXK00kkk0KXNXx.             :ONNNNNNNNNNNNNNNNXd.                              //
//                                         :KWWWWWWWXOkxdllxOXNKl.              'dXNNNNNNNNNNNNNXd.                               //
//                                         ;0WWWWWWNKOkxxoccd0XO,                .:ONNNNNNNNNNNKl.                                //
//                                         :KNWWWWNNX0kkko:,;lOk'                  'dKNNNNNNNXO;                                  //
//                                         lXNWWWWNNNXK0ko:;;o00:                   .:OXNNNNXx'                                   //
//                                        .dNNNNNNNXKKKKOxoox0XXd.                    .l0NNNO,                                    //
//                                        :0NWWNNNNKOkkxdxk0KNNNx.                      .:lc'                                     //
//                                       'xXWWWWWNNX0kxl;;cd0NNNx.                                                                //
//                                      .oKNNNWWNNNNXXKxc;;lkXWNx.                                                                //
//                                      ;kKK00KXNNNWWNX0xlcokXWNk'                                                                //
//                                      'ddccdk0KNWWNK0kdoodOXWN0;.                                                               //
//                                      @darkwheelNFT*@rickkitagawa                                                               //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RK666 is ERC721Creator {
    constructor() ERC721Creator("Inner Monsters", "RK666") {}
}