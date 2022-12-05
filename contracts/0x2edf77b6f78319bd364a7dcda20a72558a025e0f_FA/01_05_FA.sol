// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Future Abstract
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//    uZZZZZZZZZZZZZZuZZuZuZuZuZuZuuZuuZuZuuZuZuZuZuZuZZuZZZZZZZZZZZZZZZZZuu    //
//    ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ    //
//    ZZyZyyyyZyZyZyZyyZyZyZyZyZyZZyZZZZZZZyZZZZZZZZZyZZyZZZZZZZZZZZZyZZZZZZ    //
//    ZyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyZyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyZZ    //
//    yyyyyyyyyyyyyyyyyyyyyyyyyyyyyZyyZyyyyyyZyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy    //
//    yyyyyyyyyyyyyyyyyyyyyyyyyyyyZUY77<<<<774UyyyyZyyyyyyyyyyyyyyyyyyyyyyyy    //
//    yVyVVyVVVVVVVVVyyyyyyyyyyV=<_(..._..~..(-_(7Uyyyyyyyyyyyyyyyyyyyyyyyyy    //
//    yVVVVVVVVVVVVVVVVVVyyyWYi....(..._..~..(..._.(7XyyyyyVyVVyVVyVyyVyyyyy    //
//    VyVVVVVVVVVVyVVVVVVVyW]--..~._.~._.._..(..._.(_jdWyVVVVyVVVVVVVVVVVVyy    //
//    [email protected](:...._>~~..._..(..._.(:(XWWVVyVVVVyVVVVVVyVVVy    //
//    [email protected]:..~.(>.._(<~..(..._.(0dXWNXyVVVVVVVVVVVVVVVVy    //
//    VVfffpfpfpffpfffVVdHNMND...-.(o-..(..._(..(<<[email protected]    //
//    VVffffpfpfpffpfffkMMNHB<_.~>._.._sdsc_.._.(-._([email protected]@dVffffffffffffVVVy    //
//    [email protected]~~_((aJ+ggxQmqmugggJJo<<[email protected]    //
//    [email protected]?MMWyyVVVVVVVVVVVVVVV    //
//    fppfpfpffpffffffVWMqMNMMMMMMHMMMHW([email protected]@MMMMMMKMXyyVVVVVVVVVVVVVVV    //
//    [email protected]fpffpf    //
//    [email protected]@HgmWHHH#[email protected]@NVVVVVffffppppppppp    //
//    [email protected]@[email protected]    //
//    kkbbbbppppppppppWMmzVGJzI<<<<+WXHKHMNQv9+~~<<1&Jz6zdNWpppppbbbbbbkbbkb    //
//    qkqqkkkkkbbbbbbbbXMNmgmQkykXHdDd##HMdH#dHWXRdQmgQmMMWbkkkkkkkkkkqqkqkq    //
//    mmmmmmmmmqmqmqqqqkHkWHHHMdHMNMfN#@7=MMHdHMMHRHHWWWXWqqqmmmmmmgmmmmmmmm    //
//    ggggggggggggggggmmHHXpbpkMdNNH3H$((._JHvKMNNWXfffWWggggggggggggggggggg    //
//    @@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@@[email protected]@@    //
//    @@@[email protected]@[email protected]@@@[email protected]@@@@gHkWMMMNUW0d(([email protected]@@@@@@@@@@@@@@@[email protected]    //
//    @@@@@[email protected]@@@@@@@@@@@@gmHMMMNKHMHSkOyuRwhhddMHHWNM#[email protected]@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@gHMMMHHHWw_,R(R([email protected]@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@H    //
//    @[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@@HMMMMMMMMMMMMMMMMMM##[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@HH    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@H    //
//    [email protected]@[email protected]@[email protected]@[email protected]    //
//    HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHNMMWHHHMMHHHHHHHHHHHHHHHHHHHHHHHHHHHHH    //
//    HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHMMM#HHHMHHHHHHHHHHHHHHHHHHHHHHHHHHHHH    //
//    H#HHHH#HHHHHHHHHHH#HH#H#HH#HH####M#M####HHHHHHHHHHHHHHHHHHHHHHHHHHHHHH    //
//    H############################################H#HH#HHHHHHHHHHHHHHHHHH##    //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract FA is ERC1155Creator {
    constructor() ERC1155Creator("Future Abstract", "FA") {}
}