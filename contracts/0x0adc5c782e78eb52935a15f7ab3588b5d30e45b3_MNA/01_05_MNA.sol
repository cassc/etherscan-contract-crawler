// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mono No Aware
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                [email protected]   ...                           //
//                            ...........'dWMMMMMWKl'....'o00Okdxc;'.                         //
//                     ...............''''dWMMMMW0c'.....'tøkumei.eth',...                    //
//                 ...',;:cllolcc:lxkOOOO0XWMMWNO:.................',;:clc;'.                 //
//             .,cooc::dKNWWWNd,,'cKNNNNNWMMWKOo,...........................'..               //
//          ..;kXNNx,.'lkkkxdo;...,:cc::cOWNk:''.....,lkkkxxxddoolcc::;,,'......              //
//         ..,dkxol,...''...............'dOl'.......:kNN00NWMMMMMWWWNXKOc'.......             //
//        ..'ld;........'''','....,:::::cc,.......,oKWKl,,lkXWMMMMMMWXx:'......'c;            //
//        ..;xo;::,..,c:,:dkOl'..'dXNNNNNKo'....'cONNk:'...':dKWMMWKd:'......':xX0'           //
//        .'lKXKN0l:clo;.';kN0xxkkKWWMMMMWNx;',:kXMMNx:'......,lkkl,.......':xXWMWl           //
//        ..,xNWWWXKK0o,...;dOkkkkxxxxxxxxONW0k0XWMMMMWXxc'......''.......,ckXWMMMMk.         //
//        ..:xxollc::;'....''.............cKWMMMMMMMMMMMWXk:...........';oONMMMMMMMK,         //
//        .'cl'...........................cKWMMMMMMMMMWN0xl,.........,lkXWMMMMMMMMMX:         //
//        .'ll',,,....',ccclllllllooooooookNMMMMMMWX0xl:'.........,cd0NWWWWWWWWNNNNK:         //
//        .,xK00d;...'c0NWWWWWWWWWWWWWWMMMMWWNK0Odl:'.............;cllllllllccc::::;.         //
//        .,kWKo,....,ldddddddooddooooxXWNOdl:,''....................................         //
//        .,xx:'......................;OWKc..........................................         //
//        .','........................;OWWO;........................'',,,;;;::c;'....         //
//        .'''..''..'cddddddddoooc'...;OWWNd'...';,.....':ddxxxxxkkOO00KKKKXNNNx'....         //
//        .,c:'ld:..;kWWWWWWWWWWWk,...;OWMMXdldxO0o'....'xWMMMMMMMMMMMMMMMMMMMWd'...          //
//        .'oOkXKc..'coddddddxxxxl'...;OWMMMWWMMMNd'....'xWMMMMMMMMMMMMMMMMMMMNo....          //
//        ..lXWWXl....................;OWMMMMMMMMNd'....'xWMMMMMMMMMMMMMMMMMMMXl....          //
//        ..:0WWNo....................;OWMMMMMMMMNo.....,kWMMMMMMMMMMMWWWNXXK0x;....          //
//        .,kWMWKkxdddoollllcccccccccoKWMMMMMMMMNo.....,xKKK00OOkxddollc::;,''....            //
//        ..l0XNNWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMNo.....',;,,'''...................            //
//         .',;:clloddxxkkkOOOO0000000OOOO0NMMMMNo...............................             //
//          ..................'''''''''''.:0MMMMXo.....................',;:c;'..              //
//           .............................:0WMMMXl......'''';;;,':odxkO0KXNNo..               //
//          ;l;...........................:0WMMMXl.....:xkoxXXNKxllldkkOkdl:'':;.             //
//          ,0N0xolc::,. .:ollllcc:,.':looxXMMMMKc.'''.,loxXMMMMMK;  ':ccloxOXXc              //
//           lWMMMMMMMNd. ,0WWWWWWWKkdlo0WMMMMMMN0Ox:;cdkXWMMMMMXc  :XMMMMMMMMk.              //
//           .OMMMMMMMMWx. .kWMMMMMMMMNd:oKWMMMMMXd:oXMMMMMMMMW0; .lNMMMMMMMMX;               //
//            cNMMMMMMMMWO' .ckKNMMMMMMMK:.;llll:.,OWMMMMMMWXOo. .dNMMMMMMMMWd                //
//            .xWMMMMMMMMMK:   .';codxko;.  .co'  .,lxkdol:,.   ,OWMMMMMMMMMO'                //
//             'OMMMMMMMMMMXxc,.            .x0:            .':dXMMMMMMMMMMX:                 //
//              ;KMMMMMMMMMWNNXKOxoc;'..   'oKXx,.   .';:ldkKXNNWMMMMMMMMMNl                  //
//               cXMMMM::0xde0765e5aff1b9ad570145c378bf506303660a92::MMMMWd.                  //
//                cXMMMMMMMMMMMWN0OOOkkkO0KKXXXXKK0OOkO000KNWMMMMMMMMMMMWd.                   //
//                 :KMMMMMMMMMMMMMMMNKOxol:.....'coxk0XWMMMMMMMMMMMMMMMNo.                    //
//                  ,OWMMMMMMMMMMMMMMMMMMM0'    ,KMMMMMMMMMMMMMMMMMMMMK:                      //
//                   .lKMMMMMMMMMMMMMMMMW0:.    .c0WMMMMMMMMMMMMMMMMNx'                       //
//                     .dXMMMMMMMMMMMMMMX:        ;KMMMMMMMMMMMMMMWO;                         //
//                      'dXMMMMMMMMMMMMWo        :NMMMMMMMMMMMMW0:.                           //
//                         .l0WMMMMMMMMMMO.       dMMMMMMMMMMMNk:.                            //
//                           .;dKWMMMMMMMX:      'OMMMMMMMMW0o,                               //
//                              .:dKWMMMMWo      :XMMMMMN0o;.                                 //
//                                 .;okXWMk.     oWWXOdc'.                                    //
//                                     ..;0:     :l;.                                         //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//               ████████╗ ██████╗ ██╗  ██╗██╗   ██╗███╗   ███╗███████╗██╗                    //
//               ╚══██╔══╝██╔═══██╗██║ ██╔╝██║   ██║████╗ ████║██╔════╝██║                    //
//                  ██║   ██║   ██║█████╔╝ ██║   ██║██╔████╔██║█████╗  ██║                    //
//                  ██║   ██║   ██║██╔═██╗ ██║   ██║██║╚██╔╝██║██╔══╝  ██║                    //
//                  ██║   ╚██████╔╝██║  ██╗╚██████╔╝██║ ╚═╝ ██║███████╗██║                    //
//                  ╚═╝    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚═╝                    //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract MNA is ERC721Creator {
    constructor() ERC721Creator("Mono No Aware", "MNA") {}
}