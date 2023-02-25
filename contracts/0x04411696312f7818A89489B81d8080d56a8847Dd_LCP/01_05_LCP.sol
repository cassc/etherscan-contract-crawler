// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LiteCoin Pepe
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                   //
//    LLLLLLLLLLL               iiii          tttt                                                                     iiii                        PPPPPPPPPPPPPPPPP                                                                 //
//    L:::::::::L              i::::i      ttt:::t                                                                    i::::i                       P::::::::::::::::P                                                                //
//    L:::::::::L               iiii       t:::::t                                                                     iiii                        P::::::PPPPPP:::::P                                                               //
//    LL:::::::LL                          t:::::t                                                                                                 PP:::::P     P:::::P                                                              //
//      L:::::L               iiiiiiittttttt:::::ttttttt        eeeeeeeeeeee        cccccccccccccccc   ooooooooooo   iiiiiiinnnn  nnnnnnnn           P::::P     P:::::P  eeeeeeeeeeee    ppppp   ppppppppp       eeeeeeeeeeee        //
//      L:::::L               i:::::it:::::::::::::::::t      ee::::::::::::ee    cc:::::::::::::::c oo:::::::::::oo i:::::in:::nn::::::::nn         P::::P     P:::::Pee::::::::::::ee  p::::ppp:::::::::p    ee::::::::::::ee      //
//      L:::::L                i::::it:::::::::::::::::t     e::::::eeeee:::::ee c:::::::::::::::::co:::::::::::::::o i::::in::::::::::::::nn        P::::PPPPPP:::::Pe::::::eeeee:::::eep:::::::::::::::::p  e::::::eeeee:::::ee    //
//      L:::::L                i::::itttttt:::::::tttttt    e::::::e     e:::::ec:::::::cccccc:::::co:::::ooooo:::::o i::::inn:::::::::::::::n       P:::::::::::::PPe::::::e     e:::::epp::::::ppppp::::::pe::::::e     e:::::e    //
//      L:::::L                i::::i      t:::::t          e:::::::eeeee::::::ec::::::c     ccccccco::::o     o::::o i::::i  n:::::nnnn:::::n       P::::PPPPPPPPP  e:::::::eeeee::::::e p:::::p     p:::::pe:::::::eeeee::::::e    //
//      L:::::L                i::::i      t:::::t          e:::::::::::::::::e c:::::c             o::::o     o::::o i::::i  n::::n    n::::n       P::::P          e:::::::::::::::::e  p:::::p     p:::::pe:::::::::::::::::e     //
//      L:::::L                i::::i      t:::::t          e::::::eeeeeeeeeee  c:::::c             o::::o     o::::o i::::i  n::::n    n::::n       P::::P          e::::::eeeeeeeeeee   p:::::p     p:::::pe::::::eeeeeeeeeee      //
//      L:::::L         LLLLLL i::::i      t:::::t    tttttte:::::::e           c::::::c     ccccccco::::o     o::::o i::::i  n::::n    n::::n       P::::P          e:::::::e            p:::::p    p::::::pe:::::::e               //
//    LL:::::::LLLLLLLLL:::::Li::::::i     t::::::tttt:::::te::::::::e          c:::::::cccccc:::::co:::::ooooo:::::oi::::::i n::::n    n::::n     PP::::::PP        e::::::::e           p:::::ppppp:::::::pe::::::::e              //
//    L::::::::::::::::::::::Li::::::i     tt::::::::::::::t e::::::::eeeeeeee   c:::::::::::::::::co:::::::::::::::oi::::::i n::::n    n::::n     P::::::::P         e::::::::eeeeeeee   p::::::::::::::::p  e::::::::eeeeeeee      //
//    L::::::::::::::::::::::Li::::::i       tt:::::::::::tt  ee:::::::::::::e    cc:::::::::::::::c oo:::::::::::oo i::::::i n::::n    n::::n     P::::::::P          ee:::::::::::::e   p::::::::::::::pp    ee:::::::::::::e      //
//    LLLLLLLLLLLLLLLLLLLLLLLLiiiiiiii         ttttttttttt      eeeeeeeeeeeeee      cccccccccccccccc   ooooooooooo   iiiiiiii nnnnnn    nnnnnn     PPPPPPPPPP            eeeeeeeeeeeeee   p::::::pppppppp        eeeeeeeeeeeeee      //
//                                                                                                                                                                                        p:::::p                                    //
//                                                                                                                                                                                        p:::::p                                    //
//                                                                                                                                                                                       p:::::::p                                   //
//                                                                                                                                                                                       p:::::::p                                   //
//                                                                                                                                                                                       p:::::::p                                   //
//                                                                                                                                                                                       ppppppppp                                   //
//                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LCP is ERC1155Creator {
    constructor() ERC1155Creator("LiteCoin Pepe", "LCP") {}
}