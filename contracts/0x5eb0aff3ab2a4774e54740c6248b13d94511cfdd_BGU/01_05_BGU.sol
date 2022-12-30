// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BigGunns Universe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                        //
//                                                                                                                                                        //
//    BBBBBBBBBBBBBBBBB     iiii                              GGGGGGGGGGGGG                                                                               //
//    B::::::::::::::::B   i::::i                          GGG::::::::::::G                                                                               //
//    B::::::BBBBBB:::::B   iiii                         GG:::::::::::::::G                                                                               //
//    BB:::::B     B:::::B                              G:::::GGGGGGGG::::G                                                                               //
//      B::::B     B:::::Biiiiiii    ggggggggg   ggggg G:::::G       GGGGGGuuuuuu    uuuuuunnnn  nnnnnnnn    nnnn  nnnnnnnn        ssssssssss             //
//      B::::B     B:::::Bi:::::i   g:::::::::ggg::::gG:::::G              u::::u    u::::un:::nn::::::::nn  n:::nn::::::::nn    ss::::::::::s            //
//      B::::BBBBBB:::::B  i::::i  g:::::::::::::::::gG:::::G              u::::u    u::::un::::::::::::::nn n::::::::::::::nn ss:::::::::::::s           //
//      B:::::::::::::BB   i::::i g::::::ggggg::::::ggG:::::G    GGGGGGGGGGu::::u    u::::unn:::::::::::::::nnn:::::::::::::::ns::::::ssss:::::s          //
//      B::::BBBBBB:::::B  i::::i g:::::g     g:::::g G:::::G    G::::::::Gu::::u    u::::u  n:::::nnnn:::::n  n:::::nnnn:::::n s:::::s  ssssss           //
//      B::::B     B:::::B i::::i g:::::g     g:::::g G:::::G    GGGGG::::Gu::::u    u::::u  n::::n    n::::n  n::::n    n::::n   s::::::s                //
//      B::::B     B:::::B i::::i g:::::g     g:::::g G:::::G        G::::Gu::::u    u::::u  n::::n    n::::n  n::::n    n::::n      s::::::s             //
//      B::::B     B:::::B i::::i g::::::g    g:::::g  G:::::G       G::::Gu:::::uuuu:::::u  n::::n    n::::n  n::::n    n::::nssssss   s:::::s           //
//    BB:::::BBBBBB::::::Bi::::::ig:::::::ggggg:::::g   G:::::GGGGGGGG::::Gu:::::::::::::::uun::::n    n::::n  n::::n    n::::ns:::::ssss::::::s          //
//    B:::::::::::::::::B i::::::i g::::::::::::::::g    GG:::::::::::::::G u:::::::::::::::un::::n    n::::n  n::::n    n::::ns::::::::::::::s           //
//    B::::::::::::::::B  i::::::i  gg::::::::::::::g      GGG::::::GGG:::G  uu::::::::uu:::un::::n    n::::n  n::::n    n::::n s:::::::::::ss            //
//    BBBBBBBBBBBBBBBBB   iiiiiiii    gggggggg::::::g         GGGGGG   GGGG    uuuuuuuu  uuuunnnnnn    nnnnnn  nnnnnn    nnnnnn  sssssssssss              //
//                                            g:::::g                                                                                                     //
//                                gggggg      g:::::g                                                                                                     //
//                                g:::::gg   gg:::::g                                                                                                     //
//                                 g::::::ggg:::::::g                                                                                                     //
//                                  gg:::::::::::::g                                                                                                      //
//                                    ggg::::::ggg                                                                                                        //
//                                       gggggg                                                                                                           //
//                                                                                                                                                        //
//                                                                                                                                                        //
//    UUUUUUUU     UUUUUUUU                   iiii                                                                                                        //
//    U::::::U     U::::::U                  i::::i                                                                                                       //
//    U::::::U     U::::::U                   iiii                                                                                                        //
//    UU:::::U     U:::::UU                                                                                                                               //
//     U:::::U     U:::::Unnnn  nnnnnnnn    iiiiiiivvvvvvv           vvvvvvv eeeeeeeeeeee    rrrrr   rrrrrrrrr       ssssssssss       eeeeeeeeeeee        //
//     U:::::D     D:::::Un:::nn::::::::nn  i:::::i v:::::v         v:::::vee::::::::::::ee  r::::rrr:::::::::r    ss::::::::::s    ee::::::::::::ee      //
//     U:::::D     D:::::Un::::::::::::::nn  i::::i  v:::::v       v:::::ve::::::eeeee:::::eer:::::::::::::::::r ss:::::::::::::s  e::::::eeeee:::::ee    //
//     U:::::D     D:::::Unn:::::::::::::::n i::::i   v:::::v     v:::::ve::::::e     e:::::err::::::rrrrr::::::rs::::::ssss:::::se::::::e     e:::::e    //
//     U:::::D     D:::::U  n:::::nnnn:::::n i::::i    v:::::v   v:::::v e:::::::eeeee::::::e r:::::r     r:::::r s:::::s  ssssss e:::::::eeeee::::::e    //
//     U:::::D     D:::::U  n::::n    n::::n i::::i     v:::::v v:::::v  e:::::::::::::::::e  r:::::r     rrrrrrr   s::::::s      e:::::::::::::::::e     //
//     U:::::D     D:::::U  n::::n    n::::n i::::i      v:::::v:::::v   e::::::eeeeeeeeeee   r:::::r                  s::::::s   e::::::eeeeeeeeeee      //
//     U::::::U   U::::::U  n::::n    n::::n i::::i       v:::::::::v    e:::::::e            r:::::r            ssssss   s:::::s e:::::::e               //
//     U:::::::UUU:::::::U  n::::n    n::::ni::::::i       v:::::::v     e::::::::e           r:::::r            s:::::ssss::::::se::::::::e              //
//      UU:::::::::::::UU   n::::n    n::::ni::::::i        v:::::v       e::::::::eeeeeeee   r:::::r            s::::::::::::::s  e::::::::eeeeeeee      //
//        UU:::::::::UU     n::::n    n::::ni::::::i         v:::v         ee:::::::::::::e   r:::::r             s:::::::::::ss    ee:::::::::::::e      //
//          UUUUUUUUU       nnnnnn    nnnnnniiiiiiii          vvv            eeeeeeeeeeeeee   rrrrrrr              sssssssssss        eeeeeeeeeeeeee      //
//                                                                                                                                                        //
//                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BGU is ERC721Creator {
    constructor() ERC721Creator("BigGunns Universe", "BGU") {}
}