// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dan & Antonio
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//    DDDDDDDDDDDDD                                                    &&&&&&&&&&                        AAA                                        tttt                                               iiii                       //
//    D::::::::::::DDD                                                &::::::::::&                      A:::A                                    ttt:::t                                              i::::i                      //
//    D:::::::::::::::DD                                             &::::&&&:::::&                    A:::::A                                   t:::::t                                               iiii                       //
//    DDD:::::DDDDD:::::D                                           &::::&   &::::&                   A:::::::A                                  t:::::t                                                                          //
//      D:::::D    D:::::D  aaaaaaaaaaaaa  nnnn  nnnnnnnn           &::::&   &::::&                  A:::::::::A         nnnn  nnnnnnnn    ttttttt:::::ttttttt       ooooooooooo   nnnn  nnnnnnnn    iiiiiii    ooooooooooo       //
//      D:::::D     D:::::D a::::::::::::a n:::nn::::::::nn          &::::&&&::::&                  A:::::A:::::A        n:::nn::::::::nn  t:::::::::::::::::t     oo:::::::::::oo n:::nn::::::::nn  i:::::i  oo:::::::::::oo     //
//      D:::::D     D:::::D aaaaaaaaa:::::an::::::::::::::nn         &::::::::::&                  A:::::A A:::::A       n::::::::::::::nn t:::::::::::::::::t    o:::::::::::::::on::::::::::::::nn  i::::i o:::::::::::::::o    //
//      D:::::D     D:::::D          a::::ann:::::::::::::::n         &:::::::&&                  A:::::A   A:::::A      nn:::::::::::::::ntttttt:::::::tttttt    o:::::ooooo:::::onn:::::::::::::::n i::::i o:::::ooooo:::::o    //
//      D:::::D     D:::::D   aaaaaaa:::::a  n:::::nnnn:::::n       &::::::::&   &&&&            A:::::A     A:::::A       n:::::nnnn:::::n      t:::::t          o::::o     o::::o  n:::::nnnn:::::n i::::i o::::o     o::::o    //
//      D:::::D     D:::::D aa::::::::::::a  n::::n    n::::n      &:::::&&::&  &:::&           A:::::AAAAAAAAA:::::A      n::::n    n::::n      t:::::t          o::::o     o::::o  n::::n    n::::n i::::i o::::o     o::::o    //
//      D:::::D     D:::::Da::::aaaa::::::a  n::::n    n::::n     &:::::&  &::&&:::&&          A:::::::::::::::::::::A     n::::n    n::::n      t:::::t          o::::o     o::::o  n::::n    n::::n i::::i o::::o     o::::o    //
//      D:::::D    D:::::Da::::a    a:::::a  n::::n    n::::n     &:::::&   &:::::&           A:::::AAAAAAAAAAAAA:::::A    n::::n    n::::n      t:::::t    tttttto::::o     o::::o  n::::n    n::::n i::::i o::::o     o::::o    //
//    DDD:::::DDDDD:::::D a::::a    a:::::a  n::::n    n::::n     &:::::&    &::::&          A:::::A             A:::::A   n::::n    n::::n      t::::::tttt:::::to:::::ooooo:::::o  n::::n    n::::ni::::::io:::::ooooo:::::o    //
//    D:::::::::::::::DD  a:::::aaaa::::::a  n::::n    n::::n     &::::::&&&&::::::&&       A:::::A               A:::::A  n::::n    n::::n      tt::::::::::::::to:::::::::::::::o  n::::n    n::::ni::::::io:::::::::::::::o    //
//    D::::::::::::DDD     a::::::::::aa:::a n::::n    n::::n      &&::::::::&&&::::&      A:::::A                 A:::::A n::::n    n::::n        tt:::::::::::tt oo:::::::::::oo   n::::n    n::::ni::::::i oo:::::::::::oo     //
//    D∞DDDDDDDDDDD         aaaaaaaaaa  aaaa nnnnnn    nnnnnn        &&&&&&&&   &&&&&     A∞AAAAA                   AAAAAAAnnnnnn    nnnnnn          ttttttttttt     ooooooooooo     nnnnnn    nnnnnniiiiiiii   ooooooooooo       //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DA is ERC721Creator {
    constructor() ERC721Creator("Dan & Antonio", "DA") {}
}