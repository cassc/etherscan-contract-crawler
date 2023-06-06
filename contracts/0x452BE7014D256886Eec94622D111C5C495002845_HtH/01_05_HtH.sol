// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hunger to Hope
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    BBBGGGG:PBBGGBGY: ~5BBBB5! ^BBB?  ^GB#?   ?#B:  J#G.Y#P. ^B#7^BB5: .G#? :YBBBBGJ.:BBBGGGG.Y#BGGGB5^     //
//    ##P7777.G&P~~7#&J!##?::7##7^####~.P##&J   ?&#7~~P#B.5&G  ^#&7^###B?:B&?:B&Y:^!Y5!:B#P????^JBB7~~5#B7    //
//    ##BPPP5.G#BGBBBY:Y&B:  .B&5^##Y#BP&YB&J   J&#PPPB#B.5&B. :B#J~G#5PPG##5?Y#5^:YPGB5~B#GYY5J J##GBB#5!    //
//    #&Y    .G&P.Y&#! :5#BYYG&P:^B&7?G&B^Y#P^  ~P&Y: ^P&P^!GBPYB#G:^#&! 7G#&Y J##YYP#B!.B&GYYY5:J&#:!#&J     //
//    77~     !7~ .!7!   :~!??!   :!!: ~!. ~7~   :!7.  ^!!  .~7?7~. .!!.  .!7^  .~7?7~. .!!!7777:^7!  ~77:    //
//                 ^~~~!!!~.  ^!7!^     .~~^   .~~^   .^~!7~:    ..~~^^~~^:   ~~~^^^^~:  ^^::::               //
//                 YPP##BPP^7B#P5G#G~   ~#&G   ^#&B. 7G##BB##P~ ^BB#GGGB##J^Y5#GGGGG5?~  !7!5Y?               //
//                   :#&?  ~&&7   5&B.  ~##B7!!?##G ?&#5: .^G&#~^##B^::J#&P:##B?777?:                         //
//                   :G&J  ^B&Y:.^P&P.  ~###BBBB##G.5&#7    5#&?:###BBB#B5^:###GGGGG^                         //
//                    ^BB!  :!5GGB#5.   ^B#G.. ~##G ^B#BJ!!Y##P.^##B~^^^.  ^##B?7777~                         //
//                     ::.     .^^:      :^^   .Y#G~ :?P###BP7. ^BBG.      :BBBBBBB#J                         //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HtH is ERC721Creator {
    constructor() ERC721Creator("Hunger to Hope", "HtH") {}
}