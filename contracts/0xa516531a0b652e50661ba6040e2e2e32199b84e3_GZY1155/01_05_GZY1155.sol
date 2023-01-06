// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GLITCHZY ENJIN
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                     //
//                                                                                                     //
//    GLITCHZY ENJIN Are Semi-fungible tokens of glitzy 8bit glitch art                                //
//                                                                                                     //
//                                                                                                     //
//            @tS%S%S%S%S%S%S%S%S%SStS          @8888888888888888888888 ..                             //
//           t:SS%S%%S%%S%S%%S%%S%S. ..      . .X.::::::::::::::::::.%:.                               //
//               t:S%%%%%%%%%%%%%%%%%%S .:..     . [email protected];;:;;:;;:;;:;;:;;::%;.                           //
//         t:%%%%%%%%%%%%%%%%%%%S .:..     . [email protected];:;:;:;:;:;;%.;:;;%t;:                                 //
//           .t:S%%%%%%%%%%%%%%%%%%S .:..     . :@.;%.;S.;S.;S :;:%.:.%;:                              //
//               t:%%%%%%%%%%%%%%%%%%%S :::.     . :X.::;:.;:.;:.;:;::;::%;;                           //
//             t:S%%%%%%%%%tt;t;tt;tt :;:.     . .8:;;;;;;;;;;:;:%::;%.%;;                             //
//              .t:%%%%%t%%%tX;ttttttt;X [email protected]@@@@8 :@[email protected]@8X8t;%.::;:::%X;.                          //
//                 t:S%%t%%%%%;@.tt;t;t;t;t.%tttttt% S;t;ttt%%t%%8:.:;;%.;:%:;                         //
//                   .t:%%%%%%%%%;8..      . X.S%%%%%%S.X..       . S%:;::::;S;;;.                     //
//             t:S%%%%%%%%;X        . X S%%%%%%S X..         %;::;:;;..%;t                             //
//                .t:%%%%%%%%%;8t       ..X.S%%%%%%S.X..       . %S:;S.:%::%;t                         //
//                     t:S%%%%%%%%.8        . X.S%%%%%%S.X:.       . @::..;::::%Xt                     //
//                 .%.%ttttttt%t8:       . X S%%%%%%%.X..         SS;;t;;;;S% ;                        //
//                  :8 [email protected]@@ 88 88 [email protected]@%St:......  :;:t;tt8 .t t;                        //
//                     :;t;t;tttt;.%:%;.t;.t;:@[email protected]:;t;t;t;t;X8;t%SSSXXXS:                      //
//                     ....        t:S%%%%%%%tX8888888888X:;:;:;:;::X8.:.......                        //
//                              t:S%%%%%%%[email protected];:;:;;:%S8:.                                  //
//                              .t:%%%%%%%%[email protected]%.;:%:;S.:.X8:.                                 //
//                            %:S%%%%%%%[email protected]%888X ::::.;::X8:.                                    //
//                                t:%t%ttt%[email protected]: ;;;;;;;;SS8;.                                //
//                                 :8 8;888;88SX8S8S8S88 X8;;8 t;8  XS                                 //
//                                ..;t;t;;;tt%[email protected]@@@[email protected]:[email protected]%%%;                                  //
//                                  ......  [email protected]::........                                  //
//                                         .:[email protected]                                            //
//                                          .:[email protected]@%.                                           //
//                                         .:[email protected]%.                                            //
//                                           .:[email protected]                                          //
//                                            :t8XX8888888%:                                           //
//                                            ...::::::;t:.                                            //
//                                             ..    .....                                             //
//                                                                                                     //
//                                                                                                     //
//    Semi-Fungible Tokens with ERC1155                                                                //
//    ERC1155 is a new way to create semi-fungible tokens. However, what are semi-fungible             //
//    tokens? These are new types of tokens that merge different properties of the token               //
//    standards that came before them. Think of it as having the best of both worlds.                  //
//    Let’s take this useful analogy: you’re able to create a store coupon – thus                      //
//    a fungible token – which holds the value until you redeem it. After redeeming the                //
//    coupon, it has zero dollar value and you can not trade it as a regular fungible                  //
//    token. Therefore, the redeemed coupon, with altered properties, becomes unique                   //
//    with information about the item redeemed, the customer, the price, and so on.                    //
//    Hence, it becomes non-fungible. However, a semi-fungible token standard such as                  //
//    ERC1155 is capable of representing both attributes.                                              //
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GZY1155 is ERC1155Creator {
    constructor() ERC1155Creator("GLITCHZY ENJIN", "GZY1155") {}
}