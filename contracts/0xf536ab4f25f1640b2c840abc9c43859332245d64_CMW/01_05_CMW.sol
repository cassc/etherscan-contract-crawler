// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Carlos Meta World
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ,;,,;,,,,,'''',okkxxkxxxxdl::clollc,'.....':cllcc:;;;::;;;::::::;;;cdOOOkOOkkkkdlccllllclllloolloodo    //
//    ',,,,'''''''';oOOOOOOkkkdc;;;:cllc:,....'',;:::::c:::;;:::;;:;;;;;;;:loxxxkxxxxxdlc::ccclccclllllllo    //
//    ',,,'''''.';lxOOOOkkkkxl,,;:cccc:;,,'',,;;;;;;;:cllllcccc::;;;;,;;;,,,;coxkkkkkxkxdocc::cccccccllllo    //
//    .','''''';lxOOOkkkkOko:;;:cclc:;;,,;;:ccccccccccccclloooooolc::,,,,;,,;;;coxkkkkkkkxxdlc::cccccclllo    //
//    .'''''';lkOOOOOkkkkdl::ccccc:;;;;;:::::::;;;:::::::ccccllodoooolc:;;;;;;;;;:ldxkkkkkkxxdolc:::cccccl    //
//    .'''';lxOOOOkkkkkdlc:c:;,;:;;;,,,,'............',,;;:::cccloodddoolc:;;;;;;;;:coxkkkxkkxxxdoc:::ccco    //
//    .'':okOOOOOkkkkdlccc:,..',;;;,'................'',,,;;;;:::ccloodddoolc:;;,,;;;;:ldkkkkkkkxxxdl:::cd    //
//    .:okOOOOOOOkkxoccc:,...,;;,,'.........',,''.....''''',,;;;;::::cloooooollc:;,,,,,,;coxkkkkkkkxxdlc:o    //
//    :kOOOOOOOkkxdlcll;. .';;,'..',,,'''''.....      ...  .....',;;;;::ccloooooolc:;,,,;;;;ldxkkkkkxxxdoo    //
//    lOOOOOkkkkdlccll,. .','...,c:;,,'.........''',,,,''''.........',;;:::cclooooool:;,,,;,;;codkkkkxxxxx    //
//    oOOOkkkkdolccc:. ..'...,:c:,'''....',;;;:::::::::::::::;;,'.......',;;::cclooooll:;;,,,,,;:ldxkxxxxk    //
//    lkOOkkdllcccc'. .....':lc;',,,'',;:::::::::::::::::::::::::::;,'......',;::cloooollc:;;,,,,;:ldxkkkk    //
//    lOOkdlcccll;.     ..;ll:,,;;;;:::::::cc::;;,,,,,,,,'',,,;::::::::;,''....',;::cloooollc::;,,,;:ldxkk    //
//    ckxl:ccllc,.     .,lol;,;;;;::::::::;;,'..'',,''.........',;;;:::::::;,'....',;::llooolllc:;;,,;:ldx    //
//    ;l::clll:.      .:do:,,;;;:::::;;,'''''',,;;;;;;;;;;;,'.......'',;;:::::;,'....,,;:cllllllllc:;,,;cl    //
//    .:clllc,.     .,ldl;,;;;:::::;,,,,,;::::ccccccllloooolllc:;,'......',;::::;;,.....',;:cllloolllc;;,;    //
//    'collc.     ..:odl,,;;::::;;;;;::ccccccccccclllllllllooooooolc:;,'''.',;;:;;;;,.....',;;:clllllllc::    //
//    ,lol;.     .,lddl;,;::;;;;;;:cccccc:::clllllllllclllloooodoooddolc:;;,',,;;;;;;;;'.....';;::clllllcl    //
//    ,lc,.     .;ldo:,;::;;,;;:cccc:::cccclloolllllclllollllloooooooodddool:;,,,;;:;;;;;,......,;;::ccccc    //
//    ,;'.     .;ldl;,;:;,,,::c:ccc:::::cccc:;,''.....''''''',,;:clooooooddddol:;,,,;;;;;;;,'.. ..',;;:::c    //
//    ...     .,ldl,,;:;,,:lcccccc:;,'''''....                ......',;:cllodddooc:;;;;;;;;;;;,..  ..,;;;:    //
//    ..     .,ldc,;;:;,;coollllc;.......       ..''.................  ...',;:looooll:;;;;;;;;;;,'......,;    //
//    .     ..cdc,;;;;';odolcll:'. ...        ...';;'.'..;c' .,'...............,cloooolc:;;;;;;;;;;,'.  ..    //
//         ..:oc,;;;;,:odo:,;;'.         .;.   .:c;. ....,:,..,;'...,,,....   ...':coooolc:;;;:;;:;;;;'...    //
//         .;ol,,;;;';ll:'....        ..'c:.   .:oc.  ....''. ';,'',:c:'.  ...  ....,:looolc:;;;;:;;:;;;;,    //
//        .;oo;,;;;',cc;..         ..',,;c'   ....   .....',..,;;,',;lc'..   ... .....':looool:;;;::::::::    //
//       .,odc;;;;,',:,.         ..',,,,;:'    ...........,,..;;,,',:lc'...   ....  ....,cloodolc;;:::::::    //
//       'oxo:;;:;'';'.         .'';c;,,,:,    ..............;;,,'';llc'.'...... ...  ....;lloodol:;;::c::    //
//      'lxdc;;::,''.      'c' ..',od;,,,;;.     ......... .,;'''',:cc:..,'......  ...  ...,clloooolc:;:::    //
//    ..lxdc;;::,'..     .lOo. ..';dd;,;;,;:;.     ... ....,;,''',:llc,..,,........ ...  ....,cllloodolcc:    //
//    .cxdc;;;;;'.     .ckKO;. ..';oo,';:;,;:cc;'.......'',,'',,,;clc;'..,'.  ........ ... ....;cllllodddd    //
//    .ldc,;;:;'.    .:kKXXx'....',coc,,;:,,,,::cccc;;,,,,''',,,,;cc:,..'''.    ..'..............,;clloodx    //
//    .::,;;;;'.    ,xKXKKKo..'...',coc;,:c;,,,,,,,,,,'''''',;;,,:c:,'..''.       .''.......,'......',,;::    //
//    .'',:;,..   .lOKKK000o..'...'',:lc:;::::;,,,,,,,,,,',;::;;:c:,'...''.     ..........,cdxo;..      .     //
//    ..,;;'.....,d00000O00k,..,....',,:ccc::::;;;;,,,,,,,;;;,;cc:,'...''.    .........,lxxoc;'''.. .'''..    //
//    .';,...':..:x000OOOO00c..'.....'',;cll:;;,,;::;;;,,;;,,;::;,....''.    .........cdo:.  .,:,.',;,..      //
//    ......:oolc;';ok0OOOO0k;....  ...',,;::;;;,,,,,,,,,,,;,,,''....''..  ...... ..;cc'. .,lxd,.,;'.    .    //
//    ....;odddxkdc;''ck0OO00x;..... ...'',,,,,,,,,,,,,,,;;,,'......'..  ...... .,::,.  .;oxkl..''.   ...'    //
//    ..'lxxdddkklccc;.'oO00O0x;. .........'',,,,,,,,,,,,''..... .............';:;.   .;ldkx;....   ..',,,    //
//    .:xkkxddxkxlcccc:'.:k0OOOx;. ..........................   ...........';;,.    .'coxko,...    .'',,,;    //
//    .lkkkxddxkxlcccc:c:.,dO0OOx:.  ...........              ..........;::,.     .':odkxc...'.  ..'',',:d    //
//    .lkkxdddxkxlccccoool'.lO0OOkl'.      ....               ... ..':cc:'     ..':loxko;..';.  ..'''';oxk    //
//    .lkkxdddxOxlccclxkdoo:.,lkOOOx:..   ....  ..........    ..';:::;.    ..,;:clooxxl,..,;. ..'''',:dxkk    //
//    .ckkxdddxOxl:cclxxooddo;',:oxOkdl;'.................',,:cc:,..    ..,;:::clooxdc,..;:. ..'''',cdxkxl    //
//    .cxkxdddxkkl:cclxoloodxdoc,'',;clllc:cccc::::::::::;,,''.       .';:::::cooodd:'..;:'...'''',cdxkxc:    //
//    .:xkkddddkkdccclddlooddxxxdl;,'........'',,''....           ..',;::::::looooo:'..:c,...'','':dxkxc;:    //
//     :kkkddddxkdccllddlooodddxxdc:::::;,,'....            ....';;::::::::cooolll;'..;c;....'''':dxkkd:;l    //
//     :kkxdddddxoccccoollooodddddoc;::::::::;;;,,,'''''',,,;;;;;:::::::;;coolclc;'..:c:. ..'''';oxxkkl;co    //
//     :kkxdddddxo:cccldlloooddddddl:;:::::::::::::::::::::::::::::::::::lool:cc;'..:c:'. .'',,;ldxkkdc:ld    //
//     ;xkxdddddxo:ccccoolooodddddddl:::::::::::::::::::::::::::::::::ccloolclc;'.':c:,. ..'',,cdxkkko:cod    //
//     ;xkxddddxko::ccclooooooddddddoc:::::::::::::::::::::::::::::cllooollodo:..,cc:,. ..'',,,ldxkkxc:ldd    //
//     ,xkxxddddxxl:ccccloooooodddddddl:;;:::::::::::::::::::::::cloooooooc:c:..,cc:'. ..''',,:oxxkko::odd    //
//     ,dxxxddddxxoccccccloooolodddddddol:;;::::::::::::::::::cloddoooool:,;;..;cc:'.  .''',,,cddxkkl:lodd    //
//     ,dxxxdddddxdlccccc:loooloodddddddddlc::::::::::::::cclodddoooool;,',,.':cc:,. ...''',,;lddxkdccoddd    //
//     'dxxxxdddodxdlcccc:cddooooodddddddxxddollllllllloooddddolllooo:,',,..,ccc:'.  ..'''',,:odxkkocloddd    //
//     'dkxkxddddoxxdlccccccodoloooodddddxxxxxxxxxxxxxxxdddoollolodo;''''..;ccc;.   ..''''',;lddxkxlcodddd    //
//     'dkxkkxdddoodxdlcccl:;cddooooooooddddxxxxxxxxddoooollllloool;','..,:cc:,.  ...'''',,,codxkkdllodddd    //
//     'dkkkkxxdddoodxdlccclc::lddddoolllooooooodoolllllllloloddo:,,''';cccc;'.  ...'''',,,;lddxkkoloddddd    //
//     .dkkkkkkxxxdodxxdlccclc:;:loddddoooolllllllllooooooooodoc;,.',:cccc;'.  ....''''',,,:odxkkdlldddddd    //
//     .dkkkkkkkxxddddxxdolccclc;,,;:clooodddddddddoollcc::ll:,''',:clc:,..   ....''',',,,:ldxkkxllodddddd    //
//     .okkkkkkkkkxxdddxdxdocccccc::;;;;;;::ccccccccccccccll:,,;:cc:;,'.    ..''',,,,,,,;;ldxxkxoclddddddd    //
//     .dOOOkkkkkkkxxddxkxxxxdlcccccccc::::::::;;:::::clllllllloc;,'..    ..'',,,,,,,,,,;cdxxkkocloddddddd    //
//     .dOkOkkkOOOkkkxxxkkddxkkxddollllllllllllllllllllooooodoc:'...   ...'',,,,;,,,,;,;cdxxkkoccodddddddd    //
//     .okkkkOOOOOOOkkkkkkkxddxxkkkxddddddddddddddddddddddol:,.....  ..''',,,,,;;,;;;;;cdxkkxoc:lddddddddd    //
//     .okkkOOOOOOOOkkkkkOOkkxxxxxkkkxddodddoooddddddolc:;'......  ..,,,,,,,;;;;;:::::oxxkkxocclodddddxddd    //
//     .lkkkkkOOOOOOkOOOOkOOkkkkxxxxkxl;,;;;;,;:ccc:;,'.........   .,,,,;;;;;;;::::cldxxkkdlcclloddddddddo    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CMW is ERC1155Creator {
    constructor() ERC1155Creator() {}
}