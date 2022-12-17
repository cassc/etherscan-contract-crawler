// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Classic Players
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    llccoddddooolllcc:::;;;,,''......          ..................'',,,;;:ccloodddxxxOOlckkdoddoooool:;:;    //
//    ,;;:llooxxdddddxdddooodxxkxddxdoollodddlcldddxxxkdodxkkxxxddolldxdodkxdxOkkxdddokk:;:;,'............    //
//    ......................,;cllolcc::::codo:;clolooloc;::c::;;,,'''''''''''','',,,;lOd;,;,'.............    //
//      ....................,,,,',,''''''''''..'''.''''.....''....''..''''''',,,,,,;cdOkc,;,'''........'''    //
//      ...................'....'''''..'''''....'..''.......''...'''''',,;;,;::;:::cdkk0o,,;;;;,,,,,,;;;;;    //
//    ..................','.....;:,''''''.','.'',;;;,,,,,;,',;;,,:;;;:::::::::::::;oOOOKx;,:cc::::cc:cc:;:    //
//    .........'..',,'',;;;,,:oxc'',;;,,,,;:;;;;;:::;,,,,,;;:::cccc:ccccc:ccccccc:cx0KKKOc;clcccccclccc:;:    //
//    ..'',,'',,',;;;;;;::::;'.'..,;;:::::ccc:cc:;'.......';:::llc::cc::lloocllccldkKXXX0o:llllllc:cc:;;;;    //
//    '',;:;;:;,;;;;::::::ccc;.  .,:;::cclcccccc,.    ..   .;ccllolccllclolccolcclxkKNNX0l:loooolcccllc:::    //
//    ;;:::;:llcc:;;:::cc:cll;.  .:c::cccclllloo:',;:lol:'  .:llodoolllloolcloolcodoONNNKl,:oooolccccccccc    //
//    :::ccc::cc:::cccccc:ccc,.  .;cccc::coolddoooddoolc:;. .;lllllooooodxoloolccoddkNNNKl',codolllc::lccc    //
//    :cc:;;::;:::cc:;:c:cl:c,.  .'cccc:;clcll;''';;;;,'..  .;c::lllol;:oolc:cooloxoclx0Oc'':dooollcclolod    //
//    :cl;,,;;;::;:ccclc:clll;.   .:lclc:coool'......'..    .';cdkococ.,odllllododxl,',;:::;lxxdddooolccc:    //
//    c:ccc:,,::cccc::cccc:cl;.   .:oloollooooc:c,....      'lddxdlcol,:x0Oo:::oodxc'''''lkxl;,''.........    //
//    :;;:llclccccllccccclc:c:.    .',;:cloollc,...         .,:cldxxxkkxkOkx0K0kdxd;....;dkOOo;,,;;;;cc:::    //
//    ccc:cccccc:clllcccllcc::.           ...... ...         ..;clc:codxxxxk00xc;l:.....,cldkxllododolllll    //
//    OOxxxxxxdddoddddooollllcc;,....                        .';col;,',:clooxxo:,:;.....'..,ldoooddxdddddc    //
//    ccclooooddddxxkkkxxkxxxdddddoooc:;;;;;'.   ..          .',;colc;'...':odxdlo:'....'..';cc:;:::;;;;,.    //
//    ..............'',,,;;::;;::::::;;;;,,,'..  .','.....'..,::ccccc:.  ..:odddool:;,...''...............    //
//    ,;;,,,,,,,'''''''...................',,'.    ......''..,;:cc::'.    ,:,;;:;::lddlcc:::::cccccllllccl    //
//    lllcccllollllooollccllolc,...'cllollcccc,..,'    ..''...',;;;.. ... ';'....':::cc:cloollllcc::::c:::    //
//    ...........'''',,',,,,,,;'.  .',,,,'','..  .....  .............''.. .,'..''''',,...,,'............';    //
//    ;:::;;;;:::::::::;;;;;;;;,..;cccccll:,,,,,,;,;;.    ..  .......'..  'xd,........;cloollllccooc,..'od    //
//    odooollllllllllllccccccc,..'odc::cooxocllllllcc,.    ............   .:;'......,xOdc::::::::::,'..;oo    //
//    ......''..',col:'...'''.....',....:ccllc;'.......    ..             ...... ..,coxxc,'',,'..  .......    //
//    ,::;,,;c:;,;kXXx:..,,'.....  .....;ol::lollll;;'...            . .. ...    .::',oxkxoc:;,.. ........    //
//    cccoxd;..'..:odc'. ..      ..   ...:c'..'o0Oo'.. ....      ..',,,,'...,,.   .,':odkkdc......  ..        //
//    codx0O;..,:;;cc:;...     .cxo,......,;. .,l;....  .'l:. ....''',',,,,;;;;'. .';;ldxdo;...               //
//    cdOkkO:..,clc:::,.      .;clolcc:,':ll,  .,,,;,.   .cc,..',;:;;;:clddddoll:.':c,,:cc,.                  //
//    'loccdl,;;:::;;:,.       ....'''',;clc;'',,;cllc,.....':lddk0K0kxxdk0K0kc,'.';:cc,':;.                  //
//    :oxkoodxkxxl:;;:;.            ...',,,'',;;,,:dOx:',,;:cldxdk0NWNXKOdoxxoc:;..,'''';;;;.                 //
//    llkKOkxxO0KOxodxc.                ..';:;;:cloxkdllolc::clllloOXWN0ko:codddl'...   .,lxc.                //
//    clolccoxkOxk0Oxxo;.       ...     ..';ldkkxdl:::::;;,,;::cclok0XNKxl:;codo;....   .:ox:   .','          //
//    OdxdclkKOxolol;;cc:,.      ..    ..:xOOkkxc;'....'...',;::coO0000kolc:;;;'.'c:.    .;l:'';lll:.         //
//    KOxdxxkkoc::;;;lolol:'.      .. .':xK0occ;,'.'..........,cdk000kolllcc;',cclxc.....,::::;,:c;.          //
//    OK0xlcl:;;cddc;:ldx0Ol'..'......;oodOOxoloolll:;;:::;,'.:kXXXKOdlc::,'.':ddxxlcc:;dkxl;'...,'.....      //
//    ddo;.,;;:lONKOd:'',cc;:cloddoodkO0KXX00KXNNNNNXOk0KXX0ko:o00kxoc;;;;,,,:kOxkkdxkO0NWN0d:'';;;;:c;...    //
//    ::dko::loOX0xOkc:;;:cokOOKKXXKKKKKKKKK00XNNNNKkdxO0XXXNKx:cl:;''',:cccokK0OO0xd0XXXXX0kxl;:ldxkkl. .    //
//    lloolclod0XkdkkxkOkxkKKkkKKOk0XXKOOkkOOkOKXX0xodk0KXXXK00l..''''';ldxOXNXKKX0xkKNN00X0kxloxxxdolc;''    //
//    ;:;'';:ld0XkxOOO00o;dKOxkOxookKXKOxxxxxk000Odlodk0KK00O0k;...';:coOKXNNWX0KXOkOKNNKO0Oxddkxooddooc::    //
//    ,;;'..,coOX0xxOkxkl'lKXOxxdxxk0KK0xolookKKkdloodxOOO0Oko,.',,:dxxk0KXNNNNKK0kO0KXXK0Okxxkkxddoddolc:    //
//    .,;:,'';:dKXOkOkOOo';xX0xxkkxxO00KOdllloxxdooddxkOOOko:,,;;;;ldoddxxkkkOkxk0OO00XXXNXkdolcllolllcll:    //
//    :c;;:;'',:xKXKXXKOc''l00kxkkxdkOOO0kolllloddxxkkOOOkl,',,'....,,:clooddo:;:oxOKXNWWWNOc;,,,;;,;cc:ll    //
//    xKxccl:,'':dOKKKkc'..ckOkdllooxkxkO0xoooddxkkkOOOdl:''.......,::cc:::::;,,lk0KKKKK0KX0c'......,,;coo    //
//    :xxolldkl',cdxxdl,...:xkxl::cldxxkO0OddxkOkkxxxdc.........;ldkO000OkddoccdKNXK00OO000Oc.......''',:;    //
//    .,dOolOXk;,ldddol,...:ddol::clollloolc:codc,,,;;...''.'cdkO0KKXX0KNNNNXKKXK0XXXK00Oxxd,  ...',;;;,'.    //
//    ';dOkdkdc,,cxxxdo;...:oooollllloollc:::coo,..'cdl::cc,;d0XNNNNX0xkXNNNKkkOOkkOOkxdoooc. .  ...'''...    //
//    ';:::;,',:,,lxxdo;...:odxdddooodxddolccldl;'.,odl;,,''.':oxO000kkk0XXXXOkOkkxxddooooc...............    //
//    .'......';,';lodd:...:oddddxdddkkkxxdlloollc',ol:::;'.......,:ok000OO00000OOkkxxdl:'....','.........    //
//    ...';..',;;'':coo:...:llldxxxxxkOOkkxooooddl::dl,'''....      .'cxkdodddk0KK0koc,.  ......,'.......     //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract nrhmn is ERC721Creator {
    constructor() ERC721Creator("Classic Players", "nrhmn") {}
}