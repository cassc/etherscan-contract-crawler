// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ANTHOLOGY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//    oooooooooddxxxxxxxxxdoloollllllllllllllllllllllllllllllllllllldxoc::ldxxxxolllllllllllllllllllllc,'''..';:,,oO    //
//    llloooldxxxxxxxxxxxxxdllllllllllllcclllll:',clllllllllllllllloxx;.,clodxxxollllllllllllllllllllllc::,.'ldoo,cO    //
//    lldxxc.;xxxxxxxxxxxxxxdllllllllllo:.';::;..,lllllllllllllllllodxo:;;;;:oxdlclllllllllllllllllllooool;.:k:,o::k    //
//    ::oxkx,.cxxxxxxxxxxxxxxdlllllll:col,......;lllllllllllccc:;,,,,,'',;::cllc:;;,;:cllllllllllllllxl:do;,dx';x::k    //
//    ,.;dOOo..oxxxxxxxxxxxxxxdllllll:,;::::::lodoodool:;'..........'''''.........';;;;;:ccclllllllllxo,oklokc.ok;;x    //
//    ;''lO0x'.:xxxxxxxxxxxxxxxollllllc:;;:ldkkdlc::;'...'';cllodxkOO0OOOOOkxdoc;.  .':cc:,',,;:clllldkc,ldo;'cOd';x    //
//    c,.;x0Oc.'dkxxxxxxxxxxxxxxollllllldxkxl;,'.....'';codl::clodxOOxox000000000ko,.  .cxxl,..',;clllxko:''ckOo,.:x    //
//    l;''oOOd..cxxxxxxxxxxxxxxxdoloodxdoc,..;:;,..   ....,,..  ':cllcoO000000000000x:.  .:dxdc'..':cllx0O,:0Oc'..:x    //
//    lc,.ck0kc.'dkxxxxxxxxxxxxxxdokOxc.   .c:.            .,;,..'cdkO00000000000000K0kc.  .,oxc'..',:lokO,.kO:...;x    //
//    ll;.,d0Oo..lkxxxkxxlcoxxxdxkxo,.    .:,.               ...   .,cxO00000000000kk0K0Oo;.  ;o:....',;oO:.l0o'..;d    //
//    ol:''lO0d. :xkxo:'.,cdddodko'      .:,        .. ..             .,lxO00000000kclOK0K0d'  ,c,......:Ol.cKk;..;d    //
//    ol:'.:k0k, 'l:'..,cddoloxd;      ..,c.       .'   ..               .;ok0000000o,cO0000d. .:l,....'cOo.:00l'.;x    //
//    loc,.;x0k,  ..;looolllodc.       ..'.       ...    ..                 .ck0000x;.:k00000o. .:c'....:Ox.,OKo'.;x    //
//    dxl;.,d0Oo;:lol:;:llloo,                            ..                 .'cx00kc:;,cok000d. .;,....;kk.'kKx,.:x    //
//    ool:''o0Okxo:;;clooodo'                                               ,l:,;:ox:cxodO000K0l. .cc,..'dk,.dKk;.:k    //
//    lllc''cxo:;;:clllodOx,                                      ..',,;:;. ,o;.'.';;lO0000000KO:  ,xl'''oO;.lKO:.:k    //
//    llll;',;;;:llllodk0k:          .                ..             ..',ll..oo.   .:k000000000Kk,  ,oxl,o0l.;00l.;x    //
//    llllc::cllllloxOOo;.       .,lddc.              .::.               .;c:c,      ,x0000000000k;  .xOoo0x.,O0o';x    //
//    ooxxddddolloxOOl.       .cdkxdddxo.     .;;,.    .:o;.                          ,x0000000KKKk,  ,k00Kk,;OKd';x    //
//    ddk0000kolok0k,      .:xOkdodkKXN0;    'odxKk;     ,o:.                      '. .coodkO0OOkO0d.  :0KK0:,kKx,,d    //
//    ddk00KOdodO0k,     'lkkdodkKXXXXXO,   ,dodKXXKd'    'oc,.             'c;..'':l,,coxddxdxkkxkk:  'kK0Kl.oKk;'d    //
//    dox0K000O0K0c    'okxddOKXXXXXXXXx.  .xxckNXXXX0c.   .lxc.           .,ldc,.  ;:..cO000kxxOK00l. .xK0Kd.;0k;,x    //
//    xxk0K000K0Kk'  .lkxxkKXXXXXXXXX0o.   ;0oc0NXXXXXKl    .;l:.        .cc,..         'x000KOox000l. ,kK0Kk..k0ddO    //
//    k000000KK00o. 'xkxOKXXXXXK0koc,.     lKo:0NXXXXXXKo.    .c,        'o,            .lO000xdkOOd. .o0K0K0;.oKKK0    //
//    O0KKKKKK0K0c  .cokOOOkdl:'.          cXx:xXXXXXXXXXd.    ':.        ;l.            ;k000000kc. 'o0K0K0Ko.lK000    //
//    0K00KKKK000d'    ....                ,00clKNXXXXXXXXx.    .'         ,o;.          .cddxo:'. .:k000KK0Kk:dK000    //
//    KKKKKKKKK0K0koc,...........          .dXx:xXXXXXXXXXXx.    .          .:;'.           ..  ':ok0O0K0KK0KOoxKKK0    //
//    00KK000KKKK000kc;;::;:;;'.            'kKd:dKXXXXXXXXXd;.                              .;dO0K0xlk000K0K0OO0kO0    //
//    00K000KKKKKKK0x;.                      .o0kllOXXXXXXXXK0c                            .lk0K00Kk::oO00K00000Olo0    //
//    0K0dlOK0KK0000k:         .;'             .lxoclkKXXXXXK0l.                          ;k0KKK0KOc;cldOK0K000KO:cO    //
//    00Kd:xK0K0KK00kc.       .xKd. ,:.           .'..,loll:'.                    ''     .l00OO0K0o,;clld0KKOxOKk;;k    //
//    K0KOkOK0000KK0Od;.     .oXO;.,OXx.                                        '::.     .o00kk0Kk:,:ccldOKKd;dKk;,d    //
//    KK000O00oo0K0000kc.     ;c'  .dKx.                                       ;Ox'      .oKKOk0K0d;cl:lk00KxlxKx,'d    //
//    KK0KkdO0ddk0KK00Oo.           .,.                                        ;Ox.      .o000000K0o:::d0K0K000KOxdO    //
//    KKK000dokc'oxx00o'                                 .;,.       .',.       'kx.       ;OK00KK0KOocoOK0KK00O0KKKK    //
//    KKK0K0l;o;,:.'xo.                                  :Ok:,cl.  .c0Xxcol,..,d0d.        c0K0KKKKK0O00KK0K0dlx0K00    //
//    KKKKK0OOo.,:.;o,. ,l...                            ,k0xoOKl..'xXXK0XXK0KK0Ol.        .d000KKK000KKKK0KOc;d0K0K    //
//    0KKK000Kkldxoxc:o:d0cox'.,:.  .....      .coc;lxc. .dKXKXXOc':dKXKOOOOKXKx,.          :O00KK0KKKKKKK0Kk:;dOK00    //
//    00KK00000K0dlxc:o:x0lo0ll0Ko;lxxoxOo',codxOXXKKXO' .lKNXXXKkxkkxxo,...;:,.            ;dxkkO000KKK000KOlcdOK00    //
//    0KKKKKKK0KK00Oc:dOOxclkdldockK0xkKXk:cxKXXKKXX00O;..lkOkdodOXNKo'                    .:ooooodxxkkO000K0Oxk0K00    //
//    KKKKKKKKKKK0KkccodOOkkK0o,.:OOc,dXXx'.,o0XXXX0ocll:;:c;...cokXKo.                    .looooooooooddxxkOO00KKK0    //
//    0000KKKKKKK00xcc' .dOOKXKkxOKk:.:kx,.;l:l0XXXKl,oOc,lx;  .;'.;;.                    .,;,;;:ccllooooooooddxkkO0    //
//    000000000KK00xoc. .dkoONX00KXXd';xk,.dKl.;xKXKkdc.  lO;  .c,                       ..'''..'''',;::cllooooooood    //
//    0000000000000kxc  .oc.:kO0OOXN0oo0Ko;lkc  .,:;o0l   ;k;  .ox'   .....''............'..';:;,;::;'.''',,;:cclloo    //
//    0000000000000OOx,.;x;   ;kOl:ocldl:cx:.       :k:   .;.   ;x:..''''''...';;'..'''''...;lddodxdo:,'''..'';;,,,;    //
//    0000000000000000kdk0d.  .x0:   ,d' .d:        :x'        'dOxoc:,,,'''.,okl';lddxdc,''',;,,,,;;;;,''';oxkd;'''    //
//    000000000000000000000kl:lOOl,..,d: .dl.       lk'    .;cok00000Okkkxxdok0x;'ck0KK0Oxdddkkkxdolc:;;;;:d0KOl'.',    //
//    000000000000000000000000000kOOxk0Odx0d.      .ok' ..ck000000000000000KKKKd;.;x00000OxddxkOOO00OOkkxxxO00x:,,;:    //
//    0000000000000000000000000000000000000Oo;,'...;x0xoxO00000000000000000KKOkxc':k00Odc:;'';ldl:::::;;;,,cO00xc:::    //
//    000000000000000000000000000000000000000000OOO000Oxolllccccloddoxk000KKx;'''.';dko,'''',cxkl,''''',:l::lkOxc:::    //
//    000000000000000000000000000000000000000000000000xc:::;,';oxkkxdc;lOKKKOdc,....','',;::lxOx:'',,,;:ldoclooc::::    //
//    00000000000000000000000000000000000000000000000000Okxdolllllcc:;ckK0xddxl,':c;'',lxO0OOOOxooooddddolldO0Odc:::    //
//    00000000000000000000000000000000000000000000000000000000000OOkxk0KK0kxl;'.':ol,';okO00OOO0000KKKK00000000kl:::    //
//    0000000000000000000000000000000000000000OkxkkOO00000000OOOO00KKKKK0000Ol'....'''',lk0OOOxdxxxkkxddddxO0KOo::::    //
//    0000000000000000000000000000000000000KK00Okxddddxxkkkxdddddk0KKK0000000Ol;clccccccoxOOkocccclodoc::::ldxdl::::    //
//    0000000000000000000000000000000000000KKK0000Okddooooooooodk0Okk00000000KkldO00OOkxdxkOxlllokOkxdolcc::::::::::    //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ANTH is ERC721Creator {
    constructor() ERC721Creator("ANTHOLOGY", "ANTH") {}
}