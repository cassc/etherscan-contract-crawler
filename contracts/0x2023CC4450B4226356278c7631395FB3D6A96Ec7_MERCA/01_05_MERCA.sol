// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AMERICAN APOCALYPSE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMM    //
//    MMMMMMMX0OO0OkkkxkOxxxxdxxddddxkxdxxxkkddxdxkxdddxxxxkkkkkkkkkkkkkkkkkkkxxxxxxddddddddddddddd0WMMMMM    //
//    MMMMMMWd..;dd:..,okl'..;dd;..'oko'..:xx;..'lxl'..',,,,,,,,''',,,,,,,,,,,,,,,,,,,,,,,,,,,,''',xWMMMMM    //
//    MMMMMMWd..lOkc..,xOd'..lOOc..'dOd,..ckkc..,d0x,..';;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;;:::;;,;kWMMMMM    //
//    MMMMMMMx....',cl;..',c:,..,:c;'.';lc,..,:c;'.....o00OOOOOkOOOOkkOkOOOOOOOOOOOO000000KKKKKKK00XWMMMMM    //
//    MMMMMMMk.....:0Xd'..dX0:..;OXx,.'oK0c..;OXx,....'kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWMMMMM    //
//    MMMMMMMk'.....,;'.'.':;..'.;:,.'.';;'''.,:,.'....kMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMWWWWNWMMMMM    //
//    MMMMMMMk'.;kOc..'l0x,..;k0c...l0k;..;k0l...l0k;..lkkxxxxxxkkkkkkkkxxxxxxxxxxxxxddddddddddddddOWMMMMM    //
//    MMMMMMMk..,od:...cdl,..,od:...:do,..,lo:...:do,..';,,,,'''',,,,,,,'''',,'''''''''''''''''''''dNMMMMM    //
//    MMMMMMMk'....'cdc'..;od;..'cdl,..;dd;..'cdc'.....',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'dNMMMMM    //
//    MMMMMMMO'....,kKk,..l00l..,xKk;..lO0l..,xKk;.....,ccc::cccccc::::::::cccccccccccccllllllllllcxNMMMMM    //
//    MMMMMMMO'..,;''''',,'''',;''''';;'''',;''''',,...oXXNNNXXXXNXXXXXXXXXNNNNNNNNNNNNWWWWWWWWWWWNXWMMMMM    //
//    MMMMMMMO'.;OXd'..oKO:..;kXd'..oK0:..,kXx'..lK0:..dWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWMMMMM    //
//    MMMMMMMO,.'cl;...,lc'...:l;...,c:....:l;...,lc,..dNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWNNNWMMMMM    //
//    MMMMMMM0,....'lko,..;xk:..'oOo,..;xk:...lkd,.....;oooloooooooooooollllllllllllllllllllllcccccxNWMMMM    //
//    MMMMMMM0,....'dOx,..:kOl..,dOd,..:kkl..'oOx,......,,,,,,,,,,,,,,,,,'',,,,,',,,,,,,,,,,,,'''''oNMMMMM    //
//    MMMMMMM0,..;c;'.',cc,..,:l;'..,cc,..';c;'..,c:'...,,,,,,,,,,,,,,,'''',,,,,,,,,,,,,'',,,''''''oNMMMMM    //
//    MMMMMMM0;.:OXx,..oKKl..;OXx'..oKKl..;kXk,..lKKl..;ooooooooooddoooooodddddddddddddddddddddddddkNMMMMM    //
//    MMMMMMMK;..;:,.'.';;..'.,;,.'.';;'.'.,:,.'.';;'..oXNWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWNWMMMMM    //
//    MMMMMMMK;....'l0x,..;k0l...o0k,..;k0l...l0k;.....lKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWMMMMM    //
//    MMMMMMM0;.....cdl'..,ld:...:dl,..'odc...:do,.....:OKXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKK0KWMMMMM    //
//    MMMMMMMK;.'cdc,..;do;..'coc,..;oo;..':ol,..,ld:..';:c::::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;,,,oNMMMMM    //
//    MMMMMMMK;.;kKk;..l00l..,xKk;..l0Ko..'xKk:..c0Ko...,,,',,,,,,,,,,,'''',,,,,,,,,,,,,,,,,,,,,'''lNMMMMM    //
//    MMMMMMMK; .'''....''....'''....''....'''....''....''''',,,,,,,,,'',,,,,,,,,,,,,,,,,,,,,,,,,,'lXMMMMM    //
//    MMMMMMMXxddddddddddddddddddddddddddddddddddddxdddxkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOO0NMMMMM    //
//    MMMMMMMWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWMMMMM    //
//    MMMMMMMNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWMMMMM    //
//    MMMMMMMN0O00000000000000000000000000000OOOOOOOOOOOOOOOOOOOkkOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxONMMMMM    //
//    MMMMMMWKc',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'''''''''''',,,'''''''''''''''''''''''cKWMMMM    //
//    MMMMMMMKc',,,,,,,,,,,,,,,,,,,,,,,,,,,,'',,,,,,,,,,,,''',,,,,,,,,,,,,,,,,''',,,,,,,,,,'''''''':KWMMMM    //
//    MMMMMMMXl,,;;;;;;,,,;;;,,,,,,;;;;;;,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::::::::::::::::::::::;;lKMMMMM    //
//    MMMMMMMNK000KKKK00000000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKNMMMMM    //
//    MMMMMMMWNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNMMMMM    //
//    MMMMMMMWNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWMMMMMWMMMWWWWMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWNNMMMMM    //
//    MMMMMMMWOddxxdxxdddddxxxxxxxxddddddddddddddddddddddddooooooooooooooooooooooooooolllloolllllllo0MMMMM    //
//    MMMMMMMNo''','''''',,,,,''''''''''''',,,,''''''','''''''''''''''''''''''''''''''''''''''''''';kWMMMM    //
//    MMMMMMMNd'',,,',,,,,,,,''''',,,,,''',,',,'',,,''''''''''''''''''''''''''''''''''''''''''''''';OWMMMM    //
//    MMMMMMMNx:ccccccccclcccccllllllllllllllllllllllllllllllllllllllllllllllllloooooooooooooooooood0MMMMM    //
//    MMMMMMMWXXNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMWWMMNNMMMMM    //
//    MMMMMMMWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNMMMMM    //
//    MMMMMMMWNNWWWWWNNNNNNNNNNNNNNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKXWMMMM    //
//    MMMMMMMNkllllllccccccccccccccc:::::::::;;;;;::::::::::::::::::::::::::::::::;;;;;;;;;:::::::;:OWMMMM    //
//    MMMMMMWXo','','''''''''''''''''''''''''''''''''''''''''''''.''''''''''''.......'''''''''''''',xWMMMM    //
//    MMMMMMMNklllloooooooooooooooddddddddddddddddddddddddddddddddxxxxxxxxxxxxxxxxxddddddxxxxxxkkkkOXMMMMM    //
//    MMMMMMMMWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MERCA is ERC721Creator {
    constructor() ERC721Creator("AMERICAN APOCALYPSE", "MERCA") {}
}