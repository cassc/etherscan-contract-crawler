// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Collaborative Remixes Signed Artwork
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    OOkkkkkkkko;..........'.......'''...........                 ........                                 ..;okOkkkkOOkOOOOOOOOkkkkkOOOOOOOOOkkkOOOOOOKKKK    //
//    OOOOOOOkd:.....................'............                 ........                                    .,okOkOOOkOOOOOOOOkkkkkOOOOOOOOOkkkOOOOOOKKKK    //
//    oooddol:'.............'''.....................             ........                                        .;dOOkkOOOOOOOOOOkkkkOOOOOOOkkOOOOOOOOO0KKK    //
//    ...'''..................''...............',,;;;::::::;;,'.........                                           'okOkOOkOOOOOOOkkkOOOOOOOOkkOOOOOOOOO0KKK    //
//    ......................'col;'.....',;clodddxxxxxkkxdl:;;;,'.'............                                      .okOOOkkOOkOkkkkOOOOOOOOOOkOOOOOOOOO0KKK    //
//    ......................c0KOdc;;cldxxxkkkkkkkkkkkkkd,.....    .......   ..                                       .lkOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOO0KKK    //
//    ;'..................'l0KKKK0OkOOOOkkkkkkkkkkkkxxl'  .           ..     ..                                       .oOkOOOOOOOkOkkOOOOOOOkOOOOOOOOOOO0KKK    //
//    ;,'.................oKKKKKKKK0000OOOkkkkkkkkxxxo'                                                               .ckOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOOKKX    //
//    o:,................'xKKKKKKKK0OOOOOkkkkkkxxxxx:.                                                                .cOOOOOOOOOkkkkOOOOOOOOOOOOOOOOOOOOKKX    //
//    Okdc;,''...........;kKKKKKK0kxkOOkkkkxxkxxxxx;                                    . .............               .oOOOOOOOOkOkkkOOOOOOOOOOOOOOOOOOOO0KX    //
//    OOOkkdolc;'........;OXKKK0kddxkOOkkkkxxxxxxxc.                                    .....................         .'dOOOOOOOOOkkkkOOOOOOOOOOOOOOOOOOO0KX    //
//    OOOOOOOkkxolc;,...,o0KKK0kkxdxkOOOOkkkxxxxxc.                                     ......................  .       'dOOOOOOOOkOOOOOOOOOOOOOOOOOOOOOO0KX    //
//    OOOOOkOOOOOOOkxoldOKKK0kxkOOkOOkkkkkkkxxxxl.                                        ..................    .       .;kOOOOOOkkkkOOOOOOOOOOOOOOOOOOOO0KX    //
//    OOOOOOOOOOOOOOOOOO0KK0kkkkxdodxkkkkkkxoc;,.                                    ..    .................             'xOOOOOOkOkkOOOOOOOOOOOOOOOOOOOO0KX    //
//    OOOOOOOOOOOOOOO0000OOOOOOkxdoodkOkxlc,.                                    ..........''''............  .....       .,dOOOOOOkkkOOOOOOOOOOOOOOOOOOOO0KX    //
//    OOOOOOOOOOO00O0KXKOOKKKK00Okdddxdo:.                                  ..  .......'',;;c:,........      ..;o,.       .'dOOOOOkOOOOOOOOOOOOOOOOOOOOOO0KX    //
//    OOOOOOOOOkOKK0KXK0KXK0OOkkkkxkxl'.                                        ........',:lodd, ....      .. .:xd:'.       ,xOOOOOkOOOOOOOOOOOOOO0KK0OOO0KK    //
//    OOOOOOOkkO0KKKKXK0KXK00kxddxxOx,                                         .....,;,,:loxkOO;              .:xOK0dc:;.   .cOOOOOOOOOOOOOOOOkdclOKK0OOO0K0    //
//    OOOOOOOOOOKKKKKKK0KXKK0xollloo,                                       ..'''.',;:looodxk0O;              .:x0Kkodkd' . .cOOOOOOOOOOOOOOOd,...:x00OOO0KK    //
//    OOOOOOOOO0KKKKKKKKKK00Okdollo;                                        .',',,,;clodxxkO0K0,          .'.  'cdxdccc;... .dOOOOOOOxooollcc.  ..,cdOOOO0KK    //
//    OOOOOOO0KKKKKKKKKKKKKKK00000O,                                      ..',;;:cclodxxkOO0KK0;          :Okc. .:dkdccoo:..':oxdxo:,.            .,:xOOO0KX    //
//    OOOO0KKKKKKKKKKKKKKKKKKKKKKXx.                                    ...',,;clooxkxkO000KKX0;          ;llo:,;:,,cll:,..''';c:,.....'.   ...    .'dOOO0KX    //
//    OOOOKKKKKKKKKKKKXKKKKKKKKKKKl                  ....             ....',;clodddxxkO0KKKKXXKc          'lxkocccc;';' ...'',;::,::,,;cc' ..';;.   .oOOO0KX    //
//    OOOOKKKKKKKKKKKKKKXKKKKKKKKO:.               .'''',;'.            ..;:cllodxxkO0KKKKKKXXXd.          ;xkocc;:cldo;.','.,:ccccc,,::c:. .';;'   .oOOO0KX    //
//    OOOO0KKKKKKKKKKKKKKKKKK0Okdol'               .,:cc:;,'.....   .....':loddxOO0KXXXXXKKXXXXK:           .;cc:clooodl..''',cccdoc:cl:;;.  .'..   .lOOO0KX    //
//    OOOO0KKKKKKKKKKKKXKKKkolc::cl:.             .'cllodxd:...';:cllcclooodkOO0KKKXXXXXXXXXXXXXO,            ,:loocccldc',;;;::llcc::ll:,   ...    .lOOO0KX    //
//    OOOO0KKKKKKKKKKKXXKX0l;cc:::cc,             .,coo:,cxOo.  .;dO0OOO0OOO0KKKXXXXXXXXXXXXXXXXXOc.     .    'cloocccdkkxkxc,',::::::;;,.   ..     'oOOOOKX    //
//    OOOO0KKKKKKKKKKKKXKKKxlclllc;,,'            .:xdll:;ok0o.   .;xKKKK000KKXXXXXXXXXXXXXXXXXXXXXOl,. .,'...'cooc:cokOOOOOk:. .''.  .    ..     ..;dOOO0KX    //
//    OOOO0KKKKKKKKXXKKKKKKXOl:ccc::::'            :dooo:cdk0k'      ;kKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXk:;:cc:;,'''. .ckOOOOOOx,....      ...     ..,cxOOO0KX    //
//    OOOO0KKKKKKKKKKXKKKKK0dc:clool:;;.  ..       .:dOxclxxkO;       .:kKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXOl;ldl:;'. ..:xOOOOOOOo.....    ...     .,:cdkOOOO0KX    //
//    OOOO0KKKKKKKKKKXXKXKXkc:loddoooll;..,:'       .'ldlldxkOo.        .:x0KXXXXXXXXXXXXXXXXXXXXXXXXXKkl;:c:;,.. .cxOOOOOOOOl. ....  ....   .,:ldxdcoOOOOKX    //
//    OOOO0KKKKKKKKXKKKXXXK0xlc::clccccoolllo:.       .,:cdxkkOo.         .,lkKXXXXXXXXXXXXXXXXXXXXXXXXk:;;,''''..'lkOOOOOOOOx,......,;;,. .':lodl,..cOOOOKX    //
//    OOOO0KKKKKOclOKKOdokdlollloddoooooooddxkd,        .,lxkkk0k:.          .,cdkOKXXXXXXNXXXNXXNXXXKKklcc,',;;::cdOOOOOOOOOk;....';:cc;. .,col,....lOOOOKK    //
//    OOOO0KKKKK0o,oOxdccxkdolc::::::clooddxkOOko'       ..:oxxk0Kkl'            ..',;::;::;;;;;;:clc:clcccc:;::::cdOOOOOOOOOk:....;::cc:...,:c,...',oOOOOKX    //
//    OOOO0KKKKK0kO00OOkxxdlooooooodoooooooxxxxkOk:. ....  .':lokKXXKxc'.        .   ...            .,;:cooclc:c:cclkOOOOOOOOOx:..';cccc:,.':lc'.'';:oOOOOKX    //
//    OOOOOKKKKKOkOOOOkxdxdl;',clcccc::cloxkkkkOOOko,.....  ..;lx0XXXXX0xc'     .......'...          .,llddlloddcc;,lOOOOOOOOOOx;',;ccccc;',:l:..',,,lOOOOKX    //
//    OOOO0KKKKKOxxkOkdlooc;.;ooooodddollclldxxkkkkOkc'.......,lokKXXXXKKK0d:'   ...'',,....          'k00K000KK0x;.':c;cxOOOOOOl,,;:ccll:;::c;.',,,;oOOOOKX    //
//    OOOO0KKKKK0xdxkkdc:;'. 'llccclolclodxkkkkkkxxkkOx:......':ldKXXXXKKKKKX0xl;,'.........          .xXKXXKXXKXk;.....,xOOOOOOx:,;ccllllclll:;;;;;;lkxkk0K    //
//    OOOOO0KOxxdlclolcc:..  'cooooo;....';loodxxxxxxxOkl..  .';:lxkkO00KKKKKKKXKK0xl,.               .dXKKKKKKK0l,,....;kOOOOOOko:clloooddxxddoc::::ox;,,lK    //
//    OOOOOOOklclc:cc;....  .'lolc;.       .;loollloooxkk:....',:llcclok00KKKKKKXXKKXKOo,             .dKK0KKKOo:;,,'...lOOOOOOOOxlldxxxxxkkkkkkxdooldo.  ;0    //
//    OOOOOOOOkxxoc:c;'...',,',,'.        ...,clc;,,;cdxo;..',,:dkxdooxO0KXK0KKKKXXXXXKX0:             oK0000Ol...',...:xOOOOOOOOOxdxxkkOOOOOOOOO0Okxo'   ;0    //
//    OOOOOOxdkOOkdc:;''';:cc:;'.         ...,;:,.'..';:,...':ldxkkkkkkO0KKK0KXKKXXXXXKX0;             ,OK0OOk:..';,..ckOOOOOOOOOOkkkkkOO000000000000l    ,O    //
//    OOOOOOdokOOOOo;,'',:cc;''.         ..'';::.   .....   'looodk0K0KKKKK0KKKKXXXXXKX0:               :O000x:';:;'.;xOOOOOOOOOOOkOOOO0KKK000KKKKK0Ko    'k    //
//    OOOOOOOOOOOOOd::c;,:c;'''.        ..,;,;c,      ... .:lloooodk00000OO0KKKXXXXXKKk,                 ;kK0d::c;'.,dOOOOOOOOOOOOOOOO0KKKKKKK0KKKKKKl    .x    //
//    OOOOOOOOOOOOOklcooc:,'...         ..,,;c:.      .';cxOocldddxkOkkO00KKKKKXXXXX0o.                   ;O0dl:,..'okOOOOOOOOOOOOOO00KKKKKKK0000K0x:.    .d    //
//    OOOOOOOOOOkxxo;.,lc;'..     ......';;;:cc'   .,lkKXXKOdcldkO0Okk0KKKKKKKKKXXXk;      .....'...'.. ..;l:,'...,okOOOOOOOOOOOOOO00KKKKKKKKK0KOo;.      .o    //
//    OOOOOOOOOkl;::,...,;''..',;;ldxxxdoooooodc..:kKXKKKKK0kxdodxkO0KKKKKKKKKKKKKd.      ;kOkkkkkOKK0Oxdkd' ...,cxOOOOOOOOOOOOOOOO0KKKKKKK00Od:.     ''. .l    //
//    OOOOOOOOOx;..''..'cllloool:,,:cccc:;;;;clolkKKKKXKKKK0kkkxxk0KKXXKKKKKKKXXOd,       .','...';oOKK0Okl',:loxOOOOOOOOOOOOOOOOOOOKKKKKKKKk;.      .lkdc:d    //
//    OOOOOOOOOx,.....,cxxddddol,.....',;ccccclokKKKKXXKKKKK0OO00x:,;cc;;,,,,;:lodc.               .:kkxolokOOOOOOOOOOOOOOOOOOOOOOO0KKKKXKK0:        .oOOOO0    //
//    OOOOOOOkd;..,oxxkOOOkxxddol:::loodxkxdooooxO0KKKKKKKKKKKKKl.  ..            ...',..           .coooxOOOOOOOOOOOOOOOOOOOOOOOOO0KKKKXKKk'        .l0OOOO    //
//    OOOOOkkx:..,lkOOOOOOOkxxxxxdlcloddool:,,,:cco0XKKKKKKK0Okc. ...                .,okkxxxko.     .,:okOOOOOOOOOOOOOOOOOOOOOOOOOO00KKXKKl.        .lOOOOO    //
//    OOkdl;,;:oxkOOOOkkOOOkkkkxxl,.'',;;:cc:::clokKXKKXKKKKd,.   .;codxxdl:,.         .lKKKKXO,       ;xOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KKKXO,          c0OOOO    //
//    OOl......lOOOOOOl:dOOOOkkkko;,;:loodxxddxOKKKKKKXKKKKK0d:'..lKNXK000OOOd,         'kXKKO:       .dOOOOOOOOOkOOOOOOOOOOOOOOOOOOkO0KKKl           :OOOOO    //
//    OOo,...;lkOOOOOx,..cxOOOkxxdodxxkkdoooooookKKKKKXKKKKKKKK0kOKXX0Okddkdod:. .       c00o.       .;kOOOOOOOdclxOOOOOOOOOOOOOOOOOOOO0Kx.           :OOOOO    //
//    OOOkddxkOOOOOOOx;...;okOkko,.',;:cc::::::lOKKKKXXKKKKKKKKKKKKKkc,,,,:;,lc'..       .xx.        .ckOOOOOOx;';okOOOOOOOOOOOOOOOOOOOOx'            :OOOOO    //
//    OOOOOOOOOOOOOOOOxlodkOOOOko:,;cllodddxxxxx0KKKKKKKKKKKKKKKKKKO:.'clc,..'.':c'  ,dd;:O0o'..''',';oxxkkOOOx;',:dkOOOOOOOOOOOOOOkkOOOl'.           ;kOOkk    //
//    OOOOOOOOOOOOkddkOOOkOOOOOkxddddolloodxxxxxOKKKKKKKKKKKKKKKKKXOc,:clcc;'''.,;,.;kKKK0K0Oocclooolllllodxkkxc,',:oxkOOOOOOOOOOOOkkOOOkxl.          ,kOkkk    //
//    OOOOOOOOOOOOkc;dOOOOOOOOOd;.'',;:cloxkxxxxOKKKKKKKKKKKKKKKKKOoc::cc:;;,'......';cldxo:,'',,;,,,,,,;:loddxddlc:cldxOOOOOOOOOOOOkOOOOOx'          ,xOOOk    //
//    OOOOOkdoxkOOOOOOOOOOOOOOk;   .,:loodxkkxxxk0KKKKKKKKKKKKKKOoc:::;;;,.... .';:loolllolllooooollccc::;;;;:cloodddddxkkOOOOOOOOOOOOOOOOd.          'xOOOk    //
//    OOOko,..,lkOOOOOOOOOOOOOd.   .;cloodkkkkxxxOKKKKKKKKKKKKOxc;;;;,,....    .',,,;;;;:::clooddddooddxxdoolcc:::clodddxxkOOOOOOOOOOOOOOOk;          .xOOOk    //
//    OOOkc....:kOOOOOOOOOOOOOo.  .,:loddxkkkkkxxOKKKKKKKKKK0dc:;;,,....        .......''',,,,;;;::::::clooddxxxddddxxxxxxxxkOOOOOOOOOOOOOOo.         .dOkOk    //
//    OOOOkoc::dOOOOOOOOOOOOOOx' .,ccloddxkkkkkxxO0KKKKKKKK0d;,,,'...          .  .';;;;;;;,,,,''',,,,,,,,,;:ccllodddddxxxxxxxkOOOOOkOOkkOkc          .dOkOk    //
//    OOOOOOOkxxOOOOOOOOOOOOOOk:.'coooddxkkkkkkkxk000OOkkxkd:'.....            .  .;:loooooooooolooooolllcc::;;;;:llllllodxxxdxkkOOOkOkxxko.          .dOkkx    //
//    OOOOOOOOOOOOOkxdxOOOOOOOx;.,lododxkkkkkxdoooollccc:;,'....                  ..',;;;::::cllllooollloddxxdoooodxddolooddxddxxkkkkkxkkl.           .dOkkx    //
//    OOOOOOOkkOOOOl..'oOOOOkd:,,:dxxxxdddddoccc:::;;;,'.....      .                ........',,,,,;;;;,,;:ccclooddxxxxxxxxxddddddxkkxxkkx,            .oOOOk    //
//    OOkdxOOOkOOOOd:,:xOOOko;,,':xOOOko;;;,,,,'''......                           . .    ..'',''.....,;,'''',;;:cclloodddxddddddddxxkkkd.            .oOOOk    //
//    OOkxkOOkkOOOOOOOOOOOxl;''''lkOOOOkl;'........                                      .':looolllcc:oxdllc::;;;;;:clllloooooddxkkxxxkkc             .oOOOk    //
//    OOOOOOOOOOOOOOOOOOkoc;,,''cxOOOOOOkdlcc:;,........                        ...       .,;;::ccclloooolloddddooooddddddddddxkkkkkkOkc.             .lOkOk    //
//    OOOOOOOOOOOkOOOOOxl;,''''cxOOOOOOOOOOOOOkdc,'......           .          .        .  ....',,,;;:::::;:cclooddddddxxdddxkkOOkkkkOc               .lOkOx    //
//    OOOOOOkOOOOOOOOOxl;,''.,lkOOOOOOOOOOOOOOOkl;,'.......                    ....    ..   .  ........':llcc:::ccllllloddxkkkOOOkkkkk;               .lOO0k    //
//    OOOOOOOOOOkOOOkdl:;,'',lkOOOkkxxxxxxxkkxxdlc:;,,'.....    . ... ..       .. ..  .     .......  ...'okkxxdocccccclodxkkkkkkkkkkkkd:.              lOOOk    //
//    OOOOOOOOOOkOkdolc;,'',okkxxdolcclooddddoolcllllllc;............           .... ...   ... .... .....;dkOOOOxoc:cldkkkkkkkkkkkkkkkOd.              cOOOk    //
//    kOOOOkOOOOkkdlllc;;;;ldoolllc;,,:clllllc:;;;;;:cllc,.........                 .......      .........;dOOOOOkxocldxkkkkkOOkkkkkkkl.               cOOOk    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NOREMP is ERC721Creator {
    constructor() ERC721Creator("Collaborative Remixes Signed Artwork", "NOREMP") {}
}