// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Farrah Fisher Fine Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//                                                                                         //
//     :;::;;;::;,,,',;,,;;;,,;,,,,,,,,;,,,',;;:;,;,,;;;,,;;;;;,,,,,,'''''''''''','..''    //
//    ;;;,,,',;;;;;,,,,,,,;,,;;,,;,,,,;,'',,,,,,;;,;,,,,,',,,,'',''''..''.....''......     //
//    ,,,'',',;,,;;,',,,,,;,;;;;,;;;;;;,,,,,,,,,;;,,',''''',,,'''''''...'......'......     //
//    ,,,,,'',,,,,,,,',,;,,,;;;,'',,;;;;,,,,,,,,,,,'''''',,,,','''''''...'........         //
//    ;,,,,,''',,,,,,;;;,,,;;,,,,,,;;,,;;,,,,,;,',,','',''''''..''..............           //
//    ,,',,,,,,,,,'',,,,,',,',,,,,,,,:;,,,,,,,;,''''''','......................            //
//    ,''',,,;;;,,'',;,,,,,,,'','',,,,;,',',',,,,,'.''''.......................            //
//    ,'',,,;,,,;;;,',,,,,,,,'','',''',,'''',,,,'''..'','.''........'................      //
//    ;,''',,,,,,,;,',,,,,,,,',,''''',,,,,''''''''.''''''..........''...............       //
//    ,,',,,,''',,,,,'',,'',,,,''''',;,,,,,,''.','...''...........................         //
//    ,,,,,',,,,;;,,,;,,,'''',;,,,,,,,,,,,,,'''''''.............................           //
//    ,;,''',;,,,;,,;;,,,'''',,,,,,,,,'.',''''''''''...........................            //
//    ','''''',,,,,,,;,',''',,,,,,,,,,,'.'''...''''............................            //
//    ,,,,'''',,;,'',,;,,,'',,,,,;,,,,,,'.''''''....'..........................            //
//    ;,',,'',,,;;,,,,,;,;,,;;,',,,'',,''..'''''................................           //
//    ;;,,',,',,,,,,,,,;,,,;,,,'.''''''.'''''......................................        //
//    ,,,',,,,,,,''',',;,,'''.''','.''''..''..........................................     //
//    ',,,,,,,,,;,,,,,',,'''',,,,,'',,,'''',''''''''''''''''''''',,,,,,,,,,,,,,,,,',,,     //
//    ;,,,,'',,,;;'',,',;:::cccccccccccccccllcllccccclllllllllllccccccccccccccccccccc:     //
//    ,,,,,,,',;,,,,,;:cloooooooollllllllllllllllllllllllllllllllllllllllccccccccccccc     //
//    '.',,''',,'',,:looooooooooooooooooooooolllllllllllllllllllllllllllllcccccccccccc     //
//    ,''''''',,'',:oooooooooooooooooooooooooooooooooollllllllllllllllllllllcccccccccc     //
//    ,,,''',,,,,,;ldddddddddddddooooooooooooooooooooooooooollllllllllllllllcccccccccc     //
//    ,,''',,,',;,:oddddddddddddddddddddddddddddoooooooooooollllllllllllllllcccccccccc     //
//    ''''',,'',;;:oddddddddddddddddddddddddddddddddooooooolllllllllllllllllllcccccccc     //
//    '','',,,'',,:oddddddddddddddddddddddddddddddddooooooollllllllllllllllllllccccccc     //
//    ,''''',,''',:oddddddddddddddddddddddddddddddddddoooooooollllllllllllllllllcccccc     //
//    ''',,,'''',,:oddddddddddddddddddddddddddddddddddddoooooooooooooooollllllllllllll     //
//    '.'',',''''';odddddddddddddddddddddddddddddddddddddooooooooooooooooooooooooooooo     //
//    ''..',''..'';odddddddddddddddddddddddddddddddddddddooooooooooooooooooooooooooooo     //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract F3A is ERC721Creator {
    constructor() ERC721Creator("Farrah Fisher Fine Art", "F3A") {}
}