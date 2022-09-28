// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glass Crown
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//            GGGGGGGGGGGGGlllllll                                                                 CCCCCCCCCCCCC                                                                                                  //
//         GGG::::::::::::Gl:::::l                                                              CCC::::::::::::C                                                                                                  //
//       GG:::::::::::::::Gl:::::l                                                            CC:::::::::::::::C                                                                                                  //
//      G:::::GGGGGGGG::::Gl:::::l                                                           C:::::CCCCCCCC::::C                                                                                                  //
//     G:::::G       GGGGGG l::::l   aaaaaaaaaaaaa      ssssssssss       ssssssssss         C:::::C       CCCCCCrrrrr   rrrrrrrrr      ooooooooooo wwwwwww           wwwww           wwwwwwwnnnn  nnnnnnnn        //
//    G:::::G               l::::l   a::::::::::::a   ss::::::::::s    ss::::::::::s       C:::::C              r::::rrr:::::::::r   oo:::::::::::oow:::::w         w:::::w         w:::::w n:::nn::::::::nn      //
//    G:::::G               l::::l   aaaaaaaaa:::::ass:::::::::::::s ss:::::::::::::s      C:::::C              r:::::::::::::::::r o:::::::::::::::ow:::::w       w:::::::w       w:::::w  n::::::::::::::nn     //
//    G:::::G    GGGGGGGGGG l::::l            a::::as::::::ssss:::::ss::::::ssss:::::s     C:::::C              rr::::::rrrrr::::::ro:::::ooooo:::::o w:::::w     w:::::::::w     w:::::w   nn:::::::::::::::n    //
//    G:::::G    G::::::::G l::::l     aaaaaaa:::::a s:::::s  ssssss  s:::::s  ssssss      C:::::C               r:::::r     r:::::ro::::o     o::::o  w:::::w   w:::::w:::::w   w:::::w      n:::::nnnn:::::n    //
//    G:::::G    GGGGG::::G l::::l   aa::::::::::::a   s::::::s         s::::::s           C:::::C               r:::::r     rrrrrrro::::o     o::::o   w:::::w w:::::w w:::::w w:::::w       n::::n    n::::n    //
//    G:::::G        G::::G l::::l  a::::aaaa::::::a      s::::::s         s::::::s        C:::::C               r:::::r            o::::o     o::::o    w:::::w:::::w   w:::::w:::::w        n::::n    n::::n    //
//     G:::::G       G::::G l::::l a::::a    a:::::assssss   s:::::s ssssss   s:::::s       C:::::C       CCCCCC r:::::r            o::::o     o::::o     w:::::::::w     w:::::::::w         n::::n    n::::n    //
//      G:::::GGGGGGGG::::Gl::::::la::::a    a:::::as:::::ssss::::::ss:::::ssss::::::s       C:::::CCCCCCCC::::C r:::::r            o:::::ooooo:::::o      w:::::::w       w:::::::w          n::::n    n::::n    //
//       GG:::::::::::::::Gl::::::la:::::aaaa::::::as::::::::::::::s s::::::::::::::s         CC:::::::::::::::C r:::::r            o:::::::::::::::o       w:::::w         w:::::w           n::::n    n::::n    //
//         GGG::::::GGG:::Gl::::::l a::::::::::aa:::as:::::::::::ss   s:::::::::::ss            CCC::::::::::::C r:::::r             oo:::::::::::oo         w:::w           w:::w            n::::n    n::::n    //
//            GGGGGG   GGGGllllllll  aaaaaaaaaa  aaaa sssssssssss      sssssssssss                 CCCCCCCCCCCCC rrrrrrr               ooooooooooo            www             www             nnnnnn    nnnnnn    //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GC is ERC721Creator {
    constructor() ERC721Creator("Glass Crown", "GC") {}
}