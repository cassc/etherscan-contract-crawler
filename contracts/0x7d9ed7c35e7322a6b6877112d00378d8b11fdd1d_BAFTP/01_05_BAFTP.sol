// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BasedAF TentPoles
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kkkxdxxk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdl:,'........,:oOKXNNNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWNXXXXXXKKKKKK000xc,,'.. ............'coxxkkkkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMNOxxddxxkOkdooddc',,...................';oxolo0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMW0l;::::col:;;:;,,,......................':;.cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMXl''''.';.  ...,:........................'c;:XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWd,''''';' ...':;.........................;loKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWx,'''.';,....;l,..........................lkKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMk,''''';,....:d;..........................l0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMO;''''';,....:o;..........................cOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMM0;''''',;....;c:..........................;o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMK:''''',:'...,;c;.........................,ckWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMKc'''''':,....;::,........................;,dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMXl.''.'':,....';,,,......................;'.oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNo.'.''':;.....,;.',...................';'..lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWd'..''':;.... .;;....'.............'cc;....cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWx'..''';;. ..  .;;.................''......;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMk,...'';,. ... .':,........................,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMO,.'..',,.  ..  .;;....................;;..'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMM0:'''..,;.  ..   .;...,c'..............lo,.'dXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMKc',''.,:' ....  .'..,,c;..............',,,:lddxddxkO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMW0xdoolloc;:;..... .....................',,;xko:,''...',;cdkOKNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWWWNNx,''''...........  .............','...........;;;:cxNWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNx;,',,,,,'...........................'.'',,,''....'kMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMW0d:;,'',,''....',,;;:ccccc:;;;,,''''',,''........,OMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc;;;;,'.''''',,,:lodooc;,''',:ccc:;'........:OWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo',,,,,,'...................'''''.........'oNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'','..'''.........   ........      ......,kMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc''''''.............................   ..cKMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk:,''''''..........'''''''''''......   .;OWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc,'''................................;0WMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWO:,..   ............................cKWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c''.....               ............lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c,,,,'.......           ......... .;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWWNNXX0l;::::;,'............................'dNMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWWXkooolllllc,......''''''...................'.... .o0KXNWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWWKxl,....''',;;,'................'.':c,'...,::,'...  .:lllodxxkOXWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMXd,.........................    .   ...   .............',''......;xXWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWx'.'...............................................................'ckNMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWd.....................................................................:0WMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMx'.....................................................................;KMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMM0:'.............................................................. . ....lNMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWN0kdlc;,.............................................................. .xWMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWNX0kdoc;,'...................................................  ...lNMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWMWNX0kdlc;,......................................',;:cclodxkOXWMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0kdlc;'...............',;:cloodxkO00KKXNWWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOkolc:cclodxk0KXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BAFTP is ERC721Creator {
    constructor() ERC721Creator("BasedAF TentPoles", "BAFTP") {}
}