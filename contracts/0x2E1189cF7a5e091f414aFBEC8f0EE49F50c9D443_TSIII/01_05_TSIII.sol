// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Thomas Stokes III
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                 ..'',;:::;;,'......                                                            //
//                                             .,cokO000K00Okxdc,''........                                                       //
//                                          .;ok0KK00000Oxl:,''.................                                                  //
//                                       .,oOKKKK000KK0d:...............;coddxxxxdc;'..                                           //
//                                     .;x0KKKKKKKKKKKd,.........    ..'dXXXXXXXXOd:'...                                          //
//                                   .,x0KKKKKKKKKKKKk:...',;lddl:,'. ..c0XXXXX0ko,......                                         //
//                                  .o0KKKKKKKKKKKKK0d'..,c:okxlccllloxk0KXXXKOd:.      ..                                        //
//                                 ,kKKKKKKKKKKKKKKKOo:;cdkO0000KXXNNNNNNNXKKOo;. .',,'''.                                        //
//                                ,kKKKKKKKKXKKKKKKKKK000KXXNNNNNNNNNNNNNNXK0x;.,cdxoccc:,.                                       //
//                               ,OKKKKKKKKXXKKKKKKKKXXXXKKKXXXXNNNNNNNXXXK0Oxox00x;.........                                     //
//                              'kXKKKKKKKKKKXXKKKKKKXXXXKK0KKKXXXXXXXXXXXK0KKXX0d'............                                   //
//                             .dKKKKKKKKXXXKXXKKXKKKXXXXKK00KKKXXXXXXXXXXKKXXKKd'.;lddc,'......                                  //
//                             c0KKKKKKXXXXXKKKKXXKKXXXXXKK00KKKXXXXXXXXXXXXKK0xloO00kc..........                                 //
//                            ,OXKXKKXXXXXXXXKXXXXXXXXXXXKKKKKKKXXXXXXXXXXXXK0OO0KK0kdloddol:;,''..                               //
//                           .dXKKKXXXXXXXXXXXXXXXXXXXXXXKKKKKKKXXXXXXXXXXXKKXXXKKK00KKKK0Oxolc::;;.                              //
//                           ;0XKKKKXXXXXXXXXXXKKXXXXXXXXXKKKKKKXXXXXXXXXXXXXXXKKKKKKKKKK0Oxocc:;,,'.                             //
//                          .dXKKXKKXXXXXXXXXXXKXXXXXXXXXXKKKKKKXXXXXXXXXXXXXXXKKKKKKKKKK0ko;'.......                             //
//                          ,OXKKXKKXKXXXXXKKKXKXXXXXXXXXXKKKKKKXXXXXXXXXXKKKXKKKKXXXXXKOo;..       .                             //
//                          :KXKKXKKKKXXXXXKKKKXXXXXXXXXXXKKKKKKXXXXXXXXXXXXXXXKKXXXXKkl,.............                            //
//                          lKXXXXXKXXXXXKXXXXXXXXXXXXXXXXXKKKKKKXXXXXXXXXXXXXKKXXX0kc'.......''......                            //
//                          oXXXXXXXXXXXKKKXXXKXXXXXXXXXXXXKKKKKKXXXXXXXXXXXXKKKKKkl'..',,;;;;;,,,....                            //
//                          lKXKXXXXXXKKKKKKKKKXXXXXXXXXXXXXKKKKKXXXXXXXXXXXXKK0kl;..';:c:c::cc;;,....                            //
//                          ;0XXXXKK00OOkkxx0KKXXXXXXXXXXXXXXKKKKXXXXXXXXXKKKOxl;,;,';cloloccol;:,.'..                            //
//                          .xXKKKOxoollokkkO0000KKKXXXXXXXXXKKKKKKXXXXKKKOxl:,,,cl,,coddddcldc::'',.                             //
//                           ,OKOxdollldO0KXKKKKK00OxOXXXXXXXKKKKKKKKK0kxoc:,;cc:oo;;lxkxkdldxc::''.                              //
//                           ;kkxk0OxkO0KXK000KXXKx:'lO00KKKKKK0OOkkxdolllooclxolxx::oOOkOxlxkc;;...                              //
//                          ;kOOKXOxO000K0000K0kl,...;lodxxkxxxdollloodxxxxxodOdlkkccd00kOxlxkc,,...                              //
//                         .o00XXXK0O00KKXXXKkl'...'coccoxxxdxOOOxddxkO00kkOxx0kokkccxK0kOdcxk:',...                              //
//                          c0KXXXXXXXXXXK0xc,.....;lxxdok00kkKXK0OOO00XKk0KOkKOdOOlckX0xOdcxk:',...                              //
//                          .,ok0KKKK0Oko:,........,cxO0kx0K0O0XKKK000KNKOOK0OK0kO0ockX0dOd:xOc.,...                              //
//                             .',,':x00o'........':lx0XKkkKKOOXKKXXK0KNXkkKK0KKO0KdckX0dOx:oOl','..                              //
//                                   .ckkl:;'.....'cdx0XX0xOXOkKXKXXXO0NXxkKXKXX00XdckXKxkk:lOd,,,..                              //
//                                     .,;;;;,,'..'cxkO0KKxkX0k0XKKXNOONXkkKXXXX00XxcxKKkkOllOk:;;'..                             //
//                                        ....''..,lxkO0KXOxKKk0XK0XN00XNOkKXXXXK0XOcdKXOk0dlkOo:c;'.                             //
//                                               .,dxkO0KX0kKKOKXK0XNK0XN0OKNXKXXOK0llOK0O0kox0d:cc,'.                            //
//                                                ;xkO00XX0OKXKXXKKXNK0XNK0XXX0KX00Ko:x00O0OxxOkc;c;'.                            //
//                                               .lkOO0KXX0kKXXNXXXXN0OKXXKKKKO0XK0Kx;lO0OO0kxOOl,::,..                           //
//                                              .ckOK00KKKkxKXNXXKKKKkdk000kxkdx00O0k:;dOkkOOkkOd;,:;'.                           //
//                                             .oO00KkOOOkco0KKK0000Od:cllc::c;:xkxxxc':dkxxOkkkx:',:'.                           //
//                                           .:x0OOOxllc:;':kKXXXKK0xl;;,,''''..,::cc:..:oddxxxxdc'';'.                           //
//                                       ..,cdkOOOOOdc;''''.:OKK0Oxdc:;,,''..............,;:cllll;..'..                           //
//                                ...',;;:ldxkO00KKK0Oo;'''..,oxdlc:;,,'''............................                            //
//                            ..';clloooooddxxxO00KKKKOd:'.....'''''''.............................''.                            //
//                         .,:lodxkkkkkkkkOOOOkkkkO00KK0x:'......................................;looc:'.                         //
//                        ,okkOOOOOOOOOOOOOOOOOOOkkkOO000x:..................................';cdkkxxxdol:'.                      //
//                       .d0O0000OOOOOOOOO00000000OOkkkkkxl;'..........................',:cldxkkkkkkkkxxxddl;.                    //
//                       .o00000000000000000000000000OOkxdc;,,,,'......''............:xOO00OOOOkkkkkkkkkkkxxxl,                   //
//                        'dO00000000000000000000000000000Okxdooollc:,':doc;'......'oO000000OOOOOOkkkkkkkkkkkkx,                  //
//                         .lO00000000000000000000000000000000000OOOkkdloO00Oko'..'d00000000000OOOOOOkkkkkkkkkO:                  //
//                           'oO00000000000000000000000000000000000000000OO0Kk;..'d0000000000000000OOOOOkkkkOOo.                  //
//                             'lk00000000000000000000000000000000000000000Okl;,:d0000000000000000000OOOOOOOx:.                   //
//                               .:k000000000000000000000000000000000000000000000000000000000000000000000Od:.                     //
//                                 'oO0000000000000000000000000000000000000000000000000000000000000000Oxl,.                       //
//                                  .cO000000000000000000000000000000000000000000000000000000000000ko:'.                          //
//                                   .cO000000000000000000000000000000000000000000000000000000Okdc,.                              //
//                                    ;O0000000000000000000000000000000000000000000000000kxoc;'.                                  //
//                                   .d0000000000000000000000000000000000000000000Oxdoc;'..                                       //
//                                  .o00000000000000000000000000000000000Okxdol:;,..                                              //
//                                  ,k00000000000000000000OOkkxdoollc:;;,...                                                      //
//                                  .lO0000OOOkxdollc::;;,'....                                                                   //
//                                   .,lolc:;,...                                                                                 //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TSIII is ERC721Creator {
    constructor() ERC721Creator("Thomas Stokes III", "TSIII") {}
}