// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: iAmSulfie
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0OkxxkO0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKXXXXXXXXXXXXXXX0xl:;,'...,;:ldOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOdllc::::cdk0KXXXXXKKOo;..',,;;;;;;,'.'lOXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXKkol;'',,,,,'''',:lkXX0l,''',,;;;;;:;;::;;'.;kXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXKo;c:;;;;;;;;;:::;,''co;..';::;;;;;,,,,,,,,,'.;OXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXK00o,,;;;;'............. ..,;;;,..............''..:kK00KXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXk;''.......  .....         ';;'.              .,;;.....,oKXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXl. .    ... 'k0OOo.        ....  .cool'        ...    ...dKXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXX0:.',,'..    :KNNXo.              ,0NNK;           ....;ddkKXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXKo'';;::;;,.  cXNNXl          ...  ;KNNK;         .,;;,.,OXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXk,.,;;;;;;:,. lXNNK:         .,:,. :KNNK;        .,:;;,.'kXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXKl..;::;;:;;,. cKKXO,        .';:;. ;KNNK:        .,;;:;..d0XXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXX0; .;:::::;;'. .,,;,.       ..'::;. .lool'        .';;;;,..cxOXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXKc.';;;;;;;;,.......        ..,::;'.             .';;;;;:;,;;:o0XXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXKx,.,;;;;::;:;;;;;;;;,,,''',,,;;;;;;,'''..'',,,,,,;;:::;;;;;;,',lkKXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXx'.,;;;;;;;;;;::::;;::::;;:;;;;;;;;;;;;;;:;:::;::::;;::;:;;:;;,,:lOXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXk;.';:;;;::;::;;;:;;;;;:;;::::;;;;;;;;;;;;::;::;,',;;:;;;;;;::;;,''lKXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXKl.';::;;;;;;;;;;:::::;;:;;;::;:;;;;;;;;::;:::::;,..,;::;;;;;::::;. ;0XXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXX0:.':;;;:;;;;;;;::;;;;;;;;;;:;;;;;;;;;;;;;;;:::;;;'..,::;;;;:;;:::,.;0XXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXO,.,;:;;:::;;;;;;;;;;;;;;;;;;;;;;::;;;;;;;;::::::;;...;:::;;::;;::;.'kXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXk'.,;;:;::;;;;;;:::;;;;;;;;;;;;:;;:::;;;;;;;;:::::;...;;;:::;;;;;;;..xXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXO,.;;;;:::::::;;::;;;;;;:::;::::;;::;;:;'.',;;;,,'..',;;;:::;;;;;;,.'kXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXO,.,:;;;;:::;;;;;;;;;;;;::;,,;::;;;;;;;;'''.....',,;;;;:::;;::;;:;,.cKXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXX0;.';;;;;;:;;;::;;;;;;;;::;,.';;;;;::;;,',:;;;;;::;;;;;;:::::::::;.;OXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXd..,;::;;:::;;:::;;;;;;;;;;'..,,,;;,,'.';:::;;;::;;;;;;::::;:::;''dXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXKl..;::;;:::;;::::;;;;;;;;;;,''',,,''',;:::::;;::;;;;::;::;;;;;'.:OXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXX0c..;;;:;;;;;::;;;;;;;;::;;:;:::;;;;;;;;;;::;;;:;;;;:::::;;;;,.;OXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXX0c..,;;;;;;;;;;;;;;;::;;;:;;;:;;;;;;;;;;;;;;;;;::::::;;;::;,.'xXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXX0o'.,;;;;;;;;;;;;;;;;;;;;;;:::;:;;;;;;;;;;;;;:;;;;:::;;:;,.'dKXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXx,.';;:::;:::;;;;:;;;;::::;::::::;;;;;;;;:::;;;;;;;:;;'.;kXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXX0d:'';;;;:;;:::::::;;;:;;;;;::::;;;;;;::;;;;::;;;;;,.,o0XXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXKkocc:,''',,;;;;;;::;;;;;;;;;;:;;;:::;;::::;:;,''':kXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXK0Okdc:,''.....'''',;;;;;;;;;;;;;;;;,'''''...;lkKXXXXXXXXXXNXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0kxoc:;,'''.....',;;;;,;;;;,....,:cldk0XXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0OOOkddolloolccllooooddxO0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Sulfie is ERC1155Creator {
    constructor() ERC1155Creator() {}
}