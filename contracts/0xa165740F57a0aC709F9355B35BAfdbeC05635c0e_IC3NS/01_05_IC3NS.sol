// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The IC3N Series
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK00000XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,.....:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKdl:......,clxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKd. ..'',,;'. ,kKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO,....',;;,''',,,..;KMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk. .',,,,,,,,,,,.  '0MMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXx. .,;,''',,;,''.. 'kXXWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMO,.',,,'',,;;,''',;,'....:0MMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMKdoc'..,,,,,,,,,,,,,,,,,,'..'coxXMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMx. .,;,'',,;,''',;;,''',;,''.  .OMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMx. ..',;;,'',,;;,''',;,,'',;'. .OMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMKxd:...',,;;;,,,;;;;,,,;;;,,,,,'..'ldxXMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWd. ..',;;;::::::::::::::::::;,'',;,. .kMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWd. .,;;;;:loooooooooooooooool:;;;;,. .kMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWd.  .....',,,,,,,,,:odl:,,,,,'.....  .kMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWd.                 .:o:.             .kMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWd.     ........     ...    ........  .kMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWd.     .........    ...   .........  .kMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWWd.     .........   .cd:.  .........  .kMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWO:,.     .',',,,,,.   .cd:.  .,,,,,,,'. .kMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWOc;.   ...............':c;. ..........  .kMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWd. .,;.        .cooc,''...           .kMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWd. .,;;;;;;;;;;coddl,''''';;:;;;''.  .kMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWd. .,;cooodddooddddl:;;;;:ldoddoc;,. .kMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWd. .,;codddooooooooooooooooooddo:;,. .kMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWd. .,;codddddooc'........,ldoodoc;,. .kMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMN0Ol...;;:llooddodc.........'cdooll:;,...d0KNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWx...,,;;;;;;codddoooooooooooooolc;;;;;;;,..'kMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMKkxc..';;'..,ldc'.;loooddoodl,.....,;;..'lxkXMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWk;',,'.  .ld:...:cccccccc:;'''',,',,':0MMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWNNd.    .ldool;.        ,0NNNNK; .kNWWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMXxd:  .ldoodl;,,.  .ldONMMMMWOdkXMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMx. .ldoododdd:. ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMk' 'odddddddxc. :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMN00KXNNNNNNNNX00KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract IC3NS is ERC1155Creator {
    constructor() ERC1155Creator("The IC3N Series", "IC3NS") {}
}