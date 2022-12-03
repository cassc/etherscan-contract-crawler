// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cydr Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//    .   ....   ..  ..................... ..   .............'''',;;,;:::;,,'.'';odxxxxdddolc:;,,,,,;:clxKXXXKOxoc:;'.........',;ccloddoodkkxkxddxkkxddddddd     //
//    .   .     ...  .......................    ...........',;:ccodddddddddolc:;cdxkxxxxdlc:;,,,,;;:ldkO0Oxoc,.............','........';cdkO00Okxxxddddddddd     //
//              ..  ...................... ....... .....'',:ldddxkdc::lxkkkkxxdoxkOOxddoc::,,,;;::ldkxdl;'.......'''','''';olclc:c:'.......,coxOOkxddddddddd     //
//             ..   .....................  . .........',;:lxkkkkx:.....,lxOOkkkkO0K0xoc:;:;,;;::ldxdl;'......'',,,,'......:oloxxooo;'',,,'.....,:ldxdddddddd     //
//        ........ ........................  .........,:ldkOOO00o'..    .,okOkkkOKKKOxlc;;;:cccoddl;'....';cc,'...'.......,looddoo:...'',,,''.....':lodxxddd     //
//       ............................................':okOO00000Ol,.... ..:k0OOO0XKK0kxoccclooollc,....':llloo:'............;:cc:,...........''......,codddo     //
//    .   .................................... .....';lxO0KKKKXXXK0xdd;...:0NXXKKXXK0kdolcccclc:;'...'cldkkdldd,...........................',,'''......':ooo     //
//    ..   .....CYDR. ............... ........ .....,cdO0KKXXNNNNNNWWNd...cKWWWWNNX0Oxdoc;:;;;,,.. .':dddxxooxl'......'''''.............,codooool:''.. ..;co     //
//    ..   ......................... ........  ....';lk0KXXXNNNWWWWWWWx'.'dNWWWWXXKOxol:;,',,;'....,'':oddddoc'....',coddxdlc;'........;dxdoolllddl,'.. ..,:     //
//    .............................................,:dOKXNNNNNNWWWWWWK:..lKWWWWNK0Oxdl:,'',;;....,;,'..',;;,'.....,lkOkkxxkkOkl,'.....'lkolxkkkxooxc''..  .,     //
//    ';;'......,,'.......EDITIONS ............'',;ccok0X0xoookKWWWWWWk,.'oXWWWNK0kxdlc;'',;;'..':ooo:'.....''...',oOOxdkkkxxxOOd;.....,okooxkOkxooxc..'..  .    //
//    ,;;,.','..,:c:'....      ...''....';;,:clclllcokKO:.....;dOKNWMXd,.';xNWNKkkxol:,',:;'..'ldddxkc''''''''..':k0kdk0000Oxx0kc'.....;dkxdddddxxl,...'.        //
//    ..''..''...'''....      .',;c::::clccc::;,,;;:okKx'..    ..';codxd:..'dNNKOkxdl:,;;;'..'cdkkxxkl,',,,,,,''';xKkdxOOOOkxxOk:'.....',ldxxxxdo:'....'.        //
//    ...........         ..'',,;:::::,,,,''......,clxK0l'................ .'cllc:cc:;,,;'...cllooodo:;;;;;;;;,,,,cxOkddddooxOkc,''',''''',;;;;,''....';,.       //
//    ,,'..........     ..;c:;,,'...'..... .......,cldOKX0kxkOkxxdddoolc'................   ..''''''.''.'''.''''''';clllcccllc;'''',,',,,,,,,,,,,,,''':oc'.      //
//    .......  ........,::;..  ..  ...  ..  ....,;;::lx0KNWWWMMWWWWMMMMKc..:oooooolc:;;,'....'...   ...........................   .. .....................       //
//        .     ...,:cc:,..             .. ..,,,,'',,,:dOKNWWWMMWWMMMMMXl'.;dkOkkkxdolllc:;;;;'.....'::::;,,,;;;;,,,,......,''''''''.....................        //
//     .....  ...,:c:,..   .....        ....;;'.......'cxOKNWWMMMMMMMMMNo'.;x00Okko:,',;:;...      .,ccc;'...';::::c;'..  .,:;;,'','....';;,,,,,,,,,'''.....     //
//    ...  ...';cc;'..   ......   .    ..,,''..     ....cxOXWWWWMMMMMMMNo'':kKKkddc,'...,:'.       .,cc:,.. ..'::cccc;..  .';,... ..   ..,;,''''''''........     //
//    ''...',:c:,..     ..'..... ...'',,,,..           .'cx0NWWWMMMMMMMXl''c0XKkdoo;....,:;'.     ..,c:::'.   .;:::;'''.    ..    ...  .';,''....''.........     //
//    cccccccc,.    ............',,;;,'..     ..        ..ckXWWWMMMMMMWO;.'oXNXKxooc'...,;;'..     .;cccl:'.. .';;;.. ..     .....''....;c;;,,'''','........     //
//    ,:ccll;..    .''...   .',,'..        .....       .';cdkKNWWMWMMXx:'':OWX00Okxl,...':;'...',.....,;::;'.. .,;'.    ..  .;c;'..''...;c:;,,''''''........     //
//    ':::cc:,. ..','..     .,,..       .......      ..:lllloxKNWMWMXo'',oKWNXOkkkkx:'..';'.  .'lc'.   .';:;'.  .........'...';,...,;'..;:,;,,'.............     //
//    .::clc:;.',,,,..   ...''..  .......     .. ...,:c:ccclloxKWMMWk,.,xNWNXX0xxxkko;'',,.     .'... ..'cxoc,.......'cc,..  ......;:'..,;,;,''.............     //
//    .'::::::;:;....',,,;;;,.    ..       ......':ccc,..,:ccldONWWWx'.,OWWXXX0kxxxxl,.....     .:l:'...'lO00kl,.''',:kOxdlc;,'...  .   .'','.''............     //
//    ::clol:;'....,:;,'.....        .',''....,;:cc:'..  ..;:ld0XNNWO;.'dNWNNX0kxxdc'...',cc,...'cxc,'.',lO0OOOxoc:::clcc:::;,,'..  ..   .,,'.'.............     //
//    ::c:;,.....',,'.            ..'::cc:;;:cll:,........;;,cd0XXXNKl..;kWNX0xoodo;...,:lx0Oc'...;lc;;;ck000kdlc,''..'',,,,,...,:::c;.  .',..''............     //
//    ......... ...        .     ..';cccllllc:;'.......,;;,',cx0XNXXXk;..;kKKkoooddc'..;okKNW0:.  .,lxxkO000x:'.';coxkO0KKKk;.  'xNWXl   .''..''............     //
//             ...     ...... ...;;:lllool:,'..    .',;;'..':ok0KXXKK0k:..,dOxoodxkd;...,lkXXd,    .'ckOOOOOl'.,okOXWMMMMMWd.    'x0l.   .''..''............     //
//         .  ...    ...',,.';::cllllc:::,...    .':;'...';:coxO0000000Oc'.':oooxkxc,......;:,.   ...'cxOOOOx:'',cox0XNNWWK:     .,'... ..''..'.............     //
//    .......  .    .';;cc:::c::;;;'',,...   ...;,;,....,::;;ldkOOOO00KKKd,..;oxxko;'....';;'.......',cxOOOOOko:,''',;:ccc:'.   ...,::'..','................     //
//    ....    ......,::::'.............   ...,;;;.....,:;;,,,;coxkO00KXNNXx;..,ldxxo;....,oxdoollllodkkOOOOOOOOkxoollc:;;,,,,;;:cldxxl'..';'.  .............     //
//    ...........',,,,'..             ...,;::,'.....';:;,'....,cdkOKXNNNN0o;..,lolodo:...':xkxxkkkkOOOOOOO0OOOOkkOO00OkkkxxkkkOOOOOkxl'...;'.  .............     //
//    .'''..'''''......             ..':lc:,'.. ..,;;;,'..  ..,:ok0XNNXOo;'..;dkxolcll;...;dkkxxkkkxolccldkOOOOOOOOOOOOOOOOOOOO0OOOOko;..';.   .............     //
//                               ..';:::::;;'..';;;,;,.. ....,ccoxOKXKo,..,coxOOOOxlcl:'..,oOOkkkdc;'....'lkOOOOOOOOOOOOOOO00OOOOOOOOxo:;,'.   .............     //
//          ..           ......','.....,ccllccc:;;;,,....';:cccccokKXKl'..;ldkkkOOOxlcc;..':okOxl,...'::'.,okkkOOOkkOkxdkO0O00OOOOOOOOko:...   ...'.........     //
//       .',:;,.           ..         .,::lllll:,,'....;ccllol::lx0KXX0dc,..,:oxkkkkoc::;,;;;ll,....,lkd;..:kkkkOOxoc;'';d0OO0OOOOOOOkl,'.... ....'.........     //
//      .,:;:::;.                    ..,::cc:,''.....,:colcccc;;lx0XXXXXKxc,..';oxxxdc;;'',,''.....,okdc'...cxkkxl;'.,,..,lkOOOOOOOkkko,''.',....''.........     //
//    . ..;:::;.       BY        ..'''',,''.......';clolccc:;,'.;x0XXXKKKOkdc'..;ldxo:,'..','.'..',ckx:'.   .:lc,'',ldxo;'';dOOOOOOkkkkdc:;;,.  .;,.........     //
//    '''',;;,...          .....'.....         .':::clllc:;.. ..:x0KXXXXXKOd;...:odxl,.....'',cccldxxxo,..   ...';lkOOOOxl;,ck000OOkkdl:;....    ,;...  ....     //
//     ..'',,,,''...........'...            ..;:::;;::cc;.     .:xOKXXNXN0o,...:dddo;......'..;ldkkkdl:'...';::cdkkOOO0OOOkxkOOOOOxl:'........   ,:...   ..'     //
//            .....''.....     CYDR      ..';;:;,,::;;,.  .   .'ck0KXNXXOc....cOkdoc,.....''....';:;'...,:ldkxxkkkkkOOOOOO00OOkdl:'.......'','. .';...   ...     //
//                                    ..,;;,,;,',:l;..        .cdk0KXXXO:....,k0xoc,'..........     .':ldxxkkkkkkkOkOOOOkOOkoc;'...',,,,,,,'''.  .,'.     ..     //
//      ..                      .....';;,,;;;:;;,,..        .,:loxO0KXKd'.  ..;odo:'''.......    .....,:oxkkkOOOOOOOOOOkxo:,....',,,'''',,'....  .'.. ... ..     //
//                      .,;;;'',;;:;,',,',:;;,'..           ..'codxO000x,......;oo:......    ....'''....';ldkkxxxxkkkxo:,.....,;;'.''...'......  ......:'  .     //
//           .     .....:llllc;..''',,,,,....                  ..;cloxkko,....'cl:,....   ........',,''....';::;::::;'.....'',,'...''...'......  .....;Oo.       //
//    .     ...........,oodxdo:.......                           .';ldkOOxl::lx0xl:'................'''''......'......',,;,'''............'....  .'...cOo.       //
//    .................;oldkdlc;'.                              ..,cdodddxkkO000KKkc,'',;:;............''...     ....,;,..'''...........'.....    ....ld:.       //
//                                                                                                                                                               //
//                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CE is ERC1155Creator {
    constructor() ERC1155Creator("Cydr Editions", "CE") {}
}