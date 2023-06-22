// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Thomas Creative Coding Art
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    ccccccccccccccccccccccccccccccccccccccccccccccccclcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccclllllccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccclclloooolcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccllooddxddoc;,,,'',,;;:ccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccllloddxdolc:;,,''''',,,,,,;::ccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccllllllllllc::;,'..':cc:;,'',,'.'''',;:cccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccoolcc:,,;:ldl,...:ddo:,'.''..........,:cccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccc:cllc;,,,,,coxd:''.,odl:.. .'.. ..........',:ccccclccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccc:;;;,''';ll;';:;....':c,..   ...  ..,,'.......';clcclccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccc:,'.......;:,........':'. ..  ...  ..lo:'.........;cclcccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccc,................  .,:'......... ...:l;............':ccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccc;. ............... ..,'.... ........'.................;cccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccc;..   .................................',..............':cclcccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccc;..,'':cloooolc:;;cc;,'..'.........',;:oxdllccc:,........,cccclcccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccc:',looOK0OOOOO0OOOkO00Okoll,';ccoxxxkOO0OkkkOkkkxo:'......':cccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccc,,lclOK0OOOOOO0000Oxk00000kxxOOOO00KK00OkkkkOOOOkxd:.......;cccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccc:;;,,dOOOOO000OkkkxxxkOO00OOOOO0OkkO000OOkdxkkOOOkkOkc......':clccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccc:,...,dkkkk0KK0OOOkxxOkkkkOkxkkkOOOOOOOOOOOkkkO000O00Oo'......,ccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccc;.  .:xkkkk0KKK000OOOkkkkkkkxkkkkOkxkkOkkOOOOO0KKKKK0xc'..... .;clcccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccc;.  'okkkkkO0KKKKK0OkkxkkkkkkkkOOOOOOOOkxkOOOkOOO000Odc'.......,cccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccc;. .cxkkkkkxkkOOO00OkxdxkkkkkOO0000OkxkkOOOOOOkkkOOkkdc.      .,cccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccc;. .ckkkkkkkxkkkkOkkO0OkkOO00KKXXXKKOkOOOOOOOOOOOOOkkd:.....  .;cccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccc'. .lOkkkkxxkOOOkkkOO00KKKXXXXXXXXXXXK000OOOO0kkOOkxxxl'....  .:cccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccc.  .xKkxxo::lolllllcccxO0OOKXXXXXXXXK0Oxddolllc:::cldxkc.    .,ccccclccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccc,. .xXOl;..........  ..';:lxOK0dllc:,'.... ........,cdko.   .':cclcccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccc;. .dXk:'',;;,,,'...,;;'..':oxd,.....''....',,;:::clclxo'.. .'cccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccll:. .dN0olc:,''......,:c:;;;cxOd;'''';:,'.......',;looxkx:...';cccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccclo:..dNKkdl;'.......'..',;;:o0XOl;;,,,,.',........':oxkOk:..,:::ccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccloo:;,dNXOdoooolc:::;;;;:cc:lx0Oxolc;:cccccccccclodoox000k:..'',:cclcccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccddoolkNX0xddddxdoolcccllllodkOkxdollloooooooodxxxkOkOKK0xc',,,;ccclcccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccoxd:;kNX0xddxxxxdddoooooodxxxkkkddoookOxxkkkO0KKKKXKKK0Oxc,;:;:ccclcccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccldc,:ONKOkxxxxxxxddoddxxddxxkOOkddooodkxk0KKKKXX0k0XXKOdollc:;:cccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccclclddld0K0xxxxxxxxxxdddxxxddxOXNKOkkxxodxk000O00KKOdkKKOkddool::ccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccllxO00OOxooxxxxxxxxdxxxxddx0K0kxkkxxddk00K0000OO00OOkdoodolcccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccclcldkxdxxddkxxdddxddxxxxdoooolcccc::llx0K00000Okkxdl:lodocccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccclccllllloddxdddddxxxkxxxxo;'',;:;;;,,:ok0KKKK0Okxdooooool:ccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccllooodxdddxxxxxxxxxxolc:::cccccodxO0KK00OOkdodxxoc:cccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccclddoodxxxxxxxxxxxxxxkxocloooodddxOKKKKKOOxdodxdc:cclcccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccldkkddddxxxxxxxxxxxxxxdoodddxxxxOKKK0Okkxdddddlccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccclcokOxxxxxxxkkkkxxddolllllllllloodkkkxxxxxddddollcccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccldkkkkOOkO0K0kxdl:,,;;:;;;;;;:::ccldddxxddoolllcccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccloxkkkOKOOKX0oc:;,,,;;;;;;;;;;;;;:odoooddoolllccclccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccclloxkkkkKK00KKKK00Oxollooooooolooooddolooolcclcccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccllldxkkk0XXK00KXX0kdl:::::::cloooooooooolllllccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccllloxxkkO0KKKOO0KKkdl:;,''',:looooooooooool:::cccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccclloxkxxkO0O0OkO0KXXKK0Oxdooooodddoooodolc:ccc:ccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccllok00Oxkxk00O0KKXXXXXXKOkkxxddddddool:;clllc::cccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccllxKK0kOOkkO0KKOOKKOkkkkxxxxxxddool:;clloolcc::ccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccok0K0KKK0xddO0Oxxdoodxdooooooooc:;;:lodddool:,,:ccccccllccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccc:;;oO0kk0KXKOdlloolcccc::cc:::;;:;;;;;coddddollc,.',;:cccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccc:,'';d0K0OkOKKX0xol:;;,''','''',;:::loc;lddddollll;....':cclcccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccc;''';okKKKX0kk0KXKkollccccllc::ccccloddlcllloolccll;''....;cccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccc:,'',:lkO0X0KX0kkOKXKkxxxO00kddooolcldddoc:cloddollol;cl,....':cccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccc:;'''',;lOO0XKKKOO0O0XKOxxxk00Oolllllodddolcclodddooool,.,.......,:cccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccc;''''''',l000XKO000KOO0XKOxxkOkd:;;:looddollloooddooolo:...........,:ccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccc,.'''''.',;o0KX0kO000Oxx0XK0kkkd:,:cloodooooooooodddolc:'............';;:cccccccccccccccccccccc    //
//    cccccccccccccccccccccc::,..'''''..'':xKXKOk0OkkkxxOKOkxxdccoooooooooooddddddol:;'....''...........',;:cccccccccccccccccc    //
//    ccccccccccccccccc:;,,''.............';lOKOxOOxoxkkxxlllooooooooooddoodddddooo:;'......................',;:cccccccccccccc    //
//    ccccccccccccc:;,'.....................'cO0kk00kddkOOkdoddddddddolooloooodlccc,.........................''',,;:cccccccccc    //
//    cccccccc:;,'....................''.....,ckkkKKOkxxOKKOxdoooooooolc:codooool:,...................'''''',,,,''',;::ccccccc    //
//    ::;;;,''.........................'....':c;;lOOxkkdokKX0kdooooooolcllooooooc'.................',,,,,,,,,,,,,''''''',,;:cc    //
//    .......................................',,.'cxxxkxooxO0Odooooollllooooolc,..................',,,,,,,,,,,,,,,''''''...'',    //
//    .............................................'coxxdooodxk0Odolcloloooc;'.................''',,,;;;,,,,,,,,,,,,''''''....    //
//    ...............................................':oddooookKXklcclolc;,...................'',,,;;;;;,,,,,,,,,,,,,'''''''..    //
//    .................................................';cololclllccc:;'...............'''...',,,,;;,,,,,,,;;;,,,,,,,,,''''''.    //
//    ................................................;;..,:lol;,,'...:d:............',,,...',,,,,,,,,,,,,;;;;;;,,,,,,,,,'''''    //
//    ...............................................,xd'..'lxx:...  .':,...........,,,'...'''''''',,,,,,;;;;;;;;;;,,,,,,,''''    //
//    ..'........'''........................................:l:'.................,;,,'...',;,,,,,,,,,,,;;;;;;;;;;;;;,,,,,,,'''    //
//    ''''......''''''''''''...'............................,,.''................,;'....',,;,,,,,,,,,,;;;;;;;;;;;;;;,,,,,,,,''    //
//    ''.'......''''''''',,'''''''''''..........ll'.........',.'.......................,,,,,,,,,;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,    //
//    ''.''......'''...'',,'''''''''''''........,,..........''.''....................',,,,,,;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,    //
//    ''..''.....''...'''''''',,,,,,,''''...........................................',,,,;;,;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,''    //
//    .'........'''''''''''',,,;;,,,,,'''.........................................',,,;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,    //
//    .'.........'''''''',,,,,,;;,,;;;,,,,.......................................',,,;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,',;    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TCCA is ERC1155Creator {
    constructor() ERC1155Creator("Thomas Creative Coding Art", "TCCA") {}
}