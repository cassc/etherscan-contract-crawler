// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lyaly
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//    BBBBBBBBBBBBBBBBB                                                      hhhhhhh                                                                                                                 //
//    B::::::::::::::::B                                                     h:::::h                                                                                                                 //
//    B::::::BBBBBB:::::B                                                    h:::::h                                                                                                                 //
//    BB:::::B     B:::::B                                                   h:::::h                                                                                                                 //
//      B::::B     B:::::B  aaaaaaaaaaaaa  nnnn  nnnnnnnn        ssssssssss   h::::h hhhhh           eeeeeeeeeeee        eeeeeeeeeeee    nnnn  nnnnnnnn        eeeeeeeeeeee    nnnn  nnnnnnnn        //
//      B::::B     B:::::B  a::::::::::::a n:::nn::::::::nn    ss::::::::::s  h::::hh:::::hhh      ee::::::::::::ee    ee::::::::::::ee  n:::nn::::::::nn    ee::::::::::::ee  n:::nn::::::::nn      //
//      B::::BBBBBB:::::B   aaaaaaaaa:::::an::::::::::::::nn ss:::::::::::::s h::::::::::::::hh   e::::::eeeee:::::ee e::::::eeeee:::::een::::::::::::::nn  e::::::eeeee:::::een::::::::::::::nn     //
//      B:::::::::::::BB             a::::ann:::::::::::::::ns::::::ssss:::::sh:::::::hhh::::::h e::::::e     e:::::ee::::::e     e:::::enn:::::::::::::::ne::::::e     e:::::enn:::::::::::::::n    //
//      B::::BBBBBB:::::B     aaaaaaa:::::a  n:::::nnnn:::::n s:::::s  ssssss h::::::h   h::::::he:::::::eeeee::::::ee:::::::eeeee::::::e  n:::::nnnn:::::ne:::::::eeeee::::::e  n:::::nnnn:::::n    //
//      B::::B     B:::::B  aa::::::::::::a  n::::n    n::::n   s::::::s      h:::::h     h:::::he:::::::::::::::::e e:::::::::::::::::e   n::::n    n::::ne:::::::::::::::::e   n::::n    n::::n    //
//      B::::B     B:::::B a::::aaaa::::::a  n::::n    n::::n      s::::::s   h:::::h     h:::::he::::::eeeeeeeeeee  e::::::eeeeeeeeeee    n::::n    n::::ne::::::eeeeeeeeeee    n::::n    n::::n    //
//      B::::B     B:::::Ba::::a    a:::::a  n::::n    n::::nssssss   s:::::s h:::::h     h:::::he:::::::e           e:::::::e             n::::n    n::::ne:::::::e             n::::n    n::::n    //
//    BB:::::BBBBBB::::::Ba::::a    a:::::a  n::::n    n::::ns:::::ssss::::::sh:::::h     h:::::he::::::::e          e::::::::e            n::::n    n::::ne::::::::e            n::::n    n::::n    //
//    B:::::::::::::::::B a:::::aaaa::::::a  n::::n    n::::ns::::::::::::::s h:::::h     h:::::h e::::::::eeeeeeee   e::::::::eeeeeeee    n::::n    n::::n e::::::::eeeeeeee    n::::n    n::::n    //
//    B::::::::::::::::B   a::::::::::aa:::a n::::n    n::::n s:::::::::::ss  h:::::h     h:::::h  ee:::::::::::::e    ee:::::::::::::e    n::::n    n::::n  ee:::::::::::::e    n::::n    n::::n    //
//    BBBBBBBBBBBBBBBBB     aaaaaaaaaa  aaaa nnnnnn    nnnnnn  sssssssssss    hhhhhhh     hhhhhhh    eeeeeeeeeeeeee      eeeeeeeeeeeeee    nnnnnn    nnnnnn    eeeeeeeeeeeeee    nnnnnn    nnnnnn    //
//                                                                                                                                                                                                   //
//    Not copyable                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Anime is ERC721Creator {
    constructor() ERC721Creator("Lyaly", "Anime") {}
}