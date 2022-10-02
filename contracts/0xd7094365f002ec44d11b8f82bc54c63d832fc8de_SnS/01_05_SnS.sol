// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Skulls & Stones Physical Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//    00OOO0OOO00OO000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkOOkkkOOOkkOOOkkOOkkkkkdc:lxOkkkOOOkk    //
//    0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkOkOOOOOkkkOOOOkkkkkOOkkkkkkkxlc,.  .lOkOOkkkkO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkOOkkkOOOOOOOOOkkkkkOOkkkkkkkxl,.       'dOkOkkkOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOOOOOOOOOOkkkkkkkkkOOOOOkkkkkkOkkkkkOko:.           'dOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkOOOOOOOkOOOOOOOOOOOkkkkOOkkOOOOOkkkOkkkkkkkkkd:'               .okOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkOOOOOkkkkOkkOkkOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkko,.                  .cxOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkOkkkkOkOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxc'                       .ckOO    //
//    OOOOOOOOOkOOOOOOOOOOOkxoc;,,',;;:::cllodddddolllllodddxxxkkkkkkkkkkkkxkkkOOkkd:.                           'ok    //
//    OOOOOOOOOOOOOOOOOOxo:'. ..',''..............        ......',;;:lxkkOd,'lkOkd;.                              .x    //
//    OOOOOkOOOOOOOdlll;.  .;ldkkOOkkkkkxddollccclllloolccc:;;;,'..   'lxkx: .:l,.                                .o    //
//    OOOOkkkOOkkOk;     ,lkOOOkOOkkkkkkkkkOkkOkOOOkOkkkkOOOOkOkkkxo;.  'lkk:                                  .'cdO    //
//    OkOOOOOOOOOx;.     .'ckOOOkkkkkkkkkkOOkkkkOOOkkkkOOOkkOOOkkkkkkd;.  .''.  .                            .:dOOOO    //
//    OOOOOOOOOd:.          .;okOkkkkkkkOOOOkkOOOOOkkkOOkkkOOOOOOOOOxo:.     ,:.                          .,lkOOOOOO    //
//    OOOOOOOxc. ...           ':dkOkkOOOkkkOOOOOOOkkOOOOkkOOOOkdl:,.        ;xl.                       'cxOOOOOOOOO    //
//    OOOOOOd'  ,l,              .;okOOOOkOOOOOOOOkOOOOOOkdl:;,..             ,xd.                   .:dOOOOOOOOOOOO    //
//    OOOOOo. .:k:                  'cxOOOOOOOOOOOOOkdl:,..                ,'  ;kd.               .:dO0OOOOOOOOOOOOO    //
//    OOOOo. .cOd.               ..   .:okOOOOOkdl:,..                    .ox'  ;kx'          .,cdO0OOOOO0OOOOOOOOOO    //
//    OOOd' .cO0o.              .c'     .,ldo:,..                        .cOOx'  :Ox'      .,lx0000OO0O00OOO0OOOOOOO    //
//    OOk,  ;k00k'             'c'                                       ,kOOOd. .cOd.   'lk00OO000OOOOOOOOOOOOOOOOO    //
//    OOl. .d0OOOd.          .;l,          ..                           .lOOOO0d.  cOx'  ;O000000OO00OOOOOOOOOOOOOOO    //
//    0k,  :O0O000d'        .od'          ;xk:.                        .oOOO00O0o. .l0x:.:k0O0OOOOOOOOOOOOOOOOOOOOOO    //
//    0x. .o0000000x:.      .;'        .;oOO0Oo,.                     ;xOO0O0000O:  'x0OOO0OOOO0OOOOOOOOOOOOOOOOOOOO    //
//    0d. .d000000000kl;'...    ...,:ldkkxk00Okkkoc;'.           ..':dO00000000O0x'  :O0O000OOOO000OOOOOOOOOOOOOOOOO    //
//    0o. 'x0000000000000kxxdooddxO000Ol..:Od'.,k000Okdlcc:::::lodkO00000000000O00c  .d0O00OOOO000OOOOOOOOOOOOOOOOOO    //
//    0l. 'k000000000000000O0000OOO0000d. .xl  ,O000000000000000OOO0000000000000O0d.  l0O0OOOOOOOOOO0OOOOOOOOOOOOOOO    //
//    0l. 'k0000000000000000000000000O0Oo;cko..d000000000000OOOOO0000OOO0000000000k,  ;O0OOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0o. .x0000000000000000000000000O000000Oxk00000000000000000000O0O0000000OOOO0O;  ,k0OOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    Kx. .o000000000000000000000000000000000000000OO00000000000000000O000000OOOOOO:  'k0OOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    Kk' .o000000000000000000000000000000000000000O00000000000OO00OO0OO000OOOOOOOO:  .x0OOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    KO;  :0000000000000000000000000000000000000000000000000O00O000OO000OOOOOOOOOO;  'x0OOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    00l. 'kK00000000000000000000000000000000000O000000OOO0OO00OO0OOOOOOOOOOOOOOOx'  ;kOOOOOOOOOOOOOOOOOOOOOOOkOOOO    //
//    0Kd. .d00000000000000000000000000000000000000000OOOO00000OOOOOOOOOOOOOOOOOOOl. .oOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0KO;  ;O00000000000000000000000000000000OOO000OOOOOO000O00OOOOOOOOOOOOOOOOOd'  ,kOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000d.  :O0000000000000000000000000000000O000OOOOOOOO000OOOOOOOOOOOOOOOOOOOx,  .oOOOOOOOOOOOOOkOOOOOOkkOOOOOOOO    //
//    0000d. .:k000000000000000000000000000OOOO00OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd.  .lkOOOkkOOkOOOOOkOOOOOOOOOOOOOOOO    //
//    00000o.  .oO00000O00000000O0000O00000OOOOOOOOOOOOOO0OOOOOOOOOOOOOOOOOOOkl.  'oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000kc. .,ok000000O00000000OO00OOOOOOOOOOOOOOOOO0OOOOOOOOOOOOOOOOOkxl'   ;kOOOOOOOOkOOOOOOOOOOOOOOOOOOOOOOOO    //
//    00000000x:.  .:lxO0OO00OO00OOOOO00OOOOOOOOOOxlcdOOOkkkOOOOOOOOOxdoc;..   'okOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0000000000ko;.  .':oxkOkkxl,.,lxxd;.;x0OOO0k,  ;kOOo...'',,,,'..    ..,:okOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0000000000000kdc,.  ......    .:l,  .l0OOO0x.  cOO0d.   ..   ...';:odxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    00000000000000000kdl:,',;:ld, .;l:.  c00OO0x' .o0O0d. .:oxdddxkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000000000000O: .:lc,  ;O00O0O; .o0O0o. 'oxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    00000000000000000000000OOO0k; .cll:. ,k0OO0O; .o0O0d. 'ox0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000O000O0000x' .lllc. .x0O00O:  cOO0x' .;d0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000O000000O0d. 'olll' .l00000o. ;O00k' .'o0OOOOOOOOOOOOOOOOOOOOOOOOOOOOO00OOOOOOOOOOOOOOOOOOOOO    //
//    00000000000000000O0000000O0o. ,ddoo,  ,llcc:,. .,;;,.  .l0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000000000000o. .,'...   .......  .'....,cx0OOOOOOOOOOOOOOOO0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000000OOO000d. .';clooodxxkkOOkddkOOkkOO0OOO00OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000Oxc::cldkkocx000000000000000000000OOOOOO00OOOOOO0OOOOO00OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000x;''','';:ldO000000000000OOO000OOOOO0000Okkxoc:clxOOOOOOO00OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000x:'',,,'''',:loxO00000000OO0000Okxxdlllc:;,''''''lO0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0000000K0000000000kc'',,''''''''',:clddoccodddolc:;,,''..'''''.''',oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0000000K0000000000x;'',''''''''''''..'''.'''''''''''''''''''...''',o0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000o,'''''''''''''''''''.''''''''''''''.........''';x0O00OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000d;'',,,'''''''',,,:::,'''''''''''.'''.......''''ck0000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000x;''',,;:cloddxxxkOOOxdoodol:,'''''''...''''''';d0O00OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    00K000000000000000Odl::ldkO000000000000000000OOxoc:,''..'''''''''cO0O0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0000K0000000000000000OO000000000000000000000000000Oxol:;,''''''''ck0OOOOO0O000OO00OOOOOOOO00OOOOOOOOOOOOOOOOOO    //
//    000K0000000000000000000000000000000O00000O00000000O000OOkdl:;;:;:oO0OO00OOOOO00OO0OOOOOOOO00OOOOOOOOOOOOOOOOOO    //
//    0000000000000000000000000000000000000000OO00000OO0000000000Oxxkkk00000OOOOO00OOO00OOOOOO00OOOOOOOOOOOOOOOOOOOO    //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SnS is ERC721Creator {
    constructor() ERC721Creator("Skulls & Stones Physical Collection", "SnS") {}
}