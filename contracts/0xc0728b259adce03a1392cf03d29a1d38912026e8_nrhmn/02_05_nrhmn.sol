// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Opening Speech
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ,;;;;;;;;;;:::::::::::::::::::::::::::ccccccccccccccccccccccccccccccccccccccc::::::::::::::;;;;;;;;;    //
//    ,,;;;;;;;;;:::::::::::::::::::::::::::::cccccccccccccccccccccccclloddxxkkkkkxxdolc::::::::::::;;;;;;    //
//    ,,;;;;;;;;;::::::::::::::::::::::::::::::cccccccccccccccccccclodxxkkkkkOOO00KKK0Okdlc:::::::::::;;;;    //
//    ,;;;;;;;;;:::::::::::::::::::::::::::::::ccccccccccccccccccodxxxxkkkkkkkkkkOO00000Okxoc:::::::::::::    //
//    ;;;;;;;;::::::::::::::::::::::::::::::cccccccccccccccccccldxxxxxxkkkkkkkkkkkkkkkkOOOkxolc:::::::::::    //
//    ;;;;;;:::::::::::::::::::::::::::::cccccccccccccccccccccoxxxxxxxxkkkkkkkkkkkxxxxxxxxxxdocc::::::::::    //
//    ;;;;::::::::::::::::::cc:::cccccccccccccccccccccccccccloxxxxxxxxkkkkkOOOOkkkxxxxdddddoolcc::::::::::    //
//    ;:::::::ccccccccccccccccccccccccccccccccccccccccccccccoxddddxxxxkkkOOOOOOOkkkxxddooolllcc:::::::::::    //
//    :::ccccccccccccccccccccccccccccccccccccccccccccccccccodddddddxxxkkkOOOOOOkkkxxddooollccc::;;::::::::    //
//    ddxxkkOOkxdollccccccccccccccccccccccccccccccccccccccldddddddddxxxkkkkkkkkkkxxxddoollcc:::;;;;:::::::    //
//    xkO0XNWWNNXXK0kdollcccccccccccccccccccccccccccccccccoddddddddxxxkkkkkkkkkkkxxxdddoolcc::;;;;;:::::::    //
//    oxk0KNWWWWWWWWWNKkdllccccccccccccccccccccccccccccccldxdddddddxxkkOOOOOOOkkkkkkxxddoolc::;;;;;c::::::    //
//    xxkO0XNWWWMMMMMWWN0kdlllcccccccccccccccccccccccccccoxxddoc;,,,;:ccodxkOOkkkkkkkxdolc:;;;;;;;:cc:::::    //
//    xkO0XNWWNNWWWWWWWN0dxxollcccclccccccccccccccccclllloxxddl,''.........;oxkkkxdc;,'.......,;;;:cc:::::    //
//    kOKNWWWWNNNNWWWNKOoc:clllllllllcccccccccccccccllododxxddolodolc;,.....:dxxxo;.....';;;;',;;;:cc:::::    //
//    00XWWWWWNNNNXXX0d:;;:::cloollllllccccccccccccclccclodxooll:,'',,',;;,,;okxl,...,;;:cccc:;;;;:::;;:::    //
//    K0KNNNNXXNNXXXXKkl:codxxdxxollllllcccccccccccclooc:lddoll:'',;cc:cclooldkx:'';:lc;,.....',,;::,',:::    //
//    KKXXNXXXXXKKKKK00OOO0KKKK0Okdllllllccccccccccclol::lddooooolccccclodddodkx:;clool:;;'...,,;::,',;:::    //
//    XNNNNNNNNXK0OOKXNWWWWWWWNXK0kdolllllccccccccccloddxdddoodddxxxxxxkkxddodkdc;:ldooc::;;;;;,;:;'';::::    //
//    NNNWWNNNXXXKO0NNWWWWWWWWWNNK0kdoollllcccccccccccccllodolodxxkkkkkkkxddddxdl::lodxddollc:;,;::;::::::    //
//    NNNNNNNNXXXKk0NNNWNWWWWWWNNXKOxdoollllcccccccc:,,,,,:lcclodxkkkkkkxddddxkxoc;coddddoolc:,,,;;;;:::::    //
//    NWWWNNNNNX0kxOXNNNNNNNNNNNXXK0kddoollllcccccccc;;:;,',,;:lodxxkkkkxo;,:lol:,,coooooolc;,'',,;:::::::    //
//    MMMMMWWNK0Okkkk0KXXXXXXXXXXXXX0xdoolllcccccccccc:'.....',:coddxxkkxl:;;'.. .'cloollc:;''',,,,:::::::    //
//    MMMMMMMNXK00Okxxxxdox0KKKKKKXXXOdoolllccccccccccc:;;:;'',;cllloddxxdool:,''';ccccc:;,'..',:ccc::::::    //
//    WMMMMWWNXXKK0Okkdl:;;d00000000Oxdolllccccccccccccclloc;,,;clccccloooooooolc:::;;;;;,'...';::c:::::::    //
//    WWWWWWWWNNXK0OOko:,''ckOOOOkdddoollllccccccccccccccc:,,,,;:lllc;,,,,''','''''...';;,'..'',;:::::::::    //
//    NWWWWWWWWWNK0Okdc,..;oddxxxxl:cclllcccccccccccc:;'..  .,,,;:odxdc;;;,,,,''.....,cc;'...'......',;;::    //
//    WWWWWWWWWNXKOxo:,...'loodddooolccccccccccccc:,..      ..'',;codddolcc:;;;,,'',:lc;'.....        ...,    //
//    WWWWWWWWWNKOxl:'.....,ccllclddlcccccccccc:,..         ....',;clddddoolc:::::::c:,......            .    //
//    NNWWWWWNNKkdc;'.......';cccoocccccccc::;..            ,;....',:lddxxkxxddollc:;'.....                   //
//    NNNNNNKOxdl:;'........';::cc,..........               :l,'. ..';codxkkxxxdolc,....'.                    //
//    NNNNNXxcc::,,''':ccc:,';:::,.                         ;dc;'.   ..;:clllllcc;'....,,.                    //
//    XXXXKOl;;;;,'',oxddol:,,:::'.                         'xkl;'.     .............,c;.                     //
//    OOkdool:,,;;;;lxxdolc;,,;;;:;.                        .d00kl,.       ..   ..,:ll:.                      //
//    ;;;;;::::clll:cdol:;,,..,;:ldo,                       .d00KKkl'.   ....';cooool:.                       //
//    '..'''',:cccccll:,'......,:ldxo;                      .lO0KXXXOl,..':oxO00OOkxl.                        //
//    .......',;;:ccc:;'..    ..';lodo:.                     ;OK0koc;,..';cdk0KKK0Ox,                         //
//    ..........',,,,...         .';clol'                    'oc'.          ..;ldOk;.                         //
//    ...''',,,,,;:;.            ..,:codo,                   .;'...        .';,,,;,.                          //
//    ..;ccccccccc;.              .,:looll,.                 'od:',:,.    'cdxddxl.                           //
//    ,,::::::::::.              ..;ldxxkkko,                ,dkl. 'oo,  ;xkxxkOk,                            //
//    cc:::::::::'          .';:coxxkOOkkOOkx:.             .cdx:   ..;;cO0OO000l.                            //
//    ;:::::::::,.         .lxxkkOOOOOOOOOOOOko'            .okd;,,.   ;k000KKKk'                             //
//    :c:::::;:;.          .odddddddxxkkOOOkkkxo'           .okxl,..   c000KKK0c.                             //
//    ::;:;;;;;'           .ll;'...,:lxkOOOkxddol'          .od:.      'kKKKKKx.                              //
//    ;;;;;;;;,.           .coc;;cldkOOOOkkkxdoolc'         .l'        ,x0KKK0:                               //
//    ;;;;;;;;,.           .:xkkOOO00000kxxxxdollcc'        .'.      .;,:OK0Kd.                               //
//    ,,,,,,,,,.            ;ddddoxO0000Okxddddollc:,.      ..    .,c:. 'k00O;                                //
//    ,,,,,,,,,.            .;,''';dO0000Okxxddoollcc;'.    ..   .ld,   ,x00o.                                //
//    ,,,,,,,,'.            .',',,;lkOO00Okkxxddoollc::;,.  .   ,oc.   .:xOO:                                 //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract nrhmn is ERC721Creator {
    constructor() ERC721Creator("The Opening Speech", "nrhmn") {}
}