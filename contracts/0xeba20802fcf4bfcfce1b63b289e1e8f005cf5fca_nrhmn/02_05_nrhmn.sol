// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Lethal Revelry
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ldxkOO000KKKKKKKKK000000OOOOOOOkkkkkkkkOOOOOOkkOO00000OxdxkkxxxkkkOOO0000000Okkkkxxxoollllccllloolc,    //
//    oxkOOO000KKKKKKKKKK0000000OOOOOOOOkkkkkkOkkkkkkkO0000OkkkkOOkkOOOOO0000000000Okkxddddoooollooddddol;    //
//    dkkOOO0000KKKKKKKKKK000000000OOOOOOOOkkkkkkxxxkkkkkkOOkxxxxkkOOOkkO00K0000000Okxxdddddddddooooooooc;    //
//    xkkOOO0000KKKKKKKKKKK000000000000OOOOOOkkkkkkkkkkkkkkOkxxxkOOOkkkkOOOOOOOOOOOkkxxxxxxxdddddooolllc:;    //
//    kkOOO00000KKKKKKKKKKKKK0000KKK00000OOO00OOkkkkkkkxxxkxxxxkO00Okkkkkkkkkkkkkkkkkkkkxxxxxxddddooolllc:    //
//    kOOOO00000KKKKKKKKKKKKKKKXNNNXKK000000K0OOOOOkkkkkkkkxkkkkOOOkkkkkkkkkkkkkkkkkkkkkkkxxxxxxddddooollc    //
//    kOOO000000KKKKKKKKKKKKKKOdoxklclx0000000OOOOOOOkkkkkkkkOOkkOkkkkkkkOOOOOOOOOOOOOkkkkkkkOOOkxxdddoolc    //
//    OOOO000000KKKKKKKKKKKKK0xxol:..,cOK000000OOOOOOOOOO0000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KXXXK0Oxxddool    //
//    OOO000000KKKKKKKKKKKKKXkoOOc',:cd0KK00000000OOOO00KKKXK0OOOOOOOOOOOO00KKXXK0OOOOOO0KXXXNNXXKK0Okxdoo    //
//    OO00000KKKKKKKKKKKKKXKXKkxOx:;coOKKKKKK000000000KXXXXXK000000000KK00XNNNNNXK0000O0KXNNNNNXXKKK0Okxdo    //
//    O00000KKKKKKKKKKXXXXXXNXOkd;:xKKKKKKKKKK00000000KXXXXXK0000000KKKKKXNNNNNNXXK0000KXNNNNNXXXKKK00Oxdo    //
//    00000KKKKKKKKKXXXXXXXOdokOddOKKKKKKKKKKKK00000KKKK0KKK00KKKXXNNNNNNNNNNNWNNNNNNNNNNNNNNXXXKK00000kxd    //
//    0000KKKKKKKKXXXXXXXXOdoodl:dKXKKXKKKKKKKKKKK0000KKKKKKKKNNNNWWWWWWNWNXXXKKKXWWWWWWNNNXXXKK000000Okxd    //
//    000KKKKKKKXXXXXXXXXXXKOddc'oKXXXXXKKKKKKKKKK0KKKXXNXXXNNNNNNWWWWWWWWNdlddxxKWWWWNNNXXKKKK00000OOOOkx    //
//    00KKKKKKKXXXXXXXX0olooclxodKXXXXXXXXKKKKKKKKKkdxxxddooox0XNNNNNNNNNWNOodoodONWNNNNNXKK0000OOOOOOOkkx    //
//    KKKKKKKKXXXXXXXXX0c.   ;kdOXXXXXXXXXXKKKKKKkddlcc:;:;,..'ckXNNNNNNNNNXxx00kkXNNNNXXKKK0000OOOOkkkxxx    //
//    oOKKKKKXXXXXXXXXXXKOdlldOkkXXXXXXXXXXXXKKKXKOdol:::::;,,',oKXXXXXXXXXXOdOOl;kNXXXKKKKK00000OOOOkkkxx    //
//    ':ok0KKKXXXXXXXXXXXXXXKxxOk0XXNNNNNXXXXXXNNXOc,'.......,lox0XXXXXXXXXXKOd:;lOXXKKKKKKKK00000000O00Ox    //
//      ..,:;:loOXKKXXXXXXXXXd:lxOKNNNNNNNNNNNNNNKl''.',,,''',,;ckXXXXXXXXXXX0lcOXXXXXKKKKKKKK00Oxk0KXK0xl    //
//          ....,locldxdddO0KOc:cox0NNNNNNNWWNNNN0;.,,'....    .cKXXXXXXXXX0ko:dKXXXOkkOKKKOkkkkd,'';::;'.    //
//               .........'''::;:odOXNNNNNNNNNNNN0:..          ;0XXXXXXXX0Oxc';OXXKKd,';ldl;,,'''.........    //
//                       .   ....;oOKXXXNNNNNNNNNNO:..        ;OXXXXXXXXXXXKl:OXX0l:;.................  ..    //
//                               ..cxKXXXXKXXXOxkKKxc:;,''''..cOKXXXXNNNNNXXK00xoc..... ..............        //
//                            ......ckK000KXXK00O00d:,'.....'',ckKXXXXK0Oxdoddc....     .............         //
//                              ... 'oOOkkO0KKK0O0k:,,'........,o0K00OOxl:;,,,'.    .   ............          //
//                                  .,dxxkxk00OkOk:.............cxkkxddol::;'.':l;.;,. .....  ...cxxl.        //
//                                 ...:dxxdxOkxkx:..............:ddolllll::;;;;:c;',;...'''...;;;clcl,.       //
//        .'.                      .;ldO0kdxkxxd;.  ...        .;lol:clll::::;..,'.,,,cll:,',,;;';l::c.       //
//        .:'   ..                 .::;clodxddd;.              .;cll;:lll::col:',c;...','...::;;..:lc,  ..    //
//         .;,..,;....      ........ldc..'ldod:                .:cll;:lllc:::clllo;'..;:lc..,,.,' .;l;..,'    //
//     .   .,;,','. .,........,'';;;,;olldkdoc.                .:coc;:lll:c:,,'..',,....,,,;c:':c;':o,   .    //
//    .'.  .;:;;;,. .....;,.. .',::ccldc;''cl.                 ':coc;clcc:c;'..,;:,',c:,,,,'';;lddc,c:..,,    //
//    :'''':c:;'......',;,,.. .,';:cx0kdd;,c'                  ':ldc;cc:c::;....',,,cddl;,;:;::;,;,,cc';:,    //
//    ',;::,'..'',;;,;;;;'::,,:cc;';x0OOOdc'                   ,cld:;c:,:;:oo;..  .,:cc:,,ldlcc:;....,,'''    //
//    ;:c;'.',;;c::l:;;;;:oc;,,;,,,lOxclOKd..                 .;cod:;c:',;;::;,.   ...,:,',,,,''..''';,''.    //
//    ;cc:,.....oOkxo:::;,,;,'.'. .d0doxxoc'. ....            .:cdd:;c:,;;,'',,'.',....,,''...    ',.,::;.    //
//     .;c:,'...:olol,,',,,,','..'ckd,;;,,.  .,cool:;'....    'cldo:;:,,::'.....;:,'..'cc;:::,'.  .,,,,:,.    //
//    . .,......;ooc,.',:lc:,...c0Ol'.,loc.  .,:cc::cc:::::;,.:lldo;;:;cll,..';'......cl'..........'..;o;.    //
//    .  ...'....;dxo'.,;'''.  ;k0ko,.co;.  ':lolcccccc::;'''.:loxo;,',lcc;':xk:'..  .;,.     ...'''..:d;,    //
//    ...  ...',,,d00x;........'dkdl'.cl,...:dxddooddoc;,'''..:loxl;,'.;::;,okl'',.  .;;.   'coool:'.'cc''    //
//     ..   .;,..'lO0kc'',:;....oOkd''cc,..,coxxollc:,',,'.. .cldxc,,,,;;:c;,'..,;...'ll'..,;,'..',,:::,,c    //
//     .,.   .'.. .':dkxolll;,''xXXx'co'.',;:::cloool;'......'clxx;'',.',,'..  .llcdl;:;,;;'.      .;;..';    //
//     .....;;'..   .o00Ox;,;,;lON0lckl.;c,'..',;,,'..''''...'ldkd,.''..;odc.  .;cxk:.. .c;.       ..'.,c,    //
//      ..,;:,... .,oOkoc,..'ckXNNKkxko:cl,''......,,;,'.....';clc,''''':xd:......;l;  .cxl,...   ...'''od    //
//    .. ....'. .'lOOdl;'..,dKKKX0kdool::;;;;:;,'...........''...''',',;:,...........  'll'.    ..;:cllcdk    //
//    .'...  ....lkdc'..  'dXXKXXkdolxk;...''........ ..';;''...',',;.;;.. ....... ..,c;'........,::::::::    //
//    ..     .,..,lxd;.  .;xK00Xkl:,;xO,.';'  .','...,:cc;'''.....':;.,'        .. .:c:,..   ...',,'''''''    //
//    ..    ...   .:do'  .:xkkKXOxocckk'..;;...';:cc::;,''',...    ''.,,        .'......      ............    //
//     .    ..     .,lc..:lxxkNNKOxolkd'..;'....................    ..''.       .,'.             ......       //
//          .      ..;xdlodxxkOOOkdoldl.....     ...''''... ...     .,''       ..''.               .          //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract nrhmn is ERC721Creator {
    constructor() ERC721Creator("The Lethal Revelry", "nrhmn") {}
}