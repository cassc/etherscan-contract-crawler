// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Burns Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//    BBBBBBBBBBBBBBBBB                                                                               //
//    B::::::::::::::::B                                                                              //
//    B::::::BBBBBB:::::B                                                                             //
//    BB:::::B     B:::::B                                                                            //
//      B::::B     B:::::Buuuuuu    uuuuuu rrrrr   rrrrrrrrr   nnnn  nnnnnnnn        ssssssssss       //
//      B::::B     B:::::Bu::::u    u::::u r::::rrr:::::::::r  n:::nn::::::::nn    ss::::::::::s      //
//      B::::BBBBBB:::::B u::::u    u::::u r:::::::::::::::::r n::::::::::::::nn ss:::::::::::::s     //
//      B:::::::::::::BB  u::::u    u::::u rr::::::rrrrr::::::rnn:::::::::::::::ns::::::ssss:::::s    //
//      B::::BBBBBB:::::B u::::u    u::::u  r:::::r     r:::::r  n:::::nnnn:::::n s:::::s  ssssss     //
//      B::::B     B:::::Bu::::u    u::::u  r:::::r     rrrrrrr  n::::n    n::::n   s::::::s          //
//      B::::B     B:::::Bu::::u    u::::u  r:::::r              n::::n    n::::n      s::::::s       //
//      B::::B     B:::::Bu:::::uuuu:::::u  r:::::r              n::::n    n::::nssssss   s:::::s     //
//    BB:::::BBBBBB::::::Bu:::::::::::::::uur:::::r              n::::n    n::::ns:::::ssss::::::s    //
//    B:::::::::::::::::B  u:::::::::::::::ur:::::r              n::::n    n::::ns::::::::::::::s     //
//    B::::::::::::::::B    uu::::::::uu:::ur:::::r              n::::n    n::::n s:::::::::::ss      //
//    BBBBBBBBBBBBBBBBB       uuuuuuuu  uuuurrrrrrr              nnnnnn    nnnnnn  sssssssssss        //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Burns is ERC721Creator {
    constructor() ERC721Creator("Burns Art", "Burns") {}
}