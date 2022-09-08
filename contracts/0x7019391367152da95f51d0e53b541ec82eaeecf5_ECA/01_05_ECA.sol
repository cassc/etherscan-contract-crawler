// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eyes by Carlos Aquino
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    Eyes are the reflection of your soul                                                //
//    ,,,,,,,,''':dkkxkkxxo:::lol:,....':cccc:;;:::;;::::;;:lxOkkkkkkxoccclccllloooooo    //
//    ',,'''''',:dOOOkkkxl;;;:clc;'..'',;;;::ccc::::;;;;;;;;;:ldxkkxkxxoc::ccccccllllo    //
//    ',,'''',:dkOOkkkkd:;;:ccc:;,,,;:::::::clllolllcc:;;,,;,,;:ldkkkkkxxdlc::cccclllo    //
//    ''''',cdkOOkkkkxl::cccc:;;;::::::::::::cccclloodolcc:;;,;;;;coxkkkkxxdocc::cccll    //
//    ''',:dkOOOkkkxocc:;,;:;;,,''.........',,;;:::cloodooolc:;;,;;;cldxkkxxxxdlc:::co    //
//    .,cdOOOOkkkxocc:,..';;,'..........''''',,,;;;;::cclodoolcc:;,,;,;coxkkkkxxxol::o    //
//    :xOOOOOOkkdlcc,...,;'.''''..'''.............'',;::::clloooolc;;,,,;:ldxkkkxxxolo    //
//    oOOOkkkkdlclc'..','..,;;,''.........'''..........',;:::clooooll:;,,,,;coxkkkxxxx    //
//    oOkkkkdoccc;......,::;,'...'',;;::::::::::::;;,'.....',;::clooool:;;,,,;:ldxkxxk    //
//    oOOkxlccc:.  ....:l:,,;,,,;::::::::;;;;;;;;;:::::;;,.....';::cloollc:;;,,;:ldxxk    //
//    oOxlccll;.    .;ll;,;;;:::::::;,,,,,,'......',;;;::::;;'....';:clloollc:;,,;:ldx    //
//    :l:cllc,.   .'coc,,;;:::::;,,'''',;;;;,,,,''.....'',;:::;;,....,;:cllllllc:;,;cl    //
//    'clll:.    .;ol;,;;:::;;,,;;;:::cccclllooollcc;,'....'',;::;;'....,;:cllllll:;;;    //
//    ;lol,.   .'cdl;,;:::;;;;:ccccccccclllllllloooddoolc:;''',;;;;;;,.....,::clllllc:    //
//    ;oc'    .,ldc;;::;;;;:ccccc:cccllloollllllooooooooddolc:;,,;;;;;;,'....,;::cclcl    //
//    ,;.    .;oo:,;:;,;:::cc::::cccc:,,,,,,,,,,,,;;:cloooodddol:;,,;;;;;;'.....,;:::c    //
//    ..    .,ol;;:;,,cccccc:;'''''...             ....',;;:clodooc:;;;;;;;;,'....,;;:    //
//    .    .,ol;;;;,;loollc;.....     ...,,....''.............,;cooolc:;;;:;;;;,.....,    //
//         .cl;,;;,:odc:c:..      ..  .';;...'';:..,'...'..... ..':loool:;;;;;;;;,'...    //
//        .:l;,;;,:lc;...       ..:,   ,oc. ....'..,;'',::.....  ...,coool::;;:;:;;;,'    //
//       .:oc,;;,,::..       ..',;:.  ....  ....'..,;,',cl'.. ........,:loolc:;;::::;:    //
//      .;do;;:;',;.       ..,,,,;;.   .........'.';;,';cc'...  .... ...,cloooc:;:::::    //
//     .,ddc;;;,''.    .....,cc,',;.   ...........;,,',:l:'.'........  ...:looooc:::::    //
//    .,ddc;;:,..    .cd, ..;ol,,,,;,.   ........,,'',;cc;..,..........  ..,:llooolcc:    //
//    .odc;;;,..   .:kKo. ..,ol,;:,,::;,.......',,,,,;cl:'.',. ..............,:llloddo    //
//    ,lc;;;;..   ,xKX0:....,:o:,;:;,,;::::;,,,,'',,,;cc,..''.   ..............',:clod    //
//    .,,;;,.   .o0KK0O;.'..',:lc;:c;;,,,,,',,,',;:;;cc;'..'..    ........,c:,.......'    //
//    .';;'....;k000000c..'..'';:c:::::;;;,,,,,,;;;;c:,'...'.   .......'cooc:,.. ....     //
//    .,,...;'.lO00OOO0x'.'. ..',;ccc;;;;:;;;,,,;,;:;,....'.   .......:oc,..';'.','..     //
//    ....;odol;,cdOOO0Ol.... ..'',;;;;,,,,,,,,,,,,''......  .......,;,...:dd,.,'.   .    //
//    ..,oxddkxlc;':x0OOOl........''',,,,,,,,,,,,'...............,;,.  .:dkl....  ..',    //
//    .cxkxddkxccc:''lO0OOl. .........'''''........ ..........',,..  .;oxx:...  ..',,,    //
//    ,dkkdddkdccccc:':k0OOo.  .........           .......';;,.    .,ldxo'...  ..'',;o    //
//    'dkxddxkdccclddl,,oOOOd;.     ..        .      ..,::;'.  ..';coxxc..,'...''',cdk    //
//    .dkxddxkdcccoxdodc,;lxOko;...................,;;;,.   .',;:cloxd:..;,...''';lxkx    //
//    .okxddxkxcccodoodddc;,;:colc:;::;;;;;;;,,,,,,,.    ..,;:::loodo;..;;...''';oxkdc    //
//    .okxdddkxlccodooodxxxl;''.'''''',,,''....       ..';::::cloool;..::...''',lxkd::    //
//    .okxdddxxlccldolooddddl::::;;,'......   .....',;;::::::coollc,..::'..''',cdkkl;c    //
//    .okxdddddl:clolloodddddl:::::::::;;;;;;;;;;:::::::::::cooccc,.':c,...',,:dxkxc:o    //
//    .lkxdddddc:ccloooooddddoc:::::::::::::::::::::::::::clolllc,.':c,...'',:oxkko:cd    //
//    .lkxdddxxl:cccooooodddddoc:::::::::::::::::::::::clloloool,.,:c;. .'',,cdxkxc:od    //
//    .ckxddddxocccccooooodddddoc:;::::::::::::::::::cooooooc:c,.,cc,. ..'',;lxxkd:cdd    //
//    .cxxxdddddlcccccoooooddddddoc::::::::::::::ccoodooool;,;'.;cc,. ..'',,:odxkl:odd    //
//    .cxxxddddxdcccc:ldooooddddddddollcccccllllodddooool:,''.':cc,. ..''',;cdxkxlcodd    //
//     :xxxxddddxolccccloolooodddddxxxxddddddddddoollool,''..,:c:'. ..'''',:odxkdclddd    //
//     :xxkxdddodxdlccc::oddoooooodddddxxxddooolllloooc,''',:cc;.  ..''',,;ldxkkoloddd    //
//     :kkkkxxddodxdlcclc:codddoolllooooolllllloooddl;''';:cc:'. ...'''',,:odxkdlodddd    //
//     :kkkkkkxddddxdlcccc:;:cloooodddoooooollcclll;''';ccc;'.  ..''',',,;ldxkxllddddd    //
//     :kkkkkkkxxdddxddlcccc::;;;::ccccccccccccclc;,;:c:;'..  ..'''',,,,;cdxkxoloddddd    //
//     :kOOkkkkkkxdxxxxxdolcccccc::::::::::cclllllolc;'..   ..'',,,,,,,;cdxkxocldddddd    //
//     ;kkkkOOOOkkkxkkxdxxkxddoooooooooooooooooodlc;'... ...'',,,;,,,;;:dxkkoclodddddd    //
//     ;xkkOOOOkOkkkkkkkxxxxkkxdddddddddddddolc:;'.... ..',,,,,;;;;;;:ldxkxoccoddddddd    //
//     ;xkkkOOOOOOkOOkOkkkkxxkkdc::::::cllc:,'.......  .,,,,;;;;::::coxxkxolcloddddddo    //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract ECA is ERC721Creator {
    constructor() ERC721Creator("Eyes by Carlos Aquino", "ECA") {}
}