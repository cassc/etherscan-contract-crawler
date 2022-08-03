// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: B Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//    bbbbbbbb                                                                                                                                                                                 //
//    b::::::b                     tttt         hhhhhhh                                                                                                   tttt         hhhhhhh                 //
//    b::::::b                  ttt:::t         h:::::h                                                                                                ttt:::t         h:::::h                 //
//    b::::::b                  t:::::t         h:::::h                                                                                                t:::::t         h:::::h                 //
//     b:::::b                  t:::::t         h:::::h                                                                                                t:::::t         h:::::h                 //
//     b:::::bbbbbbbbb    ttttttt:::::ttttttt    h::::h hhhhh           eeeeeeeeeeee       mmmmmmm    mmmmmmm      ooooooooooo   uuuuuu    uuuuuuttttttt:::::ttttttt    h::::h hhhhh           //
//     b::::::::::::::bb  t:::::::::::::::::t    h::::hh:::::hhh      ee::::::::::::ee   mm:::::::m  m:::::::mm  oo:::::::::::oo u::::u    u::::ut:::::::::::::::::t    h::::hh:::::hhh        //
//     b::::::::::::::::b t:::::::::::::::::t    h::::::::::::::hh   e::::::eeeee:::::eem::::::::::mm::::::::::mo:::::::::::::::ou::::u    u::::ut:::::::::::::::::t    h::::::::::::::hh      //
//     b:::::bbbbb:::::::btttttt:::::::tttttt    h:::::::hhh::::::h e::::::e     e:::::em::::::::::::::::::::::mo:::::ooooo:::::ou::::u    u::::utttttt:::::::tttttt    h:::::::hhh::::::h     //
//     b:::::b    b::::::b      t:::::t          h::::::h   h::::::he:::::::eeeee::::::em:::::mmm::::::mmm:::::mo::::o     o::::ou::::u    u::::u      t:::::t          h::::::h   h::::::h    //
//     b:::::b     b:::::b      t:::::t          h:::::h     h:::::he:::::::::::::::::e m::::m   m::::m   m::::mo::::o     o::::ou::::u    u::::u      t:::::t          h:::::h     h:::::h    //
//     b:::::b     b:::::b      t:::::t          h:::::h     h:::::he::::::eeeeeeeeeee  m::::m   m::::m   m::::mo::::o     o::::ou::::u    u::::u      t:::::t          h:::::h     h:::::h    //
//     b:::::b     b:::::b      t:::::t    tttttth:::::h     h:::::he:::::::e           m::::m   m::::m   m::::mo::::o     o::::ou:::::uuuu:::::u      t:::::t    tttttth:::::h     h:::::h    //
//     b:::::bbbbbb::::::b      t::::::tttt:::::th:::::h     h:::::he::::::::e          m::::m   m::::m   m::::mo:::::ooooo:::::ou:::::::::::::::uu    t::::::tttt:::::th:::::h     h:::::h    //
//     b::::::::::::::::b       tt::::::::::::::th:::::h     h:::::h e::::::::eeeeeeee  m::::m   m::::m   m::::mo:::::::::::::::o u:::::::::::::::u    tt::::::::::::::th:::::h     h:::::h    //
//     b:::::::::::::::b          tt:::::::::::tth:::::h     h:::::h  ee:::::::::::::e  m::::m   m::::m   m::::m oo:::::::::::oo   uu::::::::uu:::u      tt:::::::::::tth:::::h     h:::::h    //
//     bbbbbbbbbbbbbbbb             ttttttttttt  hhhhhhh     hhhhhhh    eeeeeeeeeeeeee  mmmmmm   mmmmmm   mmmmmm   ooooooooooo       uuuuuuuu  uuuu        ttttttttttt  hhhhhhh     hhhhhhh    //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                      dddddddd                                                                                                                                               //
//    EEEEEEEEEEEEEEEEEEEEEE            d::::::d  iiii          tttt            iiii                                                                                                           //
//    E::::::::::::::::::::E            d::::::d i::::i      ttt:::t           i::::i                                                                                                          //
//    E::::::::::::::::::::E            d::::::d  iiii       t:::::t            iiii                                                                                                           //
//    EE::::::EEEEEEEEE::::E            d:::::d              t:::::t                                                                                                                           //
//      E:::::E       EEEEEE    ddddddddd:::::d iiiiiiittttttt:::::ttttttt    iiiiiii    ooooooooooo   nnnn  nnnnnnnn        ssssssssss                                                        //
//      E:::::E               dd::::::::::::::d i:::::it:::::::::::::::::t    i:::::i  oo:::::::::::oo n:::nn::::::::nn    ss::::::::::s                                                       //
//      E::::::EEEEEEEEEE    d::::::::::::::::d  i::::it:::::::::::::::::t     i::::i o:::::::::::::::on::::::::::::::nn ss:::::::::::::s                                                      //
//      E:::::::::::::::E   d:::::::ddddd:::::d  i::::itttttt:::::::tttttt     i::::i o:::::ooooo:::::onn:::::::::::::::ns::::::ssss:::::s                                                     //
//      E:::::::::::::::E   d::::::d    d:::::d  i::::i      t:::::t           i::::i o::::o     o::::o  n:::::nnnn:::::n s:::::s  ssssss                                                      //
//      E::::::EEEEEEEEEE   d:::::d     d:::::d  i::::i      t:::::t           i::::i o::::o     o::::o  n::::n    n::::n   s::::::s                                                           //
//      E:::::E             d:::::d     d:::::d  i::::i      t:::::t           i::::i o::::o     o::::o  n::::n    n::::n      s::::::s                                                        //
//      E:::::E       EEEEEEd:::::d     d:::::d  i::::i      t:::::t    tttttt i::::i o::::o     o::::o  n::::n    n::::nssssss   s:::::s                                                      //
//    EE::::::EEEEEEEE:::::Ed::::::ddddd::::::ddi::::::i     t::::::tttt:::::ti::::::io:::::ooooo:::::o  n::::n    n::::ns:::::ssss::::::s                                                     //
//    E::::::::::::::::::::E d:::::::::::::::::di::::::i     tt::::::::::::::ti::::::io:::::::::::::::o  n::::n    n::::ns::::::::::::::s                                                      //
//    E::::::::::::::::::::E  d:::::::::ddd::::di::::::i       tt:::::::::::tti::::::i oo:::::::::::oo   n::::n    n::::n s:::::::::::ss                                                       //
//    EEEEEEEEEEEEEEEEEEEEEE   ddddddddd   dddddiiiiiiii         ttttttttttt  iiiiiiii   ooooooooooo     nnnnnn    nnnnnn  sssssssssss                                                         //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Bdtions is ERC721Creator {
    constructor() ERC721Creator("B Editions", "Bdtions") {}
}