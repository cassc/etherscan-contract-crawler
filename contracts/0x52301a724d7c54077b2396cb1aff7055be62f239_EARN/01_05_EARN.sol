// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by Aaron Ricketts
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    dddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddddd    //
//    dddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddd    //
//    ddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddd    //
//    ddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddd    //
//    ddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddd    //
//    ddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddxdddddd    //
//    ddddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddd    //
//    xxddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddd    //
//    xxxxdddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddd    //
//    xxxxxddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddddddd    //
//    xxxxxddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddddddddxxxxxxxxxxxxxxxxxxxxxxxxdddddxxxxxxxxxxxxxxdddddddddd    //
//    xxxxxxddxxxxxddddddddxxxxxxxxxxxxxxxxxxxxddoool:,:cccc::cllclldddxxxxxxxxxxxxxxxxxxxxxxxxxdddddddddddxxxxxxxxxdddddddddd    //
//    xxxxxxxxxxxxxxddddddxxxxxxxxxxxxxxxxddol:'.....              ...',:oddxxdxxxxxxxxxxxxxxxxddddddddddxxxxxxxxxxddddddddddd    //
//    xxxxxxxxxxxxxxxxdddxxxxxxxxxxxxxdl;,'..                            ..';oxxxxxxxxdxxxxxxxddddddddddxxxxxxxddddddddddddddd    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd;..                                     .:ldxddxddddddddddddddddddxxxxxxddddddddddddddddd    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxd;                                          .,odddddddddddddddddddddxxxxxxddddddddddddddddd    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxo.   .                                        .'ldddddddddddddddddddddddddddddddddddddddddd    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxo' .coc;'..                                     .cddddddddddddddddddddddddddddddddddddddddd    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxo;.;dOOdc'..                                      .:oddddddddddddddddddddddddddddddddddddddd    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxc',oO0Okl,..                                        .cdddddddddddddddddddddddddddddddddddddoo    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxdc,cx000xc,...                                         'lddddddddddddddddddddddddddddddddddoooo    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxc,lk0K0ko,....                                          .lddddddddddddddddddddddddddddddooooooo    //
//    kxxxxxxxxxxxxxxxxkxxxxxd:,lO000OOx:...                                           .:dddddddddddddddddddddddddddddddoooooo    //
//    kkkxxxxxxxxxxxxxxxxxkxl::dO00000Od;....                                           .cddddddddddddddddddddddddddddoooooooo    //
//    kkkxxxxxkkkkkkkxxxxkx:.;dO00Oxdc,...                                               ,oddddddddddddddddddddddddddooooooooo    //
//    kkkkkkkkkkkkkkkkkxxxx:..':ll:,'..........                                          .lddddddddddddddddddddddddddooooooooo    //
//    kkkkkkkkkkkkkkkkkxkkxc......................                                       .cdddddddddddddddddddddddddoooooooooo    //
//    kkkkkkkkkkkkkkkkkkxkx:.....'......  ..    ......                                   .:oddddddddddddddddddddddoooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkdld:.;:..... .;d:.    ........                                .:odddddddddddddddddddooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkxl:cc;........:l;'..   ........                               .:ddddddddddddddddoooooooooooooodddoo    //
//    kkkkkkkkkkkkkkkkxkkxkkocc,...........................                              'ldddddddddddddoooooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkko,.............................                            'lddddddddddddoooooooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkxkOd,...............................                          .cdddddddddoooooooooooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkOd;.................................                        'codddddddoooooooooooooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkdc,...................................                      ,odddddddddoooooooooooooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkxl;...................................                     .cddddddddddooooooooooooooooooollllllloooo    //
//    kkkkkkkkkkkkkkkkkkkxkxoc;.................................      ...          .;odddddddddoooooooooooooollooolllllllllloo    //
//    kkkkkkkkkkkkkkkkkkkkkdood;.................................                  ;odddddddddoooooooooooooolllllllllllllllloo    //
//    kkkkkkkkkkkkkkkkkkkkdlc:;..................................                .;oddddddddddoooooooooooolllllllllllllllllloo    //
//    kkkkkkkkkkkkkkkkkkkkd:..      ............................                .cdddddddddoooooooooooollllllllllllllllllllloo    //
//    kkkkkkkkkkkkkkkkkkkkkxo;'..     ........................                .,ldddddddddooooooooooooollllllllllllllloooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkkkxc'.    .......................                 ;oddddddddddooooooooooooooollllllllooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkl,'..............................                 ,loddddddddoooooooooooooooollllllooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkd:''..........................                    .;oddddddddooooooooooooooooolllloooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkxolc;.....................                      .;oxxoccloddoooooooooooooooooooooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkkl,'.....................                     'cxkkkxo' ..;loooooooooooooooooooooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkkdc'..................                     .,okOOOkkkxc    'cooooooooooooooooooooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkdlc::;;:::lodc.....            ..  .  .;dO0O00Okkko,     'loooooooooooooooooooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxd;......... ........ ..'cx00O000OOkd:.       ,looooooooooooooooooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkko;.................:dkO000000OOOx:.          ,loooooddooooooooooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxd;............:oOKK00000000Oko'...         .cdoddddddoooooooooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdk0l.........;oOKKKKKKK00000Od:............   'cooooooooooooooooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddollx0l......,lx0KKKKKKKKKK00Oxc'............      .;loooodooooooooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxoccccllco0Kl. .'cx0KKKKKKKKKKKK000d;............  ..     ..;loooooooooooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkxo;,:ccll::xXXO:'cOKXKKKXXKKKKKK0KKOd;'''.........  ....  ......;loooooooooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkxl,;ccclc;'cOdcx00XXKKKKKKKKKKKKKKKOo:;,','.''...   ..............':loooooooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkxc,cllllc;..ll..dXKXXXKKKKKKKKKKK0Oxc;;;,','',,..   .................'cooooooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkxl;cdoccc:. ;:.  ;OXKKXKKKKKKKKKKOoc::;,;;,....   ......................,looooooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkkkxo:cool:cc. .'.    :0XXKXXKKKKKK0xlcc:;;;;;;.  ..''''''''''''..............:looooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkkkkkkkkkd:coolccc;.         lKXXXXXKKKK0dcc:;;;,';::;..',,'',,''',,,''..............,loooooooooooooooooo    //
//    kkkkkkkkkkkkkkkkxxkxxkkxlcooolll:. ..       :0XXXKKKKKOdc::::;;,.':::;...,',,,',;:;;,'...............'cooooooooooooooool    //
//    kkkkkkkkkkkkkkkkxxxxxkxoclddoolc,..,.      ,xKKXKKKKKkl:::;;;::;,,;:::'..',,,,,;:::;''.................;ooooooooooooooll    //
//    kkkkkkxxxxxxxxxxxxxxxxdllodddol,. ,;   .,''d0KKKKKK0xl::;::::::ccccc;'..';;;,;;:::;,''................ .,looooooooooooll    //
//    kkxxxxxxxxxxxxxxxxxxkxollooddl:' .o,   :xlo0KKKKKK0xl::;::c::ccccc:'...,;:::::::::;;,''''''''''.......  .'loooooooooooll    //
//    xxxxxxxxxxxxxxxxxxxxkxollooddl;..cd.  .xklxKKKKXK0xc:::::cccccclc,..,;;;:c:::c::::;:;;,,,,,,,,'......... .'looooooooooll    //
//    xxxxxxxxxxxxxxxxxxxxxdollloooc'..do.  :kllOKKKKK0dc:::::ccccclc;..,:::::clllllccc:c:;;;;;::;,''............'loooooooooll    //
//    xxxxxxxxxxxxxxxxxxxxxdoollool;. ,k:   ,,;x0KKKXOdl:::::clllllc'.':cccccclloolllccccc::::::;,'...............,looooooolll    //
//    xxxxxxxxxxxxxxxxxxxxdollloooc'..lx.    .l0KKKKOdlccc:cclllc;'..,cllllllloooolllllcclcc::;,,'.................,ooooooolll    //
//    xxxxxxxxxxxxxxxxxxxxolcccool;. 'xl.    ,kKKKKOocclcccclll:,..':lllllllloooolccccllc:::;;,,,'..................:oooolllll    //
//    xxxxxxxxxxxxxxxxxxxdolc:cooc,. cd'.   .lKKKKOocccccccccl;..;cllllllllloooolcclllllc:;;,,,,,'...................:ooooolll    //
//    xxxxxxxxxxxxxxxxxxxdolc:looc'..l:..   .xKKKkoccccccccc:'.,lollolllooooooollcllolc::c;,,,,,,'''.................'coolllll    //
//    xxxxxxxxxxxxxxxxxxdocccclol;. ,c'..   ;OKKkoccccllclc,.':oolllloooooddooolllloocc::c;,,,,,,,'...................,loollol    //
//    xxxxxxxxxxxxxxxxxxoc:cclool,. ;:;l;  .oK0xollclllll:'.,looooooooooooooodolllodoc:::::;;;,,,,''...................:oollll    //
//    dddddddddxxxxxxxxxo:;:clool;..;cxk'  'k0xllllclllc,.':loooloooolllllooodooooool::;;;;;;;,,,,'''..................'collll    //
//    ddddddddddddxxxxxxo:,:clool; .:d0x.  ,Oxlllccllcc,.;lllooolllllcc::llooollllllc:;;;;;,;;,,,''''...................:lllll    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EARN is ERC1155Creator {
    constructor() ERC1155Creator() {}
}