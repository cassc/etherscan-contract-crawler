// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Reborn of Stargaze
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//       SSSSSSSSSSSSSSS TTTTTTTTTTTTTTTTTTTTTTT         AAA               RRRRRRRRRRRRRRRRR           GGGGGGGGGGGGG               AAA               ZZZZZZZZZZZZZZZZZZZEEEEEEEEEEEEEEEEEEEEEE    //
//     SS:::::::::::::::ST:::::::::::::::::::::T        A:::A              R::::::::::::::::R       GGG::::::::::::G              A:::A              Z:::::::::::::::::ZE::::::::::::::::::::E    //
//    S:::::SSSSSS::::::ST:::::::::::::::::::::T       A:::::A             R::::::RRRRRR:::::R    GG:::::::::::::::G             A:::::A             Z:::::::::::::::::ZE::::::::::::::::::::E    //
//    S:::::S     SSSSSSST:::::TT:::::::TT:::::T      A:::::::A            RR:::::R     R:::::R  G:::::GGGGGGGG::::G            A:::::::A            Z:::ZZZZZZZZ:::::Z EE::::::EEEEEEEEE::::E    //
//    S:::::S            TTTTTT  T:::::T  TTTTTT     A:::::::::A             R::::R     R:::::R G:::::G       GGGGGG           A:::::::::A           ZZZZZ     Z:::::Z    E:::::E       EEEEEE    //
//    S:::::S                    T:::::T            A:::::A:::::A            R::::R     R:::::RG:::::G                        A:::::A:::::A                  Z:::::Z      E:::::E                 //
//     S::::SSSS                 T:::::T           A:::::A A:::::A           R::::RRRRRR:::::R G:::::G                       A:::::A A:::::A                Z:::::Z       E::::::EEEEEEEEEE       //
//      SS::::::SSSSS            T:::::T          A:::::A   A:::::A          R:::::::::::::RR  G:::::G    GGGGGGGGGG        A:::::A   A:::::A              Z:::::Z        E:::::::::::::::E       //
//        SSS::::::::SS          T:::::T         A:::::A     A:::::A         R::::RRRRRR:::::R G:::::G    G::::::::G       A:::::A     A:::::A            Z:::::Z         E:::::::::::::::E       //
//           SSSSSS::::S         T:::::T        A:::::AAAAAAAAA:::::A        R::::R     R:::::RG:::::G    GGGGG::::G      A:::::AAAAAAAAA:::::A          Z:::::Z          E::::::EEEEEEEEEE       //
//                S:::::S        T:::::T       A:::::::::::::::::::::A       R::::R     R:::::RG:::::G        G::::G     A:::::::::::::::::::::A        Z:::::Z           E:::::E                 //
//                S:::::S        T:::::T      A:::::AAAAAAAAAAAAA:::::A      R::::R     R:::::R G:::::G       G::::G    A:::::AAAAAAAAAAAAA:::::A    ZZZ:::::Z     ZZZZZ  E:::::E       EEEEEE    //
//    SSSSSSS     S:::::S      TT:::::::TT   A:::::A             A:::::A   RR:::::R     R:::::R  G:::::GGGGGGGG::::G   A:::::A             A:::::A   Z::::::ZZZZZZZZ:::ZEE::::::EEEEEEEE:::::E    //
//    S::::::SSSSSS:::::S      T:::::::::T  A:::::A               A:::::A  R::::::R     R:::::R   GG:::::::::::::::G  A:::::A               A:::::A  Z:::::::::::::::::ZE::::::::::::::::::::E    //
//    S:::::::::::::::SS       T:::::::::T A:::::A                 A:::::A R::::::R     R:::::R     GGG::::::GGG:::G A:::::A                 A:::::A Z:::::::::::::::::ZE::::::::::::::::::::E    //
//     SSSSSSSSSSSSSSS         TTTTTTTTTTTAAAAAAA                   AAAAAAARRRRRRRR     RRRRRRR        GGGGGG   GGGGAAAAAAA                   AAAAAAAZZZZZZZZZZZZZZZZZZZEEEEEEEEEEEEEEEEEEEEEE    //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//       SSSSSSSSSSSSSSS TTTTTTTTTTTTTTTTTTTTTTT         AAA               RRRRRRRRRRRRRRRRR           GGGGGGGGGGGGG               AAA               ZZZZZZZZZZZZZZZZZZZEEEEEEEEEEEEEEEEEEEEEE    //
//     SS:::::::::::::::ST:::::::::::::::::::::T        A:::A              R::::::::::::::::R       GGG::::::::::::G              A:::A              Z:::::::::::::::::ZE::::::::::::::::::::E    //
//    S:::::SSSSSS::::::ST:::::::::::::::::::::T       A:::::A             R::::::RRRRRR:::::R    GG:::::::::::::::G             A:::::A             Z:::::::::::::::::ZE::::::::::::::::::::E    //
//    S:::::S     SSSSSSST:::::TT:::::::TT:::::T      A:::::::A            RR:::::R     R:::::R  G:::::GGGGGGGG::::G            A:::::::A            Z:::ZZZZZZZZ:::::Z EE::::::EEEEEEEEE::::E    //
//    S:::::S            TTTTTT  T:::::T  TTTTTT     A:::::::::A             R::::R     R:::::R G:::::G       GGGGGG           A:::::::::A           ZZZZZ     Z:::::Z    E:::::E       EEEEEE    //
//    S:::::S                    T:::::T            A:::::A:::::A            R::::R     R:::::RG:::::G                        A:::::A:::::A                  Z:::::Z      E:::::E                 //
//     S::::SSSS                 T:::::T           A:::::A A:::::A           R::::RRRRRR:::::R G:::::G                       A:::::A A:::::A                Z:::::Z       E::::::EEEEEEEEEE       //
//      SS::::::SSSSS            T:::::T          A:::::A   A:::::A          R:::::::::::::RR  G:::::G    GGGGGGGGGG        A:::::A   A:::::A              Z:::::Z        E:::::::::::::::E       //
//        SSS::::::::SS          T:::::T         A:::::A     A:::::A         R::::RRRRRR:::::R G:::::G    G::::::::G       A:::::A     A:::::A            Z:::::Z         E:::::::::::::::E       //
//           SSSSSS::::S         T:::::T        A:::::AAAAAAAAA:::::A        R::::R     R:::::RG:::::G    GGGGG::::G      A:::::AAAAAAAAA:::::A          Z:::::Z          E::::::EEEEEEEEEE       //
//                S:::::S        T:::::T       A:::::::::::::::::::::A       R::::R     R:::::RG:::::G        G::::G     A:::::::::::::::::::::A        Z:::::Z           E:::::E                 //
//                S:::::S        T:::::T      A:::::AAAAAAAAAAAAA:::::A      R::::R     R:::::R G:::::G       G::::G    A:::::AAAAAAAAAAAAA:::::A    ZZZ:::::Z     ZZZZZ  E:::::E       EEEEEE    //
//    SSSSSSS     S:::::S      TT:::::::TT   A:::::A             A:::::A   RR:::::R     R:::::R  G:::::GGGGGGGG::::G   A:::::A             A:::::A   Z::::::ZZZZZZZZ:::ZEE::::::EEEEEEEE:::::E    //
//    S::::::SSSSSS:::::S      T:::::::::T  A:::::A               A:::::A  R::::::R     R:::::R   GG:::::::::::::::G  A:::::A               A:::::A  Z:::::::::::::::::ZE::::::::::::::::::::E    //
//    S:::::::::::::::SS       T:::::::::T A:::::A                 A:::::A R::::::R     R:::::R     GGG::::::GGG:::G A:::::A                 A:::::A Z:::::::::::::::::ZE::::::::::::::::::::E    //
//     SSSSSSSSSSSSSSS         TTTTTTTTTTTAAAAAAA                   AAAAAAARRRRRRRR     RRRRRRR        GGGGGG   GGGGAAAAAAA                   AAAAAAAZZZZZZZZZZZZZZZZZZZEEEEEEEEEEEEEEEEEEEEEE    //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//       SSSSSSSSSSSSSSS TTTTTTTTTTTTTTTTTTTTTTT         AAA               RRRRRRRRRRRRRRRRR           GGGGGGGGGGGGG               AAA               ZZZZZZZZZZZZZZZZZZZEEEEEEEEEEEEEEEEEEEEEE    //
//     SS:::::::::::::::ST:::::::::::::::::::::T        A:::A              R::::::::::::::::R       GGG::::::::::::G              A:::A              Z:::::::::::::::::ZE::::::::::::::::::::E    //
//    S:::::SSSSSS::::::ST:::::::::::::::::::::T       A:::::A             R::::::RRRRRR:::::R    GG:::::::::::::::G             A:::::A             Z:::::::::::::::::ZE::::::::::::::::::::E    //
//    S:::::S     SSSSSSST:::::TT:::::::TT:::::T      A:::::::A            RR:::::R     R:::::R  G:::::GGGGGGGG::::G            A:::::::A            Z:::ZZZZZZZZ:::::Z EE::::::EEEEEEEEE::::E    //
//    S:::::S            TTTTTT  T:::::T  TTTTTT     A:::::::::A             R::::R     R:::::R G:::::G       GGGGGG           A:::::::::A           ZZZZZ     Z:::::Z    E:::::E       EEEEEE    //
//    S:::::S                    T:::::T            A:::::A:::::A            R::::R     R:::::RG:::::G                        A:::::A:::::A                  Z:::::Z      E:::::E                 //
//     S::::SSSS                 T:::::T           A:::::A A:::::A           R::::RRRRRR:::::R G:::::G                       A:::::A A:::::A                Z:::::Z       E::::::EEEEEEEEEE       //
//      SS::::::SSSSS            T:::::T          A:::::A   A:::::A          R:::::::::::::RR  G:::::G    GGGGGGGGGG        A:::::A   A:::::A              Z:::::Z        E:::::::::::::::E       //
//        SSS::::::::SS          T:::::T         A:::::A     A:::::A         R::::RRRRRR:::::R G:::::G    G::::::::G       A:::::A     A:::::A            Z:::::Z         E:::::::::::::::E       //
//           SSSSSS::::S         T:::::T        A:::::AAAAAAAAA:::::A        R::::R     R:::::RG:::::G    GGGGG::::G      A:::::AAAAAAAAA:::::A          Z:::::Z          E::::::EEEEEEEEEE       //
//                S:::::S        T:::::T       A:::::::::::::::::::::A       R::::R     R:::::RG:::::G        G::::G     A:::::::::::::::::::::A        Z:::::Z           E:::::E                 //
//                S:::::S        T:::::T      A:::::AAAAAAAAAAAAA:::::A      R::::R     R:::::R G:::::G       G::::G    A:::::AAAAAAAAAAAAA:::::A    ZZZ:::::Z     ZZZZZ  E:::::E       EEEEEE    //
//    SSSSSSS     S:::::S      TT:::::::TT   A:::::A             A:::::A   RR:::::R     R:::::R  G:::::GGGGGGGG::::G   A:::::A             A:::::A   Z::::::ZZZZZZZZ:::ZEE::::::EEEEEEEE:::::E    //
//    S::::::SSSSSS:::::S      T:::::::::T  A:::::A               A:::::A  R::::::R     R:::::R   GG:::::::::::::::G  A:::::A               A:::::A  Z:::::::::::::::::ZE::::::::::::::::::::E    //
//    S:::::::::::::::SS       T:::::::::T A:::::A                 A:::::A R::::::R     R:::::R     GGG::::::GGG:::G A:::::A                 A:::::A Z:::::::::::::::::ZE::::::::::::::::::::E    //
//     SSSSSSSSSSSSSSS         TTTTTTTTTTTAAAAAAA                   AAAAAAARRRRRRRR     RRRRRRR        GGGGGG   GGGGAAAAAAA                   AAAAAAAZZZZZZZZZZZZZZZZZZZEEEEEEEEEEEEEEEEEEEEEE    //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//       SSSSSSSSSSSSSSS TTTTTTTTTTTTTTTTTTTTTTT         AAA               RRRRRRRRRRRRRRRRR           GGGGGGGGGGGGG               AAA               ZZZZZZZZZZZZZZZZZZZEEEEEEEEEEEEEEEEEEEEEE    //
//     SS:::::::::::::::ST:::::::::::::::::::::T        A:::A              R::::::::::::::::R       GGG::::::::::::G              A:::A              Z:::::::::::::::::ZE::::::::::::::::::::E    //
//    S:::::SSSSSS::::::ST:::::::::::::::::::::T       A:::::A             R::::::RRRRRR:::::R    GG:::::::::::::::G             A:::::A             Z:::::::::::::::::ZE::::::::::::::::::::E    //
//    S:::::S     SSSSSSST:::::TT:::::::TT:::::T      A:::::::A            RR:::::R     R:::::R  G:::::GGGGGGGG::::G            A:::::::A            Z:::ZZZZZZZZ:::::Z EE::::::EEEEEEEEE::::E    //
//    S:::::S                                                                                                                                                                                     //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract STRGZ is ERC721Creator {
    constructor() ERC721Creator("The Reborn of Stargaze", "STRGZ") {}
}