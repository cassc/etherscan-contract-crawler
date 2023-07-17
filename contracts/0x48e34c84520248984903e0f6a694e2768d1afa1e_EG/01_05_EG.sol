// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eternal Goddesses
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//    EEEEEEEEEEEEEEEEEEEEEE         tttt                                                                                      lllllll                                             //
//    E::::::::::::::::::::E      ttt:::t                                                                                      l:::::l                                             //
//    E::::::::::::::::::::E      t:::::t                                                                                      l:::::l                                             //
//    EE::::::EEEEEEEEE::::E      t:::::t                                                                                      l:::::l                                             //
//      E:::::E       EEEEEEttttttt:::::ttttttt        eeeeeeeeeeee    rrrrr   rrrrrrrrr   nnnn  nnnnnnnn      aaaaaaaaaaaaa    l::::l                                             //
//      E:::::E             t:::::::::::::::::t      ee::::::::::::ee  r::::rrr:::::::::r  n:::nn::::::::nn    a::::::::::::a   l::::l                                             //
//      E::::::EEEEEEEEEE   t:::::::::::::::::t     e::::::eeeee:::::eer:::::::::::::::::r n::::::::::::::nn   aaaaaaaaa:::::a  l::::l                                             //
//      E:::::::::::::::E   tttttt:::::::tttttt    e::::::e     e:::::err::::::rrrrr::::::rnn:::::::::::::::n           a::::a  l::::l                                             //
//      E:::::::::::::::E         t:::::t          e:::::::eeeee::::::e r:::::r     r:::::r  n:::::nnnn:::::n    aaaaaaa:::::a  l::::l                                             //
//      E::::::EEEEEEEEEE         t:::::t          e:::::::::::::::::e  r:::::r     rrrrrrr  n::::n    n::::n  aa::::::::::::a  l::::l                                             //
//      E:::::E                   t:::::t          e::::::eeeeeeeeeee   r:::::r              n::::n    n::::n a::::aaaa::::::a  l::::l                                             //
//      E:::::E       EEEEEE      t:::::t    tttttte:::::::e            r:::::r              n::::n    n::::na::::a    a:::::a  l::::l                                             //
//    EE::::::EEEEEEEE:::::E      t::::::tttt:::::te::::::::e           r:::::r              n::::n    n::::na::::a    a:::::a l::::::l                                            //
//    E::::::::::::::::::::E      tt::::::::::::::t e::::::::eeeeeeee   r:::::r              n::::n    n::::na:::::aaaa::::::a l::::::l                                            //
//    E::::::::::::::::::::E        tt:::::::::::tt  ee:::::::::::::e   r:::::r              n::::n    n::::n a::::::::::aa:::al::::::l                                            //
//    EEEEEEEEEEEEEEEEEEEEEE          ttttttttttt      eeeeeeeeeeeeee   rrrrrrr              nnnnnn    nnnnnn  aaaaaaaaaa  aaaallllllll                                            //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                      dddddddd            dddddddd                                                                                               //
//            GGGGGGGGGGGGG                             d::::::d            d::::::d                                                                                               //
//         GGG::::::::::::G                             d::::::d            d::::::d                                                                                               //
//       GG:::::::::::::::G                             d::::::d            d::::::d                                                                                               //
//      G:::::GGGGGGGG::::G                             d:::::d             d:::::d                                                                                                //
//     G:::::G       GGGGGG   ooooooooooo       ddddddddd:::::d     ddddddddd:::::d     eeeeeeeeeeee        ssssssssss       ssssssssss       eeeeeeeeeeee        ssssssssss       //
//    G:::::G               oo:::::::::::oo   dd::::::::::::::d   dd::::::::::::::d   ee::::::::::::ee    ss::::::::::s    ss::::::::::s    ee::::::::::::ee    ss::::::::::s      //
//    G:::::G              o:::::::::::::::o d::::::::::::::::d  d::::::::::::::::d  e::::::eeeee:::::eess:::::::::::::s ss:::::::::::::s  e::::::eeeee:::::eess:::::::::::::s     //
//    G:::::G    GGGGGGGGGGo:::::ooooo:::::od:::::::ddddd:::::d d:::::::ddddd:::::d e::::::e     e:::::es::::::ssss:::::ss::::::ssss:::::se::::::e     e:::::es::::::ssss:::::s    //
//    G:::::G    G::::::::Go::::o     o::::od::::::d    d:::::d d::::::d    d:::::d e:::::::eeeee::::::e s:::::s  ssssss  s:::::s  ssssss e:::::::eeeee::::::e s:::::s  ssssss     //
//    G:::::G    GGGGG::::Go::::o     o::::od:::::d     d:::::d d:::::d     d:::::d e:::::::::::::::::e    s::::::s         s::::::s      e:::::::::::::::::e    s::::::s          //
//    G:::::G        G::::Go::::o     o::::od:::::d     d:::::d d:::::d     d:::::d e::::::eeeeeeeeeee        s::::::s         s::::::s   e::::::eeeeeeeeeee        s::::::s       //
//     G:::::G       G::::Go::::o     o::::od:::::d     d:::::d d:::::d     d:::::d e:::::::e           ssssss   s:::::s ssssss   s:::::s e:::::::e           ssssss   s:::::s     //
//      G:::::GGGGGGGG::::Go:::::ooooo:::::od::::::ddddd::::::ddd::::::ddddd::::::dde::::::::e          s:::::ssss::::::ss:::::ssss::::::se::::::::e          s:::::ssss::::::s    //
//       GG:::::::::::::::Go:::::::::::::::o d:::::::::::::::::d d:::::::::::::::::d e::::::::eeeeeeee  s::::::::::::::s s::::::::::::::s  e::::::::eeeeeeee  s::::::::::::::s     //
//         GGG::::::GGG:::G oo:::::::::::oo   d:::::::::ddd::::d  d:::::::::ddd::::d  ee:::::::::::::e   s:::::::::::ss   s:::::::::::ss    ee:::::::::::::e   s:::::::::::ss      //
//            GGGGGG   GGGG   ooooooooooo      ddddddddd   ddddd   ddddddddd   ddddd    eeeeeeeeeeeeee    sssssssssss      sssssssssss        eeeeeeeeeeeeee    sssssssssss        //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//     _          _____     _     _   _          _____                                                                                                                             //
//    | |_ _ _   |  _  |___| |___| |_| |_ ___   | __  |___ _ _                                                                                                                     //
//    | . | | |  |   __| .'| | -_|  _|  _| -_|  | __ -| . |_'_|                                                                                                                    //
//    |___|_  |  |__|  |__,|_|___|_| |_| |___|  |_____|___|_,_|                                                                                                                    //
//        |___|                                                                                                                                                                    //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EG is ERC721Creator {
    constructor() ERC721Creator("Eternal Goddesses", "EG") {}
}