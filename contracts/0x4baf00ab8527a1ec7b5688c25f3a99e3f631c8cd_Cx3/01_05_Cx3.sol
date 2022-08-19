// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: cowDAO Cowmunnity Cowllection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//    kkkkkOkOOOOOO0OO000000000000000000000000000000000000000000KK0000KK00000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0000000OOOOOkkkxxxx    //
//    OOOOO00O0000000000000000000000000000000KKKKK00KKKKKKKK000KKKKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKKKXXKKKKKKKKKKKKKKKKKK0000000OOOOOO    //
//    OOO0000000000000000000000000000KKK000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXKKKKKKKK00000000    //
//    0000KKKKK000KKKKKKKK0000OOOO00000KK00000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXKXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKK0    //
//    0KKKKKKKK0000KKKKK00Okxxxxkkkxxk000000000K000KKKKKKKKKKKKKKKKKKK00000KKKKKKKKKKKKKKKXXXKKXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKK    //
//    0KKKKKKK00000K00000OkOOkkkOOxdddxk00000000000KKKKKKKKKKKKKKKKKKK00K00KKKKKKKKKKKKKKKXXKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKK    //
//    0000KKKK0000KK0KK0KKKK00000Okxddddxxkxdoodk00KKKKKKKK0K00000000000K00KKKKKKKKKKKXXXKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXKXXXXXKKKKKK    //
//    0000KKKKKKKKKKKKKK0O000OOkkkkkxdolodo,.  ..,;:;cxOOOkxxxkkkxxxxkO0KKKKKKKKKKKKKKXXXXKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    0000KK00000KKKKK0OkkkOOko:;,,;:clclOO;.     .,collodooddxkkOOkkkkOKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    000000000000KKKKKKKKK00OOkdl:;,.'loxXKdc:cclxkkxolloodddkOO00K0KKKKKXKKKXXXXXXKKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    0000000KKKKKKKKKKKKKKKK0kdlllcldOXOoxlcoxo:'','','.''',;ccloxO00KKKKKKXXXXXXXXKKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKKKKKKKKKKKKKKKKKKKKKOo;,'',ld0Ko,,coodolc,.,cccllllododddkOkO0KKKXKXXXXXXXXKKKKKKKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKKKKKKKKKKKKKKKKKKKXKKK0xl;:ox0K:'lo:..:dd,.lxllxO0000KKKKKKK00XXKXXXXXXXXXXXKKKKKKKK0KKKKKKKKKKKKKKXXXXXXXKKXXXXXXXXXXXXX    //
//    KKKKKKKKKKK00KKKKKKKKKKKK0oldxOXXXO'.;lc,;ll;.lKk. .':oxO00KKXXXXXKXKKKKKXXXXXKKKKKKKKKKKKKKKKKK000000KKXXXXXXKXXXXXXXXXXXXXX    //
//    KKK0000KK00000KKKKKKKKKK0kokKXNXXXx. ..,,'...l0Xx.     .;dO0KKKK0000xl;,,cdk000Okkxdollccc::lOKK0000Ol,;cdOKXXXKXXXXXXXXXXXXX    //
//    KKKK0000000000000000K00kodOKXXXXXX0dc'     ,kKXXKo'...,o0XNXXNNNXXk;.      ........       'lkKXXXXXX0;    .;xKKKXXXXXXXXXXXXX    //
//    KK0000000000000000OO0Ol....dXXXX0dOXNx. .,cOKXXXXX0kxOKXXXXXXNNXXXx.                    'oOXXXKOxOKXKx'     .l0KKXXXXXKKXXXXX    //
//    KKKKK0000000000000Okkc.    cKXOl,'dXNKl'l0KKKXXXXXXXXXXXXXXXXXXXXXO,                    ,xKKKXO:.'kXXXk'     .o0KKKKKKKKXXXXX    //
//    KKKKKK0000000000ko:,;,.....:xdold0K0xOOxc::,;xKXXXKkdolcokKXXXXXXXd.                     .xXXXK0kx0XXXXkc;;,;lox0KKKKKKKXXXXX    //
//    KK00K00K00000000Oo'  ':cllc;'..;lk0xx000k; .'oKXKKd.     .dKXXXXX0:                       lXXXXXKXXXXXXXKKKKKKOxk000KKKKXXXXX    //
//    0000K0000000000KK0dc,;:ldo:,'',::lO000000klo0KKKKKl.      ,OXKKXKl.                      'kXXXXXXXXXXXXXK0000OxdxO000KKXXXXXK    //
//    0000000000000KKKKKK0dodlllcccccldOKKKKKK00xokKKKKK0o;....cxKXKKXO,     ....            .cOXXXKxlokKXXXkc,'.....okk0000KKKXXKK    //
//    K000000000000K0K0KKKOxdddolldxkO0KKKKKK000kc:dO0KKKK0OxkOKXXXKKKKkollodkOOk:        .cx0XXXXX0;  .oKXKc       .x0k0000KKKKKKK    //
//    K0000000K000000KKKKKKOkkkxxOKKKKKKKKKKKK00kxl..;okKKKKKKKKKXXKKXXXXXXXXXXXX0l.      lKXXXXXXXX0ddx0XXXx.      .k0xO0000KKKKKK    //
//    000000000KKK00OxddddxO0OkOKKKKKKKKKKKK0000xxO;   .l0KKKKKKKKXXKKKXXXXXXOolodOOl:,,:dKXKKXXXklodk0KXXXXXk:.    'xKkk0000KKKKKK    //
//    00000000kdc;'',,.':ooccllldOKK0O00KK0000K0xOXd.   .dKKKKKKklc;,,,:lkKXX0dc:cOXXXXXNXkl;:oO0x'  .':kXXXXXO,    ,d00xk000KKKKKK    //
//    00000000d;'...,,,,lOOo:colcx0dloddk0K0000OxOXO,   .dKKKKKd.     .;oOXNNXNNNNXKKK000OoldkOOOko,    ,OXXXX0l'.  :kk00kO000KKKKK    //
//    000000000d:;;;::;:xKK0xlcccox:,oOkdkKK000Ox0XK:   ,xKKKXO,  .:ld00OdollooooxOOkOOkxddkO0OO0OOx:.  .xXXXXXXKo..l0OOK0kO00KKKXK    //
//    00000OkO0k:;:;:llcxKKKOkOkl;:,';xKkx0KK00O:c0Xd.;xOKXKX0:.'cdkOkdl:'',,:cox00xkkkkxkkO0OOkxOOOkl,. cKXXXX0O0x:oKKOOXKOkO0KKKK    //
//    00K0x:,,lo:;::clc;ck0o':oc,',cl:ckkxOK000Oc:OXOokXKXXXXk:o0KKKK0000000K0OOKKx;clcoldOO0OOxldOOkkxo:o0XXXXd',xxxKX0k0XKkk00KKK    //
//    0KK0d;ll;;;;;;::;;:cl;,cc::::;;;;okxk0000OxOKK0k0XXXK0kxOKKKKKKKKKKKKKOl'c0Kdlo;;:;lkOOkxxxxkkkxoodxOOkOXKkdO00KKKOx0XkdOKKKK    //
//    KKKKOl:::;;::::::::c:,;loccllccccd0xx0000Ok0KKKOOXXKo.'xKKKKKKKKKKKKOxxo:l0Kdcodo::lcclcloldkdoool;:OO;.oXNNNX0KXKKOxkkxO0000    //
//    KKKKKd'.,;::;:::::::,..;lclooooold0kdO000OOKXXKOOKXX0lo0KKKKKKKKKOoodOKkllxkookxdx0xc;;;,',do;;cxxdlkN0dkXNXNX00KKKKKOkkO0000    //
//    KKKKk:'.,;:::::::ccc:,';;;:loooold0OdO000kkKKKK00KKK0O0K0KKKKKKKKc.oKX0xllddx0KolxOdcdxxxclOkc,,lxk0KXNKKXNNNX00KXXKKK0000000    //
//    KKKkc;;;;;;;;;;;::::::;;,;:clllc:d0Odk000xkKK00O0KKKOO00KKKKKKKK0l;xK0xl;;cclOKkdkolkX0xkxkKKOc,ckKXKXNK0XNNNX0KXXKKKKK000000    //
//    KKK0o;;,,,,;;;;;;;;;;;;;;;:::c:::o0Odk000O0XKOOkOKKKkk000KKKK00Odcclxxc;;;;cdxOOxkdlx0KkxxdO0OdcxXXXXXN0KNNNNK0XXXKKKKKKKK000    //
//    KKKKx:;;;;;;;;;;;;;;;;;;;,;;:::;;oOOox000OKX0OOkOKK0kO000K00KOxl,,,,:kkdxxdoxxdooddoodOddkolxOOdkXNXXXX0KNNNXKKXKXXKKKKKKKK00    //
//    KKKKkc:::;;;;;;;;;;;;;;;;,;;;;;,,lOkld0000KK0OOO0KKOxO000OOOxl:::lc;;ccclc:,':ccclc:;cl::cdkkkOkdONNXKKKKNXNK0KKKXXXKKKKKKKK0    //
//    KKKKkc::::;;;;;;;;;;;;;;,,;,,,,,,cOkldOOO0KK0OOk0KKkx0Oxdxxxl,'';:,,'''.......'cc;:c:::;,:ldxkxdoxXNK000XXXXK0KKKKKKKKKKKKKK0    //
//    0Okkd:::;;;;;;;;;;;;;;;;,,,,,,,,':ddccdxkKXK0OOO0K0kk0OdokO0Oo:,',,;. .    ....cdc;:c:::c:;;ck0klckKkodkO0KX0O0KKKKKKKKKKKK00    //
//    c:::;;;;;;;;;;;;;;;;;;;:;,','',,,'.'',''cOKKkc:oOK0xllooc:odc'.':c;;'.... .. ..:lc;;,',;c;':loxxo;;:......,;;lOKKKKKKKKKKKK00    //
//    ::;;,,;;;;;;;;;;;;;;;;;;;,;;;;;;,'.......;l:'...',,...''''''''',:c;,,.  ... ...,cl;,;,,;;,,cc:;,,,'.         .:oooooooolllloo    //
//    :;,;,,:;;;;;;;;;;;;;;;;;,,;;;;;:;,'....      .       .',''''''',:l:,;,..,,,',,',;;,,,'','',,,,,,,'''..........',,,,,,,,,,,,,,    //
//    :;;;,,;;;;;;;;;;;;;;,,,,''''''''''''''................''''''',;;::;,,,,,,,,,,,,,,,,,,;;,,,'',;;;;,,,''''''',,,,,,,,,,,,,,,,,,    //
//    :;;,,,,,,,,,,,,,,,,''''''',,,,,,'''''''''''''....''''''',,,,'''','',,,,,,,,,,,,,,,,,,,,,,,''',,,,,,,,,,,,,,,,,,,,,,''',,,,,,,    //
//    :;;,,,,,,,,,,,,,,,,,,,''',,,;,,,,,,,,,,,''''''''''''''',,,,,,,,,,,,,,,,,,,,;;;;;,,,,'''''''''',,,,,,,,;;;;,,,,;;;;,,,,',,,,;;    //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Cx3 is ERC721Creator {
    constructor() ERC721Creator("cowDAO Cowmunnity Cowllection", "Cx3") {}
}