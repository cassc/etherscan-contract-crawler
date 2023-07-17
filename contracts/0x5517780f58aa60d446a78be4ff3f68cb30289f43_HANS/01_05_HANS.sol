// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HANS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//    $$\   $$\  $$$$$$\  $$\   $$\  $$$$$$\                             $$\     $$\             $$\                      //
//    $$ |  $$ |$$  __$$\ $$$\  $$ |$$  __$$\                            $$ |    \__|            $$ |                     //
//    $$ |  $$ |$$ /  $$ |$$$$\ $$ |$$ /  \__|       $$$$$$\   $$$$$$\ $$$$$$\   $$\  $$$$$$$\ $$$$$$\                    //
//    $$$$$$$$ |$$$$$$$$ |$$ $$\$$ |\$$$$$$\ $$$$$$\ \____$$\ $$  __$$\\_$$  _|  $$ |$$  _____|\_$$  _|                   //
//    $$  __$$ |$$  __$$ |$$ \$$$$ | \____$$\\______|$$$$$$$ |$$ |  \__| $$ |    $$ |\$$$$$$\    $$ |                     //
//    $$ |  $$ |$$ |  $$ |$$ |\$$$ |$$\   $$ |      $$  __$$ |$$ |       $$ |$$\ $$ | \____$$\   $$ |$$\                  //
//    $$ |  $$ |$$ |  $$ |$$ | \$$ |\$$$$$$  |      \$$$$$$$ |$$ |       \$$$$  |$$ |$$$$$$$  |  \$$$$  |                 //
//    \__|  \__|\__|  \__|\__|  \__| \______/        \_______|\__|        \____/ \__|\_______/    \____/                  //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//                    $$\                                 $$\                                                             //
//                    $$ |                                $$ |                                                            //
//     $$$$$$\   $$$$$$$ |$$\    $$\  $$$$$$\  $$$$$$$\ $$$$$$\   $$\   $$\  $$$$$$\   $$$$$$\   $$$$$$\                  //
//     \____$$\ $$  __$$ |\$$\  $$  |$$  __$$\ $$  __$$\\_$$  _|  $$ |  $$ |$$  __$$\ $$  __$$\ $$  __$$\                 //
//     $$$$$$$ |$$ /  $$ | \$$\$$  / $$$$$$$$ |$$ |  $$ | $$ |    $$ |  $$ |$$ |  \__|$$$$$$$$ |$$ |  \__|                //
//    $$  __$$ |$$ |  $$ |  \$$$  /  $$   ____|$$ |  $$ | $$ |$$\ $$ |  $$ |$$ |      $$   ____|$$ |                      //
//    \$$$$$$$ |\$$$$$$$ |   \$  /   \$$$$$$$\ $$ |  $$ | \$$$$  |\$$$$$$  |$$ |      \$$$$$$$\ $$ |                      //
//     \_______| \_______|    \_/     \_______|\__|  \__|  \____/  \______/ \__|       \_______|\__|                      //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXKOkdolcc::lxkOKXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXkoc::;;,'''.....';cdkKNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXOc'....','''''....'..',ckNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKo,'..';:cc;;,'.........',cONNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKo,''.':clol::;,''''''''',;;oKNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN0odo;,;:cloolllcc::;;;:::;,;l0NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXX0c,::clodxxdollllccclc;;,oXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNO;...,:loddddodxxdlcoo:;;oXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN0o:,.',cldxkxkkxddoodo:::dXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNOddo:;;:cloddxddl:cdkxolcdXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    kO0XNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWNNNNNOdc::;;;::::cloddddxkxxddxKNNNNNNNNNNNX0xxkxk0KOkkOK0kkO0KNNNNNNNNNNNNNNN    //
//    ,';okxkKXNNNNNNNNNNNNNNNNNNNNNNNNNWWNNNNNx;;;,';;;:::cllodxkkkxxxkKXKXX0OOkxxx:.,;'.;ol;;;ol'..';cllodxO0O000KKK    //
//    '''',,:ddodk0KXNNNNNNNNNNNNNNNNNNNNWNNNNNKo'...,::cclloooodxkkkkkdolcccc::::cl;......:l;,;cl'..........,,.'',,,,    //
//    ''..';ol::::codxO0XNXNNNNNNNNNNNNNNNNNNNNNNk,';;:ccloddoolldkkkxolc;,';c:;:;:c;......,c:'.;l,..........''.......    //
//    ,''.,cc;;:::lc;:c;:c::clk0XNNNNNNNNNNNNNNNNKo;'';cccllc::;:oxkkl;:::c::c:;,,;l:.......::'',c:...................    //
//    '..';:,''';cc;,:;........',:lodxxxkkdooddodkkd;.',,,,'',;,,lxko;;c::c;,:c,,;:lc'......,;.',::.........  ........    //
//    ....'..''':c;',;..........     .......... ...''.......',:;,:xxc,:lc;,,;;:::cccc'.......,'',:;..........   ......    //
//    Oxc;'.....','.,,........         .......    ...  ..''.':ccc:odc:loc::;::;:::;:c,.......,'..;;...........     ...    //
//    NNNXkl;...........               .......  ..... ..';;'';:cllllc:::::;,;:ccc:;;cc'......''..',.       .....     .    //
//    NNNNNNX0xoc;,.                   ... ... ..........';;',;;::::;,',;:;;;,:lc::::c;.......'...';;,,'...''''.......    //
//    NNNNNNNNNNNXKx;'...              ... ..   ..',;;,.........,;;;;;,,;,...''',::;;::'......'..,o0NXXX000KKK0Okxxk00    //
//    NNNNNNNNNNNNNNXK0Oxolc;.             ..   ....,;;,'.......',;,''..''.....'',::,;c;.......'.:KNNNNNNNNNNNNNNWNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNX0xoc,..     .....   ...';,,'........;c,.........''.'';:::c;.........,ONNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNXKOxo:,..  ..   ...,;............,'.....,;,'...',;::;::.........,ONNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNX0kl...    ......................';;;:,....';:,;:,........;0NNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNOl'.   ......................',,;,'.....,;;;::........,kNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN0c.  .........',''....''....',,'.....'';:;:c,........lKNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXd.  ..... ...',',..................',::;;c:........,kNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXd. ...... ...''...................,ll::;:c,........oXNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXx. .... .  .........'......''...''',;:;;::........;xKNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNx'.....  ..........;'.'...'......'',:;,,:,..... ...;o0NNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNk,..... .........'c;..........'...';:,,::..... .....;kNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNO:.....  ................,;'...''',:::cc'.... ......:0NNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNx.....      .....'.....';;;;;'.',,;:;;:;... ......':dKNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXl....       ..........,,;;::'.'..,:,';:,.. ......;coKNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKo. .     ............,;;;;'.....,;;,,::'. .. ..;:,lKNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKc....   ..... ........';,.......,;;,,:;. ...';::;l0NNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKl...   ....  .  ..............'cc;'.,:'..',,,,;cco0NNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXo..... ..  .. .........'...'.,::,,,;:;.';;,.,clccokKNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXk::c,     .     ......''',,,;,''';::;,,;,,,,,;,,;co0NNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKOk:.        .........,;'''''.....''..;:;c;.'',:;;l0NNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXkc,.      .........................;c;:c'..,lcclkKNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNX0o;..     ..  ................  .,c;;cc'..:c,cx0XNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKd'.             .......... .  .'::,:l;..':,..:dkKNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXd.              ..   ... .   ..:c:;cc;'',:,  ..:kX    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXOxxl.              . ....   .  ...,cc::lc,'';c;.   .l    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNX0x;....       .   .......     ..  ....;c::clc,',:lc;'.      //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXo'.....        . .......      ..   ....':c;:lo;,';llcc;..    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN0c....               .         ...   ....,:;;coc,.'cl::;,.    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXK0ko;....  ..                     ....  ......,:,;cl;',:ccclc,    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXOolc:,'......  ...                     ....  ......';;,:lc,',:cclol    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNOc'............  ..                      .... .....  .,:,;cl;'',cccoo    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN0c,,,;;;;,',:'..  .. .                    .... .....  ..;:;;cc;'';cclo    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNkc:::::::;;:;... .....                    ...  .....  ..,:;';l:..':lcl    //
//                                                                                                                        //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HANS is ERC721Creator {
    constructor() ERC721Creator("HANS", "HANS") {}
}