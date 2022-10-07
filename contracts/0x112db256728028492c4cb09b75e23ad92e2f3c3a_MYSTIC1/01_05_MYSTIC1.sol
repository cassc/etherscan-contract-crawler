// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mystic Waters
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    :::::::ccccccllllllllllloooooooooool,..   ........';:c:;,'................                                           ...    //
//    :::::ccccccccllllllllooooooooooooodl,.....';;:coollclllllll:;,,',::;'.........                                        ..    //
//    :::::ccccccclllllllooooooooooooooodl;.';:clollloolcclolcccc:;:cllol:,..........                                       ..    //
//    ::::cccccccclllllllooooooooooooooool:;::llllcccllloc::lc;,''',:cllllc;,'..........................                   ...    //
//    ::::cccccccllllllloooooooooooooodoc;'..',,;;,',,;,,;;::cccc::::ccclllc:;,,,,,,,,,''''''''''.............................    //
//    :::cccccccllllllllooooooooddddoll:,.....  ..........',,,;;:cllcc:;::::;'..',,,,,,,,,'''''''''''.........................    //
//    ::cccccccclllllllooooooooddddol:;'. ..               .........',,,;;,,'.....,;,,,,,,,,'''''''''...''....................    //
//    ::cccccccclllllloooooooodddddol:,..           ............     ..''',,,'....,;;,,,,,,,,'''''''''''''....................    //
//    ::cccccccllllllloooooooodddddol:'.....'''...',,;;,;;;:cc:,....  ......';;,..';;;,,,,,,,,'''''''''''.....................    //
//    ::ccccccllllllloooooooodddddoc,....,:cllc:;:looodoollodxdol:;,'........;lc;'.,:;;,,,,,,,,''''''''''.....................    //
//    ::cccccclllllloooooooodddddol;...,clddddolodddxkkOOOxxkOOOkxxdo:;'.....,:c,..,::;;,,,,,,,''''''''''.....................    //
//    :ccccccclllllloooooooddddddoc...:oddxxddoodxxkkO000KKKKK00000OOkxdl;'..',,'..,cc:;;,,,,,,,'''''''''.....................    //
//    :ccccccclllllloooooodddddddo;..,oddddddddddddxxkkOOOO0OOOOO000000Okkdc;,,;,..,cc:::;;,,,,,,,'''''''.....................    //
//    :ccccccclllllooooooodddddddo;..:oddddddddddooodddddxkkkkkkOOO0000OOOOxl:,'...,clcc::;;;;;,,,,,'''''.....................    //
//    :ccccccllllllooooooddddddddo;..:ldxxxkkkxxddolloooddxxxxkkOO00000OOOkdoc;'...,lllccccc::::;;;;,,,,,'....................    //
//    :ccccccllllllooooooddddddddo:..:ldxkO0KKK0OkxoodxxkkkkkkkkkkkkkkOOOOkdc:;,...cx0000000000Oxoc::;;;,'....................    //
//    :ccccccclllllooooooodddddddo:..coxxkOO0000OOkxdc;clccccccclolloxkkkkxo:,,'..,lx0KXXXNNWWWWWN0kocc::,'...................    //
//    :cccccccllllloooooooodddddddc..lddolloddddxkkxc..;::::cc:,;:,,;lxkxxoc,.'...;:;:ldk0XNNNWWWWWWXK0kxoc;,'................    //
//    ::ccccccllllllooooooooodddddo,'ccc:::ccclloooc.  ...''''''......:dxdl;....':::ldOKKK0OkxxkO0KKXNNWNNXKOd;...............    //
//    ::cccccclllllllooooooooooodddc;;:cloc,',:::;,.',,,,,,,,,,;;;;,,,,:oxdl:::,:ooxKK0OkdolcccclloddxkO0KKKKOl'..............    //
//    ::cccccclllllllloooooooooooddocd0KOo;.':lc;,;;,'...............',;clooloc,'cxdoddolc:;;:llc::ccllloddddo;...............    //
//    :::ccccccllllllllooooooooooddook0K0x:,;::,'... ..','.'.............';clc....;ccc:,..'..,oxo'',,;cllllooc'...............    //
//    :::cccccclllllllllooooooooodxddoooxo,,;,.. ..........................'lc.. .....''...,;:dkd;,,',;;:clol;................    //
//    :::ccccccclllllllllllllooodxxkdc:co:';;.. .,'......          .....,,. .,'.   ..',:cloxO0XNXOo:'.';clllc,................    //
//    ::::cccccccllllllllllllloddxOOo:;::'.'....,'...                 ...',. .''.,cdkO0XXXXXKK0O0KKkl;;:ccll;.................    //
//    :::::cccccccllllllllllllodxdol::::'... .','...                   ....;,..'lOK0OkxxkkxddooodxO0Od;,;clc'.................    //
//    :::::::ccccccccccccccccc:;;;;;:::;... .,;'...        ....         ...,:' .;llc:::::cc::ccllloxkOxlclo:'.................    //
//    ;::::::cccccccccccc:;'.....;:::cc'  ...;:''.         ...'..        ..';,. ':c;;;;;;,'..';cllloxkO0Okd:..................    //
//    ;;:::::::cccccccc:,..   ..'cc::::'  .....''.      ..     ...       ...... .:;'.'',,,'.. ..';clodxO00x:..................    //
//    ;;::::ccccccccc:,.   ..  'ldlc:;,.  .....',.      .........        .'.....'cloodkO00Oxoc:;;;;;:lok0K0o,.................    //
//    ;;;:::cccccclc:'. .. ....:xxdol:,.  .....';;.       ......        .''.....cxkOkkxdxxkO00000OOkkkO0000k:.................    //
//    ;:ll:,'''',,;,..  .......;loodxxo;........';,.                   .''.....'cllccc:::::coxkkO0KXXNNNX0xo;.................    //
//    ;::cc:,''',,,.............;:ldxkkdc,...'...';;'.               .',,......;lc;,,,,'',;:cclodxxO0KXXKOo;'.................    //
//    .  .cdlclloo:.............';lxO0KK0koc;,,....,;:,'..      ...';;;'......';:,.       ..';cccllodkkOkdc,..................    //
//    .  .cxdodddl'..............;oxO0KXXKK0Oxc,'....',;;;;,,,,;;;;;,'......';,.             .,:ccccllldxl;'..................    //
//    ,. .:xxdddo;......  ....  .,ldxxkkO00000Od:'.......';:;;:;'.........','.''..  ..       .';cccloollo:''..................    //
//    ;,..:xkdddc.........  ... .,ccc:ccodxkOOOkdc;,'.....',''''......,;;;,.  .;:,'...... ....',;:lddollc,.'..................    //
//    ;c;.:xkxdo:..  ..  ...    .:c;,'',;:lddddolll:,'''''''..'',;;;::coddc,. .'cl:;'.... .',',;:coddlcc:.....................    //
//    col,;dkxdo;..            .,oo:;cldxdo:;,,,,,,,;:ccccccccccoddolcoxkOd;.  .'clc:,'..  .,,;;:lodddol:.....................    //
//    oxo,;dkxxo,....         .,lddooxkOOxc;;;::;,,,'''..'',,;;:cc::::clodc.     .;ll:;'.   .,;:clodxxxo:.....................    //
//    loc,;dkxxc.  ......   ..:ldxxxxxxddooodxkkdlc::;,.....',,;:cccccccc;.       ..:lc'.   ';:ccloodxxd;....................     //
//    ;cl:;oxxd;. .  .......;loooddddo:;:::coxO0Odlccccccclllllllcc:,''..           .,c,   .,;:cllooodxd;.................        //
//    ,;:;;lxxo,.....  ....cdoc:::::;,,,;;:cclodolcclloolc:;;;;,...                   ..   .;:ccclloodxxo,...............         //
//    looooddo;....      .col:;;;;;;:::::ccccc:ccc::::;,,,,;;,.                      .    .;:cclllllodk00k:............           //
//    kkkkxl:'..  .     .clc;,,,,;;:c::;;;;;;;:::;,,,,,;;;;,'.                    .........,clloollooxOKKKx;.........             //
//    l::ccc:....     .;oxdolc:,'''''',,;;;;;::cc:::ccc:;;,.                    ............,lllooooodxO00kc..........            //
//    ....;:'...   ...;oolc;;;::,.....'',;:::cccllloolc:,..                   ...............:llloooooodddko,...........          //
//    .',cl;.   ... .;c:;;;;;,;::,.......''',,,,;::::;'.                     ................,lllllllllooldxo,....','.........    //
//    :cloc.  ...  .;cllccc::;;;;;'...','.  .........                        .............  .,::cllccloddoodxd;...,:;,........    //
//    llll;. ...  .,::cllllc:;,''',,;::'.                                   ..'''.......... .';::cccclodxdooxkxc'..',..    ...    //
//    lll;.  ..   .;;;:cllc:,''',;:clc,  .....                              ................ .':ccllccldxxdodxkkl'.',...          //
//    llc'  ....  .,;;;;;;,''',;:clol,  ........                            ...         ....'.';:llllcclodxdddxkkolc;........     //
//    cl:....    ..,;;;,,''',;:clloo;.     ..'.  ..                        .'.          .. .';;;:loollcclodddddxkkkkd;.....'.     //
//    cl:;;;.   ...,,,,,,,;::clooddo:.    .......',..                     .''.....    ..... .';;:cloollcccoooooddxxxkd:.....      //
//    ccccl:.  ....',,;;::cclooddddddc. ....  . ...',..                  ..'.';ccc:...''.... .,,;:cllllccccloollodddxxdc,.        //
//    ccclc:,. ....';;::cclloodddddddo,.... ........',;,..               .'.'lllc:;..''..     .',;clllllcccclllcloodddddo:'..     //
//    ccccc;,.....',;:cclllloddolc:;;:;........'''''',,,,,'..           .'.,:ccoc..''....      .',:cllllcc::cllccclooooddo:'..    //
//    c:cc;,'...'''';;:;;;;:c::;,,'',''...   ........'...',,,..        .'.,ol:c:'.'..   .    .  .,;cclllcc:::ccc::cloooooooc'.    //
//    ;;;;,,,'..''...''''.'''..''''..           ............','..     .,',cddl:'''.              .;:cccccc::::ccc::cloooolll:.    //
//    ,,,,',,,,,,'.............',;:,.           .................    .,',cldo:,,'.             . .,::ccccc::;;:cc:::clllllccc'    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MYSTIC1 is ERC721Creator {
    constructor() ERC721Creator("Mystic Waters", "MYSTIC1") {}
}